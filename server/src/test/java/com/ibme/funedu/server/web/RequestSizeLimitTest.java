package com.ibme.funedu.server.web;

import static com.ibme.funedu.server.auth.TestIdTokens.googleToken;
import static com.ibme.funedu.server.auth.TestIdTokens.randomSubject;
import static org.assertj.core.api.Assertions.assertThat;

import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class RequestSizeLimitTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    @Autowired
    TestRestTemplate http;

    @LocalServerPort
    int port;

    private String newFamily() {
        var res = http.exchange("/api/v1/auth/google", HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(randomSubject()),
                        "deviceId", UUID.randomUUID().toString())), JSON);
        return (String) res.getBody().get("accessToken");
    }

    @Test
    void oversizeBodyIs413() {
        String token = newFamily();
        byte[] prefix = "{\"since\":0,\"changes\":[{\"key\":\"kid:k1\",\"payload\":{\"x\":\""
                .getBytes(StandardCharsets.UTF_8);
        byte[] suffix = "\"}}]}".getBytes(StandardCharsets.UTF_8);
        byte[] big = new byte[RequestSizeLimitFilter.MAX_BYTES + 1024];
        System.arraycopy(prefix, 0, big, 0, prefix.length);
        for (int i = prefix.length; i < big.length - suffix.length; i++) {
            big[i] = 'a';
        }
        System.arraycopy(suffix, 0, big, big.length - suffix.length, suffix.length);

        var headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        var res = http.exchange("/api/v1/sync", HttpMethod.POST, new HttpEntity<>(big, headers), String.class);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.PAYLOAD_TOO_LARGE);
        assertThat(res.getBody()).contains("too_large");
    }

    @Test
    void chunkedOversizeBodyIs413() throws Exception {
        String token = newFamily();
        HttpURLConnection conn = (HttpURLConnection) URI.create("http://localhost:" + port + "/api/v1/sync")
                .toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setChunkedStreamingMode(8192);
        conn.setRequestProperty("Authorization", "Bearer " + token);
        conn.setRequestProperty("Content-Type", "application/json");

        try (OutputStream out = conn.getOutputStream()) {
            out.write("{\"since\":0,\"changes\":[{\"key\":\"kid:k1\",\"payload\":{\"x\":\""
                    .getBytes(StandardCharsets.UTF_8));
            byte[] chunk = new byte[32 * 1024];
            java.util.Arrays.fill(chunk, (byte) 'b');
            int total = RequestSizeLimitFilter.MAX_BYTES + 64 * 1024;
            for (int written = 0; written < total; written += chunk.length) {
                out.write(chunk);
            }
            out.write("\"}}]}".getBytes(StandardCharsets.UTF_8));
        } catch (java.io.IOException ignored) {
            // Connection reset after server replies 413 early is acceptable.
        }

        assertThat(conn.getResponseCode()).isEqualTo(413);
        try (var err = conn.getErrorStream()) {
            if (err != null) {
                String body = new String(err.readAllBytes(), StandardCharsets.UTF_8);
                assertThat(body).contains("too_large");
            }
        }
    }
}
