package com.ibme.funedu.server.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class RefreshTokenCleanup {

    private static final Logger log = LoggerFactory.getLogger(RefreshTokenCleanup.class);
    private static final int BATCH_SIZE = 5000;

    private final JdbcTemplate jdbc;

    public RefreshTokenCleanup(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Scheduled(cron = "0 15 3 * * *")
    public int purge() {
        int total = 0;
        while (true) {
            int deleted = jdbc.update("""
                    DELETE FROM refresh_tokens
                    WHERE id IN (
                        SELECT id FROM refresh_tokens
                        WHERE expires_at < now()
                           OR (revoked_at IS NOT NULL AND revoked_at < now() - interval '7 days')
                        LIMIT ?
                    )
                    """, BATCH_SIZE);
            total += deleted;
            if (deleted < BATCH_SIZE) {
                break;
            }
        }
        if (total > 0) {
            log.info("Purged {} expired/revoked refresh tokens", total);
        }
        return total;
    }
}
