package com.ibme.funedu.server.friends;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Redeems friend codes, lists friends with kid summaries, and removes friendships. */
@Service
public class FriendService {

    static final int MAX_FRIENDS = 50;
    private static final String DEFAULT_ROCKET = "rocket_orange";
    private static final Pattern CODE_PATTERN = Pattern.compile("^[A-Z0-9]{6}$");

    public record KidDto(String kidUuid, String nickname, String avatar, String rocket) {}

    public record FriendDto(UUID familyId, List<KidDto> kids, boolean online) {}

    public record RedeemResult(FriendDto friend) {}

    public static final class FriendException extends RuntimeException {
        private final HttpStatus status;
        private final String code;

        private FriendException(HttpStatus status, String code) {
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

        static FriendException codeInvalid() {
            return new FriendException(HttpStatus.NOT_FOUND, "code_invalid");
        }

        static FriendException self() {
            return new FriendException(HttpStatus.CONFLICT, "self");
        }

        static FriendException alreadyFriends() {
            return new FriendException(HttpStatus.CONFLICT, "already_friends");
        }

        static FriendException tooManyFriends() {
            return new FriendException(HttpStatus.CONFLICT, "too_many_friends");
        }
    }

    private final JdbcTemplate jdbc;
    private final ObjectMapper json;
    private final PresenceView presence;

    public FriendService(JdbcTemplate jdbc, ObjectMapper json, PresenceView presence) {
        this.jdbc = jdbc;
        this.json = json;
        this.presence = presence;
    }

    @Transactional
    public RedeemResult redeem(UUID callerFamily, String rawCode) {
        if (rawCode == null) {
            throw FriendException.codeInvalid();
        }
        String code = rawCode.trim().toUpperCase(Locale.ROOT);
        if (!CODE_PATTERN.matcher(code).matches()) {
            throw FriendException.codeInvalid();
        }

        List<CodeRow> rows = jdbc.query(
                "SELECT family_id, expires_at FROM friend_codes WHERE code = ? FOR UPDATE",
                (rs, i) -> new CodeRow(rs.getObject(1, UUID.class), rs.getTimestamp(2).toInstant()),
                code);
        if (rows.isEmpty() || !rows.get(0).expiresAt().isAfter(Instant.now())) {
            throw FriendException.codeInvalid();
        }

        UUID ownerFamily = rows.get(0).familyId();
        if (ownerFamily.equals(callerFamily)) {
            throw FriendException.self();
        }

        UUID[] pair = orderedPair(callerFamily, ownerFamily);
        // Lock both families in canonical UUID order to prevent deadlocks and cap races.
        jdbc.query(
                "SELECT id FROM families WHERE id IN (?, ?) ORDER BY id FOR UPDATE",
                rs -> null,
                pair[0], pair[1]);

        boolean exists = Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM friendships WHERE family_a = ? AND family_b = ?)",
                Boolean.class, pair[0], pair[1]));
        if (exists) {
            throw FriendException.alreadyFriends();
        }

        if (friendCount(callerFamily) >= MAX_FRIENDS || friendCount(ownerFamily) >= MAX_FRIENDS) {
            throw FriendException.tooManyFriends();
        }

        jdbc.update("DELETE FROM friend_codes WHERE code = ?", code);
        jdbc.update("INSERT INTO friendships (family_a, family_b) VALUES (?, ?)", pair[0], pair[1]);

        FriendDto dto = assembleFriends(List.of(ownerFamily)).get(0);
        return new RedeemResult(dto);
    }

    public List<FriendDto> listFriends(UUID callerFamily) {
        List<UUID> friendIds = jdbc.query("""
                SELECT CASE WHEN family_a = ? THEN family_b ELSE family_a END AS friend_id
                FROM friendships
                WHERE family_a = ? OR family_b = ?
                ORDER BY created_at ASC, 1 ASC
                """,
                (rs, i) -> rs.getObject(1, UUID.class),
                callerFamily, callerFamily, callerFamily);
        if (friendIds.isEmpty()) {
            return List.of();
        }
        return assembleFriends(friendIds);
    }

    public void remove(UUID callerFamily, UUID otherFamily) {
        if (otherFamily == null || callerFamily.equals(otherFamily)) {
            return;
        }
        UUID[] pair = orderedPair(callerFamily, otherFamily);
        jdbc.update(
                "DELETE FROM friendships WHERE family_a = ? AND family_b = ?",
                pair[0], pair[1]);
    }

    /** PostgreSQL UUID < compares unsigned bytes, matching lowercase hex string order. */
    static UUID[] orderedPair(UUID first, UUID second) {
        return first.toString().compareTo(second.toString()) < 0
                ? new UUID[] {first, second}
                : new UUID[] {second, first};
    }

    private int friendCount(UUID familyId) {
        Integer count = jdbc.queryForObject(
                "SELECT count(*) FROM friendships WHERE family_a = ? OR family_b = ?",
                Integer.class, familyId, familyId);
        return count != null ? count : 0;
    }

    private List<FriendDto> assembleFriends(List<UUID> friendIds) {
        UUID[] idArray = friendIds.toArray(UUID[]::new);
        Map<UUID, FamilyRecords> byFamily = new HashMap<>();
        for (UUID id : friendIds) {
            byFamily.put(id, new FamilyRecords());
        }

        jdbc.query("""
                SELECT family_id, key, kind, payload::text
                FROM sync_records
                WHERE family_id = ANY(?)
                  AND kind IN ('kid', 'setting', 'game')
                  AND NOT deleted
                """,
                ps -> ps.setArray(1, ps.getConnection().createArrayOf("uuid", idArray)),
                rs -> {
                    UUID famId = rs.getObject(1, UUID.class);
                    FamilyRecords recs = byFamily.get(famId);
                    if (recs == null) return;
                    String key = rs.getString(2);
                    String kind = rs.getString(3);
                    JsonNode payload = parse(rs.getString(4));
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
                            if (key.startsWith("setting:")
                                    && key.endsWith(":raceNickname")
                                    && key.length() > "setting::raceNickname".length()) {
                                String kidUuid = key.substring(
                                        "setting:".length(),
                                        key.length() - ":raceNickname".length());
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

        List<FriendDto> out = new ArrayList<>(friendIds.size());
        for (UUID famId : friendIds) {
            FamilyRecords recs = byFamily.get(famId);
            recs.kids.sort(Comparator.comparingLong(KidRecord::createdAt).thenComparing(KidRecord::kidUuid));
            List<KidDto> kids = new ArrayList<>(recs.kids.size());
            for (KidRecord k : recs.kids) {
                String raceNick = recs.raceNicknames.get(k.kidUuid());
                String nickname = nonBlankOr(raceNick, nonNullOr(k.nickname(), ""));
                String avatar = nonNullOr(k.avatar(), "");
                String rocket = recs.rockets.getOrDefault(k.kidUuid(), DEFAULT_ROCKET);
                kids.add(new KidDto(k.kidUuid(), nickname, avatar, rocket));
            }
            out.add(new FriendDto(famId, kids, presence.isOnline(famId)));
        }
        return out;
    }

    private JsonNode parse(String raw) {
        if (raw == null) return null;
        try {
            return json.readTree(raw);
        } catch (JsonProcessingException e) {
            return null;
        }
    }

    private static String textOrNull(JsonNode node, String field) {
        JsonNode child = node.get(field);
        return child != null && child.isTextual() ? child.asText() : null;
    }

    private static long createdAtOf(JsonNode payload) {
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

    private static String nonBlankOr(String preferred, String fallback) {
        return preferred != null && !preferred.isBlank() ? preferred : fallback;
    }

    private static String nonNullOr(String value, String fallback) {
        return value != null ? value : fallback;
    }

    private record CodeRow(UUID familyId, Instant expiresAt) {}

    private record KidRecord(String kidUuid, String nickname, String avatar, long createdAt) {}

    private static final class FamilyRecords {
        final List<KidRecord> kids = new ArrayList<>();
        final Map<String, String> raceNicknames = new HashMap<>();
        final Map<String, String> rockets = new HashMap<>();
    }
}
