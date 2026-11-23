package com.ibme.funedu.server.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.TestDatabase;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "funedu.auth.requests-per-minute=3")
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class AuthRateLimitTest {

    @LocalServerPort
    int port;

    @Autowired
    ObjectMapper json;

    private final HttpClient client = HttpClient.newHttpClient();

    private HttpResponse<String> postGoogle() throws Exception {
        String payload = json.writeValueAsString(
                Map.of("idToken", "x", "deviceId", UUID.randomUUID().toString()));
        var req = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1/auth/google"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload))
                .build();
        return client.send(req, HttpResponse.BodyHandlers.ofString());
    }

    @Test
    void tooManySignInAttemptsFromOneAddressGet429() throws Exception {
        for (int i = 0; i < 3; i++) {
            assertThat(postGoogle().statusCode()).isEqualTo(401);
        }
        var limited = postGoogle();
        assertThat(limited.statusCode()).isEqualTo(429);
        assertThat(limited.headers().firstValue("Retry-After")).isPresent();
        assertThat(limited.body()).contains("\"too_many\"");
        // Health checks are never limited.
        var healthReq = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/actuator/health"))
                .GET()
                .build();
        assertThat(client.send(healthReq, HttpResponse.BodyHandlers.ofString()).statusCode()).isEqualTo(200);
    }
}
