package com.ibme.funedu.server.friends;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Stores and serves kid showcase cards and friend reactions. */
@Service
public class ShowcaseService {

    static final int MAX_PAYLOAD_BYTES = 4096;
    static final int MAX_KID_UUID_LEN = 64;
    static final int MAX_PINNED = 3;
    static final int MAX_PINNED_ITEM_LEN = 64;
    static final String FALLBACK_NICKNAME = "Bạn đua";

    private static final Set<String> TOP_LEVEL_KEYS = Set.of(
            "nickname", "avatar", "rocket", "trail", "pinned", "races", "wins", "stickers", "learning");
    private static final Map<String, Integer> STRING_LIMITS = Map.of(
            "nickname", 40,
            "avatar", 120,
            "rocket", 64,
            "trail", 64);
    private static final Set<String> INT_FIELDS = Set.of("races", "wins", "stickers");
    private static final Set<String> LEARNING_KEYS = Set.of("glyphs", "lessons", "stars");
    private static final List<String> ORDERED_REACTION_KINDS = List.of("clap", "heart", "star");
    private static final Set<String> REACTION_KINDS = Set.copyOf(ORDERED_REACTION_KINDS);

    public static final class ShowcaseException extends RuntimeException {
        private final HttpStatus status;
        private final String code;

        private ShowcaseException(HttpStatus status, String code) {
            super(code, null, false, false);
            this.status = status;
            this.code = code;
        }

        public HttpStatus status() {
            return status;
        }

        public String code() {
            return code;
        }

        static ShowcaseException badRequest() {
            return new ShowcaseException(HttpStatus.BAD_REQUEST, "bad_request");
        }

        static ShowcaseException notFound() {
            return new ShowcaseException(HttpStatus.NOT_FOUND, "not_found");
        }
    }

    private final JdbcTemplate jdbc;
    private final ObjectMapper json;
    private final LobbyNotifier lobbyNotifier;

    public ShowcaseService(JdbcTemplate jdbc, ObjectMapper json, LobbyNotifier lobbyNotifier) {
        this.jdbc = jdbc;
        this.json = json;
        this.lobbyNotifier = lobbyNotifier;
    }

    public void put(UUID callerFamily, String kidUuid, byte[] rawBody) {
        if (kidUuid == null || kidUuid.isBlank() || kidUuid.length() > MAX_KID_UUID_LEN || kidUuid.indexOf('\0') >= 0) {
            throw ShowcaseException.badRequest();
        }
        if (rawBody == null || rawBody.length == 0 || rawBody.length > MAX_PAYLOAD_BYTES) {
            throw ShowcaseException.badRequest();
        }

        JsonNode root;
        try {
            root = json.readTree(rawBody);
        } catch (IOException e) {
            throw ShowcaseException.badRequest();
        }
        if (root == null || !root.isObject()) {
            throw ShowcaseException.badRequest();
        }

        ObjectNode clean = validateAndCanonicalize(root);
        String serialized;
        try {
            serialized = json.writeValueAsString(clean);
        } catch (JsonProcessingException e) {
            throw ShowcaseException.badRequest();
        }
        if (serialized.getBytes(StandardCharsets.UTF_8).length > MAX_PAYLOAD_BYTES) {
            throw ShowcaseException.badRequest();
        }

        jdbc.update("""
                INSERT INTO showcases (family_id, kid_uuid, payload, updated_at)
                VALUES (?, ?, ?::jsonb, now())
                ON CONFLICT (family_id, kid_uuid) DO UPDATE
                SET payload = EXCLUDED.payload, updated_at = now()
                """,
                callerFamily, kidUuid, serialized);
    }

    public ObjectNode get(UUID callerFamily, UUID targetFamily, String kidUuid) {
        if (targetFamily == null || kidUuid == null || kidUuid.isBlank() || kidUuid.length() > MAX_KID_UUID_LEN) {
            throw ShowcaseException.notFound();
        }
        if (!callerFamily.equals(targetFamily) && !isFriend(callerFamily, targetFamily)) {
            throw ShowcaseException.notFound();
        }

        List<String> payloads = jdbc.query(
                "SELECT payload::text FROM showcases WHERE family_id = ? AND kid_uuid = ?",
                (rs, i) -> rs.getString(1),
                targetFamily, kidUuid);
        if (payloads.isEmpty()) {
            throw ShowcaseException.notFound();
        }

        Map<String, Integer> reactions = new LinkedHashMap<>();
        for (String kind : ORDERED_REACTION_KINDS) {
            reactions.put(kind, 0);
        }
        Set<String> mineSet = new HashSet<>();
        jdbc.query("""
                SELECT kind, count(*)::int, bool_or(from_family = ?)
                FROM showcase_reactions
                WHERE to_family = ? AND to_kid = ?
                GROUP BY kind
                """,
                rs -> {
                    String kind = rs.getString(1);
                    int count = rs.getInt(2);
                    boolean isMine = rs.getBoolean(3);
                    if (reactions.containsKey(kind)) {
                        reactions.put(kind, count);
                    }
                    if (isMine) {
                        mineSet.add(kind);
                    }
                },
                callerFamily, targetFamily, kidUuid);

        List<String> mine = new ArrayList<>();
        for (String kind : ORDERED_REACTION_KINDS) {
            if (mineSet.contains(kind)) {
                mine.add(kind);
            }
        }

        ObjectNode out;
        try {
            JsonNode parsed = json.readTree(payloads.get(0));
            out = parsed != null && parsed.isObject() ? (ObjectNode) parsed : json.createObjectNode();
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
        out.set("reactions", json.valueToTree(reactions));
        out.set("mine", json.valueToTree(mine));
        return out;
    }

    public void react(UUID callerFamily, UUID targetFamily, String kidUuid, String kind) {
        if (kind == null || !REACTION_KINDS.contains(kind)) {
            throw ShowcaseException.badRequest();
        }
        if (targetFamily == null || kidUuid == null || kidUuid.isBlank() || kidUuid.length() > MAX_KID_UUID_LEN) {
            throw ShowcaseException.notFound();
        }
        if (!isFriend(callerFamily, targetFamily)) {
            throw ShowcaseException.notFound();
        }

        boolean exists = Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM showcases WHERE family_id = ? AND kid_uuid = ?)",
                Boolean.class, targetFamily, kidUuid));
        if (!exists) {
            throw ShowcaseException.notFound();
        }

        int inserted;
        try {
            inserted = jdbc.update("""
                    INSERT INTO showcase_reactions (to_family, to_kid, from_family, kind)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT DO NOTHING
                    """,
                    targetFamily, kidUuid, callerFamily, kind);
        } catch (DataIntegrityViolationException e) {
            throw ShowcaseException.notFound();
        }

        if (inserted > 0) {
            String fromNickname = resolveNickname(callerFamily);
            lobbyNotifier.notify(targetFamily, Map.of(
                    "t", "reaction",
                    "kidUuid", kidUuid,
                    "kind", kind,
                    "fromNickname", fromNickname));
        }
    }

    private ObjectNode validateAndCanonicalize(JsonNode root) {
        ObjectNode clean = json.createObjectNode();
        var fields = root.fields();
        while (fields.hasNext()) {
            var entry = fields.next();
            String key = entry.getKey();
            JsonNode val = entry.getValue();
            if (!TOP_LEVEL_KEYS.contains(key)) {
                throw ShowcaseException.badRequest();
            }
            if (val == null || val.isNull()) {
                continue;
            }
            Integer maxLen = STRING_LIMITS.get(key);
            if (maxLen != null) {
                if (!val.isTextual() || val.asText().length() > maxLen || val.asText().indexOf('\0') >= 0) {
                    throw ShowcaseException.badRequest();
                }
                clean.put(key, val.asText());
            } else if (INT_FIELDS.contains(key)) {
                clean.put(key, requireNonNegativeInt(val));
            } else if ("pinned".equals(key)) {
                if (!val.isArray() || val.size() > MAX_PINNED) {
                    throw ShowcaseException.badRequest();
                }
                ArrayNode arr = clean.putArray("pinned");
                for (JsonNode item : val) {
                    if (item == null
                            || !item.isTextual()
                            || item.asText().length() > MAX_PINNED_ITEM_LEN
                            || item.asText().indexOf('\0') >= 0) {
                        throw ShowcaseException.badRequest();
                    }
                    arr.add(item.asText());
                }
            } else if ("learning".equals(key)) {
                if (!val.isObject()) {
                    throw ShowcaseException.badRequest();
                }
                ObjectNode learningOut = json.createObjectNode();
                var lf = val.fields();
                while (lf.hasNext()) {
                    var le = lf.next();
                    String lk = le.getKey();
                    JsonNode lv = le.getValue();
                    if (!LEARNING_KEYS.contains(lk)) {
                        throw ShowcaseException.badRequest();
                    }
                    if (lv == null || lv.isNull()) {
                        continue;
                    }
                    learningOut.put(lk, requireNonNegativeInt(lv));
                }
                if (!learningOut.isEmpty()) {
                    clean.set("learning", learningOut);
                }
            }
        }
        return clean;
    }

    private static int requireNonNegativeInt(JsonNode node) {
        if (!node.isIntegralNumber() || !node.canConvertToInt()) {
            throw ShowcaseException.badRequest();
        }
        int v = node.intValue();
        if (v < 0) {
            throw ShowcaseException.badRequest();
        }
        return v;
    }

    private boolean isFriend(UUID first, UUID second) {
        if (first.equals(second)) {
            return false;
        }
        UUID[] pair = FriendService.orderedPair(first, second);
        return Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM friendships WHERE family_a = ? AND family_b = ?)",
                Boolean.class, pair[0], pair[1]));
    }

    private String resolveNickname(UUID callerFamily) {
        SyncKidRecords.FamilyRecords recs =
                SyncKidRecords.load(jdbc, json, List.of(callerFamily), false).get(callerFamily);
        if (recs == null) {
            return FALLBACK_NICKNAME;
        }
        for (SyncKidRecords.KidRecord k : recs.sortedKids()) {
            String race = recs.raceNicknames.get(k.kidUuid());
            if (race != null && !race.isBlank()) {
                return race;
            }
            if (k.nickname() != null && !k.nickname().isBlank()) {
                return k.nickname();
            }
        }
        for (String race : recs.raceNicknames.values()) {
            if (race != null && !race.isBlank()) {
                return race;
            }
        }
        return FALLBACK_NICKNAME;
    }
}
