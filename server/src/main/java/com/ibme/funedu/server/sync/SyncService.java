package com.ibme.funedu.server.sync;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.HashMap;
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
    public static final int MAX_DEPTH = 6;
    public static final int MAX_STRING_BYTES = 4 * 1024;
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
        if (!changes.isEmpty()) {
            String[] keys = changes.stream().map(Change::key).toArray(String[]::new);
            Map<String, Long> serverVersions = new HashMap<>();
            jdbc.query(
                    "SELECT key, version FROM sync_records WHERE family_id = ? AND key = ANY(?)",
                    rs -> {
                        serverVersions.put(rs.getString(1), rs.getLong(2));
                    },
                    familyId, keys);

            List<Object[]> batch = new ArrayList<>();
            List<String> deletedKids = new ArrayList<>();
            for (Change c : changes) {
                Long serverVersion = serverVersions.get(c.key());
                boolean fresh = serverVersion == null ? c.baseVersion() == null : serverVersion.equals(c.baseVersion());
                if (!fresh) {
                    conflicts.add(c.key());
                    continue;
                }
                String payload = c.deleted() ? null : write(c.payload());
                if (c.deleted() && "kid".equals(SyncKinds.kindOf(c.key()))) {
                    deletedKids.add(c.key().substring("kid:".length()));
                }
                batch.add(new Object[] {
                        familyId, c.key(), SyncKinds.kindOf(c.key()), payload, c.deleted()
                });
            }

            if (!batch.isEmpty()) {
                jdbc.batchUpdate("""
                        INSERT INTO sync_records (family_id, key, kind, payload, deleted, version)
                        VALUES (?, ?, ?, ?::jsonb, ?, nextval('sync_version_seq'))
                        ON CONFLICT (family_id, key) DO UPDATE
                        SET payload = EXCLUDED.payload, deleted = EXCLUDED.deleted,
                            version = EXCLUDED.version, updated_at = now()
                        """, batch);
            }
            // A deleted kid must not stay visible to friends: drop its showcase
            // (reactions cascade) in the same transaction.
            if (!deletedKids.isEmpty()) {
                jdbc.update("DELETE FROM showcases WHERE family_id = ? AND kid_uuid = ANY(?)",
                        familyId, deletedKids.toArray(String[]::new));
            }
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
        List<String> missingConflicts = conflicts.stream()
                .filter(k -> !out.containsKey(k))
                .toList();
        if (!missingConflicts.isEmpty()) {
            String[] missingKeys = missingConflicts.toArray(String[]::new);
            jdbc.query(
                    "SELECT key, payload::text, deleted, version FROM sync_records WHERE family_id = ? AND key = ANY(?)",
                    rs -> {
                        out.put(rs.getString(1), new Record(rs.getString(1), read(rs.getString(2)), rs.getBoolean(3), rs.getLong(4)));
                    },
                    familyId, missingKeys);
        }
        return new Result(version, List.copyOf(out.values()), conflicts, hasMore);
    }

    private void validate(List<Change> changes) {
        if (changes.size() > MAX_CHANGES) throw new BadSyncRequest("too many changes");
        var seen = new java.util.HashSet<String>();
        for (Change c : changes) {
            String kind = SyncKinds.kindOf(c.key());
            if (kind == null) throw new BadSyncRequest("bad key");
            if (!seen.add(c.key())) throw new BadSyncRequest("duplicate key");
            if (c.deleted()) continue;
            if (c.payload() == null || c.payload().isNull() || !c.payload().isObject()) {
                throw new BadSyncRequest("missing payload");
            }
            if (write(c.payload()).getBytes(java.nio.charset.StandardCharsets.UTF_8).length > MAX_PAYLOAD_BYTES) {
                throw new BadSyncRequest("payload too big");
            }
            validateTree(c.payload(), 0, !"page".equals(kind));
        }
    }

    private static void validateTree(JsonNode node, int parentDepth, boolean limitStrings) {
        if (node.isObject() || node.isArray()) {
            int depth = parentDepth + 1;
            if (depth > MAX_DEPTH) throw new BadSyncRequest("payload too deep");
            if (node.isObject()) {
                var fields = node.fields();
                while (fields.hasNext()) {
                    var entry = fields.next();
                    if (limitStrings
                            && entry.getKey().getBytes(java.nio.charset.StandardCharsets.UTF_8).length
                                    > MAX_STRING_BYTES) {
                        throw new BadSyncRequest("string too long");
                    }
                    validateTree(entry.getValue(), depth, limitStrings);
                }
            } else {
                for (JsonNode child : node) {
                    validateTree(child, depth, limitStrings);
                }
            }
        } else if (limitStrings && node.isTextual()) {
            if (node.asText().getBytes(java.nio.charset.StandardCharsets.UTF_8).length > MAX_STRING_BYTES) {
                throw new BadSyncRequest("string too long");
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
