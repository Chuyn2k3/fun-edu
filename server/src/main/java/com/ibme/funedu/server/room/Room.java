package com.ibme.funedu.server.room;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.regex.Pattern;
import org.springframework.web.socket.WebSocketSession;

/**
 * One race room: 2-4 kids from families who know its code. The server keeps
 * the authoritative state (who is in, steps, finish order); state mutations and
 * JSON snapshot building happen under the room lock, while all WebSocket I/O
 * happens outside the lock via {@link #deliver(Outbox)}.
 */
class Room {

    enum State { lobby, countdown, racing, done }

    record Send(WebSocketSession session, String text) {}

    record Outbox(List<Send> sends, List<WebSocketSession> closes) {
        static final Outbox EMPTY = new Outbox(List.of(), List.of());

        boolean isEmpty() {
            return sends.isEmpty() && closes.isEmpty();
        }
    }

    record JoinResult(String error, Outbox outbox) {}

    record TickResult(boolean alive, Outbox outbox) {}

    static final int RACE_LENGTH = 18;
    static final Set<String> STICKERS = Set.of(
            "cheer", "love", "party", "bubble", "tongue", "byebye", "rain",
            "sleepy", "turtle", "smoke", "wow", "fast", "hi", "gg",
            "q_almost", "q_fast", "q_oops", "q_chase", "q_again");
    private static final Pattern AVATAR = Pattern.compile("assets/images/[a-z0-9_\\-/]{1,80}\\.(png|webp)");
    private static final Pattern ROCKET = Pattern.compile("rocket_[a-z]{1,20}");

    static final class Player {
        final String id;
        final UUID familyId;
        final String kid;
        String name;
        String avatar;
        String rocket;
        int steps;
        Integer rank;
        WebSocketSession session;
        Instant disconnectedAt;
        Instant lastStep = Instant.EPOCH;
        Instant lastSticker = Instant.EPOCH;
        boolean left;

        Player(String id, UUID familyId, String kid) {
            this.id = id;
            this.familyId = familyId;
            this.kid = kid;
        }

        boolean connected() {
            return session != null && session.isOpen();
        }
    }

    final String code;
    final UUID hostFamily;
    final Instant createdAt;
    private final RoomProperties props;
    private final Function<Object, String> json;

    private final Map<String, Player> players = new LinkedHashMap<>();
    private State state = State.lobby;
    private String hostId;
    private Instant startsAt;
    private Instant raceStartedAt;
    private Instant doneAt;
    private String endReason;
    private int nextId = 1;
    private int finished;
    private boolean dirty;
    /**
     * Grows with every snapshot built. A slow socket can deliver an older
     * snapshot after a newer one; the app keeps only the newest.
     */
    private long seq;

    Room(String code, UUID hostFamily, Instant now, RoomProperties props, Function<Object, String> json) {
        this.code = code;
        this.hostFamily = hostFamily;
        this.createdAt = now;
        this.props = props;
        this.json = json;
    }

    synchronized State state() {
        return state;
    }

    synchronized boolean hasActiveFamily(UUID family) {
        if (family == null || state != State.lobby) return false;
        for (Player p : players.values()) {
            if (!p.left && p.familyId.equals(family)) {
                return true;
            }
        }
        return false;
    }

    Instant expiresAt() {
        return createdAt.plus(props.lobbyTtl());
    }

    /** Returns an error code or an outbox of messages to deliver outside the lock. */
    synchronized JoinResult join(WebSocketSession session, UUID family, String kid,
            String name, String avatar, String rocket, Instant now) {
        if (kid == null || kid.isBlank() || kid.length() > 64) {
            return new JoinResult("bad_message", Outbox.EMPTY);
        }
        for (Player p : players.values()) {
            if (p.familyId.equals(family) && p.kid.equals(kid) && !p.left) {
                // Same kid again (reconnect, or a second tab): take over.
                WebSocketSession old = p.session;
                p.session = session;
                p.disconnectedAt = null;
                List<WebSocketSession> closes = (old != null && old != session && old.isOpen())
                        ? List.of(old)
                        : List.of();
                dirty = false;
                return new JoinResult(null, joinOutbox(p, now, closes));
            }
        }
        if (state != State.lobby) return new JoinResult("started", Outbox.EMPTY);
        long active = players.values().stream().filter(p -> !p.left).count();
        if (active >= props.maxPlayers()) return new JoinResult("room_full", Outbox.EMPTY);
        Player p = new Player("p" + nextId++, family, kid);
        p.name = cleanName(name);
        p.avatar = avatar != null && AVATAR.matcher(avatar).matches() ? avatar : "";
        p.rocket = rocket != null && ROCKET.matcher(rocket).matches() ? rocket : "rocket_orange";
        p.session = session;
        players.put(p.id, p);
        if (hostId == null && family.equals(hostFamily)) hostId = p.id;
        if (hostId == null) hostId = p.id;
        dirty = false;
        return new JoinResult(null, joinOutbox(p, now, List.of()));
    }

    synchronized Outbox start(WebSocketSession from, Instant now) {
        Player p = bySession(from);
        if (p == null) return Outbox.EMPTY;
        if (!p.id.equals(hostId)) {
            return singleSend(p, Map.of("t", "error", "code", "not_host"));
        }
        if (state != State.lobby) return Outbox.EMPTY;
        long ready = players.values().stream().filter(x -> x.connected() && !x.left).count();
        if (ready < 2) {
            return singleSend(p, Map.of("t", "error", "code", "need_two"));
        }
        // Drop anyone who is not here right now.
        players.values().removeIf(x -> !x.connected() || x.left);
        state = State.countdown;
        endReason = null;
        startsAt = now.plus(props.countdown());
        dirty = false;
        return broadcastOutbox(now);
    }

    /** "Đua lại!": the host brings everyone still here back to the lobby. */
    synchronized Outbox again(WebSocketSession from, Instant now) {
        Player p = bySession(from);
        if (p == null || !p.id.equals(hostId) || state != State.done) return Outbox.EMPTY;
        players.values().removeIf(x -> !x.connected() || x.left);
        for (Player x : players.values()) {
            x.steps = 0;
            x.rank = null;
            x.lastStep = Instant.EPOCH;
        }
        finished = 0;
        endReason = null;
        state = State.lobby;
        startsAt = null;
        raceStartedAt = null;
        doneAt = null;
        dirty = false;
        return broadcastOutbox(now);
    }

    /**
     * Records a progress step and marks the room dirty for the next coalesced
     * flush; if the step ends the race, sends the final snapshot immediately.
     */
    synchronized Outbox step(WebSocketSession from, int n, Instant now) {
        Player p = bySession(from);
        if (p == null || state != State.racing || p.rank != null) return Outbox.EMPTY;
        int gain = n - p.steps;
        if (gain < 1 || gain > 2 || n > RACE_LENGTH) return Outbox.EMPTY;
        if (now.isBefore(p.lastStep.plus(props.minStepInterval()))) return Outbox.EMPTY;
        p.steps = n;
        p.lastStep = now;
        if (n == RACE_LENGTH) p.rank = ++finished;
        boolean ended = checkDone(now);
        if (ended) {
            dirty = false;
            return broadcastOutbox(now);
        }
        dirty = true;
        return Outbox.EMPTY;
    }

    /** Builds one shared snapshot if dirty and resets the dirty flag. */
    synchronized Outbox flush(Instant now) {
        if (!dirty) return Outbox.EMPTY;
        dirty = false;
        return broadcastOutbox(now);
    }

    synchronized Outbox sticker(WebSocketSession from, String id, String to, Instant now) {
        Player p = bySession(from);
        if (p == null || p.left || id == null || !STICKERS.contains(id)) return Outbox.EMPTY;
        if (now.isBefore(p.lastSticker.plusSeconds(3))) return Outbox.EMPTY;
        p.lastSticker = now;
        String validTo = null;
        if (to != null && !to.isBlank()) {
            Player target = players.get(to);
            if (target != null && !target.left) {
                validTo = to;
            }
        }
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("t", "sticker");
        payload.put("from", p.id);
        payload.put("id", id);
        if (validTo != null) {
            payload.put("to", validTo);
        }
        String msg = json.apply(payload);
        List<Send> sends = new ArrayList<>();
        for (Player x : players.values()) {
            if (x.connected() && !x.left) sends.add(new Send(x.session, msg));
        }
        return sends.isEmpty() ? Outbox.EMPTY : new Outbox(sends, List.of());
    }

    synchronized Outbox leave(WebSocketSession from, Instant now) {
        Player p = bySession(from);
        if (p == null) return Outbox.EMPTY;
        if (state == State.lobby) {
            players.remove(p.id);
            if (p.id.equals(hostId)) hostId = players.keySet().stream().findFirst().orElse(null);
        } else {
            p.left = true;
            p.disconnectedAt = now;
        }
        p.session = null;
        checkDone(now);
        dirty = false;
        Outbox b = broadcastOutbox(now);
        return new Outbox(b.sends(), List.of(from));
    }

    synchronized Outbox disconnected(WebSocketSession session, Instant now) {
        Player p = bySession(session);
        if (p == null) return Outbox.EMPTY;
        p.session = null;
        p.disconnectedAt = now;
        dirty = false;
        return broadcastOutbox(now);
    }

    /** Time-driven changes; returns alive=false when the room should be removed. */
    synchronized TickResult tick(Instant now) {
        boolean changed = false;
        Instant cutoff = now.minus(props.reconnectGrace());
        if (state == State.lobby) {
            boolean hostGone = hostId != null && gone(players.get(hostId), cutoff);
            if (players.values().removeIf(p -> gone(p, cutoff))) changed = true;
            if (hostGone) hostId = players.keySet().stream().findFirst().orElse(null);
            if (now.isAfter(expiresAt())) {
                return new TickResult(false, closeAllOutbox("expired"));
            }
        } else if (state == State.countdown) {
            for (Player p : players.values()) {
                if (!p.left && gone(p, cutoff)) {
                    p.left = true;
                    changed = true;
                }
            }
            if (!now.isBefore(startsAt)) {
                state = State.racing;
                raceStartedAt = now;
                changed = true;
                checkDone(now);
            }
        } else if (state == State.racing) {
            for (Player p : players.values()) {
                if (!p.left && gone(p, cutoff)) {
                    p.left = true;
                    changed = true;
                }
            }
            changed |= checkDone(now);
        } else if (state == State.done && now.isAfter(doneAt.plus(props.keepDone()))) {
            return new TickResult(false, closeAllOutbox(null));
        }
        if (changed) {
            dirty = false;
            return new TickResult(true, broadcastOutbox(now));
        }
        return new TickResult(true, Outbox.EMPTY);
    }

    private boolean gone(Player p, Instant cutoff) {
        return p != null && !p.connected() && p.disconnectedAt != null && p.disconnectedAt.isBefore(cutoff);
    }

    private boolean checkDone(Instant now) {
        if (state != State.racing) return false;
        List<Player> present = players.values().stream().filter(p -> !p.left).toList();
        if (present.size() == 1) {
            Player last = present.get(0);
            if (last.rank == null) {
                int rankedCount = (int) players.values().stream().filter(p -> p.rank != null).count();
                last.rank = rankedCount + 1;
                finished = Math.max(finished, last.rank);
                endReason = "others_left";
                state = State.done;
                doneAt = now;
                return true;
            }
        }
        boolean timeUp = raceStartedAt != null && now.isAfter(raceStartedAt.plus(props.maxRaceTime()));
        boolean allIn = players.values().stream().allMatch(p -> p.rank != null || p.left);
        if (!timeUp && !allIn) return false;
        state = State.done;
        doneAt = now;
        return true;
    }

    private Player bySession(WebSocketSession s) {
        for (Player p : players.values()) if (p.session == s) return p;
        return null;
    }

    private Outbox joinOutbox(Player joined, Instant now, List<WebSocketSession> closes) {
        String joinedMsg = json.apply(Map.of("t", "joined", "you", joined.id));
        String roomMsg = json.apply(snapshot(now));
        List<Send> sends = new ArrayList<>();
        if (joined.connected()) sends.add(new Send(joined.session, joinedMsg));
        for (Player x : players.values()) {
            if (x.connected()) sends.add(new Send(x.session, roomMsg));
        }
        return new Outbox(sends, closes);
    }

    private Outbox singleSend(Player p, Map<String, Object> msg) {
        if (!p.connected()) return Outbox.EMPTY;
        return new Outbox(List.of(new Send(p.session, json.apply(msg))), List.of());
    }

    private Outbox broadcastOutbox(Instant now) {
        String payload = json.apply(snapshot(now));
        List<Send> sends = new ArrayList<>();
        for (Player p : players.values()) {
            if (p.connected()) sends.add(new Send(p.session, payload));
        }
        return sends.isEmpty() ? Outbox.EMPTY : new Outbox(sends, List.of());
    }

    Map<String, Object> snapshot(Instant now) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (Player p : players.values()) {
            boolean connected = p.connected() && !p.left;
            boolean away = !connected && !p.left && p.disconnectedAt != null;
            Long awayMsLeft = away
                    ? Math.max(0L, Duration.between(now, p.disconnectedAt.plus(props.reconnectGrace())).toMillis())
                    : null;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", p.id);
            m.put("name", p.name);
            m.put("avatar", p.avatar);
            m.put("rocket", p.rocket);
            m.put("steps", p.steps);
            m.put("rank", p.rank);
            // Omit default flags (connected=true, away=false, left=false) to keep 4-player snapshots <= 600 bytes.
            if (!connected) m.put("connected", false);
            if (away) m.put("away", true);
            m.put("awayMsLeft", awayMsLeft);
            if (p.left) m.put("left", true);
            list.add(m);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("t", "room");
        out.put("seq", ++seq);
        out.put("code", code);
        out.put("state", state.name());
        out.put("host", hostId);
        out.put("endReason", endReason);
        if (state == State.countdown && startsAt != null) out.put("startsAt", startsAt.toEpochMilli());
        out.put("players", list);
        return out;
    }

    private Outbox closeAllOutbox(String error) {
        String errPayload = error == null ? null : json.apply(Map.of("t", "error", "code", error));
        List<Send> sends = new ArrayList<>();
        List<WebSocketSession> closes = new ArrayList<>();
        for (Player p : players.values()) {
            if (!p.connected()) continue;
            if (errPayload != null) sends.add(new Send(p.session, errPayload));
            closes.add(p.session);
        }
        return sends.isEmpty() && closes.isEmpty() ? Outbox.EMPTY : new Outbox(sends, closes);
    }

    /**
     * Dispatches all WebSocket sends and closes outside any room lock on
     * virtual threads so one slow/blocked client never stalls the room or tick.
     */
    static void deliver(Outbox outbox) {
        if (outbox == null || outbox.isEmpty()) return;
        for (Send s : outbox.sends()) {
            SocketSender.send(s.session(), s.text());
        }
        for (WebSocketSession c : outbox.closes()) {
            SocketSender.close(c);
        }
    }

    static void closeQuietly(WebSocketSession s) {
        SocketSender.closeQuietly(s);
    }

    /** Printable, single line, at most 16 characters; never empty. */
    static String cleanName(String raw) {
        if (raw == null) return "Bạn nhỏ";
        String s = raw.replaceAll("[\\p{Cntrl}\\p{Cf}]", " ").replaceAll("\\s+", " ").strip();
        int[] cps = s.codePoints().limit(16).toArray();
        s = new String(cps, 0, cps.length).strip();
        return s.isEmpty() ? "Bạn nhỏ" : s;
    }
}
