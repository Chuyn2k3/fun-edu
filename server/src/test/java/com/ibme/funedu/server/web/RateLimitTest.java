package com.ibme.funedu.server.web;

import static com.ibme.funedu.server.auth.TestIdTokens.googleToken;
import static com.ibme.funedu.server.auth.TestIdTokens.randomSubject;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class RateLimitTest {

    @LocalServerPort
    int port;

    @Autowired
    RateLimitFilter rateLimits;

    @Autowired
    ObjectMapper json;

    private final HttpClient client = HttpClient.newHttpClient();

    @BeforeEach
    @AfterEach
    void resetLimits() {
        rateLimits.reset();
    }

    private HttpResponse<String> postJson(String path, Object body, String accessToken) throws Exception {
        var req = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Content-Type", "application/json");
        if (accessToken != null) {
            req.header("Authorization", "Bearer " + accessToken);
        }
        String payload = body == null ? "" : json.writeValueAsString(body);
        req.POST(HttpRequest.BodyPublishers.ofString(payload));
        return client.send(req.build(), HttpResponse.BodyHandlers.ofString());
    }

    private String newFamily() throws Exception {
        var res = postJson("/api/v1/auth/google",
                Map.of("idToken", googleToken(randomSubject()), "deviceId", UUID.randomUUID().toString()),
                null);
        assertThat(res.statusCode()).isEqualTo(200);
        return (String) json.readValue(res.body(), Map.class).get("accessToken");
    }

    private HttpResponse<String> sync(String access) throws Exception {
        return postJson("/api/v1/sync", Map.of("since", 0, "changes", List.of()), access);
    }

    private HttpResponse<String> createRoom(String access) throws Exception {
        return postJson("/api/v1/rooms", null, access);
    }

    @Test
    void syncRateLimitedPerFamily() throws Exception {
        String familyA = newFamily();
        for (int i = 0; i < 60; i++) {
            assertThat(sync(familyA).statusCode()).isEqualTo(200);
        }
        var blocked = sync(familyA);
        assertThat(blocked.statusCode()).isEqualTo(429);
        assertThat(blocked.body()).contains("\"too_many\"");
        assertThat(blocked.headers().firstValue("Retry-After")).isPresent();
    }

    @Test
    void syncRateLimitedPerIp() throws Exception {
        String familyA = newFamily();
        String familyB = newFamily();
        String familyC = newFamily();
        for (int i = 0; i < 60; i++) {
            assertThat(sync(familyA).statusCode()).isEqualTo(200);
        }
        for (int i = 0; i < 60; i++) {
            assertThat(sync(familyB).statusCode()).isEqualTo(200);
        }
        var blocked = sync(familyC);
        assertThat(blocked.statusCode()).isEqualTo(429);
        assertThat(blocked.body()).contains("\"too_many\"");
        assertThat(blocked.headers().firstValue("Retry-After")).isPresent();
    }

    @Test
    void roomsRateLimitedPerFamily() throws Exception {
        String familyA = newFamily();
        for (int i = 0; i < 10; i++) {
            assertThat(createRoom(familyA).statusCode()).isEqualTo(200);
        }
        var blocked = createRoom(familyA);
        assertThat(blocked.statusCode()).isEqualTo(429);
        assertThat(blocked.body()).contains("\"too_many\"");
        assertThat(blocked.headers().firstValue("Retry-After")).isPresent();
    }
}
