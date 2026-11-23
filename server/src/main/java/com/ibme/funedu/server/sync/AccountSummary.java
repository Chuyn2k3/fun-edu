package com.ibme.funedu.server.sync;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AccountSummary {

    public record Kid(
            String nickname,
            String avatar,
            long stars,
            long glyphs,
            long pages,
            long items,
            long badges) {}

    public record Result(boolean hasData, List<Kid> kids) {}

    private final JdbcTemplate jdbc;

    public AccountSummary(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Result of(UUID familyId) {
        boolean hasRecords = Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM sync_records WHERE family_id = ? AND NOT deleted)",
                Boolean.class, familyId));
        boolean hasUploadDevice = Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM family_devices WHERE family_id = ? AND mode = 'upload')",
                Boolean.class, familyId));
        boolean hasData = hasRecords || hasUploadDevice;

        List<KidRow> kidRows = jdbc.query(
                "SELECT split_part(key, ':', 2) AS kid_id, " +
                "       payload->>'nickname' AS nickname, " +
                "       payload->>'avatar' AS avatar " +
                "FROM sync_records " +
                "WHERE family_id = ? AND kind = 'kid' AND NOT deleted " +
                "ORDER BY payload->>'createdAt' ASC NULLS LAST, key ASC " +
                "LIMIT 4",
                (rs, i) -> new KidRow(rs.getString(1), rs.getString(2), rs.getString(3)),
                familyId);

        if (kidRows.isEmpty()) {
            return new Result(hasData, List.of());
        }

        Map<String, KidStats> statsMap = new HashMap<>();
        for (KidRow k : kidRows) {
            statsMap.put(k.kidId, new KidStats());
        }

        jdbc.query(
                "SELECT split_part(key, ':', 2) AS kid_id, kind, " +
                "       count(*) AS n, " +
                "       sum(CASE WHEN kind = 'lesson' THEN COALESCE((payload->>'stars')::bigint, 0) ELSE 0 END) AS stars " +
                "FROM sync_records " +
                "WHERE family_id = ? AND NOT deleted " +
                "  AND kind IN ('lesson', 'glyph', 'page', 'item', 'badge') " +
                "GROUP BY 1, 2",
                rs -> {
                    String kidId = rs.getString(1);
                    KidStats s = statsMap.get(kidId);
                    if (s != null) {
                        String kind = rs.getString(2);
                        long n = rs.getLong(3);
                        long stars = rs.getLong(4);
                        switch (kind) {
                            case "lesson" -> s.stars += stars;
                            case "glyph" -> s.glyphs += n;
                            case "page" -> s.pages += n;
                            case "item" -> s.items += n;
                            case "badge" -> s.badges += n;
                        }
                    }
                },
                familyId);

        List<Kid> kids = new ArrayList<>();
        for (KidRow k : kidRows) {
            KidStats s = statsMap.get(k.kidId);
            kids.add(new Kid(
                    k.nickname != null ? k.nickname : "",
                    k.avatar != null ? k.avatar : "",
                    s != null ? s.stars : 0,
                    s != null ? s.glyphs : 0,
                    s != null ? s.pages : 0,
                    s != null ? s.items : 0,
                    s != null ? s.badges : 0));
        }

        return new Result(hasData, kids);
    }

    private static class KidStats {
        long stars = 0;
        long glyphs = 0;
        long pages = 0;
        long items = 0;
        long badges = 0;
    }

    private record KidRow(String kidId, String nickname, String avatar) {}
}
