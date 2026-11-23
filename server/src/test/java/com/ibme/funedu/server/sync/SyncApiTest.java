package com.ibme.funedu.server.sync;

import static com.ibme.funedu.server.auth.TestIdTokens.*;
import static org.assertj.core.api.Assertions.assertThat;

import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import java.util.ArrayList;
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
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class SyncApiTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    @Autowired
    TestRestTemplate http;

    String newFamily() {
        return newFamily(UUID.randomUUID());
    }

    String newFamily(UUID deviceId) {
        var res = http.exchange("/api/v1/auth/google", HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(randomSubject()),
                        "deviceId", deviceId.toString())), JSON);
        String token = (String) res.getBody().get("accessToken");
        var h = new HttpHeaders();
        h.setBearerAuth(token);
        http.exchange("/api/v1/sync/link", HttpMethod.POST,
                new HttpEntity<>(Map.of("mode", "upload"), h), JSON);
        return token;
    }

    ResponseEntity<Map<String, Object>> sync(String access, long since, List<Map<String, Object>> changes) {
        var h = new HttpHeaders();
        if (access != null) h.setBearerAuth(access);
        return http.exchange("/api/v1/sync", HttpMethod.POST,
                new HttpEntity<>(Map.of("since", since, "changes", changes), h), JSON);
    }

    static Map<String, Object> change(String key, Object payload, Long baseVersion) {
        var m = new HashMap<String, Object>();
        m.put("key", key);
        m.put("payload", payload);
        m.put("deleted", payload == null);
        m.put("baseVersion", baseVersion);
        return m;
    }

    @SuppressWarnings("unchecked")
    static List<Map<String, Object>> records(ResponseEntity<Map<String, Object>> res) {
        return (List<Map<String, Object>>) res.getBody().get("records");
    }

    static long version(ResponseEntity<Map<String, Object>> res) {
        return ((Number) res.getBody().get("version")).longValue();
    }

    static long versionOf(ResponseEntity<Map<String, Object>> res, String key) {
        return records(res).stream().filter(r -> r.get("key").equals(key))
                .map(r -> ((Number) r.get("version")).longValue()).findFirst().orElseThrow();
    }

    @Test
    void syncNeedsSignIn() {
        assertThat(sync(null, 0, List.of()).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void pushedRecordsComeBackToAnotherDeviceOfTheSameFamily() {
        String access = newFamily();
        var push = sync(access, 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null),
                change("lesson:k1:2026-11-21T08:00:00.000Z", Map.of("stars", 3), null)));
        assertThat(push.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(push.getBody().get("conflicts")).isEqualTo(List.of());

        // A fresh device pulls everything from 0.
        var pull = sync(access, 0, List.of());
        assertThat(records(pull)).extracting(r -> r.get("key"))
                .containsExactlyInAnyOrder("kid:k1", "lesson:k1:2026-11-21T08:00:00.000Z");
        assertThat(records(pull).get(0).get("payload")).isNotNull();

        // Nothing new since the latest version.
        assertThat(records(sync(access, version(pull), List.of()))).isEmpty();
    }

    @Test
    void familiesNeverSeeEachOthersRecords() {
        String a = newFamily();
        String b = newFamily();
        sync(a, 0, List.of(change("kid:secret", Map.of("nickname", "A"), null)));
        assertThat(records(sync(b, 0, List.of()))).isEmpty();
        // Same key in another family is a separate record, not a conflict.
        var other = sync(b, 0, List.of(change("kid:secret", Map.of("nickname", "B"), null)));
        assertThat(other.getBody().get("conflicts")).isEqualTo(List.of());
        assertThat(records(sync(a, 0, List.of())).get(0).get("payload")).isEqualTo(Map.of("nickname", "A"));
    }

    @Test
    void aStaleBaseVersionIsAConflictAndKeepsTheServerCopy() {
        String access = newFamily();
        var first = sync(access, 0, List.of(change("level:k1:toan", Map.of("level", 2), null)));
        long v1 = versionOf(first, "level:k1:toan");

        // Device A updates from v1.
        var a = sync(access, v1, List.of(change("level:k1:toan", Map.of("level", 3), v1)));
        assertThat(a.getBody().get("conflicts")).isEqualTo(List.of());
        // Device B still thinks v1 is current: rejected, and it gets A's copy back.
        var b = sync(access, v1, List.of(change("level:k1:toan", Map.of("level", 1), v1)));
        assertThat(b.getBody().get("conflicts")).isEqualTo(List.of("level:k1:toan"));
        assertThat(records(b)).singleElement()
                .satisfies(r -> assertThat(r.get("payload")).isEqualTo(Map.of("level", 3)));
        // Creating a key that already exists (no base version) is a conflict too.
        var dup = sync(access, 0, List.of(change("level:k1:toan", Map.of("level", 9), null)));
        assertThat(dup.getBody().get("conflicts")).isEqualTo(List.of("level:k1:toan"));
    }

    @Test
    void deletionsSyncAsTombstones() {
        String access = newFamily();
        var made = sync(access, 0, List.of(change("kid:k9", Map.of("nickname", "Bo"), null)));
        long v = versionOf(made, "kid:k9");
        var del = sync(access, v, List.of(change("kid:k9", null, v)));
        assertThat(del.getBody().get("conflicts")).isEqualTo(List.of());
        var pull = sync(access, 0, List.of());
        assertThat(records(pull)).singleElement().satisfies(r -> {
            assertThat(r.get("deleted")).isEqualTo(true);
            assertThat(r.get("payload")).isNull();
        });
    }

    @Test
    void pullIsPagedSoBigFamiliesSyncInSeveralRounds() {
        String access = newFamily();
        var many = new ArrayList<Map<String, Object>>();
        for (int i = 0; i < 1200; i++) many.add(change("lesson:k1:" + i, Map.of("stars", 1), null));
        sync(access, 0, many.subList(0, 600));
        sync(access, 0, many.subList(600, 1200));

        var page1 = sync(access, 0, List.of());
        assertThat(records(page1)).hasSize(1000);
        assertThat(page1.getBody().get("hasMore")).isEqualTo(true);
        var page2 = sync(access, version(page1), List.of());
        assertThat(records(page2)).hasSize(200);
        assertThat(page2.getBody().get("hasMore")).isEqualTo(false);
    }

    @Test
    void badChangesAreRejectedWithoutDetails() {
        String access = newFamily();
        // Unknown record kind.
        assertThat(sync(access, 0, List.of(change("hack:x", Map.of(), null))).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
        // Stroke coordinates never leave the device.
        assertThat(sync(access, 0, List.of(change("stroke:k1:1", Map.of(), null))).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
        // Oversized payload.
        assertThat(sync(access, 0, List.of(change("kid:big", Map.of("x", "a".repeat(20_000)), null)))
                .getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        // Too many changes in one call.
        var tooMany = new ArrayList<Map<String, Object>>();
        for (int i = 0; i < 2001; i++) tooMany.add(change("lesson:k:" + i, Map.of(), null));
        assertThat(sync(access, 0, tooMany).getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        // Nothing was stored by the rejected calls.
        assertThat(records(sync(access, 0, List.of()))).isEmpty();
    }

    @Test
    void deletingTheAccountDeletesTheFamilyRecords() {
        String access = newFamily();
        sync(access, 0, List.of(change("kid:k1", Map.of("nickname", "Na"), null)));
        var h = new HttpHeaders();
        h.setBearerAuth(access);
        http.exchange("/api/v1/account", HttpMethod.DELETE, new HttpEntity<>(h), String.class);
        assertThat(sync(access, 0, List.of()).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void batchPushMixedConflicts() {
        String access = newFamily();
        sync(access, 0, List.of(
                change("lesson:k1:c1", Map.of("stars", 1), null),
                change("lesson:k1:c2", Map.of("stars", 2), null),
                change("lesson:k1:c3", Map.of("stars", 3), null)));

        var changes = new ArrayList<Map<String, Object>>();
        changes.add(change("lesson:k1:c1", Map.of("stars", 10), 999999L));
        changes.add(change("lesson:k1:c2", Map.of("stars", 20), 999999L));
        changes.add(change("lesson:k1:c3", Map.of("stars", 30), 999999L));
        for (int i = 0; i < 497; i++) {
            changes.add(change("lesson:k1:new_" + i, Map.of("stars", 1), null));
        }

        var res = sync(access, 0, changes);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        @SuppressWarnings("unchecked")
        var conflicts = (List<String>) res.getBody().get("conflicts");
        assertThat(conflicts).containsExactlyInAnyOrder("lesson:k1:c1", "lesson:k1:c2", "lesson:k1:c3");

        var recs = records(res);
        assertThat(recs).extracting(r -> r.get("key"))
                .contains("lesson:k1:c1", "lesson:k1:c2", "lesson:k1:c3");
    }

    @Test
    void pushTwoThousandIsFast() {
        String access = newFamily();
        var changes = new ArrayList<Map<String, Object>>();
        for (int i = 0; i < 2000; i++) {
            changes.add(change("lesson:k1:" + i, Map.of("stars", 2), null));
        }

        long start = System.currentTimeMillis();
        var res = sync(access, 0, changes);
        long elapsed = System.currentTimeMillis() - start;

        System.out.printf("pushTwoThousandIsFast took %d ms%n", elapsed);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(elapsed).isLessThan(3000);
    }

    @Test
    void deepPayloadIsRejected() {
        String access = newFamily();
        // Depth 6 is accepted; depth 7 is rejected with 400.
        Map<String, Object> d6 = Map.of("l6", 1);
        for (int i = 5; i >= 1; i--) d6 = Map.of("l" + i, d6);
        assertThat(sync(access, 0, List.of(change("setting:k1:ok", d6, null))).getStatusCode())
                .isEqualTo(HttpStatus.OK);

        Map<String, Object> d7 = Map.of("l7", 1);
        for (int i = 6; i >= 1; i--) d7 = Map.of("l" + i, d7);
        assertThat(sync(access, 0, List.of(change("setting:k1:deep", d7, null))).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void longStringIsRejected() {
        String access = newFamily();
        // Non-page strings are capped at 4 KB; page keeps the 16 KB payload cap.
        assertThat(sync(access, 0, List.of(change("kid:k1", Map.of("nickname", "a".repeat(4097)), null)))
                .getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(sync(access, 0, List.of(change("page:k1:a", Map.of("svg", "p".repeat(5000)), null)))
                .getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
