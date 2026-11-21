package com.ibme.funedu.server.auth;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
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

    /** What the app receives after signing in or refreshing. */
    public record Session(String accessToken, String refreshToken, long expiresIn, UUID familyId) {}

    /** The signed-in parent, re-read from the database on every request. */
    public record Parent(UUID id, UUID familyId, String provider, String email) {}

    private final IdTokenDecoders idTokens;
    private final TokenService tokens;
    private final AuthProperties props;
    private final JdbcTemplate jdbc;
    private final TransactionTemplate tx;

    public AuthService(IdTokenDecoders idTokens, TokenService tokens, AuthProperties props,
            JdbcTemplate jdbc, TransactionTemplate tx) {
        this.idTokens = idTokens;
        this.tokens = tokens;
        this.props = props;
        this.jdbc = jdbc;
        this.tx = tx;
    }

    public boolean supports(String provider) {
        return idTokens.supports(provider);
    }

    public Session signIn(String provider, String idToken) {
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
        return newSession(parent);
    }

    // Commit even when we answer 401: revoking every session on reuse must stick.
    @Transactional(noRollbackFor = AuthFailedException.class)
    public Session refresh(String refreshToken) {
        byte[] hash = TokenService.hash(refreshToken);
        List<Object[]> rows = jdbc.query(
                "SELECT id, parent_id, expires_at, revoked_at FROM refresh_tokens WHERE token_hash = ? FOR UPDATE",
                (rs, i) -> new Object[] {
                        rs.getObject(1, UUID.class), rs.getObject(2, UUID.class),
                        rs.getTimestamp(3).toInstant(), rs.getTimestamp(4)},
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
        return newSession(parent);
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
        jdbc.update("DELETE FROM families WHERE id = ?", parent.familyId());
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

    private Session newSession(Parent parent) {
        String refresh = tokens.newRefreshToken();
        jdbc.update("INSERT INTO refresh_tokens (id, parent_id, token_hash, expires_at) VALUES (?, ?, ?, ?)",
                UUID.randomUUID(), parent.id(), TokenService.hash(refresh),
                Timestamp.from(Instant.now().plus(props.refreshTtl())));
        return new Session(tokens.accessToken(parent.id(), parent.familyId()), refresh,
                props.accessTtl().toSeconds(), parent.familyId());
    }

    private static String emailOf(Jwt jwt) {
        String email = jwt.getClaimAsString("email");
        if (email == null || email.isBlank() || email.length() > 320) return null;
        return email;
    }
}
