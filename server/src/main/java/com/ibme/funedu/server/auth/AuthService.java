package com.ibme.funedu.server.auth;

import com.ibme.funedu.server.friends.LobbyNotifier;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

/** Sign-in, session refresh, logout and account deletion. */
@Service
public class AuthService {

    /** Device link status returned in the session. */
    public record Device(boolean linked) {}

    /** What the app receives after signing in or refreshing. */
    public record Session(
            String accessToken,
            String refreshToken,
            long expiresIn,
            UUID familyId,
            Device device,
            UUID deviceId) {}

    /** The signed-in parent, re-read from the database on every request. */
    public record Parent(UUID id, UUID familyId, String provider, String email) {}

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(AuthService.class);

    private final IdTokenDecoders idTokens;
    private final TokenService tokens;
    private final AuthProperties props;
    private final JdbcTemplate jdbc;
    private final TransactionTemplate tx;
    private final AppleProperties apple;
    private final AppleTokenApi appleApi;
    private final TokenCipher cipher;
    private final LobbyNotifier lobby;

    public AuthService(IdTokenDecoders idTokens, TokenService tokens, AuthProperties props,
            JdbcTemplate jdbc, TransactionTemplate tx, AppleProperties apple, AppleTokenApi appleApi,
            LobbyNotifier lobby) {
        this.idTokens = idTokens;
        this.tokens = tokens;
        this.props = props;
        this.jdbc = jdbc;
        this.tx = tx;
        this.apple = apple;
        this.appleApi = appleApi;
        this.cipher = new TokenCipher(props.jwtSecret());
        this.lobby = lobby;
    }

    public boolean supports(String provider) {
        return idTokens.supports(provider);
    }

    /**
     * [authorizationCode] (Apple only): exchanged for Apple's refresh token,
     * kept sealed so deleting the account can revoke it. Apple being down
     * never blocks the sign-in.
     */
    public Session signIn(String provider, String idToken, String authorizationCode, UUID deviceId) {
        Jwt jwt = idTokens.decode(provider, idToken);
        String subject = jwt.getSubject();
        String email = emailOf(jwt);
        Parent parent;
        try {
            parent = tx.execute(s -> findOrCreate(provider, subject, email));
        } catch (DuplicateKeyException firstSignInRace) {
            // Two devices signed in for the first time at once: the other one won.
            parent = tx.execute(s -> findOrCreate(provider, subject, email));
        }
        if ("apple".equals(provider) && authorizationCode != null && !authorizationCode.isBlank()
                && apple.configured()) {
            linkApple(parent, jwt, authorizationCode);
        }
        return newSession(parent, Objects.requireNonNull(deviceId, "deviceId"));
    }

    private void linkApple(Parent parent, Jwt jwt, String code) {
        String clientId = jwt.getAudience().stream()
                .filter(props.apple().clientIds()::contains).findFirst().orElse(null);
        if (clientId == null) return;
        try {
            appleApi.exchange(clientId, code).ifPresent(rt -> jdbc.update(
                    "UPDATE parent_accounts SET apple_refresh_token = ?, apple_client_id = ? WHERE id = ?",
                    cipher.seal(rt), clientId, parent.id()));
        } catch (RuntimeException e) {
            log.warn("Apple code exchange failed: {}", e.getClass().getSimpleName());
        }
    }

    // Commit even when we answer 401: revoking every session on reuse must stick.
    @Transactional(noRollbackFor = AuthFailedException.class)
    public Session refresh(String refreshToken) {
        byte[] hash = TokenService.hash(refreshToken);
        List<Object[]> rows = jdbc.query(
                "SELECT id, parent_id, expires_at, revoked_at, device_id FROM refresh_tokens WHERE token_hash = ? FOR UPDATE",
                (rs, i) -> new Object[] {
                        rs.getObject(1, UUID.class), rs.getObject(2, UUID.class),
                        rs.getTimestamp(3).toInstant(), rs.getTimestamp(4),
                        rs.getObject(5, UUID.class)},
                hash);
        if (rows.isEmpty()) throw new AuthFailedException("unknown refresh token");
        Object[] row = rows.get(0);
        UUID tokenId = (UUID) row[0];
        UUID parentId = (UUID) row[1];
        if (row[3] != null) {
            // A rotated token came back: someone copied it. End every session of this parent.
            jdbc.update("UPDATE refresh_tokens SET revoked_at = now() WHERE parent_id = ? AND revoked_at IS NULL",
                    parentId);
            throw new AuthFailedException("refresh token reused");
        }
        if (((Instant) row[2]).isBefore(Instant.now())) throw new AuthFailedException("refresh token expired");
        jdbc.update("UPDATE refresh_tokens SET revoked_at = now() WHERE id = ?", tokenId);
        Parent parent = findParent(parentId).orElseThrow(() -> new AuthFailedException("account gone"));
        UUID deviceId = (UUID) row[4];
        return newSession(parent, deviceId);
    }

    public void logout(String refreshToken) {
        jdbc.update("UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = ? AND revoked_at IS NULL",
                TokenService.hash(refreshToken));
    }

    /** The parent behind an access token, or 401 if the account was deleted. */
    public Parent currentParent(Jwt accessToken) {
        UUID id;
        try {
            id = UUID.fromString(accessToken.getSubject());
        } catch (RuntimeException e) {
            throw new AuthFailedException("bad subject");
        }
        return findParent(id).orElseThrow(() -> new AuthFailedException("account gone"));
    }

    /** Deletes the whole family; tokens and (later) kids and progress cascade. */
    public void deleteAccount(Parent parent) {
        var appleLink = jdbc.query(
                "SELECT apple_refresh_token, apple_client_id FROM parent_accounts WHERE id = ?",
                (rs, i) -> new String[] {rs.getString(1), rs.getString(2)}, parent.id());
        List<UUID> friendIds = tx.execute(status -> {
            jdbc.query("SELECT id FROM families WHERE id = ? FOR UPDATE", rs -> null, parent.familyId());
            List<UUID> friends = jdbc.query("""
                    SELECT CASE WHEN family_a = ? THEN family_b ELSE family_a END
                    FROM friendships
                    WHERE family_a = ? OR family_b = ?
                    """,
                    (rs, i) -> rs.getObject(1, UUID.class),
                    parent.familyId(), parent.familyId(), parent.familyId());
            jdbc.update("DELETE FROM families WHERE id = ?", parent.familyId());
            return friends;
        });
        lobby.familyDeleted(parent.familyId());
        if (friendIds != null) {
            for (UUID friendId : friendIds) {
                lobby.friendRemoved(parent.familyId(), friendId);
            }
        }
        // Apple requires revoking its tokens on account deletion. Best effort:
        // the account is gone either way.
        if (!appleLink.isEmpty() && appleLink.get(0)[0] != null && apple.configured()) {
            try {
                appleApi.revoke(appleLink.get(0)[1], cipher.open(appleLink.get(0)[0]));
            } catch (RuntimeException e) {
                log.warn("Apple token revoke failed: {}", e.getClass().getSimpleName());
            }
        }
    }

    private Parent findOrCreate(String provider, String subject, String email) {
        List<Parent> found = jdbc.query(
                "SELECT id, family_id, provider, email FROM parent_accounts WHERE provider = ? AND subject = ?",
                (rs, i) -> new Parent(rs.getObject(1, UUID.class), rs.getObject(2, UUID.class),
                        rs.getString(3), rs.getString(4)),
                provider, subject);
        if (!found.isEmpty()) {
            Parent p = found.get(0);
            if (email != null && !email.equals(p.email())) {
                jdbc.update("UPDATE parent_accounts SET email = ? WHERE id = ?", email, p.id());
            }
            return new Parent(p.id(), p.familyId(), p.provider(), email != null ? email : p.email());
        }
        UUID family = UUID.randomUUID();
        UUID parent = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", family);
        jdbc.update("INSERT INTO parent_accounts (id, family_id, provider, subject, email) VALUES (?, ?, ?, ?, ?)",
                parent, family, provider, subject, email);
        return new Parent(parent, family, provider, email);
    }

    private Optional<Parent> findParent(UUID id) {
        return jdbc.query("SELECT id, family_id, provider, email FROM parent_accounts WHERE id = ?",
                (rs, i) -> new Parent(rs.getObject(1, UUID.class), rs.getObject(2, UUID.class),
                        rs.getString(3), rs.getString(4)),
                id).stream().findFirst();
    }

    public boolean isDeviceLinked(UUID familyId, UUID deviceId) {
        if (familyId == null || deviceId == null) return false;
        Boolean exists = jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM family_devices WHERE family_id = ? AND device_id = ?)",
                Boolean.class, familyId, deviceId);
        return Boolean.TRUE.equals(exists);
    }

    private Session newSession(Parent parent, UUID deviceId) {
        String refresh = tokens.newRefreshToken();
        jdbc.update("INSERT INTO refresh_tokens (id, parent_id, token_hash, expires_at, device_id) VALUES (?, ?, ?, ?, ?)",
                UUID.randomUUID(), parent.id(), TokenService.hash(refresh),
                Timestamp.from(Instant.now().plus(props.refreshTtl())), deviceId);
        boolean linked = isDeviceLinked(parent.familyId(), deviceId);
        return new Session(tokens.accessToken(parent.id(), parent.familyId(), deviceId), refresh,
                props.accessTtl().toSeconds(), parent.familyId(), new Device(linked), deviceId);
    }

    private static String emailOf(Jwt jwt) {
        String email = jwt.getClaimAsString("email");
        if (email == null || email.isBlank() || email.length() > 320) return null;
        return email;
    }
}
