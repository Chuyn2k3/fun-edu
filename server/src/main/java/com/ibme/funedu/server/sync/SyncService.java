package com.ibme.funedu.server.sync;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** One round trip: store the device's changes, return what it has not seen. */
@Service
public class SyncService {

    public static final int MAX_CHANGES = 2000;
    public static final int MAX_PAYLOAD_BYTES = 16 * 1024;
    public static final int PAGE = 1000;

    public record Change(String key, JsonNode payload, boolean deleted, Long baseVersion) {}

    public record Record(String key, JsonNode payload, boolean deleted, long version) {}

    public record Result(long version, List<Record> records, List<String> conflicts, boolean hasMore) {}

    public static class BadSyncRequest extends RuntimeException {
        BadSyncRequest(String reason) {
            super(reason, null, false, false);
        }
    }

    private final JdbcTemplate jdbc;
    private final ObjectMapper json;

    public SyncService(JdbcTemplate jdbc, ObjectMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Transactional
    public Result sync(UUID familyId, long since, List<Change> changes) {
        validate(changes);
        // One sync at a time per family, so versions are visible in order and
        // a cursor never skips a record committed later with a lower version.
        jdbc.query("SELECT pg_advisory_xact_lock(hashtextextended(?, 0))", rs -> null, familyId.toString());

        List<String> conflicts = new ArrayList<>();
        for (Change c : changes) {
            List<Long> current = jdbc.queryForList(
                    "SELECT version FROM sync_records WHERE family_id = ? AND key = ?", Long.class, familyId, c.key());
            Long serverVersion = current.isEmpty() ? null : current.get(0);
            boolean fresh = serverVersion == null ? c.baseVersion() == null : serverVersion.equals(c.baseVersion());
            if (!fresh) {
                conflicts.add(c.key());
                continue;
            }
            String payload = c.deleted() ? null : write(c.payload());
            jdbc.update("""
                    INSERT INTO sync_records (family_id, key, kind, payload, deleted, version)
                    VALUES (?, ?, ?, ?::jsonb, ?, nextval('sync_version_seq'))
                    ON CONFLICT (family_id, key) DO UPDATE
                    SET payload = EXCLUDED.payload, deleted = EXCLUDED.deleted,
                        version = EXCLUDED.version, updated_at = now()
                    """, familyId, c.key(), SyncKinds.kindOf(c.key()), payload, c.deleted());
        }

        List<Record> page = jdbc.query("""
                SELECT key, payload::text, deleted, version FROM sync_records
                WHERE family_id = ? AND version > ? ORDER BY version LIMIT ?
                """, (rs, i) -> new Record(rs.getString(1), read(rs.getString(2)), rs.getBoolean(3), rs.getLong(4)),
                familyId, since, PAGE + 1);
        boolean hasMore = page.size() > PAGE;
        if (hasMore) page = page.subList(0, PAGE);
        long version = page.isEmpty() ? since : page.get(page.size() - 1).version();

        // The device must see the winning copy of every key it lost on,
        // even one it had already pulled.
        Map<String, Record> out = new LinkedHashMap<>();
        page.forEach(r -> out.put(r.key(), r));
        for (String key : conflicts) {
            if (out.containsKey(key)) continue;
            jdbc.query("SELECT key, payload::text, deleted, version FROM sync_records WHERE family_id = ? AND key = ?",
                    rs -> {
                        out.put(key, new Record(rs.getString(1), read(rs.getString(2)), rs.getBoolean(3),
                                rs.getLong(4)));
                    }, familyId, key);
        }
        return new Result(version, List.copyOf(out.values()), conflicts, hasMore);
    }

    private void validate(List<Change> changes) {
        if (changes.size() > MAX_CHANGES) throw new BadSyncRequest("too many changes");
        var seen = new java.util.HashSet<String>();
        for (Change c : changes) {
            if (SyncKinds.kindOf(c.key()) == null) throw new BadSyncRequest("bad key");
            if (!seen.add(c.key())) throw new BadSyncRequest("duplicate key");
            if (c.deleted()) continue;
            if (c.payload() == null || c.payload().isNull() || !c.payload().isObject()) {
                throw new BadSyncRequest("missing payload");
            }
            if (write(c.payload()).getBytes(java.nio.charset.StandardCharsets.UTF_8).length > MAX_PAYLOAD_BYTES) {
                throw new BadSyncRequest("payload too big");
            }
        }
    }

    private String write(JsonNode node) {
        try {
            return json.writeValueAsString(node);
        } catch (JsonProcessingException e) {
            throw new BadSyncRequest("bad payload");
        }
    }

    private JsonNode read(String text) {
        if (text == null) return null;
        try {
            return json.readTree(text);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }
}
