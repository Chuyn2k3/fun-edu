package com.ibme.funedu.server.friends;

import static com.ibme.funedu.server.auth.TestIdTokens.googleToken;
import static com.ibme.funedu.server.auth.TestIdTokens.randomSubject;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.RefreshTokenCleanup;
import com.ibme.funedu.server.auth.TestIdTokens;
import com.ibme.funedu.server.web.RateLimitFilter;
import java.lang.reflect.Proxy;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.sql.DataSource;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Bean;
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
@Import({TestDatabase.class, TestIdTokens.class, FriendApiTest.SqlCounterConfig.class})
class FriendApiTest {

    static final ParameterizedTypeReference<Map<String, Object>> MAP = new ParameterizedTypeReference<>() {};
    static final ParameterizedTypeReference<List<Map<String, Object>>> LIST = new ParameterizedTypeReference<>() {};

    @TestConfiguration(proxyBeanMethods = false)
    static class SqlCounterConfig {
        static final AtomicBoolean RECORDING = new AtomicBoolean(false);
        static final CopyOnWriteArrayList<String> STATEMENTS = new CopyOnWriteArrayList<>();

        static void start() {
            STATEMENTS.clear();
            RECORDING.set(true);
        }

        static List<String> stop() {
            RECORDING.set(false);
            return List.copyOf(STATEMENTS);
        }

        @Bean
        static BeanPostProcessor dataSourceSqlCounter() {
            return new BeanPostProcessor() {
                @Override
                public Object postProcessAfterInitialization(Object bean, String beanName) {
                    if (bean instanceof DataSource ds) {
                        return Proxy.newProxyInstance(
                                SqlCounterConfig.class.getClassLoader(),
                                new Class<?>[] {DataSource.class},
                                (proxy, method, args) -> {
                                    Object res = method.invoke(ds, args);
                                    if ("getConnection".equals(method.getName()) && res instanceof Connection conn) {
                                        return wrapConnection(conn);
                                    }
                                    return res;
                                });
                    }
                    return bean;
                }
            };
        }

        private static Connection wrapConnection(Connection conn) {
            return (Connection) Proxy.newProxyInstance(
                    SqlCounterConfig.class.getClassLoader(),
                    new Class<?>[] {Connection.class},
                    (proxy, method, args) -> {
                        Object res = method.invoke(conn, args);
                        String name = method.getName();
                        if ("prepareStatement".equals(name) && res instanceof PreparedStatement ps) {
                            String sql = args != null && args.length > 0 ? String.valueOf(args[0]) : "?";
                            return wrapStatement(ps, PreparedStatement.class, sql);
                        }
                        if ("prepareCall".equals(name) && res instanceof CallableStatement cs) {
                            String sql = args != null && args.length > 0 ? String.valueOf(args[0]) : "?";
                            return wrapStatement(cs, CallableStatement.class, sql);
                        }
                        if ("createStatement".equals(name) && res instanceof Statement st) {
                            return wrapStatement(st, Statement.class, null);
                        }
                        return res;
                    });
        }

        private static <T extends Statement> T wrapStatement(T delegate, Class<T> iface, String fixedSql) {
            return iface.cast(Proxy.newProxyInstance(
                    SqlCounterConfig.class.getClassLoader(),
                    new Class<?>[] {iface},
                    (proxy, method, args) -> {
                        String m = method.getName();
                        if (RECORDING.get()
                                && (m.equals("execute")
                                        || m.equals("executeQuery")
                                        || m.equals("executeUpdate")
                                        || m.equals("executeBatch"))) {
                            String sql = fixedSql != null
                                    ? fixedSql
                                    : (args != null && args.length > 0 ? String.valueOf(args[0]) : "statement");
                            STATEMENTS.add(sql);
                        }
                        return method.invoke(delegate, args);
                    }));
        }
    }

    private record FamilySession(UUID familyId, String token) {}

    @LocalServerPort
    int port;

    @Autowired
    TestRestTemplate http;

    @Autowired
    ObjectMapper json;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    RateLimitFilter rateLimits;

    @Autowired
    RefreshTokenCleanup cleanup;

    private final HttpClient rawClient = HttpClient.newHttpClient();

    @BeforeEach
    @AfterEach
    void resetLimits() {
        SqlCounterConfig.RECORDING.set(false);
        rateLimits.reset();
    }

    private FamilySession newFamily() {
        rateLimits.reset();
        var res = http.exchange(
                "/api/v1/auth/google",
                HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(randomSubject()), "deviceId", UUID.randomUUID().toString())),
                MAP);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        UUID familyId = UUID.fromString((String) res.getBody().get("familyId"));
        String token = (String) res.getBody().get("accessToken");
        var h = bearer(token);
        http.exchange("/api/v1/sync/link", HttpMethod.POST, new HttpEntity<>(Map.of("mode", "upload"), h), MAP);
        return new FamilySession(familyId, token);
    }

    private UUID insertFamilyRow() {
        UUID id = UUID.randomUUID();
        jdbc.update("INSERT INTO families (id) VALUES (?)", id);
        return id;
    }

    private static HttpHeaders bearer(String token) {
        var h = new HttpHeaders();
        if (token != null) h.setBearerAuth(token);
        return h;
    }

    private ResponseEntity<Map<String, Object>> createCode(String token) {
        return http.exchange("/api/v1/friends/code", HttpMethod.POST, new HttpEntity<>(bearer(token)), MAP);
    }

    private ResponseEntity<Map<String, Object>> redeem(String token, String code) {
        return http.exchange(
                "/api/v1/friends/redeem",
                HttpMethod.POST,
                new HttpEntity<>(Map.of("code", code), bearer(token)),
                MAP);
    }

    private ResponseEntity<List<Map<String, Object>>> listFriends(String token) {
        return http.exchange("/api/v1/friends", HttpMethod.GET, new HttpEntity<>(bearer(token)), LIST);
    }

    private ResponseEntity<Void> deleteFriend(String token, UUID friendFamilyId) {
        return http.exchange(
                "/api/v1/friends/" + friendFamilyId,
                HttpMethod.DELETE,
                new HttpEntity<>(bearer(token)),
                Void.class);
    }

    private void syncRecords(String token, List<Map<String, Object>> changes) {
        var res = http.exchange(
                "/api/v1/sync",
                HttpMethod.POST,
                new HttpEntity<>(Map.of("since", 0, "changes", changes), bearer(token)),
                MAP);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    private static Map<String, Object> change(String key, Map<String, Object> payload) {
        return Map.of("key", key, "payload", payload, "deleted", false);
    }

    @Test
    void codeHas6SafeCharsAndExpiresIn24h() {
        FamilySession fam = newFamily();
        Instant before = Instant.now();
        var res = createCode(fam.token());
        Instant after = Instant.now();

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        String code = (String) res.getBody().get("code");
        Instant expiresAt = Instant.parse((String) res.getBody().get("expiresAt"));

        assertThat(code).matches("^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$");
        assertThat(code).doesNotContainAnyWhitespaces();
        assertThat(Set.of('0', 'O', '1', 'I')).noneMatch(c -> code.indexOf(c) >= 0);
        assertThat(expiresAt).isBetween(before.plus(Duration.ofHours(24)).minusSeconds(5),
                after.plus(Duration.ofHours(24)).plusSeconds(5));
    }

    @Test
    void fourthLiveCodeReplacesTheOldest() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();

        List<String> created = new ArrayList<>();
        for (int i = 0; i < 4; i++) {
            var res = createCode(a.token());
            assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
            created.add((String) res.getBody().get("code"));
        }

        Integer liveCount = jdbc.queryForObject(
                "SELECT count(*) FROM friend_codes WHERE family_id = ? AND expires_at > now()",
                Integer.class, a.familyId());
        assertThat(liveCount).isEqualTo(3);

        // Oldest code (index 0) was evicted; codes 1, 2, 3 remain valid.
        var oldRes = redeem(b.token(), created.get(0));
        assertThat(oldRes.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(oldRes.getBody()).containsEntry("error", "code_invalid");

        var secondRes = redeem(b.token(), created.get(1));
        assertThat(secondRes.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    @SuppressWarnings("unchecked")
    void redeemMakesBothFamiliesFriendsOnce() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();

        String code = (String) createCode(a.token()).getBody().get("code");
        // Trim & case-insensitive on redeem.
        var res = redeem(b.token(), "  " + code.toLowerCase(Locale.ROOT) + " ");
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);

        Map<String, Object> friend = (Map<String, Object>) res.getBody().get("friend");
        assertThat(friend.get("familyId")).isEqualTo(a.familyId().toString());
        assertThat(friend.get("online")).isEqualTo(false);

        UUID[] ordered = FriendService.orderedPair(a.familyId(), b.familyId());
        Integer rowCount = jdbc.queryForObject(
                "SELECT count(*) FROM friendships WHERE family_a = ? AND family_b = ?",
                Integer.class, ordered[0], ordered[1]);
        assertThat(rowCount).isEqualTo(1);

        // Code was consumed on success.
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM friend_codes WHERE code = ?", Integer.class, code)).isZero();

        var aList = listFriends(a.token());
        var bList = listFriends(b.token());
        assertThat(aList.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(bList.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(aList.getBody()).extracting(f -> f.get("familyId")).containsExactly(b.familyId().toString());
        assertThat(bList.getBody()).extracting(f -> f.get("familyId")).containsExactly(a.familyId().toString());
    }

    @Test
    void redeemOwnCodeIs409Self() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        String code = (String) createCode(a.token()).getBody().get("code");

        var res = redeem(a.token(), code);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(res.getBody()).containsEntry("error", "self");

        // Code must NOT be consumed on error.
        assertThat(redeem(b.token(), code).getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void redeemTwiceIs409AlreadyFriends() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        FamilySession c = newFamily();

        String code1 = (String) createCode(a.token()).getBody().get("code");
        assertThat(redeem(b.token(), code1).getStatusCode()).isEqualTo(HttpStatus.OK);

        String code2 = (String) createCode(a.token()).getBody().get("code");
        var dup = redeem(b.token(), code2);
        assertThat(dup.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(dup.getBody()).containsEntry("error", "already_friends");

        // code2 must NOT be consumed on error: C can still redeem it.
        assertThat(redeem(c.token(), code2).getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void expiredOrWrongCodeIsTheSame404CodeInvalid() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();

        String expiredCode = (String) createCode(a.token()).getBody().get("code");
        jdbc.update(
                "UPDATE friend_codes SET expires_at = ? WHERE code = ?",
                Timestamp.from(Instant.now().minus(1, ChronoUnit.HOURS)), expiredCode);

        var wrongFormat = redeem(b.token(), "AB");
        var unknown = redeem(b.token(), "000000");
        var expired = redeem(b.token(), expiredCode);

        for (var r : List.of(wrongFormat, unknown, expired)) {
            assertThat(r.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
            assertThat(r.getBody()).isEqualTo(Map.of("error", "code_invalid"));
        }
    }

    @Test
    void fiftyFirstFriendIs409TooManyFriends() {
        FamilySession a = newFamily();
        for (int i = 0; i < 50; i++) {
            UUID peer = insertFamilyRow();
            UUID[] pair = FriendService.orderedPair(a.familyId(), peer);
            jdbc.update("INSERT INTO friendships (family_a, family_b) VALUES (?, ?)", pair[0], pair[1]);
        }

        FamilySession peer51 = newFamily();
        String codeFrom51 = (String) createCode(peer51.token()).getBody().get("code");
        var callerFull = redeem(a.token(), codeFrom51);
        assertThat(callerFull.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(callerFull.getBody()).containsEntry("error", "too_many_friends");

        // Also blocked when the code owner already has 50 friends.
        FamilySession peer52 = newFamily();
        String codeFromA = (String) createCode(a.token()).getBody().get("code");
        var ownerFull = redeem(peer52.token(), codeFromA);
        assertThat(ownerFull.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(ownerFull.getBody()).containsEntry("error", "too_many_friends");
    }

    @Test
    @SuppressWarnings("unchecked")
    void listShowsRaceNicknameAvatarRocket() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();

        syncRecords(b.token(), List.of(
                change("kid:k1", Map.of("nickname", "Na", "avatar", "fox", "age", 5, "createdAt", 1000L)),
                change("setting:k1:raceNickname", Map.of("value", "Siêu Na", "u", 2000L)),
                change("game:k1", Map.of("rocket", "rocket_blue", "u", 2000L)),
                change("kid:k2", Map.of("nickname", "Bi", "avatar", "panda", "age", 4, "createdAt", 2000L))));

        String code = (String) createCode(b.token()).getBody().get("code");
        assertThat(redeem(a.token(), code).getStatusCode()).isEqualTo(HttpStatus.OK);

        var res = listFriends(a.token());
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(res.getBody()).hasSize(1);

        Map<String, Object> friendB = res.getBody().get(0);
        assertThat(friendB.get("familyId")).isEqualTo(b.familyId().toString());
        assertThat(friendB.get("online")).isEqualTo(false);

        List<Map<String, Object>> kids = (List<Map<String, Object>>) friendB.get("kids");
        assertThat(kids).containsExactly(
                Map.of("kidUuid", "k1", "nickname", "Siêu Na", "avatar", "fox", "rocket", "rocket_blue"),
                Map.of("kidUuid", "k2", "nickname", "Bi", "avatar", "panda", "rocket", "rocket_orange"));
    }

    @Test
    void listUsesAtMost3SqlStatementsFor30Friends() {
        FamilySession a = newFamily();
        for (int i = 0; i < 30; i++) {
            UUID peer = insertFamilyRow();
            UUID[] pair = FriendService.orderedPair(a.familyId(), peer);
            jdbc.update("INSERT INTO friendships (family_a, family_b) VALUES (?, ?)", pair[0], pair[1]);
            String kidId = "kid-" + i;
            jdbc.update("""
                    INSERT INTO sync_records (family_id, key, kind, payload, deleted, version)
                    VALUES (?, ?, 'kid', ?::jsonb, false, nextval('sync_version_seq')),
                           (?, ?, 'setting', ?::jsonb, false, nextval('sync_version_seq')),
                           (?, ?, 'game', ?::jsonb, false, nextval('sync_version_seq'))
                    """,
                    peer, "kid:" + kidId, "{\"nickname\":\"Bé " + i + "\",\"avatar\":\"bunny\",\"createdAt\":1000}",
                    peer, "setting:" + kidId + ":raceNickname", "{\"value\":\"Racer " + i + "\"}",
                    peer, "game:" + kidId, "{\"rocket\":\"rocket_green\"}");
        }

        SqlCounterConfig.start();
        ResponseEntity<List<Map<String, Object>>> res;
        try {
            res = listFriends(a.token());
        } finally {
            List<String> sqls = SqlCounterConfig.stop();
            assertThat(sqls.size()).isLessThanOrEqualTo(3);
        }

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(res.getBody()).hasSize(30);
    }

    @Test
    void deleteRemovesBothDirections() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        String code = (String) createCode(a.token()).getBody().get("code");
        assertThat(redeem(b.token(), code).getStatusCode()).isEqualTo(HttpStatus.OK);

        var del = deleteFriend(a.token(), b.familyId());
        assertThat(del.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        assertThat(listFriends(a.token()).getBody()).isEmpty();
        assertThat(listFriends(b.token()).getBody()).isEmpty();

        // Deleting again is idempotent.
        assertThat(deleteFriend(b.token(), a.familyId()).getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
    }

    @Test
    void deletingAnAccountRemovesItsFriendshipsAndCodes() {
        FamilySession a = newFamily();
        FamilySession b = newFamily();

        String code = (String) createCode(a.token()).getBody().get("code");
        assertThat(redeem(b.token(), code).getStatusCode()).isEqualTo(HttpStatus.OK);
        String code2 = (String) createCode(a.token()).getBody().get("code");

        var delAcc = http.exchange("/api/v1/account", HttpMethod.DELETE, new HttpEntity<>(bearer(a.token())), Void.class);
        assertThat(delAcc.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        assertThat(listFriends(b.token()).getBody()).isEmpty();
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM friend_codes WHERE code = ?", Integer.class, code2)).isZero();
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM friendships WHERE family_a = ? OR family_b = ?",
                Integer.class, a.familyId(), a.familyId())).isZero();
    }

    private HttpResponse<String> rawPostJson(String path, Object body, String token) throws Exception {
        var req = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + token)
                .POST(HttpRequest.BodyPublishers.ofString(body == null ? "" : json.writeValueAsString(body)));
        return rawClient.send(req.build(), HttpResponse.BodyHandlers.ofString());
    }

    @Test
    void redeemIsRateLimitedPerFamily() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        rateLimits.reset();

        // Use java.net.http.HttpClient so 429 + Retry-After: 3600 does not trigger Apache HttpClient retry sleep.
        for (int i = 0; i < 20; i++) {
            var res = rawPostJson("/api/v1/friends/redeem", Map.of("code", "000000"), a.token());
            assertThat(res.statusCode()).isEqualTo(404);
        }

        var blocked = rawPostJson("/api/v1/friends/redeem", Map.of("code", "000000"), a.token());
        assertThat(blocked.statusCode()).isEqualTo(429);
        assertThat(blocked.body()).contains("\"too_many\"");
        assertThat(blocked.headers().firstValue("Retry-After")).isPresent();

        // Another family has its own bucket.
        assertThat(rawPostJson("/api/v1/friends/redeem", Map.of("code", "000000"), b.token()).statusCode())
                .isEqualTo(404);

        // Code creation is also limited to 10/hour/family.
        for (int i = 0; i < 10; i++) {
            assertThat(rawPostJson("/api/v1/friends/code", null, a.token()).statusCode()).isEqualTo(200);
        }
        var codeBlocked = rawPostJson("/api/v1/friends/code", null, a.token());
        assertThat(codeBlocked.statusCode()).isEqualTo(429);
        assertThat(codeBlocked.body()).contains("\"too_many\"");
    }

    @Test
    void nightlyCleanupRemovesExpiredCodes() {
        FamilySession fam = newFamily();
        String deadCode = (String) createCode(fam.token()).getBody().get("code");
        String liveCode = (String) createCode(fam.token()).getBody().get("code");
        jdbc.update(
                "UPDATE friend_codes SET expires_at = ? WHERE code = ?",
                Timestamp.from(Instant.now().minus(1, ChronoUnit.HOURS)), deadCode);

        int purged = cleanup.purge();
        assertThat(purged).isGreaterThanOrEqualTo(1);

        assertThat(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM friend_codes WHERE code = ?)", Boolean.class, deadCode)).isFalse();
        assertThat(jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM friend_codes WHERE code = ?)", Boolean.class, liveCode)).isTrue();
    }
}
