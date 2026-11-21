package com.ibme.funedu.server.room;

import static com.ibme.funedu.server.auth.TestIdTokens.*;
import static com.ibme.funedu.server.room.RoomSocket.players;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
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
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "funedu.rooms.countdown=200ms",
        "funedu.rooms.min-step-interval=50ms",
        "funedu.rooms.reconnect-grace=1s"})
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class RoomFlowTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    @Autowired
    TestRestTemplate http;

    @LocalServerPort
    int port;

    String family() {
        return (String) http.exchange("/api/v1/auth/google", HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(randomSubject()))), JSON)
                .getBody().get("accessToken");
    }

    ResponseEntity<Map<String, Object>> createRoom(String access) {
        var h = new HttpHeaders();
        if (access != null) h.setBearerAuth(access);
        return http.exchange("/api/v1/rooms", HttpMethod.POST, new HttpEntity<>(h), JSON);
    }

    String room(String access) {
        return (String) createRoom(access).getBody().get("code");
    }

    static String kid() {
        return UUID.randomUUID().toString();
    }

    @Test
    void creatingARoomNeedsSignInAndGivesAnEasyCode() {
        assertThat(createRoom(null).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        var res = createRoom(family());
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        // No 0/O or 1/I so a parent can read it out loud.
        assertThat((String) res.getBody().get("code")).matches("[A-HJ-NP-Z2-9]{6}");
        assertThat(res.getBody()).containsKey("expiresAt");
    }

    @Test
    void theSocketNeedsAValidAccessToken() {
        assertThatThrownBy(() -> RoomSocket.open(port, "AAAAAA", null)).isInstanceOf(Exception.class);
        assertThatThrownBy(() -> RoomSocket.open(port, "AAAAAA", "garbage")).isInstanceOf(Exception.class);
    }

    @Test
    void twoFamiliesRaceAndGetRanked() throws Exception {
        String a = family(), b = family();
        String code = room(a);
        try (var host = RoomSocket.open(port, code, a); var guest = RoomSocket.open(port, code, b)) {
            host.join(kid(), "Na");
            var lobby = host.awaitRoom(m -> "lobby".equals(m.get("state")));
            assertThat(lobby.get("host")).isEqualTo(lobby.get("you"));

            guest.join(kid(), "Bo");
            var both = guest.awaitRoom(m -> players(m).size() == 2);
            assertThat(players(both)).extracting(p -> p.get("name")).containsExactly("Na", "Bo");
            assertThat(both.get("host")).isNotEqualTo(both.get("you"));

            // Only the host starts.
            guest.send(Map.of("t", "start"));
            guest.await(m -> "error".equals(m.get("t")) && "not_host".equals(m.get("code")));
            host.send(Map.of("t", "start"));
            host.awaitRoom(m -> "countdown".equals(m.get("state")) && m.get("startsAt") != null);
            host.awaitRoom(m -> "racing".equals(m.get("state")));

            for (int n = 1; n <= 10; n++) {
                Thread.sleep(60);
                host.send(Map.of("t", "step", "n", n));
            }
            var hostDone = guest.awaitRoom(m -> players(m).get(0).get("rank") != null);
            assertThat(players(hostDone).get(0).get("rank")).isEqualTo(1);
            assertThat(players(hostDone).get(0).get("steps")).isEqualTo(10);

            for (int n = 1; n <= 10; n++) {
                Thread.sleep(60);
                guest.send(Map.of("t", "step", "n", n));
            }
            var done = host.awaitRoom(m -> "done".equals(m.get("state")));
            assertThat(players(done)).extracting(p -> p.get("rank")).containsExactly(1, 2);
        }
    }

    @Test
    void stepsMustBeOneOrTwoAtATimeAndNotTooFast() throws Exception {
        String a = family(), b = family();
        String code = room(a);
        try (var host = RoomSocket.open(port, code, a); var guest = RoomSocket.open(port, code, b)) {
            host.join(kid(), "Na");
            host.awaitRoom(m -> true);
            guest.join(kid(), "Bo");
            host.awaitRoom(m -> players(m).size() == 2);
            host.send(Map.of("t", "start"));
            host.awaitRoom(m -> "racing".equals(m.get("state")));

            host.send(Map.of("t", "step", "n", 3)); // jumps 3: ignored
            Thread.sleep(80);
            host.send(Map.of("t", "step", "n", 2)); // comet: +2 is fine
            host.send(Map.of("t", "step", "n", 3)); // too soon after the last: ignored
            Thread.sleep(80);
            host.send(Map.of("t", "step", "n", 3));
            var r = guest.awaitRoom(m -> ((Number) players(m).get(0).get("steps")).intValue() == 3);
            assertThat(players(r).get(0).get("steps")).isEqualTo(3);
        }
    }

    @Test
    void unknownFullOrStartedRoomsRefuseToJoin() throws Exception {
        String a = family();
        try (var s = RoomSocket.open(port, "ZZZZZZ", a)) {
            s.join(kid(), "Na");
            s.await(m -> "error".equals(m.get("t")) && "not_found".equals(m.get("code")));
        }

        String code = room(a);
        var sockets = new java.util.ArrayList<RoomSocket>();
        try {
            for (int i = 0; i < 4; i++) {
                var s = RoomSocket.open(port, code, i == 0 ? a : family());
                s.join(kid(), "K" + i);
                s.awaitRoom(m -> true);
                sockets.add(s);
            }
            try (var fifth = RoomSocket.open(port, code, family())) {
                fifth.join(kid(), "K5");
                fifth.await(m -> "error".equals(m.get("t")) && "room_full".equals(m.get("code")));
            }
            sockets.get(0).send(Map.of("t", "start"));
            sockets.get(0).awaitRoom(m -> "racing".equals(m.get("state")));
            // Kick one out to make space: a started room still refuses newcomers.
            sockets.get(3).send(Map.of("t", "leave"));
            try (var late = RoomSocket.open(port, code, family())) {
                late.join(kid(), "Late");
                late.await(m -> "error".equals(m.get("t")) && "started".equals(m.get("code")));
            }
        } finally {
            for (var s : sockets) s.close();
        }
    }

    @Test
    void aDroppedKidRejoinsWithTheirSteps() throws Exception {
        String a = family(), b = family();
        String code = room(a);
        String guestKid = kid();
        try (var host = RoomSocket.open(port, code, a)) {
            host.join(kid(), "Na");
            host.awaitRoom(m -> true);
            var guest = RoomSocket.open(port, code, b);
            guest.join(guestKid, "Bo");
            host.awaitRoom(m -> players(m).size() == 2);
            host.send(Map.of("t", "start"));
            guest.awaitRoom(m -> "racing".equals(m.get("state")));
            Thread.sleep(60);
            guest.send(Map.of("t", "step", "n", 1));
            host.awaitRoom(m -> ((Number) players(m).get(1).get("steps")).intValue() == 1);

            guest.close();
            host.awaitRoom(m -> Boolean.FALSE.equals(players(m).get(1).get("connected")));

            try (var back = RoomSocket.open(port, code, b)) {
                back.join(guestKid, "Bo");
                var again = back.awaitRoom(m -> "racing".equals(m.get("state")));
                assertThat(players(again).get(1).get("steps")).isEqualTo(1);
                assertThat(players(again).get(1).get("connected")).isEqualTo(true);
            }
        }
    }

    @Test
    void stickersAreRelayedOnlyFromTheFixedSet() throws Exception {
        String a = family(), b = family();
        String code = room(a);
        try (var host = RoomSocket.open(port, code, a); var guest = RoomSocket.open(port, code, b)) {
            host.join(kid(), "Na");
            host.awaitRoom(m -> true);
            guest.join(kid(), "Bo");
            host.awaitRoom(m -> players(m).size() == 2);

            guest.send(Map.of("t", "sticker", "id", "free text here"));
            guest.send(Map.of("t", "sticker", "id", "cheer"));
            var s = host.await(m -> "sticker".equals(m.get("t")));
            assertThat(s.get("id")).isEqualTo("cheer");
            assertThat(s.get("from")).isNotNull();
        }
    }

    @Test
    void namesAreTrimmedAndBadAvatarsReplaced() throws Exception {
        String a = family();
        String code = room(a);
        try (var host = RoomSocket.open(port, code, a)) {
            host.send(Map.of("t", "join", "kid", kid(), "name", "  Một cái tên dài quá trời luôn đó \n",
                    "avatar", "http://evil.example/x.png", "rocket", "<b>"));
            var r = host.awaitRoom(m -> true);
            var p = players(r).get(0);
            assertThat((String) p.get("name")).hasSizeLessThanOrEqualTo(16).doesNotContain("\n");
            assertThat(p.get("avatar")).isEqualTo("");
            assertThat(p.get("rocket")).isEqualTo("rocket_orange");
        }
    }

    @Test
    void theHostLeavingTheLobbyHandsTheRoomOver() throws Exception {
        String a = family(), b = family();
        String code = room(a);
        try (var host = RoomSocket.open(port, code, a); var guest = RoomSocket.open(port, code, b)) {
            host.join(kid(), "Na");
            host.awaitRoom(m -> true);
            guest.join(kid(), "Bo");
            guest.awaitRoom(m -> players(m).size() == 2);
            host.send(Map.of("t", "leave"));
            var r = guest.awaitRoom(m -> players(m).size() == 1);
            assertThat(r.get("host")).isEqualTo(r.get("you"));
        }
    }
}
