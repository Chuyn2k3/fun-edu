package com.ibme.funedu.server.auth;

import static com.ibme.funedu.server.auth.TestIdTokens.*;
import static org.assertj.core.api.Assertions.assertThat;

import com.ibme.funedu.server.TestDatabase;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

/** Apple requires revoking its tokens when a parent deletes the account. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "funedu.apple.team-id=TEAM123456",
        "funedu.apple.key-id=KEY1234567",
        "funedu.apple.private-key=unused-by-the-fake"})
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class, AppleRevokeTest.FakeAppleConfig.class})
class AppleRevokeTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    /** Records what the server asked Apple to do. */
    static class FakeApple implements AppleTokenApi {
        final List<String> exchanged = new ArrayList<>();
        final List<String> revoked = new ArrayList<>();
        boolean failExchange;

        @Override
        public Optional<String> exchange(String clientId, String code) {
            if (failExchange) throw new IllegalStateException("apple down");
            exchanged.add(clientId + "|" + code);
            return Optional.of("apple-rt-" + code);
        }

        @Override
        public void revoke(String clientId, String refreshToken) {
            revoked.add(clientId + "|" + refreshToken);
        }
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class FakeAppleConfig {
        @Bean
        @Primary
        FakeApple fakeApple() {
            return new FakeApple();
        }
    }

    @Autowired
    TestRestTemplate http;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    FakeApple apple;

    @BeforeEach
    void reset() {
        apple.exchanged.clear();
        apple.revoked.clear();
        apple.failExchange = false;
    }

    Map<String, Object> signIn(String idToken, String code) {
        var body = code == null
                ? Map.of("idToken", idToken, "deviceId", UUID.randomUUID().toString())
                : Map.of("idToken", idToken, "authorizationCode", code, "deviceId", UUID.randomUUID().toString());
        var res = http.exchange("/api/v1/auth/apple", HttpMethod.POST, new HttpEntity<>(body), JSON);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        return res.getBody();
    }

    void deleteAccount(String access) {
        var h = new HttpHeaders();
        h.setBearerAuth(access);
        assertThat(http.exchange("/api/v1/account", HttpMethod.DELETE, new HttpEntity<>(h), String.class)
                .getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
    }

    @Test
    void appleCodeIsExchangedStoredEncryptedAndRevokedOnDelete() {
        var login = signIn(appleToken(randomSubject()), "code-1");
        assertThat(apple.exchanged).containsExactly("com.ibme.funedu|code-1");

        String stored = jdbc.queryForObject(
                "SELECT apple_refresh_token FROM parent_accounts WHERE family_id = ?::uuid",
                String.class, login.get("familyId"));
        assertThat(stored).isNotBlank().doesNotContain("apple-rt-code-1");

        deleteAccount((String) login.get("accessToken"));
        assertThat(apple.revoked).containsExactly("com.ibme.funedu|apple-rt-code-1");
    }

    @Test
    void aNewCodeReplacesTheStoredToken() {
        String sub = randomSubject();
        signIn(appleToken(sub), "first");
        var login = signIn(appleToken(sub), "second");
        deleteAccount((String) login.get("accessToken"));
        assertThat(apple.revoked).containsExactly("com.ibme.funedu|apple-rt-second");
    }

    @Test
    void withoutACodeNothingIsAskedOfApple() {
        var login = signIn(appleToken(randomSubject()), null);
        deleteAccount((String) login.get("accessToken"));
        assertThat(apple.exchanged).isEmpty();
        assertThat(apple.revoked).isEmpty();
    }

    @Test
    void appleBeingDownNeverBlocksSignIn() {
        apple.failExchange = true;
        var login = signIn(appleToken(randomSubject()), "code-x");
        assertThat(login).containsKey("accessToken");
    }

    @Test
    void googleAccountsNeverTalkToApple() {
        var res = http.exchange("/api/v1/auth/google", HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(randomSubject()), "authorizationCode", "c",
                        "deviceId", UUID.randomUUID().toString())), JSON);
        deleteAccount((String) res.getBody().get("accessToken"));
        assertThat(apple.exchanged).isEmpty();
        assertThat(apple.revoked).isEmpty();
    }
}
