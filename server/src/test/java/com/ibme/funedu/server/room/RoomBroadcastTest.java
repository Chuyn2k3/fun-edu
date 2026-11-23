package com.ibme.funedu.server.room;

import static com.ibme.funedu.server.auth.TestIdTokens.googleToken;
import static com.ibme.funedu.server.auth.TestIdTokens.randomSubject;
import static com.ibme.funedu.server.room.RoomSocket.players;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.Principal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketExtension;
import org.springframework.web.socket.WebSocketMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "funedu.rooms.countdown=150ms",
        "funedu.rooms.min-step-interval=10ms",
        "funedu.rooms.reconnect-grace=1s"})
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class RoomBroadcastTest {

    static final ParameterizedTypeReference<Map<String, Object>> JSON = new ParameterizedTypeReference<>() {};

    @Autowired
    TestRestTemplate http;

    @LocalServerPort
    int port;

    private String family() {
        return (String) http.exchange("/api/v1/auth/google", HttpMethod.POST,
                new HttpEntity<>(Map.of("idToken", googleToken(randomSubject()),
                        "deviceId", UUID.randomUUID().toString())), JSON)
                .getBody().get("accessToken");
    }

    private String createRoom(String access) {
        var h = new HttpHeaders();
        h.setBearerAuth(access);
        return (String) http.exchange("/api/v1/rooms", HttpMethod.POST, new HttpEntity<>(h), JSON)
                .getBody().get("code");
    }

    private static ObjectMapper nonNullMapper() {
        return new ObjectMapper().setSerializationInclusion(JsonInclude.Include.NON_NULL);
    }

    private static RoomProperties defaultProps() {
        return new RoomProperties(
                Duration.ofMillis(150),
                Duration.ofMinutes(30),
                Duration.ofSeconds(20),
                Duration.ofMinutes(10),
                Duration.ofMinutes(10),
                Duration.ofMillis(10),
                4,
                20,
                10);
    }

    private static String writeJson(ObjectMapper mapper, Object v) {
        try {
            return mapper.writeValueAsString(v);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Test
    void snapshotsAreCoalesced() throws Exception {
        // Unit check: step() sets dirty and returns no sends; flush() produces one shared snapshot.
        ObjectMapper mapper = nonNullMapper();
        Instant t0 = Instant.parse("2026-11-23T10:00:00Z");
        UUID famA = UUID.randomUUID(), famB = UUID.randomUUID();
        Room room = new Room("COALES", famA, t0, defaultProps(), v -> writeJson(mapper, v));
        var s1 = new RecordingSession("s1");
        var s2 = new RecordingSession("s2");
        room.join(s1, famA, "k1", "Na", "", "rocket_orange", t0);
        room.join(s2, famB, "k2", "Bo", "", "rocket_blue", t0);
        room.start(s1, t0);
        room.tick(t0.plusMillis(200));

        assertThat(room.step(s1, 1, t0.plusMillis(220)).sends()).isEmpty();
        assertThat(room.step(s2, 1, t0.plusMillis(230)).sends()).isEmpty();
        assertThat(room.step(s1, 3, t0.plusMillis(250)).sends()).isEmpty();
        assertThat(room.step(s2, 2, t0.plusMillis(260)).sends()).isEmpty();
        assertThat(room.step(s1, 4, t0.plusMillis(280)).sends()).isEmpty();

        Room.Outbox flushed = room.flush(t0.plusMillis(300));
        assertThat(flushed.sends()).hasSize(2);
        // Same shared payload instance/content sent to both sessions.
        assertThat(flushed.sends().get(0).text()).isEqualTo(flushed.sends().get(1).text());
        assertThat(room.flush(t0.plusMillis(400)).sends()).isEmpty();

        // Integration check: 5 steps in 100ms from 2 players -> <= 2 snapshots in 200ms.
        String a = family(), b = family(), c = family();
        String code = createRoom(a);
        try (var p1 = RoomSocket.open(port, code, a);
                var p2 = RoomSocket.open(port, code, b);
                var listener = RoomSocket.open(port, code, c)) {
            p1.join("k1", "Na");
            p1.awaitRoom(m -> true);
            p2.join("k2", "Bo");
            p2.awaitRoom(m -> players(m).size() == 2);
            listener.join("k3", "Bi");
            listener.awaitRoom(m -> players(m).size() == 3);

            p1.send(Map.of("t", "start"));
            listener.awaitRoom(m -> "racing".equals(m.get("state")));
            listener.inbox.clear();

            // Send 5 steps across 75ms right after the racing tick.
            long startMs = System.currentTimeMillis();
            p1.send(Map.of("t", "step", "n", 1));
            Thread.sleep(18);
            p2.send(Map.of("t", "step", "n", 1));
            Thread.sleep(18);
            p1.send(Map.of("t", "step", "n", 2));
            Thread.sleep(18);
            p2.send(Map.of("t", "step", "n", 2));
            Thread.sleep(18);
            p1.send(Map.of("t", "step", "n", 3));

            List<Map<String, Object>> snapshots = new ArrayList<>();
            long deadline = startMs + 190;
            while (System.currentTimeMillis() < deadline) {
                Map<String, Object> m = listener.inbox.poll(15, TimeUnit.MILLISECONDS);
                if (m != null && "room".equals(m.get("t"))) {
                    snapshots.add(m);
                }
            }
            assertThat(snapshots).isNotEmpty();
            assertThat(snapshots.size()).isLessThanOrEqualTo(2);
            Map<String, Object> last = snapshots.get(snapshots.size() - 1);
            assertThat(players(last).get(0).get("steps")).isEqualTo(3);
            assertThat(players(last).get(1).get("steps")).isEqualTo(2);
        }
    }

    @Test
    void stateChangesAreSentAtOnce() throws Exception {
        // Unit check: start() returns countdown snapshot synchronously in Outbox.
        ObjectMapper mapper = nonNullMapper();
        Instant t0 = Instant.parse("2026-11-23T10:00:00Z");
        UUID famA = UUID.randomUUID(), famB = UUID.randomUUID();
        Room room = new Room("IMMED1", famA, t0, defaultProps(), v -> writeJson(mapper, v));
        var s1 = new RecordingSession("s1");
        var s2 = new RecordingSession("s2");
        room.join(s1, famA, "k1", "Na", "", "rocket_orange", t0);
        room.join(s2, famB, "k2", "Bo", "", "rocket_blue", t0);
        Room.Outbox startOutbox = room.start(s1, t0);
        assertThat(startOutbox.sends()).hasSize(2);
        assertThat(startOutbox.sends().get(0).text()).contains("\"state\":\"countdown\"");

        // Integration check: start -> countdown arrives immediately (< 50ms, without waiting for 100ms tick).
        String a = family(), b = family();
        String code = createRoom(a);
        try (var host = RoomSocket.open(port, code, a); var guest = RoomSocket.open(port, code, b)) {
            host.join("k1", "Na");
            host.awaitRoom(m -> true);
            guest.join("k2", "Bo");
            host.awaitRoom(m -> players(m).size() == 2);
            guest.inbox.clear();

            long tStart = System.nanoTime();
            host.send(Map.of("t", "start"));
            var countdown = guest.awaitRoom(m -> "countdown".equals(m.get("state")));
            long elapsedMs = (System.nanoTime() - tStart) / 1_000_000L;
            assertThat(countdown.get("startsAt")).isNotNull();
            assertThat(elapsedMs).isLessThan(50L);
        }
    }

    @Test
    void snapshotIsUnder600BytesFor4Players() {
        ObjectMapper mapper = nonNullMapper();
        Instant t0 = Instant.parse("2026-11-23T10:00:00Z");
        UUID fam = UUID.randomUUID();
        Room room = new Room("ABC234", fam, t0, defaultProps(), v -> writeJson(mapper, v));
        String[] names = {"Nguyễn An", "Trần Bình", "Lê Chi", "Phạm Dũng"};
        RecordingSession[] sessions = new RecordingSession[4];
        for (int i = 0; i < 4; i++) {
            sessions[i] = new RecordingSession("s" + i);
            room.join(sessions[i], UUID.randomUUID(), "kid-" + i, names[i],
                    "assets/images/avatars/penguin.png", "rocket_orange", t0);
        }
        room.start(sessions[0], t0);
        room.tick(t0.plusMillis(200));

        Instant stepTime = t0.plusMillis(220);
        Room.Outbox doneOut = Room.Outbox.EMPTY;
        for (int step = 2; step <= Room.RACE_LENGTH; step += 2) {
            stepTime = stepTime.plusMillis(20);
            for (int i = 0; i < 4; i++) {
                doneOut = room.step(sessions[i], step, stepTime);
            }
        }
        assertThat(doneOut.sends()).hasSize(4);
        String doneJson = doneOut.sends().get(0).text();
        assertThat(doneJson.getBytes(StandardCharsets.UTF_8).length).isLessThanOrEqualTo(600);

        // Check racing snapshot size (players 0 & 1 finished, players 2 & 3 at step 16).
        Room doneCheck = new Room("XYZ789", fam, t0, defaultProps(), v -> writeJson(mapper, v));
        RecordingSession[] rs = new RecordingSession[4];
        for (int i = 0; i < 4; i++) {
            rs[i] = new RecordingSession("r" + i);
            doneCheck.join(rs[i], UUID.randomUUID(), "kid-" + i, names[i],
                    "assets/images/avatars/penguin.png", "rocket_orange", t0);
        }
        doneCheck.start(rs[0], t0);
        doneCheck.tick(t0.plusMillis(200));
        Instant st = t0.plusMillis(220);
        for (int step = 2; step <= 16; step += 2) {
            st = st.plusMillis(20);
            for (int i = 0; i < 4; i++) {
                doneCheck.step(rs[i], step, st);
            }
        }
        // Player 0 and 1 finished (ranks 1, 2), players 2 and 3 at step 16.
        st = st.plusMillis(20);
        doneCheck.step(rs[0], 18, st);
        doneCheck.step(rs[1], 18, st);
        Room.Outbox racingOut = doneCheck.flush(st.plusMillis(10));
        assertThat(racingOut.sends()).hasSize(4);
        String racingJson = racingOut.sends().get(0).text();
        assertThat(racingJson.getBytes(StandardCharsets.UTF_8).length).isLessThanOrEqualTo(600);
    }

    @Test
    void slowClientDoesNotBlockTheRoom() throws Exception {
        ObjectMapper mapper = nonNullMapper();
        Instant t0 = Instant.parse("2026-11-23T10:00:00Z");
        UUID fam = UUID.randomUUID();
        Room room = new Room("SLOW01", fam, t0, defaultProps(), v -> writeJson(mapper, v));

        CountDownLatch releaseSlow = new CountDownLatch(1);
        CountDownLatch slowStarted = new CountDownLatch(1);
        CountDownLatch slowClosed = new CountDownLatch(1);
        RecordingSession slowRaw = new RecordingSession("slow") {
            @Override
            public void sendMessage(WebSocketMessage<?> message) throws IOException {
                slowStarted.countDown();
                try {
                    releaseSlow.await(5, TimeUnit.SECONDS);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }

            @Override
            public void close(CloseStatus status) {
                super.close(status);
                slowClosed.countDown();
            }
        };
        // Small buffer/time limit so the decorator closes the blocked client promptly.
        WebSocketSession slow = new ConcurrentWebSocketSessionDecorator(slowRaw, 80, 512);
        RecordingSession fast1 = new RecordingSession("fast1");
        RecordingSession fast2 = new RecordingSession("fast2");
        RecordingSession fast3 = new RecordingSession("fast3");

        try {
            Room.deliver(room.join(slow, UUID.randomUUID(), "k0", "Slow", "assets/images/avatars/fox.png", "rocket_orange", t0).outbox());
            Room.deliver(room.join(fast1, UUID.randomUUID(), "k1", "Fast1", "assets/images/avatars/fox.png", "rocket_blue", t0).outbox());
            Room.deliver(room.join(fast2, UUID.randomUUID(), "k2", "Fast2", "assets/images/avatars/fox.png", "rocket_green", t0).outbox());
            Room.deliver(room.join(fast3, UUID.randomUUID(), "k3", "Fast3", "assets/images/avatars/fox.png", "rocket_purple", t0).outbox());

            assertThat(slowStarted.await(1, TimeUnit.SECONDS)).isTrue();
            Room.deliver(room.start(slow, t0));
            Room.deliver(room.tick(t0.plusMillis(200)).outbox());

            fast1.received.clear();
            fast2.received.clear();
            fast3.received.clear();

            // Trigger multiple step + flush cycles while slow client is completely blocked.
            Instant now = t0.plusMillis(220);
            for (int step = 2; step <= 10; step += 2) {
                now = now.plusMillis(25);
                room.step(fast1, step, now);
                long callStart = System.nanoTime();
                Room.deliver(room.flush(now));
                long callMs = (System.nanoTime() - callStart) / 1_000_000L;
                assertThat(callMs).isLessThan(30L);
                Thread.sleep(25);
            }

            // All 3 fast clients received the latest step (10) on time despite blocked slow client.
            for (RecordingSession fast : List.of(fast1, fast2, fast3)) {
                String msg = awaitText(fast, m -> m.contains("\"steps\":10"));
                assertThat(msg).contains("\"steps\":10");
            }

            // Slow client was closed by ConcurrentWebSocketSessionDecorator due to time/buffer limit.
            assertThat(slowClosed.await(1, TimeUnit.SECONDS)).isTrue();
            assertThat(slowRaw.isOpen()).isFalse();
        } finally {
            releaseSlow.countDown();
        }
    }

    @Test
    void youArrivesInJoinedMessage() throws Exception {
        String a = family(), b = family();
        String code = createRoom(a);
        try (var host = RoomSocket.open(port, code, a); var guest = RoomSocket.open(port, code, b)) {
            host.join("k1", "Na");
            var hostJoined = host.await(m -> "joined".equals(m.get("t")));
            assertThat(hostJoined.get("you")).isEqualTo("p1");
            var hostRoom = host.awaitRoom(m -> true);
            assertThat(hostRoom).doesNotContainKey("you");

            guest.join("k2", "Bo");
            var guestJoined = guest.await(m -> "joined".equals(m.get("t")));
            assertThat(guestJoined.get("you")).isEqualTo("p2");
            var guestRoom = guest.awaitRoom(m -> players(m).size() == 2);
            assertThat(guestRoom).doesNotContainKey("you");
        }
    }

    private static String awaitText(RecordingSession session, java.util.function.Predicate<String> match)
            throws InterruptedException {
        long deadline = System.currentTimeMillis() + 1000;
        while (System.currentTimeMillis() < deadline) {
            String s = session.received.poll(50, TimeUnit.MILLISECONDS);
            if (s != null && match.test(s)) return s;
        }
        throw new AssertionError("No matching message received");
    }

    private static class RecordingSession implements WebSocketSession {
        private final String id;
        private final AtomicBoolean open = new AtomicBoolean(true);
        private final Map<String, Object> attrs = new ConcurrentHashMap<>();
        final BlockingQueue<String> received = new LinkedBlockingQueue<>();

        RecordingSession(String id) {
            this.id = id;
        }

        @Override public String getId() { return id; }
        @Override public URI getUri() { return null; }
        @Override public HttpHeaders getHandshakeHeaders() { return new HttpHeaders(); }
        @Override public Map<String, Object> getAttributes() { return attrs; }
        @Override public Principal getPrincipal() { return null; }
        @Override public InetSocketAddress getLocalAddress() { return null; }
        @Override public InetSocketAddress getRemoteAddress() { return null; }
        @Override public String getAcceptedProtocol() { return null; }
        @Override public void setTextMessageSizeLimit(int messageSizeLimit) {}
        @Override public int getTextMessageSizeLimit() { return 64 * 1024; }
        @Override public void setBinaryMessageSizeLimit(int messageSizeLimit) {}
        @Override public int getBinaryMessageSizeLimit() { return 64 * 1024; }
        @Override public List<WebSocketExtension> getExtensions() { return List.of(); }

        @Override
        public void sendMessage(WebSocketMessage<?> message) throws IOException {
            if (!open.get()) throw new IOException("closed");
            received.add(message.getPayload().toString());
        }

        @Override public boolean isOpen() { return open.get(); }
        @Override public void close() { open.set(false); }
        @Override public void close(CloseStatus status) { open.set(false); }
    }
}
