package com.ibme.funedu.server.lobby;

import static com.ibme.funedu.server.auth.TestIdTokens.googleToken;
import static com.ibme.funedu.server.auth.TestIdTokens.randomSubject;
import static com.ibme.funedu.server.room.RoomSocket.players;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import com.ibme.funedu.server.room.RoomSocket;
import com.ibme.funedu.server.web.RateLimitFilter;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.socket.CloseStatus;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "funedu.rooms.countdown=150ms",
        "funedu.rooms.min-step-interval=20ms",
        "funedu.rooms.reconnect-grace=1s"})
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class LobbyFlowTest {

    static final ParameterizedTypeReference<Map<String, Object>> MAP = new ParameterizedTypeReference<>() {};
    static final ParameterizedTypeReference<List<Map<String, Object>>> LIST = new ParameterizedTypeReference<>() {};

    private record FamilySession(UUID familyId, String token) {}

    @LocalServerPort
    int port;

    @Autowired
    TestRestTemplate http;

    @Autowired
    RateLimitFilter rateLimits;

    @Autowired
    LobbyRegistry lobbyRegistry;

    @Autowired
    LobbySocketHandler lobbyHandler;

    @BeforeEach
    @AfterEach
    void resetLimits() {
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

    private void removeFriend(FamilySession caller, UUID friendFamilyId) {
        var res = http.exchange(
                "/api/v1/friends/" + friendFamilyId,
                HttpMethod.DELETE,
                new HttpEntity<>(bearer(caller.token())),
                Void.class);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
    }

    private List<Map<String, Object>> listFriends(FamilySession caller) {
        var res = http.exchange("/api/v1/friends", HttpMethod.GET, new HttpEntity<>(bearer(caller.token())), LIST);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        return res.getBody();
    }

    private String createRoom(FamilySession caller) {
        var res = http.exchange("/api/v1/rooms", HttpMethod.POST, new HttpEntity<>(bearer(caller.token())), MAP);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        return (String) res.getBody().get("code");
    }

    private void syncRecords(String token, List<Map<String, Object>> changes) {
        var res = http.exchange(
                "/api/v1/sync",
                HttpMethod.POST,
                new HttpEntity<>(Map.of("since", 0, "changes", changes), bearer(token)),
                MAP);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    @SuppressWarnings("unchecked")
    void friendsSeeEachOtherComeOnlineAndGoOffline() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        try (var sockA = LobbySocket.open(port, a.token())) {
            var helloA = sockA.await(m -> "hello".equals(m.get("t")));
            assertThat((List<String>) helloA.get("friendsOnline")).isEmpty();
            assertThat(listFriends(a).get(0).get("online")).isEqualTo(false);

            long onlineV;
            try (var sockB = LobbySocket.open(port, b.token())) {
                var helloB = sockB.await(m -> "hello".equals(m.get("t")));
                assertThat((List<String>) helloB.get("friendsOnline")).containsExactly(a.familyId().toString());

                var onlineMsg = sockA.await(m -> "presence".equals(m.get("t")));
                assertThat(onlineMsg.get("familyId")).isEqualTo(b.familyId().toString());
                assertThat(onlineMsg.get("online")).isEqualTo(true);
                onlineV = ((Number) onlineMsg.get("v")).longValue();

                assertThat(listFriends(a).get(0).get("online")).isEqualTo(true);
            }

            var offlineMsg = sockA.await(m -> "presence".equals(m.get("t")) && Boolean.FALSE.equals(m.get("online")));
            assertThat(offlineMsg.get("familyId")).isEqualTo(b.familyId().toString());
            // A slow socket can swap two presence messages; the app keeps the
            // one with the larger count, so each carries a growing one.
            long offlineV = ((Number) offlineMsg.get("v")).longValue();
            assertThat(offlineV).isGreaterThan(onlineV);
            assertThat(((Number) helloA.get("v")).longValue()).isLessThan(onlineV);
            assertThat(listFriends(a).get(0).get("online")).isEqualTo(false);
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void strangersGetNoPresence() throws Exception {
        FamilySession a = newFamily();
        FamilySession stranger = newFamily();

        try (var sockA = LobbySocket.open(port, a.token())) {
            sockA.await(m -> "hello".equals(m.get("t")));

            try (var sockStranger = LobbySocket.open(port, stranger.token())) {
                var helloS = sockStranger.await(m -> "hello".equals(m.get("t")));
                assertThat((List<String>) helloS.get("friendsOnline")).isEmpty();
            }

            sockA.assertNoMessage(m -> "presence".equals(m.get("t")), 200);
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void presenceStaysOnlineWhileAnyDeviceIsConnected() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        try (var sockB = LobbySocket.open(port, b.token())) {
            sockB.await(m -> "hello".equals(m.get("t")));

            var dev1 = LobbySocket.open(port, a.token());
            try {
                dev1.await(m -> "hello".equals(m.get("t")));
                var cameOnline = sockB.await(m -> "presence".equals(m.get("t")));
                assertThat(cameOnline.get("familyId")).isEqualTo(a.familyId().toString());
                assertThat(cameOnline.get("online")).isEqualTo(true);

                try (var dev2 = LobbySocket.open(port, a.token())) {
                    var hello2 = dev2.await(m -> "hello".equals(m.get("t")));
                    assertThat((List<String>) hello2.get("friendsOnline")).containsExactly(b.familyId().toString());
                    // 2nd device must NOT push a redundant online presence.
                    sockB.assertNoMessage(m -> "presence".equals(m.get("t")), 150);

                    // Close 1st device while 2nd stays open -> friend must still see A online.
                    dev1.close();
                    sockB.assertNoMessage(m -> "presence".equals(m.get("t")), 200);
                    assertThat(lobbyRegistry.isOnline(a.familyId())).isTrue();
                    assertThat(listFriends(b).get(0).get("online")).isEqualTo(true);
                }

                // Now 2nd (last) device closed -> friend receives offline presence.
                var wentOffline = sockB.await(m -> "presence".equals(m.get("t")));
                assertThat(wentOffline.get("familyId")).isEqualTo(a.familyId().toString());
                assertThat(wentOffline.get("online")).isEqualTo(false);
                assertThat(lobbyRegistry.isOnline(a.familyId())).isFalse();
                assertThat(listFriends(b).get(0).get("online")).isEqualTo(false);
            } finally {
                dev1.close();
            }
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void inviteReachesAnOnlineFriendWithin300ms() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        String kidUuid = UUID.randomUUID().toString();
        syncRecords(a.token(), List.of(
                Map.of("key", "kid:" + kidUuid,
                        "payload", Map.of("nickname", "Na", "avatar", "assets/images/avatars/fox.png", "createdAt", 1000L),
                        "deleted", false),
                Map.of("key", "setting:" + kidUuid + ":raceNickname",
                        "payload", Map.of("value", "Siêu Na"),
                        "deleted", false)));

        String code = createRoom(a);
        try (var roomA = RoomSocket.open(port, code, a.token());
                var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token())) {
            roomA.join(kidUuid, "Siêu Na");
            roomA.awaitRoom(m -> true);
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));

            long startNanos = System.nanoTime();
            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));

            var invite = lobbyB.await(m -> "invite".equals(m.get("t")));
            long elapsedMs = (System.nanoTime() - startNanos) / 1_000_000L;
            assertThat(elapsedMs).isLessThan(300L);
            assertThat((String) invite.get("inviteId")).isNotBlank();
            assertThat(invite.get("roomCode")).isEqualTo(code);
            assertThat(((Number) invite.get("expiresInMs")).longValue()).isEqualTo(30_000L);

            Map<String, Object> from = (Map<String, Object>) invite.get("from");
            assertThat(from).containsEntry("familyId", a.familyId().toString());
            assertThat(from).containsEntry("kidUuid", kidUuid);
            assertThat(from).containsEntry("nickname", "Siêu Na");
            assertThat(from).containsEntry("avatar", "assets/images/avatars/fox.png");
        }
    }

    @Test
    void inviteToAnOfflineFriendIsRefused() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        FamilySession stranger = newFamily();
        makeFriends(a, b);

        String kidUuid = UUID.randomUUID().toString();
        String code = createRoom(a);
        try (var roomA = RoomSocket.open(port, code, a.token());
                var lobbyA = LobbySocket.open(port, a.token());
                var lobbyStranger = LobbySocket.open(port, stranger.token())) {
            roomA.join(kidUuid, "Na");
            roomA.awaitRoom(m -> true);
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyStranger.await(m -> "hello".equals(m.get("t")));

            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            var offlineErr = lobbyA.await(m -> "error".equals(m.get("t")));
            assertThat(offlineErr.get("code")).isEqualTo("friend_offline");

            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", stranger.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            var strangerErr = lobbyA.await(m -> "error".equals(m.get("t")));
            assertThat(strangerErr.get("code")).isEqualTo("not_friends");
        }
    }

    @Test
    void inviteExpiresAfter30sAndIsCancelled() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        String kidUuid = UUID.randomUUID().toString();
        String code = createRoom(a);
        try (var roomA = RoomSocket.open(port, code, a.token());
                var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token())) {
            roomA.join(kidUuid, "Na");
            roomA.awaitRoom(m -> true);
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));

            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            var invite = lobbyB.await(m -> "invite".equals(m.get("t")));
            String inviteId = (String) invite.get("inviteId");

            // At +29s the invite is still valid.
            lobbyRegistry.purgeExpiredInvites(Instant.now().plusSeconds(29));
            lobbyB.assertNoMessage(m -> "invite_cancelled".equals(m.get("t")), 100);

            // At +31s (> 30s TTL) it expires and invite_cancelled is pushed.
            lobbyRegistry.purgeExpiredInvites(Instant.now().plusSeconds(31));
            var cancelled = lobbyB.await(m -> "invite_cancelled".equals(m.get("t")));
            assertThat(cancelled.get("inviteId")).isEqualTo(inviteId);

            // After expiry, a new invite can be sent for the same pair.
            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            var fresh = lobbyB.await(m -> "invite".equals(m.get("t")));
            assertThat(fresh.get("inviteId")).isNotEqualTo(inviteId);
        }
    }

    @Test
    void secondPendingInviteForTheSamePairIsRefused() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        String kidUuid = UUID.randomUUID().toString();
        String code = createRoom(a);
        try (var roomA = RoomSocket.open(port, code, a.token());
                var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token())) {
            roomA.join(kidUuid, "Na");
            roomA.awaitRoom(m -> true);
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));

            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            var inv1 = lobbyB.await(m -> "invite".equals(m.get("t")));
            String id1 = (String) inv1.get("inviteId");

            // Second pending invite for same pair (A -> B) is refused.
            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            var err = lobbyA.await(m -> "error".equals(m.get("t")));
            assertThat(err.get("code")).isEqualTo("invite_pending");

            // Reverse direction (B -> A) for the same pair is also refused while pending.
            String codeB = createRoom(b);
            try (var roomB = RoomSocket.open(port, codeB, b.token())) {
                roomB.join("kid-b", "Bo");
                roomB.awaitRoom(m -> true);
                lobbyB.send(Map.of(
                        "t", "invite",
                        "toFamilyId", a.familyId().toString(),
                        "roomCode", codeB,
                        "kidUuid", "kid-b"));
                var revErr = lobbyB.await(m -> "error".equals(m.get("t")));
                assertThat(revErr.get("code")).isEqualTo("invite_pending");
            }

            // Declining clears the pending invite so a new invite works afterwards.
            lobbyB.send(Map.of("t", "invite_reply", "inviteId", id1, "accept", false));
            var reply = lobbyA.await(m -> "invite_reply".equals(m.get("t")));
            assertThat(reply.get("inviteId")).isEqualTo(id1);
            assertThat(reply.get("accept")).isEqualTo(false);

            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            var inv2 = lobbyB.await(m -> "invite".equals(m.get("t")));
            assertThat(inv2.get("inviteId")).isNotEqualTo(id1);
        }
    }

    @Test
    void inviteNeedsTheInviterInTheRoom() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        String kidUuid = UUID.randomUUID().toString();
        String code = createRoom(a);
        try (var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token())) {
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));

            // Unknown room code.
            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", "ZZZZZZ",
                    "kidUuid", kidUuid));
            assertThat(lobbyA.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("not_in_room");

            // Created room via REST, but inviter hasn't joined via /ws/room yet.
            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", kidUuid));
            assertThat(lobbyA.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("not_in_room");

            // Now join the room -> invite succeeds.
            try (var roomA = RoomSocket.open(port, code, a.token())) {
                roomA.join(kidUuid, "Na");
                roomA.awaitRoom(m -> true);

                lobbyA.send(Map.of(
                        "t", "invite",
                        "toFamilyId", b.familyId().toString(),
                        "roomCode", code,
                        "kidUuid", kidUuid));
                var inv = lobbyB.await(m -> "invite".equals(m.get("t")));
                lobbyB.send(Map.of("t", "invite_reply", "inviteId", inv.get("inviteId"), "accept", false));
                lobbyA.await(m -> "invite_reply".equals(m.get("t")));

                // After leaving the room -> invite refused again.
                roomA.send(Map.of("t", "leave"));
                roomA.awaitClosed();

                lobbyA.send(Map.of(
                        "t", "invite",
                        "toFamilyId", b.familyId().toString(),
                        "roomCode", code,
                        "kidUuid", kidUuid));
                assertThat(lobbyA.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("not_in_room");
            }

            // Once a room has started (no longer in lobby state), inviting into it is refused.
            String startedCode = createRoom(a);
            try (var rA = RoomSocket.open(port, startedCode, a.token());
                    var rB = RoomSocket.open(port, startedCode, b.token())) {
                rA.join(kidUuid, "Na");
                rA.awaitRoom(m -> true);
                rB.join("kid-b", "Bo");
                rA.awaitRoom(m -> players(m).size() == 2);
                rA.send(Map.of("t", "start"));
                rA.awaitRoom(m -> "countdown".equals(m.get("state")) || "racing".equals(m.get("state")));

                lobbyA.send(Map.of(
                        "t", "invite",
                        "toFamilyId", b.familyId().toString(),
                        "roomCode", startedCode,
                        "kidUuid", kidUuid));
                assertThat(lobbyA.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("not_in_room");
            }
        }
    }

    @Test
    void fourthConnectionIsClosed() throws Exception {
        FamilySession a = newFamily();
        var s1 = LobbySocket.open(port, a.token());
        var s2 = LobbySocket.open(port, a.token());
        var s3 = LobbySocket.open(port, a.token());
        try {
            s1.await(m -> "hello".equals(m.get("t")));
            s2.await(m -> "hello".equals(m.get("t")));
            s3.await(m -> "hello".equals(m.get("t")));

            try (var s4 = LobbySocket.open(port, a.token())) {
                var err = s4.await(m -> "error".equals(m.get("t")));
                assertThat(err.get("code")).isEqualTo("too_many");
                CloseStatus status = s4.awaitClosed();
                assertThat(status.getCode()).isEqualTo(CloseStatus.POLICY_VIOLATION.getCode());
            }

            // First 3 connections remain healthy.
            s1.send(Map.of("t", "ping"));
            s1.await(m -> "pong".equals(m.get("t")));
        } finally {
            s1.close();
            s2.close();
            s3.close();
        }
    }

    @Test
    void floodingClosesTheConnection() throws Exception {
        FamilySession a = newFamily();
        try (var sock = LobbySocket.open(port, a.token())) {
            sock.await(m -> "hello".equals(m.get("t")));

            for (int i = 0; i < 8; i++) {
                try {
                    sock.send(Map.of("t", "ping"));
                } catch (Exception ignored) {
                    break;
                }
            }

            var err = sock.await(m -> "error".equals(m.get("t")) && "too_many".equals(m.get("code")));
            assertThat(err.get("code")).isEqualTo("too_many");
            CloseStatus status = sock.awaitClosed();
            assertThat(status.getCode()).isEqualTo(CloseStatus.POLICY_VIOLATION.getCode());
        }
    }

    @Test
    void wsWithoutTokenIsRefused() {
        assertThatThrownBy(() -> LobbySocket.open(port, null)).isInstanceOf(Exception.class);
        assertThatThrownBy(() -> LobbySocket.open(port, "not-a-jwt")).isInstanceOf(Exception.class);
    }

    @Test
    void friendAddedAndRemovedArePushedAndTheCacheFollows() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();

        String code = createRoom(a);
        try (var roomA = RoomSocket.open(port, code, a.token());
                var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token())) {
            roomA.join("kid-a", "Na");
            roomA.awaitRoom(m -> true);
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));

            // Not friends yet -> invite refused.
            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", "kid-a"));
            assertThat(lobbyA.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("not_friends");

            // Redeem friend code -> both receive friend_added + immediate online presence.
            makeFriends(a, b);
            var addedA = lobbyA.await(m -> "friend_added".equals(m.get("t")));
            assertThat(addedA.get("familyId")).isEqualTo(b.familyId().toString());
            var presA = lobbyA.await(m -> "presence".equals(m.get("t")));
            assertThat(presA.get("familyId")).isEqualTo(b.familyId().toString());
            assertThat(presA.get("online")).isEqualTo(true);

            var addedB = lobbyB.await(m -> "friend_added".equals(m.get("t")));
            assertThat(addedB.get("familyId")).isEqualTo(a.familyId().toString());
            var presB = lobbyB.await(m -> "presence".equals(m.get("t")));
            assertThat(presB.get("familyId")).isEqualTo(a.familyId().toString());
            assertThat(presB.get("online")).isEqualTo(true);

            // Cache updated -> invite now works!
            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", "kid-a"));
            assertThat(lobbyB.await(m -> "invite".equals(m.get("t"))).get("roomCode")).isEqualTo(code);

            // Remove friend -> both receive friend_removed and pending invite is cancelled.
            removeFriend(a, b.familyId());
            assertThat(lobbyB.await(m -> "invite_cancelled".equals(m.get("t"))).get("inviteId")).isNotNull();
            assertThat(lobbyA.await(m -> "friend_removed".equals(m.get("t"))).get("familyId"))
                    .isEqualTo(b.familyId().toString());
            assertThat(lobbyB.await(m -> "friend_removed".equals(m.get("t"))).get("familyId"))
                    .isEqualTo(a.familyId().toString());

            // Subsequent disconnect/reconnect of B sends NO presence to A.
            lobbyB.close();
            lobbyA.assertNoMessage(m -> "presence".equals(m.get("t")), 200);

            try (var lobbyB2 = LobbySocket.open(port, b.token())) {
                lobbyB2.await(m -> "hello".equals(m.get("t")));
                lobbyA.assertNoMessage(m -> "presence".equals(m.get("t")), 200);
            }
        }
    }

    @Test
    void removingAFriendMidRaceDoesNotAffectTheRoom() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        String code = createRoom(a);
        try (var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token());
                var roomA = RoomSocket.open(port, code, a.token());
                var roomB = RoomSocket.open(port, code, b.token())) {
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));

            roomA.join("kid-a", "Na");
            roomA.awaitRoom(m -> true);
            roomB.join("kid-b", "Bo");
            roomA.awaitRoom(m -> players(m).size() == 2);

            roomA.send(Map.of("t", "start"));
            roomA.awaitRoom(m -> "racing".equals(m.get("state")));
            roomB.awaitRoom(m -> "racing".equals(m.get("state")));

            // Step partway, then A deletes B from friends mid-race.
            Thread.sleep(50);
            roomA.send(Map.of("t", "step", "n", 2));
            roomB.send(Map.of("t", "step", "n", 2));
            roomB.awaitRoom(m -> Integer.valueOf(2).equals(players(m).get(0).get("steps")));

            removeFriend(a, b.familyId());
            assertThat(lobbyA.await(m -> "friend_removed".equals(m.get("t"))).get("familyId"))
                    .isEqualTo(b.familyId().toString());
            assertThat(lobbyB.await(m -> "friend_removed".equals(m.get("t"))).get("familyId"))
                    .isEqualTo(a.familyId().toString());

            // Race continues and completes normally for both players.
            for (int n = 4; n <= 18; n += 2) {
                Thread.sleep(50);
                roomA.send(Map.of("t", "step", "n", n));
            }
            var aFinished = roomB.awaitRoom(m -> Integer.valueOf(1).equals(players(m).get(0).get("rank")));
            assertThat(players(aFinished).get(0).get("steps")).isEqualTo(18);

            for (int n = 4; n <= 18; n += 2) {
                Thread.sleep(50);
                roomB.send(Map.of("t", "step", "n", n));
            }
            var done = roomA.awaitRoom(m -> "done".equals(m.get("state")));
            assertThat(players(done)).extracting(p -> p.get("rank")).containsExactly(1, 2);

            assertThat(listFriends(a)).isEmpty();
        }
    }

    @Test
    void idleTimeoutClosesConnectionCleanly() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        try (var lobbyA = LobbySocket.open(port, a.token())) {
            lobbyA.await(m -> "hello".equals(m.get("t")));
            assertThat(lobbyRegistry.isOnline(a.familyId())).isTrue();

            // Ping refreshes lastActivityAt and returns pong.
            lobbyA.send(Map.of("t", "ping"));
            lobbyA.await(m -> "pong".equals(m.get("t")));

            // At +59s (< 60s idle timeout), connection stays open.
            lobbyHandler.sweepIdleSessions(Instant.now().plusSeconds(59));
            lobbyA.send(Map.of("t", "ping"));
            lobbyA.await(m -> "pong".equals(m.get("t")));
            assertThat(lobbyRegistry.isOnline(a.familyId())).isTrue();

            // At +61s (> 60s idle timeout), connection closes cleanly and family goes offline.
            lobbyHandler.sweepIdleSessions(Instant.now().plusSeconds(61));
            CloseStatus closed = lobbyA.awaitClosed();
            assertThat(closed.getCode()).isEqualTo(CloseStatus.NORMAL.getCode());

            assertThat(lobbyRegistry.isOnline(a.familyId())).isFalse();
            assertThat(listFriends(b).get(0).get("online")).isEqualTo(false);
        }
    }

    @Test
    void inviteReplyAcceptTrueNotifiesInviterAndNonRecipientIsIgnored() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        FamilySession c = newFamily();
        makeFriends(a, b);

        String code = createRoom(a);
        try (var roomA = RoomSocket.open(port, code, a.token());
                var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token());
                var lobbyC = LobbySocket.open(port, c.token())) {
            roomA.join("kid-a", "Na");
            roomA.awaitRoom(m -> true);
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));
            lobbyC.await(m -> "hello".equals(m.get("t")));

            lobbyA.send(Map.of(
                    "t", "invite",
                    "toFamilyId", b.familyId().toString(),
                    "roomCode", code,
                    "kidUuid", "kid-a"));
            String inviteId = (String) lobbyB.await(m -> "invite".equals(m.get("t"))).get("inviteId");

            // A third party trying to reply to someone else's invite is ignored.
            lobbyC.send(Map.of("t", "invite_reply", "inviteId", inviteId, "accept", false));
            lobbyA.assertNoMessage(m -> "invite_reply".equals(m.get("t")), 150);

            // Real recipient accepts -> inviter receives invite_reply(accept=true).
            lobbyB.send(Map.of("t", "invite_reply", "inviteId", inviteId, "accept", true));
            var reply = lobbyA.await(m -> "invite_reply".equals(m.get("t")));
            assertThat(reply.get("inviteId")).isEqualTo(inviteId);
            assertThat(reply.get("accept")).isEqualTo(true);
        }
    }

    @Test
    void oversizeAndMalformedMessagesReturnBadMessage() throws Exception {
        FamilySession a = newFamily();
        try (var sock = LobbySocket.open(port, a.token())) {
            sock.await(m -> "hello".equals(m.get("t")));

            // Oversize (> 2048 bytes)
            sock.send(Map.of("t", "ping", "pad", "x".repeat(2100)));
            assertThat(sock.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("bad_message");

            // Malformed JSON
            sock.sendRaw("{not-json");
            assertThat(sock.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("bad_message");

            // Non-object JSON
            sock.sendRaw("[1,2,3]");
            assertThat(sock.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("bad_message");

            // NUL / control char in kidUuid
            sock.send(Map.of(
                    "t", "invite",
                    "toFamilyId", UUID.randomUUID().toString(),
                    "roomCode", "ABCDEF",
                    "kidUuid", "kid\u0000bad"));
            assertThat(sock.await(m -> "error".equals(m.get("t"))).get("code")).isEqualTo("bad_message");
        }
    }

    @Test
    void showcaseReactionIsPushedToLobby() throws Exception {
        FamilySession owner = newFamily();
        FamilySession friend = newFamily();
        makeFriends(owner, friend);

        syncRecords(friend.token(), List.of(
                Map.of("key", "kid:f1", "payload", Map.of("nickname", "Bi", "createdAt", 1000L), "deleted", false),
                Map.of("key", "setting:f1:raceNickname", "payload", Map.of("value", "Siêu Bi"), "deleted", false)));

        var putRes = http.exchange(
                "/api/v1/showcase/kid-1",
                HttpMethod.PUT,
                new HttpEntity<>(Map.of("nickname", "Na"), bearer(owner.token())),
                Void.class);
        assertThat(putRes.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        try (var ownerLobby = LobbySocket.open(port, owner.token())) {
            ownerLobby.await(m -> "hello".equals(m.get("t")));

            var reactRes = http.exchange(
                    "/api/v1/showcase/" + owner.familyId() + "/kid-1/react",
                    HttpMethod.POST,
                    new HttpEntity<>(Map.of("kind", "star"), bearer(friend.token())),
                    Void.class);
            assertThat(reactRes.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

            var pushed = ownerLobby.await(m -> "reaction".equals(m.get("t")));
            assertThat(pushed.get("kidUuid")).isEqualTo("kid-1");
            assertThat(pushed.get("kind")).isEqualTo("star");
            assertThat(pushed.get("fromNickname")).isEqualTo("Siêu Bi");
        }
    }

    @Test
    void deleteAccountNotifiesFriendsAndClosesDeletedFamilyLobby() throws Exception {
        FamilySession a = newFamily();
        FamilySession b = newFamily();
        makeFriends(a, b);

        try (var lobbyA = LobbySocket.open(port, a.token());
                var lobbyB = LobbySocket.open(port, b.token())) {
            lobbyA.await(m -> "hello".equals(m.get("t")));
            lobbyB.await(m -> "hello".equals(m.get("t")));

            var delRes = http.exchange("/api/v1/account", HttpMethod.DELETE, new HttpEntity<>(bearer(a.token())), Void.class);
            assertThat(delRes.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

            CloseStatus closed = lobbyA.awaitClosed();
            assertThat(closed.getCode()).isEqualTo(CloseStatus.NORMAL.getCode());

            var removed = lobbyB.await(m -> "friend_removed".equals(m.get("t")));
            assertThat(removed.get("familyId")).isEqualTo(a.familyId().toString());
            assertThat(lobbyRegistry.isOnline(a.familyId())).isFalse();
        }
    }
}
