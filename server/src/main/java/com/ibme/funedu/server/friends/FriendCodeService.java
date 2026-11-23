package com.ibme.funedu.server.friends;

import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Generates short-lived 6-character friend codes for a family. */
@Service
public class FriendCodeService {

    /** Unambiguous alphabet: omits 0, O, 1, I. */
    static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    static final int CODE_LENGTH = 6;
    static final int MAX_LIVE_CODES = 3;
    static final Duration CODE_TTL = Duration.ofHours(24);

    public record FriendCode(String code, Instant expiresAt) {}

    private final JdbcTemplate jdbc;
    private final SecureRandom random = new SecureRandom();

    public FriendCodeService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public FriendCode createCode(UUID familyId) {
        // Serialize code creation per family so the 3-live-code cap holds under concurrency.
        jdbc.query("SELECT pg_advisory_xact_lock(hashtextextended(?, 1))", rs -> null, familyId.toString());

        jdbc.update("DELETE FROM friend_codes WHERE family_id = ? AND expires_at <= now()", familyId);
        jdbc.update("""
                DELETE FROM friend_codes
                WHERE code IN (
                    SELECT code FROM friend_codes
                    WHERE family_id = ? AND expires_at > now()
                    ORDER BY created_at DESC, code DESC
                    OFFSET ?
                )
                """, familyId, MAX_LIVE_CODES - 1);

        Instant expiresAt = Instant.now().plus(CODE_TTL);
        Timestamp expiresTs = Timestamp.from(expiresAt);

        for (int attempt = 0; attempt < 16; attempt++) {
            String code = randomCode();
            int inserted = jdbc.update("""
                    INSERT INTO friend_codes (code, family_id, expires_at, created_at)
                    VALUES (?, ?, ?, clock_timestamp())
                    ON CONFLICT (code) DO NOTHING
                    """, code, familyId, expiresTs);
            if (inserted == 1) {
                return new FriendCode(code, expiresAt);
            }
        }
        throw new IllegalStateException("Could not allocate unique friend code");
    }

    private String randomCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
