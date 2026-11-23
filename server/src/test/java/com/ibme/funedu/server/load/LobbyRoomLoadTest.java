package com.ibme.funedu.server.load;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.TestDatabase;
import com.ibme.funedu.server.auth.TestIdTokens;
import com.ibme.funedu.server.auth.TokenService;
import com.ibme.funedu.server.friends.FriendService;
import com.ibme.funedu.server.lobby.LobbyRegistry;
import java.io.BufferedReader;
import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryUsage;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.sql.PreparedStatement;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLongArray;
import java.util.concurrent.locks.ReentrantLock;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

/**
 * Sustained load &amp; latency test against real PostgreSQL matching Spec §9.2 / Task 16:
 * <ul>
 *   <li>2,000 concurrent {@code /ws/lobby} connections (500 families × 4 devices, 10 friends each)</li>
 *   <li>300 concurrent 4-player rooms (1,200 {@code /ws/room} connections) racing 18 steps + stickers</li>
 *   <li>1 stalled raw-socket client in Room 0 (small SO_RCVBUF, unread InputStream) that triggers
 *       server {@code ConcurrentWebSocketSessionDecorator} backpressure &amp; disconnect while fast
 *       peers and other rooms remain within latency budgets</li>
 *   <li>Concurrent {@code GET /api/v1/friends} REST calls under load</li>
 * </ul>
 */
@Tag("load")
@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
            "funedu.rooms.countdown=200ms",
            "funedu.rooms.min-step-interval=10ms",
            "funedu.rooms.reconnect-grace=15s",
            "funedu.rooms.max-race-time=5m",
            "funedu.lobby.max-connections-per-family=4",
            "funedu.lobby.idle-timeout=180s"
        })
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class LobbyRoomLoadTest {

    // Spec §9.2 defaults: 2,000 /ws/lobby (500 families x 4) + 300 rooms, 60 s. Override via env
    // LOAD_LOBBY_FAMILIES, LOAD_ROOMS, LOAD_TEST_SECONDS (rooms must be <= 1.25 x families).
    private static final int LOBBY_FAMILIES = Math.max(8, envInt("LOAD_LOBBY_FAMILIES", 500));
    private static final int LOBBY_CONNS_PER_FAMILY = 4;
    private static final int TOTAL_LOBBY_SESSIONS = LOBBY_FAMILIES * LOBBY_CONNS_PER_FAMILY;
    private static final int ROOM_COUNT = Math.max(2, Math.min(envInt("LOAD_ROOMS", 300), LOBBY_FAMILIES * 5 / 4));
    private static final int PLAYERS_PER_ROOM = 4;
    private static final int RACE_STEPS = 18;
    private static final long STEP_INTERVAL_MS = 200L;
    private static final long SLOW_ROOM_PEER_STAGGER_MS = 130L;
    private static final int FRIENDS_REST_CONCURRENCY = 4;
    private static final int HANDSHAKE_CONCURRENCY = 64;
    private static final int LOAD_SECONDS = readLoadSeconds();

    private static final double MAX_ROOM_BROADCAST_P99_MS = 150.0;
    private static final double MAX_LOBBY_INVITE_P99_MS = 300.0;
    private static final double MAX_GET_FRIENDS_P99_MS = 100.0;

    private static final String START_JSON = "{\"t\":\"start\"}";
    private static final String AGAIN_JSON = "{\"t\":\"again\"}";
    private static final String CHEER_JSON = "{\"t\":\"sticker\",\"id\":\"cheer\"}";
    private static final String[] STEP_JSON = new String[RACE_STEPS + 1];

    static {
        for (int i = 1; i <= RACE_STEPS; i++) {
            STEP_JSON[i] = "{\"t\":\"step\",\"n\":" + i + "}";
        }
    }

    @LocalServerPort
    int port;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    TokenService tokens;

    @Autowired
    ObjectMapper json;

    @Autowired
    LobbyRegistry lobbyRegistry;

    private record SeedFamily(UUID familyId, UUID parentId, String kidUuid, String name, String token) {}

    private static int readLoadSeconds() {
        return Math.max(5, envInt("LOAD_TEST_SECONDS", 60));
    }

    private static int envInt(String name, int dflt) {
        String raw = System.getenv(name);
        if (raw == null || raw.isBlank()) raw = System.getProperty(name);
        if (raw == null || raw.isBlank()) return dflt;
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException ignored) {
            return dflt;
        }
    }

    @Test
    void twoThousandLobbyAndThreeHundredRoomsStayWithinLatencyBudget() throws Exception {
        final List<SeedFamily> families = new ArrayList<>(LOBBY_FAMILIES);
        final List<LobbySession> lobbySessions = new ArrayList<>(TOTAL_LOBBY_SESSIONS);
        final List<RoomCohort> rooms = new ArrayList<>(ROOM_COUNT);

        int poolSize = 8;
        List<HttpClient> wsClients = new ArrayList<>(poolSize);
        ExecutorService wsExec = Executors.newVirtualThreadPerTaskExecutor();
        for (int i = 0; i < poolSize; i++) {
            wsClients.add(HttpClient.newBuilder()
                    .executor(wsExec)
                    .connectTimeout(Duration.ofSeconds(20))
                    .build());
        }
        HttpClient restClient = HttpClient.newBuilder()
                .executor(wsExec)
                .connectTimeout(Duration.ofSeconds(15))
                .build();

        int maxRoundsEstimate = Math.max(4, (LOAD_SECONDS / 3) + 2);
        LongSamples roomBroadcastAll =
                new LongSamples(ROOM_COUNT * PLAYERS_PER_ROOM * PLAYERS_PER_ROOM * RACE_STEPS * maxRoundsEstimate);
        LongSamples roomBroadcastSlowRoomFastPeers =
                new LongSamples((PLAYERS_PER_ROOM - 1) * PLAYERS_PER_ROOM * RACE_STEPS * (LOAD_SECONDS / 5 + 40));
        LongSamples lobbyInviteSamples = new LongSamples(ROOM_COUNT * maxRoundsEstimate * 2);
        LongSamples getFriendsSamples = new LongSamples(Math.max(500, LOAD_SECONDS * 120));

        ConcurrentHashMap<String, Long> inviteSentNanos = new ConcurrentHashMap<>();
        AtomicInteger unexpectedErrors = new AtomicInteger();
        AtomicInteger stickersReceived = new AtomicInteger();
        AtomicInteger invitesReceived = new AtomicInteger();
        AtomicInteger getFriendsNon200 = new AtomicInteger();
        AtomicInteger roundsCompleted = new AtomicInteger();
        AtomicInteger roundsSlowRoom = new AtomicInteger();

        long testStartNanos = System.nanoTime();
        try {
            seedFamilies(families);

            // 1. Connect 2,000 /ws/lobby sessions (500 families × 4 devices) and await "hello".
            openLobbySessions(
                    families,
                    wsClients,
                    wsExec,
                    lobbySessions,
                    inviteSentNanos,
                    lobbyInviteSamples,
                    invitesReceived,
                    unexpectedErrors);
            for (LobbySession ls : lobbySessions) {
                assertThat(ls.helloLatch.await(30, TimeUnit.SECONDS))
                        .as("lobby hello for family %s device %d", ls.family.familyId(), ls.deviceIdx)
                        .isTrue();
            }

            // 2. Create 300 rooms via REST and connect 1,200 /ws/room sessions
            // (Room 0 peer 3 = raw Socket with 1 KB SO_RCVBUF that stops reading).
            List<String> roomCodes = createRooms(families, restClient);
            openRooms(
                    families,
                    roomCodes,
                    wsClients,
                    wsExec,
                    rooms,
                    roomBroadcastAll,
                    roomBroadcastSlowRoomFastPeers,
                    stickersReceived,
                    unexpectedErrors);

            // Warm up REST GET /api/v1/friends path before timed measurements.
            for (int i = 0; i < 10; i++) {
                var warm = restGetFriends(restClient, families.get(i).token());
                assertThat(warm.statusCode()).isEqualTo(200);
            }

            // 3. Initial wave of lobby invites while all 300 rooms are in lobby state.
            CountDownLatch initialInvitesLatch = new CountDownLatch(ROOM_COUNT);
            sendInviteWave(rooms, lobbySessions, inviteSentNanos, initialInvitesLatch, unexpectedErrors);
            assertThat(initialInvitesLatch.await(20, TimeUnit.SECONDS))
                    .as("initial invite wave delivered while rooms in lobby")
                    .isTrue();

            long loadDeadlineNanos = System.nanoTime() + TimeUnit.SECONDS.toNanos(LOAD_SECONDS);

            // 4. Room 0: prove real slow-client backpressure & server close without stalling fast peers.
            RoomCohort slowRoom = rooms.get(0);
            CompletableFuture<Void> slowRoomFuture =
                    CompletableFuture.runAsync(
                            () -> runSlowRoom(slowRoom, unexpectedErrors, roundsSlowRoom, loadDeadlineNanos), wsExec);

            // 5. Rooms 1..299: race full 18-step rounds continuously for LOAD_SECONDS.
            List<CompletableFuture<Void>> fastRoomFutures = new ArrayList<>(ROOM_COUNT - 1);
            for (int r = 1; r < ROOM_COUNT; r++) {
                RoomCohort cohort = rooms.get(r);
                fastRoomFutures.add(CompletableFuture.runAsync(
                        () -> runFastRoomForDuration(
                                cohort,
                                lobbySessions,
                                inviteSentNanos,
                                unexpectedErrors,
                                roundsCompleted,
                                loadDeadlineNanos),
                        wsExec));
            }

            // 6. Concurrent REST GET /api/v1/friends calls throughout the active load window.
            CompletableFuture<Void> restLoadFuture = runGetFriendsLoad(
                    restClient,
                    wsExec,
                    families,
                    getFriendsSamples,
                    getFriendsNon200,
                    unexpectedErrors,
                    loadDeadlineNanos);

            CompletableFuture.allOf(fastRoomFutures.toArray(CompletableFuture[]::new))
                    .get(LOAD_SECONDS + 45L, TimeUnit.SECONDS);
            slowRoomFuture.get(LOAD_SECONDS + 90L, TimeUnit.SECONDS);
            restLoadFuture.get(15, TimeUnit.SECONDS);

            // Wait briefly for any trailing in-flight invites to arrive.
            long inviteDeadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(2);
            while (!inviteSentNanos.isEmpty() && System.nanoTime() < inviteDeadline) {
                Thread.sleep(20);
            }

            long elapsedMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - testStartNanos);
            MemoryUsage heap = ManagementFactory.getMemoryMXBean().getHeapMemoryUsage();
            long rssKb = readProcessRssKb();
            RawStalledRoomSocket stalled = slowRoom.peers[PLAYERS_PER_ROOM - 1].rawStalledSocket;
            int stalledUnreadBytes = stalled.unreadBytesAvailable();
            boolean stalledSeenDisconnectedByRoom = slowRoom.stalledPeerDisconnectedObserved.getCount() == 0;
            boolean stalledSocketClosedByServer = stalled.drainUntilClosed(15_000);
            boolean stalledClosedByServer = stalledSeenDisconnectedByRoom && stalledSocketClosedByServer;
            long stalledBytesSent = stalled.bytesDrained;

            LatencyStats roomStats = roomBroadcastAll.stats();
            LatencyStats slowRoomStats = roomBroadcastSlowRoomFastPeers.stats();
            LatencyStats inviteStats = lobbyInviteSamples.stats();
            LatencyStats friendsStats = getFriendsSamples.stats();

            printSummary(
                    elapsedMs,
                    rooms,
                    lobbySessions,
                    roundsCompleted.get(),
                    roomStats,
                    slowRoomStats,
                    inviteStats,
                    friendsStats,
                    stickersReceived.get(),
                    invitesReceived.get(),
                    unexpectedErrors.get(),
                    getFriendsNon200.get(),
                    stalledUnreadBytes,
                    stalledClosedByServer,
                    roundsSlowRoom.get(),
                    heap,
                    rssKb);

            assertThat(unexpectedErrors.get()).as("unexpected WebSocket/HTTP errors").isZero();
            assertThat(getFriendsNon200.get()).as("non-200 GET /api/v1/friends responses").isZero();
            assertThat(stalledSeenDisconnectedByRoom)
                    .as("room 0 snapshot reported the stalled peer disconnected (server limited/closed it)")
                    .isTrue();
            assertThat(stalledSocketClosedByServer)
                    .as("stalled raw socket reached EOF/reset after server closed it (unread=%d, drained=%d)",
                            stalledUnreadBytes, stalledBytesSent)
                    .isTrue();
            assertThat(roomStats.count())
                    .as("room broadcast samples")
                    .isGreaterThanOrEqualTo((ROOM_COUNT - 1) * PLAYERS_PER_ROOM * RACE_STEPS);
            assertThat(slowRoomStats.count()).isGreaterThanOrEqualTo(3 * RACE_STEPS);
            assertThat(roundsSlowRoom.get()).as("room 0 rounds with stalled client").isGreaterThanOrEqualTo(1);
            assertThat(inviteStats.count()).isGreaterThanOrEqualTo(ROOM_COUNT);
            assertThat(friendsStats.count()).isGreaterThanOrEqualTo(100);

            assertThat(roomStats.p99Ms()).as("roomBroadcast p99 ms").isLessThanOrEqualTo(MAX_ROOM_BROADCAST_P99_MS);
            assertThat(slowRoomStats.p99Ms())
                    .as("room 0 fast peers (with stalled peer) p99 ms")
                    .isLessThanOrEqualTo(MAX_ROOM_BROADCAST_P99_MS);
            assertThat(inviteStats.p99Ms()).as("lobbyInvite p99 ms").isLessThanOrEqualTo(MAX_LOBBY_INVITE_P99_MS);
            assertThat(friendsStats.p99Ms()).as("getFriends p99 ms").isLessThanOrEqualTo(MAX_GET_FRIENDS_P99_MS);
        } finally {
            try {
                teardownSockets(rooms, lobbySessions, restClient, wsClients, wsExec);
            } finally {
                try {
                    cleanupFamilies(families);
                } catch (RuntimeException e) {
                    System.err.println("cleanupFamilies failed: " + e);
                }
            }
        }
    }

    private static void teardownSockets(
            List<RoomCohort> rooms,
            List<LobbySession> lobbySessions,
            HttpClient restClient,
            List<HttpClient> wsClients,
            ExecutorService wsExec) {
        try {
            closeRooms(rooms);
        } catch (RuntimeException e) {
            System.err.println("closeRooms failed: " + e);
        }
        try {
            closeLobbies(lobbySessions);
        } catch (RuntimeException e) {
            System.err.println("closeLobbies failed: " + e);
        }
        try {
            restClient.shutdownNow();
        } catch (RuntimeException ignored) {
            // best effort
        }
        for (HttpClient c : wsClients) {
            try {
                c.shutdownNow();
            } catch (RuntimeException ignored) {
                // best effort
            }
        }
        wsExec.shutdownNow();
    }

    private void seedFamilies(List<SeedFamily> out) throws Exception {
        jdbc.update("DELETE FROM families WHERE id IN (SELECT family_id FROM parent_accounts WHERE subject LIKE 'load-%')");
        for (int i = 0; i < LOBBY_FAMILIES; i++) {
            UUID famId = UUID.randomUUID();
            UUID parentId = UUID.randomUUID();
            UUID deviceId = UUID.randomUUID();
            String kidUuid = UUID.randomUUID().toString();
            String name = "Be" + i;
            String token = tokens.accessToken(parentId, famId, deviceId);
            out.add(new SeedFamily(famId, parentId, kidUuid, name, token));
        }

        jdbc.batchUpdate("INSERT INTO families (id) VALUES (?)", out, 250, (PreparedStatement ps, SeedFamily f) -> {
            ps.setObject(1, f.familyId());
        });

        jdbc.batchUpdate(
                "INSERT INTO parent_accounts (id, family_id, provider, subject, email) VALUES (?, ?, 'google', ?, ?)",
                out,
                250,
                (PreparedStatement ps, SeedFamily f) -> {
                    ps.setObject(1, f.parentId());
                    ps.setObject(2, f.familyId());
                    ps.setString(3, "load-" + f.parentId());
                    ps.setString(4, null);
                });

        record SyncRow(UUID familyId, String key, String kind, String payloadJson) {}
        List<SyncRow> syncRows = new ArrayList<>(LOBBY_FAMILIES * 3);
        for (int i = 0; i < out.size(); i++) {
            SeedFamily f = out.get(i);
            syncRows.add(new SyncRow(
                    f.familyId(),
                    "kid:" + f.kidUuid(),
                    "kid",
                    json.writeValueAsString(Map.of(
                            "nickname", f.name(),
                            "avatar", "assets/images/avatars/fox.png",
                            "createdAt", 1000L + i))));
            syncRows.add(new SyncRow(
                    f.familyId(),
                    "setting:" + f.kidUuid() + ":raceNickname",
                    "setting",
                    json.writeValueAsString(Map.of("value", "Sieu " + f.name()))));
            syncRows.add(new SyncRow(
                    f.familyId(),
                    "game:" + f.kidUuid(),
                    "game",
                    json.writeValueAsString(Map.of("rocket", "rocket_blue"))));
        }
        jdbc.batchUpdate(
                "INSERT INTO sync_records (family_id, key, kind, payload, deleted, version) "
                        + "VALUES (?, ?, ?, ?::jsonb, false, nextval('sync_version_seq'))",
                syncRows,
                500,
                (PreparedStatement ps, SyncRow r) -> {
                    ps.setObject(1, r.familyId());
                    ps.setString(2, r.key());
                    ps.setString(3, r.kind());
                    ps.setString(4, r.payloadJson());
                });

        List<UUID[]> pairs = new ArrayList<>(LOBBY_FAMILIES * 5);
        for (int i = 0; i < LOBBY_FAMILIES; i++) {
            UUID a = out.get(i).familyId();
            for (int d = 1; d <= 5; d++) {
                UUID b = out.get((i + d) % LOBBY_FAMILIES).familyId();
                pairs.add(FriendService.orderedPair(a, b));
            }
        }
        jdbc.batchUpdate(
                "INSERT INTO friendships (family_a, family_b) VALUES (?, ?) ON CONFLICT DO NOTHING",
                pairs,
                500,
                (PreparedStatement ps, UUID[] p) -> {
                    ps.setObject(1, p[0]);
                    ps.setObject(2, p[1]);
                });
    }

    private void cleanupFamilies(List<SeedFamily> families) {
        if (families == null || families.isEmpty()) return;
        UUID[] ids = families.stream().map(SeedFamily::familyId).toArray(UUID[]::new);
        jdbc.update("DELETE FROM families WHERE id = ANY(?)", ps -> {
            ps.setArray(1, ps.getConnection().createArrayOf("uuid", ids));
        });
    }

    private void openLobbySessions(
            List<SeedFamily> families,
            List<HttpClient> clients,
            ExecutorService exec,
            List<LobbySession> outSessions,
            ConcurrentHashMap<String, Long> inviteSentNanos,
            LongSamples inviteSamples,
            AtomicInteger invitesReceived,
            AtomicInteger unexpectedErrors)
            throws Exception {
        Semaphore gate = new Semaphore(HANDSHAKE_CONCURRENCY);
        List<CompletableFuture<Void>> futures = new ArrayList<>(TOTAL_LOBBY_SESSIONS);
        URI uri = URI.create("ws://localhost:" + port + "/ws/lobby");
        for (int fIdx = 0; fIdx < LOBBY_FAMILIES; fIdx++) {
            SeedFamily fam = families.get(fIdx);
            for (int dev = 0; dev < LOBBY_CONNS_PER_FAMILY; dev++) {
                int globalIdx = fIdx * LOBBY_CONNS_PER_FAMILY + dev;
                HttpClient client = clients.get(globalIdx % clients.size());
                LobbySession ls = new LobbySession(
                        fam, dev, exec, json, inviteSentNanos, inviteSamples, invitesReceived, unexpectedErrors);
                outSessions.add(ls);
                gate.acquire();
                CompletableFuture<WebSocket> cf = client.newWebSocketBuilder()
                        .header("Authorization", "Bearer " + fam.token())
                        .buildAsync(uri, ls);
                ls.connectFuture = cf;
                futures.add(cf.whenComplete((ws, err) -> {
                    gate.release();
                    if (err != null) {
                        unexpectedErrors.incrementAndGet();
                    } else {
                        ls.ws = ws;
                    }
                }).thenAccept(ws -> {}));
            }
        }
        CompletableFuture.allOf(futures.toArray(CompletableFuture[]::new)).get(45, TimeUnit.SECONDS);
    }

    private List<String> createRooms(List<SeedFamily> families, HttpClient restClient) throws Exception {
        List<String> codes = new ArrayList<>(ROOM_COUNT);
        URI uri = URI.create("http://localhost:" + port + "/api/v1/rooms");
        Semaphore gate = new Semaphore(HANDSHAKE_CONCURRENCY);
        List<CompletableFuture<String>> futures = new ArrayList<>(ROOM_COUNT);
        for (int r = 0; r < ROOM_COUNT; r++) {
            // Host family matches player 0 in openRooms: (r * 4) % 500 (at most 3 rooms per host family).
            String token = families.get((r * PLAYERS_PER_ROOM) % LOBBY_FAMILIES).token();
            gate.acquire();
            HttpRequest req = HttpRequest.newBuilder(uri)
                    .header("Authorization", "Bearer " + token)
                    .POST(HttpRequest.BodyPublishers.noBody())
                    .build();
            futures.add(restClient
                    .sendAsync(req, HttpResponse.BodyHandlers.ofString())
                    .whenComplete((res, err) -> gate.release())
                    .thenApply(res -> {
                        if (res.statusCode() != 200) {
                            throw new IllegalStateException("create room failed: " + res.statusCode());
                        }
                        try {
                            return json.readTree(res.body()).get("code").asText();
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }));
        }
        for (CompletableFuture<String> f : futures) {
            codes.add(f.get(20, TimeUnit.SECONDS));
        }
        return codes;
    }

    private void openRooms(
            List<SeedFamily> families,
            List<String> codes,
            List<HttpClient> clients,
            ExecutorService exec,
            List<RoomCohort> outCohorts,
            LongSamples roomBroadcastAll,
            LongSamples roomBroadcastSlowRoomFastPeers,
            AtomicInteger stickersReceived,
            AtomicInteger unexpectedErrors)
            throws Exception {
        Semaphore gate = new Semaphore(HANDSHAKE_CONCURRENCY);
        List<CompletableFuture<Void>> connects = new ArrayList<>(ROOM_COUNT * PLAYERS_PER_ROOM);

        for (int r = 0; r < ROOM_COUNT; r++) {
            String code = codes.get(r);
            RoomCohort cohort = new RoomCohort(r, code, PLAYERS_PER_ROOM);
            outCohorts.add(cohort);
            LongSamples targetSamples = (r == 0) ? roomBroadcastSlowRoomFastPeers : roomBroadcastAll;

            for (int p = 0; p < PLAYERS_PER_ROOM; p++) {
                // Distribute 1,200 room sessions across 500 families: max 3 room sockets/family (<= 5 limit),
                // and all 4 players in any room belong to 4 distinct families.
                SeedFamily fam = families.get((r * PLAYERS_PER_ROOM + p) % LOBBY_FAMILIES);
                boolean isStalled = (r == 0 && p == PLAYERS_PER_ROOM - 1);
                RoomPeer peer = new RoomPeer(
                        cohort, p, fam, isStalled, exec, json, targetSamples, stickersReceived, unexpectedErrors);
                cohort.peers[p] = peer;

                if (isStalled) {
                    RawStalledRoomSocket raw = RawStalledRoomSocket.connect(port, code, fam.token(), json);
                    peer.rawStalledSocket = raw;
                    continue;
                }

                HttpClient client = clients.get((r * PLAYERS_PER_ROOM + p) % clients.size());
                URI uri = URI.create("ws://localhost:" + port + "/ws/room?code=" + code);
                gate.acquire();
                CompletableFuture<WebSocket> cf = client.newWebSocketBuilder()
                        .header("Authorization", "Bearer " + fam.token())
                        .buildAsync(uri, peer);
                peer.connectFuture = cf;
                connects.add(cf.whenComplete((ws, err) -> {
                    gate.release();
                    if (err != null) {
                        unexpectedErrors.incrementAndGet();
                    } else {
                        peer.ws = ws;
                    }
                }).thenAccept(ws -> {}));
            }
        }
        CompletableFuture.allOf(connects.toArray(CompletableFuture[]::new)).get(45, TimeUnit.SECONDS);

        // Join all 4 players in deterministic order so p1..p4 match peer indices 0..3.
        for (RoomCohort cohort : outCohorts) {
            for (int p = 0; p < PLAYERS_PER_ROOM; p++) {
                RoomPeer peer = cohort.peers[p];
                SeedFamily fam = peer.family;
                Map<String, Object> joinMsg = Map.of(
                        "t", "join",
                        "kid", fam.kidUuid(),
                        "name", cohort.roomIndex == 0 ? ("SlowRoomPlayer_" + p) : fam.name(),
                        "avatar", cohort.roomIndex == 0
                                ? "assets/images/avatars/penguin.png"
                                : "assets/images/avatars/fox.png",
                        "rocket", "rocket_orange");
                if (peer.isStalledRole) {
                    peer.rawStalledSocket.sendJson(joinMsg);
                    peer.rawStalledSocket.awaitMessageType("joined", 5000);
                    peer.joinedLatch.countDown();
                } else {
                    peer.sendJson(joinMsg);
                    assertThat(peer.joinedLatch.await(10, TimeUnit.SECONDS))
                            .as("room %s peer %d joined", cohort.code, p)
                            .isTrue();
                }
            }
        }
        for (RoomCohort cohort : outCohorts) {
            assertThat(cohort.fullLobbyLatch.await(15, TimeUnit.SECONDS))
                    .as("room %s full lobby (4 players)", cohort.code)
                    .isTrue();
        }
    }

    private CompletableFuture<Void> runGetFriendsLoad(
            HttpClient restClient,
            ExecutorService exec,
            List<SeedFamily> families,
            LongSamples samples,
            AtomicInteger non200,
            AtomicInteger unexpectedErrors,
            long deadlineNanos) {
        AtomicInteger counter = new AtomicInteger();
        List<CompletableFuture<Void>> workers = new ArrayList<>(FRIENDS_REST_CONCURRENCY);
        for (int w = 0; w < FRIENDS_REST_CONCURRENCY; w++) {
            final int workerId = w;
            workers.add(CompletableFuture.runAsync(() -> {
                while (System.nanoTime() < deadlineNanos) {
                    int idx = counter.getAndIncrement();
                    SeedFamily fam = families.get((idx * 17 + workerId) % LOBBY_FAMILIES);
                    long t0 = System.nanoTime();
                    try {
                        HttpResponse<String> res = restGetFriends(restClient, fam.token());
                        long elapsed = System.nanoTime() - t0;
                        if (res.statusCode() != 200) {
                            non200.incrementAndGet();
                        } else {
                            samples.record(elapsed);
                        }
                        Thread.sleep(40);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        return;
                    } catch (Exception e) {
                        unexpectedErrors.incrementAndGet();
                    }
                }
            }, exec));
        }
        return CompletableFuture.allOf(workers.toArray(CompletableFuture[]::new));
    }

    private HttpResponse<String> restGetFriends(HttpClient client, String token) throws Exception {
        HttpRequest req = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1/friends"))
                .header("Authorization", "Bearer " + token)
                .GET()
                .build();
        return client.send(req, HttpResponse.BodyHandlers.ofString());
    }

    private void sendInviteWave(
            List<RoomCohort> rooms,
            List<LobbySession> lobbySessions,
            ConcurrentHashMap<String, Long> inviteSentNanos,
            CountDownLatch waveLatch,
            AtomicInteger unexpectedErrors) {
        for (RoomCohort cohort : rooms) {
            sendRoomInvite(cohort, lobbySessions, inviteSentNanos, waveLatch, unexpectedErrors);
        }
    }

    private void sendRoomInvite(
            RoomCohort cohort,
            List<LobbySession> lobbySessions,
            ConcurrentHashMap<String, Long> inviteSentNanos,
            CountDownLatch ackLatch,
            AtomicInteger unexpectedErrors) {
        // Host family matches player 0 of room r: (r * 4) % 500. Offset friend by (1 + r/125) in [1..3]
        // so all 300 rooms have distinct (host, friend) pairs (never colliding on invite_pending).
        int hostFamIdx = (cohort.roomIndex * PLAYERS_PER_ROOM) % LOBBY_FAMILIES;
        int friendOffset = 1 + (cohort.roomIndex / (LOBBY_FAMILIES / PLAYERS_PER_ROOM));
        int friendFamIdx = (hostFamIdx + friendOffset) % LOBBY_FAMILIES;
        LobbySession hostLobby = lobbySessions.get(hostFamIdx * LOBBY_CONNS_PER_FAMILY);
        LobbySession targetPrimary = lobbySessions.get(friendFamIdx * LOBBY_CONNS_PER_FAMILY);
        SeedFamily target = targetPrimary.family;
        String key = hostLobby.family.familyId() + ":" + target.familyId() + ":" + cohort.code;
        targetPrimary.pendingAckLatches.put(key, ackLatch);
        inviteSentNanos.put(key, System.nanoTime());
        try {
            hostLobby.sendJson(Map.of(
                    "t", "invite",
                    "toFamilyId", target.familyId().toString(),
                    "roomCode", cohort.code,
                    "kidUuid", hostLobby.family.kidUuid()));
        } catch (Exception e) {
            inviteSentNanos.remove(key);
            targetPrimary.pendingAckLatches.remove(key);
            ackLatch.countDown();
            unexpectedErrors.incrementAndGet();
        }
    }

    /**
     * Room 0: peer 3 is a raw socket (tiny SO_RCVBUF) that stops reading after the first racing frame but keeps
     * playing (writes steps) so rounds can cycle. Snapshots keep flowing to it until the server's kernel send
     * buffer is full and the ConcurrentWebSocketSessionDecorator limits (2000 ms send time / 64 KB buffer) fire.
     */
    private void runSlowRoom(
            RoomCohort cohort, AtomicInteger unexpectedErrors, AtomicInteger roundsDone, long loadDeadlineNanos) {
        try {
            Thread.sleep(2000);
            RoomPeer host = cohort.peers[0];
            RawStalledRoomSocket stalled = cohort.peers[PLAYERS_PER_ROOM - 1].rawStalledSocket;
            // Keep cycling rounds until the server drops the stalled client (bounded by load window + 60 s).
            long hardDeadline = loadDeadlineNanos + TimeUnit.SECONDS.toNanos(60);
            int round = 0;
            while (round == 0
                    || (cohort.stalledPeerDisconnectedObserved.getCount() > 0 && System.nanoTime() < hardDeadline)) {
                if (round > 0) {
                    cohort.resetForNextRound();
                    host.sendRaw(AGAIN_JSON);
                    assertThat(cohort.lobbyLatch.await(10, TimeUnit.SECONDS))
                            .as("slow room back to lobby round %d", round)
                            .isTrue();
                }
                host.sendRaw(START_JSON);
                assertThat(cohort.racingLatch.await(10, TimeUnit.SECONDS))
                        .as("slow room %s racing round %d", cohort.code, round)
                        .isTrue();
                if (round == 0) {
                    // Wait until the raw socket reads the racing frame, then never read again.
                    stalled.awaitRacingAndFreeze();
                }
                boolean stalledWritable = true;
                for (int step = 1; step <= RACE_STEPS; step++) {
                    for (int p = 0; p < PLAYERS_PER_ROOM; p++) {
                        Thread.sleep(SLOW_ROOM_PEER_STAGGER_MS);
                        if (p < PLAYERS_PER_ROOM - 1) {
                            cohort.recordStepSent(p, step, System.nanoTime());
                            cohort.peers[p].sendRaw(STEP_JSON[step]);
                        } else if (stalledWritable) {
                            try {
                                stalled.sendText(STEP_JSON[step]);
                            } catch (IOException e) {
                                stalledWritable = false; // server already dropped it
                            }
                        }
                    }
                    if (step == 1 || step == 7 || step == 13) {
                        // Stickers add extra frames to the stalled peer (3 s per-player rate limit applies).
                        cohort.peers[0].sendRaw(CHEER_JSON);
                    }
                }
                boolean done = cohort.doneLatch.await(4, TimeUnit.SECONDS);
                roundsDone.incrementAndGet();
                round++;
                if (!done && cohort.stalledPeerDisconnectedObserved.getCount() == 0) {
                    break; // stalled peer was dropped mid-round; room waits out reconnect grace, so stop here.
                }
                assertThat(done).as("slow room %s done round %d", cohort.code, round - 1).isTrue();
            }
        } catch (Throwable e) {
            unexpectedErrors.incrementAndGet();
            throw new RuntimeException("slow room failed", e);
        }
    }

    private void runFastRoomForDuration(
            RoomCohort cohort,
            List<LobbySession> lobbySessions,
            ConcurrentHashMap<String, Long> inviteSentNanos,
            AtomicInteger unexpectedErrors,
            AtomicInteger roundsCompleted,
            long deadlineNanos) {
        try {
            // Stagger room starts across the 200 ms step period to avoid artificial client-side thundering herd.
            Thread.sleep((cohort.roomIndex % 20) * 10L);

            int round = 0;
            while (round == 0 || System.nanoTime() < deadlineNanos) {
                if (round > 0) {
                    cohort.resetForNextRound();
                    cohort.peers[0].sendRaw(AGAIN_JSON);
                    assertThat(cohort.lobbyLatch.await(10, TimeUnit.SECONDS))
                            .as("room %s back to lobby", cohort.code)
                            .isTrue();
                    CountDownLatch roundInviteLatch = new CountDownLatch(1);
                    sendRoomInvite(cohort, lobbySessions, inviteSentNanos, roundInviteLatch, unexpectedErrors);
                    assertThat(roundInviteLatch.await(10, TimeUnit.SECONDS))
                            .as("room %s invite delivered in round %d", cohort.code, round)
                            .isTrue();
                }

                cohort.peers[0].sendRaw(START_JSON);
                assertThat(cohort.racingLatch.await(10, TimeUnit.SECONDS))
                        .as("room %s racing round %d", cohort.code, round)
                        .isTrue();

                for (int step = 1; step <= RACE_STEPS; step++) {
                    Thread.sleep(STEP_INTERVAL_MS);
                    String stepPayload = STEP_JSON[step];
                    for (int p = 0; p < PLAYERS_PER_ROOM; p++) {
                        RoomPeer peer = cohort.peers[p];
                        cohort.recordStepSent(p, step, System.nanoTime());
                        peer.sendRaw(stepPayload);
                    }
                    if (step == 6) {
                        for (int p = 0; p < PLAYERS_PER_ROOM; p++) {
                            cohort.peers[p].sendRaw(CHEER_JSON);
                        }
                    }
                }

                boolean done = cohort.doneLatch.await(15, TimeUnit.SECONDS);
                if (!done) {
                    System.err.printf(
                            "Room %s round %d timed out waiting for done: peer0Observed=%s unexpectedErrors=%d%n",
                            cohort.code,
                            round,
                            Arrays.toString(cohort.peers[0].observedSteps),
                            unexpectedErrors.get());
                }
                assertThat(done)
                        .as("room %s done round %d", cohort.code, round)
                        .isTrue();
                roundsCompleted.incrementAndGet();
                round++;
            }
        } catch (Exception e) {
            unexpectedErrors.incrementAndGet();
            throw new RuntimeException("fast room " + cohort.code + " failed", e);
        }
    }

    private static void closeRooms(List<RoomCohort> rooms) {
        List<CompletableFuture<Void>> closes = new ArrayList<>();
        for (RoomCohort cohort : rooms) {
            for (RoomPeer peer : cohort.peers) {
                if (peer == null) continue;
                peer.closingIntentionally = true;
                if (peer.rawStalledSocket != null) {
                    peer.rawStalledSocket.closeQuietly();
                    continue;
                }
                WebSocket ws = peer.ws;
                if (ws == null && peer.connectFuture != null && peer.connectFuture.isDone()
                        && !peer.connectFuture.isCompletedExceptionally()) {
                    ws = peer.connectFuture.getNow(null);
                }
                if (ws == null && peer.connectFuture != null && !peer.connectFuture.isDone()) {
                    peer.connectFuture.cancel(true);
                }
                if (ws != null) {
                    final WebSocket target = ws;
                    closes.add(target
                            .sendClose(WebSocket.NORMAL_CLOSURE, "done")
                            .exceptionally(err -> {
                                target.abort();
                                return null;
                            })
                            .thenAccept(w -> {}));
                }
            }
        }
        try {
            CompletableFuture.allOf(closes.toArray(CompletableFuture[]::new)).get(10, TimeUnit.SECONDS);
        } catch (Exception ignored) {
            for (RoomCohort cohort : rooms) {
                for (RoomPeer peer : cohort.peers) {
                    if (peer != null && peer.ws != null) peer.ws.abort();
                }
            }
        }
    }

    private static void closeLobbies(List<LobbySession> sessions) {
        List<CompletableFuture<Void>> closes = new ArrayList<>(sessions.size());
        for (LobbySession ls : sessions) {
            ls.closingIntentionally = true;
            WebSocket ws = ls.ws;
            if (ws == null && ls.connectFuture != null && ls.connectFuture.isDone()
                    && !ls.connectFuture.isCompletedExceptionally()) {
                ws = ls.connectFuture.getNow(null);
            }
            if (ws == null && ls.connectFuture != null && !ls.connectFuture.isDone()) {
                ls.connectFuture.cancel(true);
            }
            if (ws != null) {
                final WebSocket target = ws;
                closes.add(target
                        .sendClose(WebSocket.NORMAL_CLOSURE, "done")
                        .exceptionally(err -> {
                            target.abort();
                            return null;
                        })
                        .thenAccept(w -> {}));
            }
        }
        try {
            CompletableFuture.allOf(closes.toArray(CompletableFuture[]::new)).get(10, TimeUnit.SECONDS);
        } catch (Exception ignored) {
            for (LobbySession ls : sessions) {
                if (ls.ws != null) ls.ws.abort();
            }
        }
    }

    private static long readProcessRssKb() {
        try {
            long pid = ProcessHandle.current().pid();
            Process p = new ProcessBuilder("ps", "-o", "rss=", "-p", Long.toString(pid))
                    .redirectErrorStream(true)
                    .start();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                String line = br.readLine();
                p.waitFor(2, TimeUnit.SECONDS);
                if (line != null && !line.isBlank()) {
                    return Long.parseLong(line.trim());
                }
            }
        } catch (Exception ignored) {
            // Non-POSIX environments fall back to -1.
        }
        return -1L;
    }

    private static void printSummary(
            long elapsedMs,
            List<RoomCohort> rooms,
            List<LobbySession> lobbySessions,
            int roundsCompleted,
            LatencyStats roomStats,
            LatencyStats slowRoomStats,
            LatencyStats inviteStats,
            LatencyStats friendsStats,
            int stickersReceived,
            int invitesReceived,
            int unexpectedErrors,
            int getFriendsNon200,
            int stalledUnreadBytes,
            boolean stalledClosedByServer,
            int slowRoomRounds,
            MemoryUsage heap,
            long rssKb) {
        double heapUsedMb = heap.getUsed() / (1024.0 * 1024.0);
        double heapCommittedMb = heap.getCommitted() / (1024.0 * 1024.0);
        double rssMb = rssKb > 0 ? rssKb / 1024.0 : -1.0;

        System.out.println("=== LobbyRoomLoadTest Summary ===");
        System.out.printf(
                "duration_ms=%d target_load_s=%d lobby_sessions=%d (%dx%d) rooms=%d room_sessions=%d fast_rounds_completed=%d step_interval_ms=%d (spec: 2000 lobby, 300 rooms, 200 ms, 60 s)%n",
                elapsedMs, LOAD_SECONDS, lobbySessions.size(), LOBBY_FAMILIES, LOBBY_CONNS_PER_FAMILY,
                rooms.size(), rooms.size() * PLAYERS_PER_ROOM, roundsCompleted, STEP_INTERVAL_MS);
        System.out.printf("stickers_received=%d invites_received=%d unexpected_errors=%d rest_non200=%d%n",
                stickersReceived, invitesReceived, unexpectedErrors, getFriendsNon200);
        System.out.printf(
                "roomBroadcast (n=%d): p50=%.2f ms, p95=%.2f ms, p99=%.2f ms, max=%.2f ms (budget<=%.0f ms)%n",
                roomStats.count(), roomStats.p50Ms(), roomStats.p95Ms(), roomStats.p99Ms(), roomStats.maxMs(),
                MAX_ROOM_BROADCAST_P99_MS);
        System.out.printf(
                "room0FastPeersWithStalledClient (n=%d, rounds=" + slowRoomRounds + ", stalled_unread_bytes=%d, stalled_closed_by_server=%s): p50=%.2f ms, p95=%.2f ms, p99=%.2f ms, max=%.2f ms%n",
                slowRoomStats.count(), stalledUnreadBytes, stalledClosedByServer,
                slowRoomStats.p50Ms(), slowRoomStats.p95Ms(), slowRoomStats.p99Ms(), slowRoomStats.maxMs());
        System.out.printf(
                "lobbyInvite (n=%d): p50=%.2f ms, p95=%.2f ms, p99=%.2f ms, max=%.2f ms (budget<=%.0f ms)%n",
                inviteStats.count(), inviteStats.p50Ms(), inviteStats.p95Ms(), inviteStats.p99Ms(), inviteStats.maxMs(),
                MAX_LOBBY_INVITE_P99_MS);
        System.out.printf(
                "getFriends (n=%d): p50=%.2f ms, p95=%.2f ms, p99=%.2f ms, max=%.2f ms (budget<=%.0f ms)%n",
                friendsStats.count(), friendsStats.p50Ms(), friendsStats.p95Ms(), friendsStats.p99Ms(),
                friendsStats.maxMs(), MAX_GET_FRIENDS_P99_MS);
        System.out.printf(
                "memory (combined test JVM: server + all WS clients): heap_used=%.1f MB, heap_committed=%.1f MB, rss=%.1f MB%n",
                heapUsedMb, heapCommittedMb, rssMb);
        System.out.println("================================");
    }

    /**
     * Minimal raw-TCP RFC 6455 client with 1 KB SO_RCVBUF that stops reading after entering racing state,
     * causing kernel TCP buffers to fill and triggering {@code ConcurrentWebSocketSessionDecorator}'s limits.
     */
    private static final class RawStalledRoomSocket {
        private static final SecureRandom RNG = new SecureRandom();
        private final Socket socket;
        private final InputStream in;
        private final OutputStream out;
        private final ObjectMapper json;

        private RawStalledRoomSocket(Socket socket, ObjectMapper json) throws IOException {
            this.socket = socket;
            this.in = socket.getInputStream();
            this.out = socket.getOutputStream();
            this.json = json;
        }

        static RawStalledRoomSocket connect(int port, String code, String token, ObjectMapper json) throws Exception {
            Socket socket = new Socket();
            socket.setReceiveBufferSize(1024); // must precede connect() to bound the TCP window
            socket.setSoTimeout(10_000);
            socket.connect(new InetSocketAddress("127.0.0.1", port), 5000);
            try {
                byte[] keyBytes = new byte[16];
                RNG.nextBytes(keyBytes);
                String wsKey = Base64.getEncoder().encodeToString(keyBytes);
                String req = "GET /ws/room?code=" + code + " HTTP/1.1\r\n"
                        + "Host: localhost:" + port + "\r\n"
                        + "Upgrade: websocket\r\n"
                        + "Connection: Upgrade\r\n"
                        + "Sec-WebSocket-Key: " + wsKey + "\r\n"
                        + "Sec-WebSocket-Version: 13\r\n"
                        + "Authorization: Bearer " + token + "\r\n\r\n";
                OutputStream out = socket.getOutputStream();
                out.write(req.getBytes(StandardCharsets.US_ASCII));
                out.flush();

                InputStream in = socket.getInputStream();
                String statusLine = readLine(in);
                if (statusLine == null || !statusLine.contains("101")) {
                    throw new IOException("WebSocket upgrade failed: " + statusLine);
                }
                String line;
                while ((line = readLine(in)) != null && !line.isEmpty()) {
                    // Drain upgrade headers.
                }
                return new RawStalledRoomSocket(socket, json);
            } catch (Exception e) {
                socket.close();
                throw e;
            }
        }

        void sendJson(Map<String, Object> msg) throws IOException {
            sendBytes(json.writeValueAsBytes(msg));
        }

        void sendText(String text) throws IOException {
            sendBytes(text.getBytes(StandardCharsets.UTF_8));
        }

        private synchronized void sendBytes(byte[] payload) throws IOException {
            byte[] mask = new byte[4];
            RNG.nextBytes(mask);
            out.write(0x81); // FIN + text frame
            if (payload.length < 126) {
                out.write(0x80 | payload.length);
            } else {
                out.write(0x80 | 126);
                out.write((payload.length >>> 8) & 0xFF);
                out.write(payload.length & 0xFF);
            }
            out.write(mask);
            byte[] masked = new byte[payload.length];
            for (int i = 0; i < payload.length; i++) {
                masked[i] = (byte) (payload[i] ^ mask[i % 4]);
            }
            out.write(masked);
            out.flush();
        }

        void awaitMessageType(String expectedType, long timeoutMs) throws Exception {
            long deadline = System.currentTimeMillis() + timeoutMs;
            while (System.currentTimeMillis() < deadline) {
                String text = readTextFrame();
                if (text == null) throw new EOFException("raw socket closed before " + expectedType);
                JsonNode m = json.readTree(text);
                if (expectedType.equals(m.path("t").asText(""))) return;
            }
            throw new IOException("Timed out waiting for " + expectedType);
        }

        void awaitRacingAndFreeze() throws Exception {
            long deadline = System.currentTimeMillis() + 10_000;
            while (System.currentTimeMillis() < deadline) {
                String text = readTextFrame();
                if (text == null) throw new EOFException("raw socket closed before racing");
                JsonNode m = json.readTree(text);
                if ("room".equals(m.path("t").asText("")) && "racing".equals(m.path("state").asText(""))) {
                    // Freeze: stop reading completely from socket InputStream.
                    return;
                }
            }
            throw new IOException("Timed out waiting for racing state on raw socket");
        }

        private String readTextFrame() throws IOException {
            while (true) {
                int b0 = in.read();
                if (b0 < 0) return null;
                int b1 = in.read();
                if (b1 < 0) return null;
                int opcode = b0 & 0x0F;
                long len = b1 & 0x7F;
                if (len == 126) {
                    int hi = in.read();
                    int lo = in.read();
                    if (hi < 0 || lo < 0) return null;
                    len = ((hi & 0xFF) << 8) | (lo & 0xFF);
                } else if (len == 127) {
                    byte[] ext = in.readNBytes(8);
                    if (ext.length < 8) return null;
                    len = ByteBuffer.wrap(ext).getLong();
                }
                if ((b1 & 0x80) != 0) {
                    in.readNBytes(4); // Unexpected server mask if any.
                }
                byte[] payload = in.readNBytes((int) len);
                if (payload.length < len) return null;
                if (opcode == 0x8) return null; // close
                if (opcode == 0x9) { // ping -> pong
                    out.write(0x8A);
                    out.write(0x80);
                    byte[] mask = new byte[4];
                    RNG.nextBytes(mask);
                    out.write(mask);
                    out.flush();
                    continue;
                }
                if (opcode == 0x1 || opcode == 0x0) {
                    return new String(payload, StandardCharsets.UTF_8);
                }
            }
        }

        private static String readLine(InputStream in) throws IOException {
            StringBuilder sb = new StringBuilder();
            int prev = -1;
            int cur;
            while ((cur = in.read()) != -1) {
                if (cur == '\n' && prev == '\r') {
                    sb.setLength(sb.length() - 1);
                    return sb.toString();
                }
                sb.append((char) cur);
                prev = cur;
            }
            return sb.isEmpty() ? null : sb.toString();
        }

        volatile long bytesDrained;

        /** Reads (and discards) whatever the server queued until EOF/reset; false if still open at timeout. */
        boolean drainUntilClosed(int timeoutMs) {
            long end = System.currentTimeMillis() + timeoutMs;
            byte[] sink = new byte[8192];
            try {
                socket.setSoTimeout(2000);
                while (System.currentTimeMillis() < end) {
                    try {
                        int n = in.read(sink);
                        if (n < 0) return true;
                        bytesDrained += n;
                    } catch (java.net.SocketTimeoutException e) {
                        // keep waiting
                    }
                }
            } catch (IOException e) {
                return true; // connection reset => server closed it
            }
            return false;
        }

        int unreadBytesAvailable() {
            try {
                return in.available();
            } catch (IOException e) {
                return 0;
            }
        }

        void closeQuietly() {
            try {
                socket.close();
            } catch (IOException ignored) {
                // Already closed.
            }
        }
    }

    private static final class LobbySession implements WebSocket.Listener {
        final SeedFamily family;
        final int deviceIdx;
        final ExecutorService exec;
        final ObjectMapper json;
        final ConcurrentHashMap<String, Long> inviteSentNanos;
        final LongSamples inviteSamples;
        final AtomicInteger invitesReceived;
        final AtomicInteger unexpectedErrors;
        final ConcurrentHashMap<String, CountDownLatch> pendingAckLatches = new ConcurrentHashMap<>();
        final CountDownLatch helloLatch = new CountDownLatch(1);
        final StringBuilder buf = new StringBuilder();
        final ReentrantLock sendLock = new ReentrantLock();
        volatile CompletableFuture<WebSocket> connectFuture;
        volatile WebSocket ws;
        volatile boolean closingIntentionally;

        LobbySession(
                SeedFamily family,
                int deviceIdx,
                ExecutorService exec,
                ObjectMapper json,
                ConcurrentHashMap<String, Long> inviteSentNanos,
                LongSamples inviteSamples,
                AtomicInteger invitesReceived,
                AtomicInteger unexpectedErrors) {
            this.family = family;
            this.deviceIdx = deviceIdx;
            this.exec = exec;
            this.json = json;
            this.inviteSentNanos = inviteSentNanos;
            this.inviteSamples = inviteSamples;
            this.invitesReceived = invitesReceived;
            this.unexpectedErrors = unexpectedErrors;
        }

        void sendJson(Map<String, Object> msg) throws Exception {
            String payload = json.writeValueAsString(msg);
            sendLock.lock();
            try {
                ws.sendText(payload, true).join();
            } finally {
                sendLock.unlock();
            }
        }

        private void sendReplyAsync(String payload) {
            exec.execute(() -> {
                if (closingIntentionally || ws == null) return;
                sendLock.lock();
                try {
                    if (!closingIntentionally && ws != null) {
                        ws.sendText(payload, true).join();
                    }
                } catch (Exception e) {
                    if (!closingIntentionally) {
                        unexpectedErrors.incrementAndGet();
                    }
                } finally {
                    sendLock.unlock();
                }
            });
        }

        @Override
        public void onOpen(WebSocket webSocket) {
            this.ws = webSocket;
            webSocket.request(1);
        }

        @Override
        public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
            String payload = null;
            synchronized (buf) {
                buf.append(data);
                if (last) {
                    payload = buf.toString();
                    buf.setLength(0);
                }
            }
            if (payload != null) {
                handleMessage(payload);
            }
            webSocket.request(1);
            return null;
        }

        private void handleMessage(String payload) {
            try {
                JsonNode m = json.readTree(payload);
                String t = m.path("t").asText("");
                switch (t) {
                    case "hello" -> helloLatch.countDown();
                    case "invite" -> {
                        long now = System.nanoTime();
                        String fromFam = m.path("from").path("familyId").asText("");
                        String roomCode = m.path("roomCode").asText("");
                        String inviteId = m.path("inviteId").asText("");
                        String key = fromFam + ":" + family.familyId() + ":" + roomCode;
                        Long sent = inviteSentNanos.remove(key);
                        if (sent != null) {
                            inviteSamples.record(now - sent);
                        }
                        if (deviceIdx == 0) {
                            invitesReceived.incrementAndGet();
                            if (!inviteId.isEmpty()) {
                                String reply = json.writeValueAsString(
                                        Map.of("t", "invite_reply", "inviteId", inviteId, "accept", false));
                                sendReplyAsync(reply);
                            }
                            CountDownLatch ack = pendingAckLatches.remove(key);
                            if (ack != null) {
                                ack.countDown();
                            }
                        }
                    }
                    case "error" -> {
                        System.err.println("Lobby error for " + family.familyId() + ": " + payload);
                        unexpectedErrors.incrementAndGet();
                    }
                    default -> {}
                }
            } catch (Exception e) {
                unexpectedErrors.incrementAndGet();
            }
        }

        @Override
        public CompletionStage<?> onPing(WebSocket webSocket, ByteBuffer message) {
            exec.execute(() -> {
                if (closingIntentionally || ws == null) return;
                sendLock.lock();
                try {
                    if (!closingIntentionally && ws != null) {
                        ws.sendPong(message).join();
                    }
                } catch (Exception ignored) {
                    // Closed during teardown.
                } finally {
                    sendLock.unlock();
                }
            });
            webSocket.request(1);
            return null;
        }

        @Override
        public CompletionStage<?> onClose(WebSocket webSocket, int statusCode, String reason) {
            if (!closingIntentionally) {
                unexpectedErrors.incrementAndGet();
            }
            return null;
        }

        @Override
        public void onError(WebSocket webSocket, Throwable error) {
            if (!closingIntentionally) {
                unexpectedErrors.incrementAndGet();
            }
        }
    }

    private static final class RoomCohort {
        final int roomIndex;
        final String code;
        final RoomPeer[] peers;
        final AtomicLongArray[] stepSentNanos;
        final CountDownLatch fullLobbyLatch;
        final CountDownLatch stalledPeerDisconnectedObserved = new CountDownLatch(1);
        volatile CountDownLatch lobbyLatch;
        volatile CountDownLatch racingLatch;
        volatile CountDownLatch doneLatch;
        final CountDownLatch fastPeersFinishedLatch = new CountDownLatch(PLAYERS_PER_ROOM - 1);

        RoomCohort(int roomIndex, String code, int peerCount) {
            this.roomIndex = roomIndex;
            this.code = code;
            this.peers = new RoomPeer[peerCount];
            this.stepSentNanos = new AtomicLongArray[peerCount];
            for (int p = 0; p < peerCount; p++) {
                this.stepSentNanos[p] = new AtomicLongArray(RACE_STEPS + 1);
            }
            int activeListeners = (roomIndex == 0) ? (peerCount - 1) : peerCount;
            this.fullLobbyLatch = new CountDownLatch(activeListeners);
            this.racingLatch = new CountDownLatch(activeListeners);
            this.lobbyLatch = new CountDownLatch(activeListeners);
            this.doneLatch = new CountDownLatch(activeListeners);
        }

        void recordStepSent(int peerIdx, int step, long nanos) {
            stepSentNanos[peerIdx].set(step, nanos);
        }

        long getStepSent(int peerIdx, int step) {
            return stepSentNanos[peerIdx].get(step);
        }

        void resetForNextRound() {
            for (int p = 0; p < peers.length; p++) {
                for (int s = 0; s <= RACE_STEPS; s++) {
                    stepSentNanos[p].set(s, 0L);
                }
                peers[p].resetObservedSteps();
            }
            int listeners = (roomIndex == 0) ? peers.length - 1 : peers.length;
            lobbyLatch = new CountDownLatch(listeners);
            racingLatch = new CountDownLatch(listeners);
            doneLatch = new CountDownLatch(listeners);
        }
    }

    private static final class RoomPeer implements WebSocket.Listener {
        final RoomCohort cohort;
        final int peerIdx;
        final SeedFamily family;
        final boolean isStalledRole;
        final ExecutorService exec;
        final ObjectMapper json;
        final LongSamples roomBroadcastSamples;
        final AtomicInteger stickersReceived;
        final AtomicInteger unexpectedErrors;

        final CountDownLatch joinedLatch = new CountDownLatch(1);
        final StringBuilder buf = new StringBuilder();
        final int[] observedSteps = new int[PLAYERS_PER_ROOM];
        final ReentrantLock sendLock = new ReentrantLock();
        volatile CompletableFuture<WebSocket> connectFuture;
        volatile RawStalledRoomSocket rawStalledSocket;
        volatile boolean signaledFullLobby;
        volatile boolean signaledLobbyRound;
        volatile boolean signaledRacingRound;
        volatile boolean signaledDoneRound;
        volatile boolean signaledFastFinished;
        volatile boolean closingIntentionally;
        volatile WebSocket ws;

        RoomPeer(
                RoomCohort cohort,
                int peerIdx,
                SeedFamily family,
                boolean isStalledRole,
                ExecutorService exec,
                ObjectMapper json,
                LongSamples roomBroadcastSamples,
                AtomicInteger stickersReceived,
                AtomicInteger unexpectedErrors) {
            this.cohort = cohort;
            this.peerIdx = peerIdx;
            this.family = family;
            this.isStalledRole = isStalledRole;
            this.exec = exec;
            this.json = json;
            this.roomBroadcastSamples = roomBroadcastSamples;
            this.stickersReceived = stickersReceived;
            this.unexpectedErrors = unexpectedErrors;
        }

        void resetObservedSteps() {
            Arrays.fill(observedSteps, 0);
            signaledLobbyRound = false;
            signaledRacingRound = false;
            signaledDoneRound = false;
        }

        void sendJson(Map<String, Object> msg) throws Exception {
            sendRaw(json.writeValueAsString(msg));
        }

        void sendRaw(String payload) {
            sendLock.lock();
            try {
                ws.sendText(payload, true).join();
            } finally {
                sendLock.unlock();
            }
        }

        @Override
        public void onOpen(WebSocket webSocket) {
            this.ws = webSocket;
            webSocket.request(1);
        }

        @Override
        public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
            buf.append(data);
            if (last) {
                String payload = buf.toString();
                buf.setLength(0);
                handleMessage(payload);
            }
            webSocket.request(1);
            return null;
        }

        private void handleMessage(String payload) {
            try (JsonParser p = json.getFactory().createParser(payload)) {
                if (p.nextToken() != JsonToken.START_OBJECT) return;
                String t = "";
                String state = "";
                int playerCount = 0;
                int[] playerSteps = new int[PLAYERS_PER_ROOM];
                boolean[] playerConnected = {true, true, true, true};

                while (p.nextToken() != JsonToken.END_OBJECT) {
                    String field = p.currentName();
                    JsonToken val = p.nextToken();
                    if ("t".equals(field)) {
                        t = p.getValueAsString("");
                    } else if ("state".equals(field)) {
                        state = p.getValueAsString("");
                    } else if ("players".equals(field) && val == JsonToken.START_ARRAY) {
                        while (p.nextToken() != JsonToken.END_ARRAY) {
                            if (p.currentToken() == JsonToken.START_OBJECT && playerCount < PLAYERS_PER_ROOM) {
                                int idx = playerCount++;
                                while (p.nextToken() != JsonToken.END_OBJECT) {
                                    String pf = p.currentName();
                                    JsonToken pv = p.nextToken();
                                    if ("steps".equals(pf)) {
                                        playerSteps[idx] = p.getIntValue();
                                    } else if ("connected".equals(pf)) {
                                        playerConnected[idx] = p.getBooleanValue();
                                    } else if (pv.isStructStart()) {
                                        p.skipChildren();
                                    }
                                }
                            } else if (p.currentToken().isStructStart()) {
                                p.skipChildren();
                            }
                        }
                    } else if (val.isStructStart()) {
                        p.skipChildren();
                    }
                }

                switch (t) {
                    case "joined" -> joinedLatch.countDown();
                    case "sticker" -> stickersReceived.incrementAndGet();
                    case "room" -> handleRoomSnapshot(state, playerCount, playerSteps, playerConnected);
                    case "error" -> {
                        if (!isStalledRole) unexpectedErrors.incrementAndGet();
                    }
                    default -> {}
                }
            } catch (Exception e) {
                if (!isStalledRole) unexpectedErrors.incrementAndGet();
            }
        }

        private void handleRoomSnapshot(String state, int playerCount, int[] playerSteps, boolean[] playerConnected) {
            long now = System.nanoTime();
            if ("lobby".equals(state)) {
                if (!signaledFullLobby && playerCount == PLAYERS_PER_ROOM) {
                    signaledFullLobby = true;
                    cohort.fullLobbyLatch.countDown();
                }
                boolean allZero = playerCount == PLAYERS_PER_ROOM;
                for (int i = 0; i < playerCount; i++) {
                    if (playerSteps[i] != 0) {
                        allZero = false;
                        break;
                    }
                }
                if (allZero && !signaledLobbyRound && signaledFullLobby) {
                    signaledLobbyRound = true;
                    cohort.lobbyLatch.countDown();
                }
                return;
            }

            if ("racing".equals(state) || "done".equals(state)) {
                if (!signaledRacingRound) {
                    signaledRacingRound = true;
                    cohort.racingLatch.countDown();
                }
                boolean allFastPeersAt18 = true;
                for (int p = 0; p < playerCount; p++) {
                    int steps = playerSteps[p];
                    if (steps > observedSteps[p]) {
                        for (int s = observedSteps[p] + 1; s <= steps && s <= RACE_STEPS; s++) {
                            long sent = cohort.getStepSent(p, s);
                            if (sent > 0L) {
                                roomBroadcastSamples.record(now - sent);
                            }
                        }
                        observedSteps[p] = steps;
                    }
                    if (p < PLAYERS_PER_ROOM - 1 && steps < RACE_STEPS) {
                        allFastPeersAt18 = false;
                    }
                    if (cohort.roomIndex == 0 && p == PLAYERS_PER_ROOM - 1 && !playerConnected[p]) {
                        cohort.stalledPeerDisconnectedObserved.countDown();
                    }
                }
                if (cohort.roomIndex == 0 && allFastPeersAt18 && !signaledFastFinished) {
                    signaledFastFinished = true;
                    cohort.fastPeersFinishedLatch.countDown();
                }
                if ("done".equals(state) && !signaledDoneRound) {
                    signaledDoneRound = true;
                    cohort.doneLatch.countDown();
                }
            }
        }

        @Override
        public CompletionStage<?> onPing(WebSocket webSocket, ByteBuffer message) {
            exec.execute(() -> {
                if (closingIntentionally || ws == null) return;
                sendLock.lock();
                try {
                    if (!closingIntentionally && ws != null) {
                        ws.sendPong(message).join();
                    }
                } catch (Exception ignored) {
                    // Closed during teardown.
                } finally {
                    sendLock.unlock();
                }
            });
            webSocket.request(1);
            return null;
        }

        @Override
        public CompletionStage<?> onClose(WebSocket webSocket, int statusCode, String reason) {
            if (!closingIntentionally && !isStalledRole) {
                unexpectedErrors.incrementAndGet();
            }
            return null;
        }

        @Override
        public void onError(WebSocket webSocket, Throwable error) {
            if (!closingIntentionally && !isStalledRole) {
                unexpectedErrors.incrementAndGet();
            }
        }
    }

    private record LatencyStats(int count, double p50Ms, double p95Ms, double p99Ms, double maxMs) {}

    private static final class LongSamples {
        private long[] values;
        private int size;

        LongSamples(int initialCapacity) {
            this.values = new long[Math.max(16, initialCapacity)];
        }

        synchronized void record(long nanos) {
            if (nanos < 0) nanos = 0;
            if (size == values.length) {
                values = Arrays.copyOf(values, values.length * 2);
            }
            values[size++] = nanos;
        }

        synchronized LatencyStats stats() {
            if (size == 0) {
                return new LatencyStats(0, 0, 0, 0, 0);
            }
            long[] copy = Arrays.copyOf(values, size);
            Arrays.sort(copy);
            return new LatencyStats(
                    size,
                    percentile(copy, 0.50) / 1_000_000.0,
                    percentile(copy, 0.95) / 1_000_000.0,
                    percentile(copy, 0.99) / 1_000_000.0,
                    copy[size - 1] / 1_000_000.0);
        }

        private static long percentile(long[] sorted, double p) {
            int idx = (int) Math.ceil(p * sorted.length) - 1;
            idx = Math.max(0, Math.min(sorted.length - 1, idx));
            return sorted[idx];
        }
    }
}
