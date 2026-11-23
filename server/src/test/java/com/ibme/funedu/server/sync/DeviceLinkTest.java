package com.ibme.funedu.server.sync;

import static com.ibme.funedu.server.auth.TestIdTokens.*;
import static org.assertj.core.api.Assertions.assertThat;

import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import com.ibme.funedu.server.auth.TokenService;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
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
class DeviceLinkTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    @Autowired
    TestRestTemplate http;

    @Autowired
    TokenService tokenService;

    @Autowired
    JdbcTemplate jdbc;

    record AuthInfo(String accessToken, String sub, UUID deviceId) {}

    AuthInfo signIn(String sub, UUID deviceId) {
        var res = http.exchange("/api/v1/auth/google", HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(sub),
                        "deviceId", deviceId.toString())), JSON);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        String token = (String) res.getBody().get("accessToken");
        return new AuthInfo(token, sub, deviceId);
    }

    ResponseEntity<Map<String, Object>> link(String access, String mode) {
        var h = new HttpHeaders();
        if (access != null) h.setBearerAuth(access);
        var body = mode != null ? Map.of("mode", mode) : Map.of();
        return http.exchange("/api/v1/sync/link", HttpMethod.POST,
                new HttpEntity<>(body, h), JSON);
    }

    ResponseEntity<Map<String, Object>> getLink(String access) {
        var h = new HttpHeaders();
        if (access != null) h.setBearerAuth(access);
        return http.exchange("/api/v1/sync/link", HttpMethod.GET,
                new HttpEntity<>(h), JSON);
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

    @Test
    void pushBeforeLinkIs409() {
        var auth = signIn(randomSubject(), UUID.randomUUID());

        // Push with changes is rejected with 409 link_required
        var push = sync(auth.accessToken(), 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null)));
        assertThat(push.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(push.getBody().get("error")).isEqualTo("link_required");

        // Pull with empty changes is allowed (returns 200)
        var pull = sync(auth.accessToken(), 0, List.of());
        assertThat(pull.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void uploadIntoEmptyAccount() {
        var auth = signIn(randomSubject(), UUID.randomUUID());

        var linkRes = link(auth.accessToken(), "upload");
        assertThat(linkRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(linkRes.getBody().get("linked")).isEqualTo(true);

        var push = sync(auth.accessToken(), 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null)));
        assertThat(push.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void uploadIntoAccountWithData() {
        String sub = randomSubject();
        var dev1 = signIn(sub, UUID.randomUUID());
        assertThat(link(dev1.accessToken(), "upload").getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(sync(dev1.accessToken(), 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null))).getStatusCode())
                .isEqualTo(HttpStatus.OK);

        // Device 2 signs into same account
        var dev2 = signIn(sub, UUID.randomUUID());
        var linkRes = link(dev2.accessToken(), "upload");
        assertThat(linkRes.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(linkRes.getBody().get("error")).isEqualTo("account_not_empty");

        @SuppressWarnings("unchecked")
        var account = (Map<String, Object>) linkRes.getBody().get("account");
        assertThat(account).isNotNull();
        assertThat(account.get("hasData")).isEqualTo(true);
        @SuppressWarnings("unchecked")
        var kids = (List<Map<String, Object>>) account.get("kids");
        assertThat(kids).singleElement().satisfies(k -> assertThat(k.get("nickname")).isEqualTo("Na"));

        // Push from dev2 is still rejected with 409 link_required
        var push = sync(dev2.accessToken(), 0, List.of(
                change("kid:k2", Map.of("nickname", "Bo", "avatar", "chip", "age", 4), null)));
        assertThat(push.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(push.getBody().get("error")).isEqualTo("link_required");
    }

    @Test
    void onlyTombstonesAllowsUpload() {
        String sub = randomSubject();
        var dev1 = signIn(sub, UUID.randomUUID());
        link(dev1.accessToken(), "fresh");
        var push = sync(dev1.accessToken(), 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null)));
        long v = ((Number) ((List<?>) push.getBody().get("records")).stream()
                .map(r -> ((Map<?, ?>) r).get("version")).findFirst().orElseThrow()).longValue();

        // Tombstone kid:k1
        sync(dev1.accessToken(), v, List.of(change("kid:k1", null, v)));

        // Device 2 signs in and tries upload mode
        var dev2 = signIn(sub, UUID.randomUUID());
        var linkRes = link(dev2.accessToken(), "upload");
        assertThat(linkRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(linkRes.getBody().get("linked")).isEqualTo(true);
    }

    @Test
    void twoDevicesUploadAtOnce() throws Exception {
        String sub = randomSubject();
        var dev1 = signIn(sub, UUID.randomUUID());
        var dev2 = signIn(sub, UUID.randomUUID());

        CountDownLatch dev1Pushed = new CountDownLatch(1);
        AtomicInteger dev2Status = new AtomicInteger();

        Thread t2 = new Thread(() -> {
            try {
                if (dev1Pushed.await(5, TimeUnit.SECONDS)) {
                    var res = link(dev2.accessToken(), "upload");
                    dev2Status.set(res.getStatusCode().value());
                }
            } catch (InterruptedException ignored) {}
        });
        t2.start();

        // dev1 links upload and pushes data
        assertThat(link(dev1.accessToken(), "upload").getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(sync(dev1.accessToken(), 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null))).getStatusCode())
                .isEqualTo(HttpStatus.OK);
        dev1Pushed.countDown();

        t2.join(5000);
        assertThat(dev2Status.get()).isEqualTo(HttpStatus.CONFLICT.value());
    }

    @Test
    void replaceLocalAndFreshAlwaysLink() {
        String sub = randomSubject();
        var dev1 = signIn(sub, UUID.randomUUID());
        link(dev1.accessToken(), "upload");
        sync(dev1.accessToken(), 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null)));

        // Device 2 links with replace_local -> 200
        var dev2 = signIn(sub, UUID.randomUUID());
        var linkRes = link(dev2.accessToken(), "replace_local");
        assertThat(linkRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(linkRes.getBody().get("linked")).isEqualTo(true);

        // Idempotent: calling again is 200
        var linkRes2 = link(dev2.accessToken(), "replace_local");
        assertThat(linkRes2.getStatusCode()).isEqualTo(HttpStatus.OK);

        // Device 3 links with fresh -> 200
        var dev3 = signIn(sub, UUID.randomUUID());
        var freshRes = link(dev3.accessToken(), "fresh");
        assertThat(freshRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(freshRes.getBody().get("linked")).isEqualTo(true);
    }

    @Test
    void getLinkReportsState() {
        var auth = signIn(randomSubject(), UUID.randomUUID());

        var before = getLink(auth.accessToken());
        assertThat(before.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(before.getBody().get("linked")).isEqualTo(false);

        link(auth.accessToken(), "fresh");

        var after = getLink(auth.accessToken());
        assertThat(after.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(after.getBody().get("linked")).isEqualTo(true);
    }

    @Test
    void tokenWithoutDeviceIsUnlinked() {
        var auth = signIn(randomSubject(), UUID.randomUUID());
        UUID parentId = jdbc.queryForObject(
                "SELECT id FROM parent_accounts WHERE provider = 'google' AND subject = ?",
                UUID.class, auth.sub());
        UUID familyId = jdbc.queryForObject(
                "SELECT family_id FROM parent_accounts WHERE id = ?", UUID.class, parentId);
        String tokenNoDev = tokenService.accessToken(parentId, familyId);

        var push = sync(tokenNoDev, 0, List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "chip", "age", 5), null)));
        assertThat(push.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(push.getBody().get("error")).isEqualTo("link_required");

        var linkRes = link(tokenNoDev, "fresh");
        assertThat(linkRes.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(linkRes.getBody().get("error")).isEqualTo("link_required");
    }

    @Test
    void deleteAccountRemovesLinks() {
        var auth = signIn(randomSubject(), UUID.randomUUID());
        link(auth.accessToken(), "fresh");

        Integer countBefore = jdbc.queryForObject(
                "SELECT count(*) FROM family_devices WHERE device_id = ?",
                Integer.class, auth.deviceId());
        assertThat(countBefore).isEqualTo(1);

        var h = new HttpHeaders();
        h.setBearerAuth(auth.accessToken());
        var del = http.exchange("/api/v1/account", HttpMethod.DELETE, new HttpEntity<>(h), String.class);
        assertThat(del.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        Integer countAfter = jdbc.queryForObject(
                "SELECT count(*) FROM family_devices WHERE device_id = ?",
                Integer.class, auth.deviceId());
        assertThat(countAfter).isEqualTo(0);
    }

    @Test
    void badModeIs400() {
        var auth = signIn(randomSubject(), UUID.randomUUID());
        var res = link(auth.accessToken(), "hack_mode");
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(res.getBody().get("error")).isEqualTo("bad_request");
    }
}
