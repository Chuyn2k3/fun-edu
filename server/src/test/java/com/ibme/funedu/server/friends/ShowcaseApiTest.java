package com.ibme.funedu.server.friends;

import static com.ibme.funedu.server.auth.TestIdTokens.googleToken;
import static com.ibme.funedu.server.auth.TestIdTokens.randomSubject;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import com.ibme.funedu.server.web.RateLimitFilter;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;
import org.junit.jupiter.api.AfterEach;
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
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class, ShowcaseApiTest.RecordingNotifierConfig.class})
class ShowcaseApiTest {

    static final ParameterizedTypeReference<Map<String, Object>> MAP = new ParameterizedTypeReference<>() {};

    record SentNotification(UUID familyId, Map<String, Object> message) {}

    @TestConfiguration(proxyBeanMethods = false)
    static class RecordingNotifierConfig {
        static final CopyOnWriteArrayList<SentNotification> SENT = new CopyOnWriteArrayList<>();

        @Bean
        @Primary
        LobbyNotifier recordingLobbyNotifier() {
            return (familyId, message) -> SENT.add(new SentNotification(familyId, Map.copyOf(message)));
        }
    }

    private record FamilySession(UUID familyId, String token) {}

    @Autowired
    TestRestTemplate http;

    @Autowired
    ObjectMapper json;

    @Autowired
    RateLimitFilter rateLimits;

    @BeforeEach
    @AfterEach
    void resetState() {
        RecordingNotifierConfig.SENT.clear();
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
        http.exchange("/api/v1/sync/link", HttpMethod.POST, new HttpEntity<>(Map.of("mode", "upload"), bearer(token)), MAP);
        return new FamilySession(familyId, token);
    }

    private static HttpHeaders bearer(String token) {
        var h = new HttpHeaders();
        if (token != null) h.setBearerAuth(token);
        return h;
    }

    private static HttpHeaders bearerJson(String token) {
        HttpHeaders h = bearer(token);
        h.setContentType(MediaType.APPLICATION_JSON);
        return h;
    }

    private void makeFriends(FamilySession a, FamilySession b) {
        var codeRes = http.exchange("/api/v1/friends/code", HttpMethod.POST, new HttpEntity<>(bearer(a.token())), MAP);
        assertThat(codeRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        String code = (String) codeRes.getBody().get("code");
        var redeemRes = http.exchange(
                "/api/v1/friends/redeem",
                HttpMethod.POST,
                new HttpEntity<>(Map.of("code", code), bearer(b.token())),
                MAP);
        assertThat(redeemRes.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    private void syncRecords(String token, List<Map<String, Object>> changes) {
        var res = http.exchange(
                "/api/v1/sync",
                HttpMethod.POST,
                new HttpEntity<>(Map.of("since", 0, "changes", changes), bearer(token)),
                MAP);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    private ResponseEntity<Map<String, Object>> putShowcase(String token, String kidUuid, Object body) {
        return http.exchange(
                "/api/v1/showcase/" + kidUuid,
                HttpMethod.PUT,
                new HttpEntity<>(body, bearerJson(token)),
                MAP);
    }

    private ResponseEntity<Map<String, Object>> putRawShowcase(String token, String kidUuid, String rawJson) {
        return http.exchange(
                "/api/v1/showcase/" + kidUuid,
                HttpMethod.PUT,
                new HttpEntity<>(rawJson, bearerJson(token)),
                MAP);
    }

    private ResponseEntity<Map<String, Object>> getShowcase(String token, UUID familyId, String kidUuid) {
        return http.exchange(
                "/api/v1/showcase/" + familyId + "/" + kidUuid,
                HttpMethod.GET,
                new HttpEntity<>(bearer(token)),
                MAP);
    }

    private ResponseEntity<Map<String, Object>> react(String token, UUID familyId, String kidUuid, String kind) {
        return http.exchange(
                "/api/v1/showcase/" + familyId + "/" + kidUuid + "/react",
                HttpMethod.POST,
                new HttpEntity<>(Map.of("kind", kind), bearer(token)),
                MAP);
    }

    @Test
    @SuppressWarnings("unchecked")
    void ownerCanPutAndFriendCanGet() {
        FamilySession owner = newFamily();
        FamilySession friend = newFamily();
        makeFriends(owner, friend);

        Map<String, Object> payload = Map.of(
                "nickname", "Siêu Na",
                "avatar", "fox",
                "rocket", "rocket_blue",
                "trail", "trail_rainbow",
                "pinned", List.of("badge_1", "sticker_2", "sticker_3"),
                "races", 12,
                "wins", 7,
                "stickers", 24,
                "learning", Map.of("glyphs", 18, "lessons", 9, "stars", 42));

        var putRes = putShowcase(owner.token(), "kid-1", payload);
        assertThat(putRes.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        for (FamilySession viewer : List.of(owner, friend)) {
            var getRes = getShowcase(viewer.token(), owner.familyId(), "kid-1");
            assertThat(getRes.getStatusCode()).isEqualTo(HttpStatus.OK);
            Map<String, Object> body = getRes.getBody();
            assertThat(body).containsEntry("nickname", "Siêu Na");
            assertThat(body).containsEntry("avatar", "fox");
            assertThat(body).containsEntry("rocket", "rocket_blue");
            assertThat(body).containsEntry("trail", "trail_rainbow");
            assertThat(body).containsEntry("races", 12);
            assertThat(body).containsEntry("wins", 7);
            assertThat(body).containsEntry("stickers", 24);
            assertThat((List<String>) body.get("pinned"))
                    .containsExactly("badge_1", "sticker_2", "sticker_3");
            assertThat((Map<String, Object>) body.get("learning"))
                    .containsExactlyInAnyOrderEntriesOf(Map.of("glyphs", 18, "lessons", 9, "stars", 42));
            assertThat((Map<String, Object>) body.get("reactions"))
                    .containsExactlyInAnyOrderEntriesOf(Map.of("clap", 0, "heart", 0, "star", 0));
            assertThat((List<String>) body.get("mine")).isEmpty();
        }
    }

    @Test
    void strangerGets404() {
        FamilySession owner = newFamily();
        FamilySession stranger = newFamily();
        FamilySession friend = newFamily();
        makeFriends(owner, friend);

        assertThat(putShowcase(owner.token(), "kid-1", Map.of("nickname", "Na")).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);

        var getRes = getShowcase(stranger.token(), owner.familyId(), "kid-1");
        assertThat(getRes.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(getRes.getBody()).isEqualTo(Map.of("error", "not_found"));

        var reactRes = react(stranger.token(), owner.familyId(), "kid-1", "clap");
        assertThat(reactRes.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(reactRes.getBody()).isEqualTo(Map.of("error", "not_found"));

        // Friend querying missing kid showcase also gets 404.
        var missingGet = getShowcase(friend.token(), owner.familyId(), "missing-kid");
        assertThat(missingGet.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(missingGet.getBody()).isEqualTo(Map.of("error", "not_found"));

        var missingReact = react(friend.token(), owner.familyId(), "missing-kid", "heart");
        assertThat(missingReact.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(missingReact.getBody()).isEqualTo(Map.of("error", "not_found"));
    }

    @Test
    void unknownKeyOrOversizePayloadIs400() {
        FamilySession owner = newFamily();
        FamilySession friend = newFamily();
        makeFriends(owner, friend);

        // Top-level unknown key
        var unknownTop = putShowcase(owner.token(), "kid-1", Map.of("nickname", "Na", "email", "a@b.com"));
        assertThat(unknownTop.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(unknownTop.getBody()).isEqualTo(Map.of("error", "bad_request"));

        // Unknown key inside learning
        var unknownLearning = putShowcase(
                owner.token(),
                "kid-1",
                Map.of("nickname", "Na", "learning", Map.of("glyphs", 1, "level", 99)));
        assertThat(unknownLearning.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(unknownLearning.getBody()).isEqualTo(Map.of("error", "bad_request"));

        // pinned > 3 items
        var tooManyPinned = putShowcase(
                owner.token(),
                "kid-1",
                Map.of("pinned", List.of("a", "b", "c", "d")));
        assertThat(tooManyPinned.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(tooManyPinned.getBody()).isEqualTo(Map.of("error", "bad_request"));

        // pinned item > 64 chars
        var longPinnedItem = putShowcase(
                owner.token(),
                "kid-1",
                Map.of("pinned", List.of("x".repeat(65))));
        assertThat(longPinnedItem.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(longPinnedItem.getBody()).isEqualTo(Map.of("error", "bad_request"));

        // pinned non-string item
        var nonStringPinned = putShowcase(
                owner.token(),
                "kid-1",
                Map.of("pinned", List.of(123)));
        assertThat(nonStringPinned.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(nonStringPinned.getBody()).isEqualTo(Map.of("error", "bad_request"));

        // > 4 KB payload
        String oversizeRaw = "{\"nickname\":\"Na\"" + " ".repeat(4090) + "}";
        assertThat(oversizeRaw.length()).isGreaterThan(4096);
        var oversize = putRawShowcase(owner.token(), "kid-1", oversizeRaw);
        assertThat(oversize.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(oversize.getBody()).isEqualTo(Map.of("error", "bad_request"));

        // Invalid string field length & negative int & bad kidUuid
        assertThat(putShowcase(owner.token(), "kid-1", Map.of("nickname", "n".repeat(41))).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(putShowcase(owner.token(), "kid-1", Map.of("races", -1)).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(putShowcase(owner.token(), "k".repeat(65), Map.of("nickname", "Na")).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);

        // Invalid reaction kind
        assertThat(putShowcase(owner.token(), "kid-1", Map.of("nickname", "Na")).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);
        var badReaction = react(friend.token(), owner.familyId(), "kid-1", "dislike");
        assertThat(badReaction.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(badReaction.getBody()).isEqualTo(Map.of("error", "bad_request"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void reactingTwiceCountsOnceAndNotifiesOnce() {
        FamilySession owner = newFamily();
        FamilySession friend = newFamily();
        makeFriends(owner, friend);

        syncRecords(friend.token(), List.of(
                Map.of("key", "kid:f1", "payload", Map.of("nickname", "Bi", "createdAt", 1000L), "deleted", false),
                Map.of("key", "setting:f1:raceNickname", "payload", Map.of("value", "Siêu Bi"), "deleted", false)));

        assertThat(putShowcase(owner.token(), "kid-1", Map.of("nickname", "Na")).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);

        assertThat(react(friend.token(), owner.familyId(), "kid-1", "star").getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(react(friend.token(), owner.familyId(), "kid-1", "star").getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);

        var getRes = getShowcase(friend.token(), owner.familyId(), "kid-1");
        assertThat(getRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat((Map<String, Object>) getRes.getBody().get("reactions"))
                .containsExactlyInAnyOrderEntriesOf(Map.of("clap", 0, "heart", 0, "star", 1));
        assertThat((List<String>) getRes.getBody().get("mine")).containsExactly("star");

        assertThat(RecordingNotifierConfig.SENT).containsExactly(
                new SentNotification(owner.familyId(), Map.of(
                        "t", "reaction",
                        "kidUuid", "kid-1",
                        "kind", "star",
                        "fromNickname", "Siêu Bi")));
    }

    @Test
    @SuppressWarnings("unchecked")
    void reactionCountsGrouped() {
        FamilySession owner = newFamily();
        FamilySession f1 = newFamily();
        FamilySession f2 = newFamily();
        FamilySession f3 = newFamily();
        makeFriends(owner, f1);
        makeFriends(owner, f2);
        makeFriends(owner, f3);

        assertThat(putShowcase(owner.token(), "kid-1", Map.of("nickname", "Na")).getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);

        assertThat(react(f1.token(), owner.familyId(), "kid-1", "clap").getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(react(f1.token(), owner.familyId(), "kid-1", "star").getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(react(f2.token(), owner.familyId(), "kid-1", "clap").getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(react(f2.token(), owner.familyId(), "kid-1", "heart").getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(react(f3.token(), owner.familyId(), "kid-1", "clap").getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        var f1View = getShowcase(f1.token(), owner.familyId(), "kid-1");
        assertThat(f1View.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat((Map<String, Object>) f1View.getBody().get("reactions"))
                .containsExactlyInAnyOrderEntriesOf(Map.of("clap", 3, "heart", 1, "star", 1));
        assertThat((List<String>) f1View.getBody().get("mine")).containsExactlyInAnyOrder("clap", "star");

        var f2View = getShowcase(f2.token(), owner.familyId(), "kid-1");
        assertThat((List<String>) f2View.getBody().get("mine")).containsExactlyInAnyOrder("clap", "heart");

        var ownerView = getShowcase(owner.token(), owner.familyId(), "kid-1");
        assertThat((Map<String, Object>) ownerView.getBody().get("reactions"))
                .containsExactlyInAnyOrderEntriesOf(Map.of("clap", 3, "heart", 1, "star", 1));
        assertThat((List<String>) ownerView.getBody().get("mine")).isEmpty();

        // Fallback nickname "Bạn đua" used when caller has no synced kid/raceNickname.
        assertThat(RecordingNotifierConfig.SENT).hasSize(5);
        assertThat(RecordingNotifierConfig.SENT.get(0).message())
                .containsEntry("fromNickname", "Bạn đua");
    }

    @Test
    void learningAbsentWhenNotSent() throws Exception {
        FamilySession owner = newFamily();
        FamilySession friend = newFamily();
        makeFriends(owner, friend);

        assertThat(putShowcase(owner.token(), "kid-1", Map.of(
                "nickname", "Na",
                "races", 3,
                "wins", 2,
                "stickers", 5)).getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        var getRes = getShowcase(friend.token(), owner.familyId(), "kid-1");
        assertThat(getRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getRes.getBody()).doesNotContainKey("learning");

        // Also when "learning": null is explicitly sent, learning must remain absent.
        assertThat(putRawShowcase(owner.token(), "kid-1", "{\"nickname\":\"Na\",\"learning\":null}").getStatusCode())
                .isEqualTo(HttpStatus.NO_CONTENT);
        var getNullRes = getShowcase(friend.token(), owner.familyId(), "kid-1");
        assertThat(getNullRes.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getNullRes.getBody()).doesNotContainKey("learning");
        assertThat(json.writeValueAsString(getNullRes.getBody())).doesNotContain("\"learning\"");
    }
}
