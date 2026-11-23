package com.ibme.funedu.server.sync;

import com.ibme.funedu.server.auth.TokenService;
import java.util.Set;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DeviceLinkService {

    public static final Set<String> ALLOWED_MODES = Set.of("upload", "replace_local", "fresh");

    public static class LinkRequiredException extends RuntimeException {}

    public static class AccountNotEmptyException extends RuntimeException {
        private final AccountSummary.Result account;

        public AccountNotEmptyException(AccountSummary.Result account) {
            this.account = account;
        }

        public AccountSummary.Result account() {
            return account;
        }
    }

    public static class BadModeException extends RuntimeException {}

    public record LinkResult(boolean linked) {}

    private final JdbcTemplate jdbc;
    private final AccountSummary accountSummary;

    public DeviceLinkService(JdbcTemplate jdbc, AccountSummary accountSummary) {
        this.jdbc = jdbc;
        this.accountSummary = accountSummary;
    }

    public static UUID deviceIdOf(Jwt token) {
        if (token == null) return null;
        String dev = token.getClaimAsString(TokenService.DEVICE_CLAIM);
        if (dev == null || dev.isBlank()) return null;
        try {
            return UUID.fromString(dev);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public boolean isLinked(UUID familyId, UUID deviceId) {
        if (familyId == null || deviceId == null) return false;
        Boolean exists = jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM family_devices WHERE family_id = ? AND device_id = ?)",
                Boolean.class, familyId, deviceId);
        return Boolean.TRUE.equals(exists);
    }

    @Transactional
    public LinkResult link(UUID familyId, UUID deviceId, String mode) {
        if (mode == null || !ALLOWED_MODES.contains(mode)) {
            throw new BadModeException();
        }

        // Lock family row to serialize link requests
        jdbc.queryForObject("SELECT id FROM families WHERE id = ? FOR UPDATE", UUID.class, familyId);

        if (isLinked(familyId, deviceId)) {
            return new LinkResult(true);
        }

        if ("upload".equals(mode)) {
            AccountSummary.Result account = accountSummary.of(familyId);
            if (account.hasData()) {
                throw new AccountNotEmptyException(account);
            }
        }

        jdbc.update(
                "INSERT INTO family_devices (family_id, device_id, mode) VALUES (?, ?, ?)",
                familyId, deviceId, mode);

        return new LinkResult(true);
    }
}
