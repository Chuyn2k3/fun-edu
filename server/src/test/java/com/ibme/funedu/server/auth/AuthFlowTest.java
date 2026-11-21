package com.ibme.funedu.server.auth;

import static com.ibme.funedu.server.auth.TestIdTokens.*;
import static org.assertj.core.api.Assertions.assertThat;

import com.ibme.funedu.server.TestDatabase;
import java.time.Instant;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.annotation.Import;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class AuthFlowTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    @Autowired
    TestRestTemplate http;

    @Autowired
    JdbcTemplate jdbc;

    ResponseEntity<Map<String, Object>> post(String path, Map<String, String> body) {
        return http.exchange(path, HttpMethod.POST, new HttpEntity<>(body), JSON);
    }

    ResponseEntity<Map<String, Object>> signIn(String provider, String idToken) {
        return post("/api/v1/auth/" + provider, Map.of("idToken", idToken));
    }

    ResponseEntity<Map<String, Object>> withBearer(HttpMethod method, String path, String access) {
        var h = new HttpHeaders();
        h.setBearerAuth(access);
        return http.exchange(path, method, new HttpEntity<>(h), JSON);
    }

    @Test
    void googleSignInCreatesAFamilyOnceAndReturnsTokens() {
        String sub = randomSubject();
        var first = signIn("google", googleToken(sub));
        assertThat(first.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(first.getBody()).containsKeys("accessToken", "refreshToken", "expiresIn", "familyId");

        var again = signIn("google", googleToken(sub));
        assertThat(again.getBody().get("familyId")).isEqualTo(first.getBody().get("familyId"));
        Integer families = jdbc.queryForObject(
                "SELECT count(*) FROM parent_accounts WHERE provider = 'google' AND subject = ?", Integer.class, sub);
        assertThat(families).isEqualTo(1);
    }

    @Test
    void appleSignInWorksAndIsSeparateFromGoogleWithTheSameSubject() {
        String sub = randomSubject();
        var apple = signIn("apple", appleToken(sub));
        var google = signIn("google", googleToken(sub));
        assertThat(apple.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(google.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(apple.getBody().get("familyId")).isNotEqualTo(google.getBody().get("familyId"));
    }

    @Test
    void badIdTokensAreRejected() {
        String sub = randomSubject();
        Instant later = Instant.now().plusSeconds(600);
        // Wrong audience, wrong issuer, expired, unknown key, token of the other provider.
        assertThat(signIn("google", sign(GOOGLE, "https://accounts.google.com", "someone-else", sub, later))
                .getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(signIn("google", sign(GOOGLE, "https://evil.example", GOOGLE_CLIENT, sub, later))
                .getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(signIn("google", sign(GOOGLE, "https://accounts.google.com", GOOGLE_CLIENT, sub,
                Instant.now().minusSeconds(600))).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(signIn("google", sign(ROGUE, "https://accounts.google.com", GOOGLE_CLIENT, sub, later))
                .getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(signIn("apple", googleToken(sub)).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(signIn("google", "not-a-jwt").getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(signIn("facebook", googleToken(sub)).getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        Integer rows = jdbc.queryForObject(
                "SELECT count(*) FROM parent_accounts WHERE subject = ?", Integer.class, sub);
        assertThat(rows).isZero();
    }

    @Test
    void missingIdTokenIsABadRequestWithoutDetails() {
        var res = post("/api/v1/auth/google", Map.of());
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(res.getBody()).containsOnlyKeys("error");
    }

    @Test
    void meNeedsAValidAccessToken() {
        var login = signIn("google", googleToken(randomSubject())).getBody();
        var me = withBearer(HttpMethod.GET, "/api/v1/me", (String) login.get("accessToken"));
        assertThat(me.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(me.getBody().get("familyId")).isEqualTo(login.get("familyId"));
        assertThat(me.getBody().get("provider")).isEqualTo("google");

        assertThat(http.getForEntity("/api/v1/me", String.class).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(withBearer(HttpMethod.GET, "/api/v1/me", "garbage").getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        // A provider id token is not a FunEdu access token.
        assertThat(withBearer(HttpMethod.GET, "/api/v1/me", googleToken(randomSubject())).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void refreshRotatesAndReusingAnOldTokenRevokesTheFamilyOfTokens() {
        var login = signIn("google", googleToken(randomSubject())).getBody();
        String first = (String) login.get("refreshToken");

        var rotated = post("/api/v1/auth/refresh", Map.of("refreshToken", first));
        assertThat(rotated.getStatusCode()).isEqualTo(HttpStatus.OK);
        String second = (String) rotated.getBody().get("refreshToken");
        assertThat(second).isNotEqualTo(first);

        // Replaying the used token looks like theft: it fails and kills the new one too.
        assertThat(post("/api/v1/auth/refresh", Map.of("refreshToken", first)).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(post("/api/v1/auth/refresh", Map.of("refreshToken", second)).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(post("/api/v1/auth/refresh", Map.of("refreshToken", "made-up")).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void refreshTokensAreStoredOnlyAsHashes() {
        var login = signIn("google", googleToken(randomSubject())).getBody();
        String token = (String) login.get("refreshToken");
        Integer plain = jdbc.queryForObject(
                "SELECT count(*) FROM refresh_tokens WHERE encode(token_hash, 'escape') = ?", Integer.class, token);
        assertThat(plain).isZero();
    }

    @Test
    void logoutRevokesTheRefreshToken() {
        var login = signIn("apple", appleToken(randomSubject())).getBody();
        String refresh = (String) login.get("refreshToken");
        assertThat(post("/api/v1/auth/logout", Map.of("refreshToken", refresh)).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(post("/api/v1/auth/refresh", Map.of("refreshToken", refresh)).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void deletingTheAccountRemovesTheFamilyAndEndsEverySession() {
        String sub = randomSubject();
        var login = signIn("google", googleToken(sub)).getBody();
        String access = (String) login.get("accessToken");

        assertThat(withBearer(HttpMethod.DELETE, "/api/v1/account", access).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);

        Integer families = jdbc.queryForObject("SELECT count(*) FROM families WHERE id = ?::uuid",
                Integer.class, login.get("familyId"));
        assertThat(families).isZero();
        assertThat(post("/api/v1/auth/refresh", Map.of("refreshToken", (String) login.get("refreshToken")))
                .getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        // The access token has not expired yet but its account is gone.
        assertThat(withBearer(HttpMethod.GET, "/api/v1/me", access).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
        // Signing in again starts a brand new, empty family.
        var fresh = signIn("google", googleToken(sub)).getBody();
        assertThat(fresh.get("familyId")).isNotEqualTo(login.get("familyId"));
    }

    @Test
    void aFamilyHasExactlyOneParentAccount() {
        var login = signIn("google", googleToken(randomSubject())).getBody();
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbc.update(
                "INSERT INTO parent_accounts (id, family_id, provider, subject) VALUES (gen_random_uuid(), ?::uuid, 'apple', ?)",
                login.get("familyId"), randomSubject()))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
    }
}
