package com.ibme.funedu.server.sync;

import static com.ibme.funedu.server.auth.TestIdTokens.googleToken;
import static com.ibme.funedu.server.auth.TestIdTokens.randomSubject;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
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
class AccountSummaryTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    @Autowired
    TestRestTemplate http;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    AccountSummary accountSummary;

    @Autowired
    ObjectMapper objectMapper;

    @Test
    void matchesSharedFixture() throws Exception {
        UUID familyId = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", familyId);

        String json = Files.readString(Path.of("../test/fixtures/summary_records.json"));
        JsonNode root = objectMapper.readTree(json);

        long version = 1;
        for (JsonNode rec : root.get("records")) {
            String key = rec.get("key").asText();
            String kind = rec.get("kind").asText();
            boolean deleted = rec.get("deleted").asBoolean();
            String payload = deleted || rec.get("payload").isNull()
                    ? null
                    : objectMapper.writeValueAsString(rec.get("payload"));

            jdbc.update(
                    "INSERT INTO sync_records (family_id, key, kind, payload, deleted, version) VALUES (?, ?, ?, ?::jsonb, ?, ?)",
                    familyId, key, kind, payload, deleted, version++);
        }

        AccountSummary.Result result = accountSummary.of(familyId);
        assertThat(result.hasData()).isTrue();
        assertThat(result.kids()).hasSize(1);

        AccountSummary.Kid kid = result.kids().get(0);
        assertThat(kid.nickname()).isEqualTo("Na");
        assertThat(kid.avatar()).isEqualTo("fox");
        assertThat(kid.stars()).isEqualTo(7);
        assertThat(kid.glyphs()).isEqualTo(2);
        assertThat(kid.pages()).isEqualTo(1);
        assertThat(kid.items()).isEqualTo(1);
        assertThat(kid.badges()).isEqualTo(1);
    }

    @Test
    void onlyTombstonesIsEmpty() {
        UUID familyId = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", familyId);

        jdbc.update(
                "INSERT INTO sync_records (family_id, key, kind, payload, deleted, version) VALUES (?, 'kid:k1', 'kid', NULL, true, 1)",
                familyId);

        AccountSummary.Result result = accountSummary.of(familyId);
        assertThat(result.hasData()).isFalse();
        assertThat(result.kids()).isEmpty();
    }

    @Test
    void uploadLinkCountsAsData() {
        UUID familyId = UUID.randomUUID();
        UUID deviceId = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", familyId);
        jdbc.update(
                "INSERT INTO family_devices (family_id, device_id, mode) VALUES (?, ?, 'upload')",
                familyId, deviceId);

        AccountSummary.Result result = accountSummary.of(familyId);
        assertThat(result.hasData()).isTrue();
        assertThat(result.kids()).isEmpty();
    }

    @Test
    void pageKindAccepted() {
        UUID deviceId = UUID.randomUUID();
        var res = http.exchange("/api/v1/auth/google", HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(randomSubject()),
                        "deviceId", deviceId.toString())), JSON);
        String access = (String) res.getBody().get("accessToken");
        UUID familyId = UUID.fromString((String) res.getBody().get("familyId"));

        // Link device so sync is accepted
        jdbc.update("INSERT INTO family_devices (family_id, device_id, mode) VALUES (?, ?, 'upload')",
                familyId, deviceId);

        var h = new HttpHeaders();
        h.setBearerAuth(access);

        // Accepted page change
        var validChanges = List.of(Map.of(
                "key", "page:" + UUID.randomUUID() + ":chu-a",
                "payload", Map.of("mistakes", 0)));
        var ok = http.exchange("/api/v1/sync", HttpMethod.POST,
                new HttpEntity<>(Map.of("since", 0, "changes", validChanges), h), JSON);
        assertThat(ok.getStatusCode()).isEqualTo(HttpStatus.OK);

        // Over 16KB payload -> 400
        var largePayload = "x".repeat(17000);
        var invalidChanges = List.of(Map.of(
                "key", "page:" + UUID.randomUUID() + ":chu-b",
                "payload", Map.of("data", largePayload)));
        var bad = http.exchange("/api/v1/sync", HttpMethod.POST,
                new HttpEntity<>(Map.of("since", 0, "changes", invalidChanges), h), JSON);
        assertThat(bad.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
