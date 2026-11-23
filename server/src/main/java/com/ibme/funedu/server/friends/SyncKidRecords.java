package com.ibme.funedu.server.friends;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Batch-reads {@code kid}, {@code setting:*:raceNickname}, and {@code game}
 * sync records for one or more families using a single SQL query.
 */
final class SyncKidRecords {

    private static final String SETTING_PREFIX = "setting:";
    private static final String RACE_NICKNAME_SUFFIX = ":raceNickname";

    record KidRecord(String kidUuid, String nickname, String avatar, long createdAt) {}

    static final class FamilyRecords {
        final List<KidRecord> kids = new ArrayList<>();
        final Map<String, String> raceNicknames = new HashMap<>();
        final Map<String, String> rockets = new HashMap<>();

        List<KidRecord> sortedKids() {
            kids.sort(Comparator.comparingLong(KidRecord::createdAt).thenComparing(KidRecord::kidUuid));
            return kids;
        }
    }

    private SyncKidRecords() {}

    static Map<UUID, FamilyRecords> load(
            JdbcTemplate jdbc, ObjectMapper json, List<UUID> familyIds, boolean includeGame) {
        Map<UUID, FamilyRecords> byFamily = new HashMap<>(familyIds.size() * 2);
        if (familyIds.isEmpty()) {
            return byFamily;
        }
        for (UUID id : familyIds) {
            byFamily.put(id, new FamilyRecords());
        }
        UUID[] idArray = familyIds.toArray(UUID[]::new);
        String sql = includeGame
                ? """
                  SELECT family_id, key, kind, payload::text
                  FROM sync_records
                  WHERE family_id = ANY(?)
                    AND kind IN ('kid', 'setting', 'game')
                    AND NOT deleted
                  """
                : """
                  SELECT family_id, key, kind, payload::text
                  FROM sync_records
                  WHERE family_id = ANY(?)
                    AND kind IN ('kid', 'setting')
                    AND NOT deleted
                  """;

        jdbc.query(
                sql,
                ps -> ps.setArray(1, ps.getConnection().createArrayOf("uuid", idArray)),
                rs -> {
                    UUID famId = rs.getObject(1, UUID.class);
                    FamilyRecords recs = byFamily.get(famId);
                    if (recs == null) return;
                    String key = rs.getString(2);
                    String kind = rs.getString(3);
                    JsonNode payload = parse(json, rs.getString(4));
                    if (payload == null) return;

                    switch (kind) {
                        case "kid" -> {
                            if (key.startsWith("kid:")) {
                                String kidUuid = key.substring("kid:".length());
                                recs.kids.add(new KidRecord(
                                        kidUuid,
                                        textOrNull(payload, "nickname"),
                                        textOrNull(payload, "avatar"),
                                        createdAtOf(payload)));
                            }
                        }
                        case "setting" -> {
                            int minLen = SETTING_PREFIX.length() + RACE_NICKNAME_SUFFIX.length();
                            if (key.startsWith(SETTING_PREFIX)
                                    && key.endsWith(RACE_NICKNAME_SUFFIX)
                                    && key.length() > minLen) {
                                String kidUuid = key.substring(
                                        SETTING_PREFIX.length(),
                                        key.length() - RACE_NICKNAME_SUFFIX.length());
                                String val = textOrNull(payload, "value");
                                if (val != null && !val.isBlank()) {
                                    recs.raceNicknames.put(kidUuid, val);
                                }
                            }
                        }
                        case "game" -> {
                            if (key.startsWith("game:")) {
                                String kidUuid = key.substring("game:".length());
                                String rocket = textOrNull(payload, "rocket");
                                if (rocket != null && !rocket.isBlank()) {
                                    recs.rockets.put(kidUuid, rocket);
                                }
                            }
                        }
                        default -> {}
                    }
                });
        return byFamily;
    }

    static JsonNode parse(ObjectMapper json, String raw) {
        if (raw == null) return null;
        try {
            return json.readTree(raw);
        } catch (JsonProcessingException e) {
            return null;
        }
    }

    static String textOrNull(JsonNode node, String field) {
        JsonNode child = node.get(field);
        return child != null && child.isTextual() ? child.asText() : null;
    }

    static long createdAtOf(JsonNode payload) {
        JsonNode c = payload.get("createdAt");
        if (c == null || c.isNull()) return 0L;
        if (c.isNumber()) return c.asLong();
        if (c.isTextual()) {
            try {
                return Long.parseLong(c.asText());
            } catch (NumberFormatException ignored) {
                return 0L;
            }
        }
        return 0L;
    }
}
