package com.ibme.funedu.server.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.ibme.funedu.server.TestDatabase;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import(TestDatabase.class)
class RefreshTokenCleanupTest {

    @Autowired
    RefreshTokenCleanup cleanup;

    @Autowired
    JdbcTemplate jdbc;

    private final SecureRandom random = new SecureRandom();

    private byte[] randomHash() {
        byte[] b = new byte[32];
        random.nextBytes(b);
        return b;
    }

    @Test
    void purgeRemovesExpiredAndOldRevoked() {
        UUID familyId = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", familyId);
        UUID parentId = UUID.randomUUID();
        jdbc.update("INSERT INTO parent_accounts (id, family_id, provider, subject) VALUES (?, ?, 'google', ?)",
                parentId, familyId, "clean-sub-" + UUID.randomUUID());

        Instant now = Instant.now();
        UUID dev = UUID.randomUUID();

        // 1. Valid active token (expires in future, not revoked) -> KEEP
        UUID tActive = UUID.randomUUID();
        jdbc.update("INSERT INTO refresh_tokens (id, parent_id, token_hash, device_id, expires_at) VALUES (?, ?, ?, ?, ?)",
                tActive, parentId, randomHash(), dev, Timestamp.from(now.plus(30, ChronoUnit.DAYS)));

        // 2. Expired token (expires in past, not revoked) -> REMOVE
        UUID tExpired = UUID.randomUUID();
        jdbc.update("INSERT INTO refresh_tokens (id, parent_id, token_hash, device_id, expires_at) VALUES (?, ?, ?, ?, ?)",
                tExpired, parentId, randomHash(), dev, Timestamp.from(now.minus(1, ChronoUnit.DAYS)));

        // 3. Revoked 8 days ago -> REMOVE
        UUID tRevokedOld = UUID.randomUUID();
        jdbc.update("INSERT INTO refresh_tokens (id, parent_id, token_hash, device_id, expires_at, revoked_at) VALUES (?, ?, ?, ?, ?, ?)",
                tRevokedOld, parentId, randomHash(), dev, Timestamp.from(now.plus(30, ChronoUnit.DAYS)), Timestamp.from(now.minus(8, ChronoUnit.DAYS)));

        // 4. Revoked 1 day ago -> KEEP (needed for replay detection)
        UUID tRevokedRecent = UUID.randomUUID();
        jdbc.update("INSERT INTO refresh_tokens (id, parent_id, token_hash, device_id, expires_at, revoked_at) VALUES (?, ?, ?, ?, ?, ?)",
                tRevokedRecent, parentId, randomHash(), dev, Timestamp.from(now.plus(30, ChronoUnit.DAYS)), Timestamp.from(now.minus(1, ChronoUnit.DAYS)));

        int purged = cleanup.purge();
        assertThat(purged).isGreaterThanOrEqualTo(2);

        // Check the 4 tokens
        assertThat(exists(tActive)).isTrue();
        assertThat(exists(tExpired)).isFalse();
        assertThat(exists(tRevokedOld)).isFalse();
        assertThat(exists(tRevokedRecent)).isTrue();
    }

    private boolean exists(UUID id) {
        return Boolean.TRUE.equals(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM refresh_tokens WHERE id = ?)", Boolean.class, id));
    }
}
