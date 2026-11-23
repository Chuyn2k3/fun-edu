package com.ibme.funedu.server.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.ibme.funedu.server.TestDatabase;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "funedu.auth.requests-per-minute=3")
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class AuthRateLimitTest {

    @Autowired
    TestRestTemplate http;

    @Test
    void tooManySignInAttemptsFromOneAddressGet429() {
        for (int i = 0; i < 3; i++) {
            assertThat(http.postForEntity("/api/v1/auth/google",
                    Map.of("idToken", "x", "deviceId", UUID.randomUUID().toString()), String.class)
                    .getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        }
        assertThat(http.postForEntity("/api/v1/auth/google",
                Map.of("idToken", "x", "deviceId", UUID.randomUUID().toString()), String.class)
                .getStatusCode()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS);
        // Health checks are never limited.
        assertThat(http.getForEntity("/actuator/health", String.class).getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
