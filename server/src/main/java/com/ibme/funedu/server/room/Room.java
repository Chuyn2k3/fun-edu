package com.ibme.funedu.server.room;

import java.io.IOException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.regex.Pattern;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

/**
 * One race room: 2-4 kids from families who know its code. The server keeps
 * the authoritative state (who is in, steps, finish order); every change is
 * pushed to every player as a full snapshot. All methods lock the room.
 */
class Room {

    enum State { lobby, countdown, racing, done }

    static final int RACE_LENGTH = 10;
    static final Set<String> STICKERS = Set.of("cheer", "wow", "love", "fast", "hi", "gg");
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
    private int nextId = 1;
    private int finished;

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

    Instant expiresAt() {
        return createdAt.plus(props.lobbyTtl());
    }

    /** Returns an error code, or null when [session] is now in the room. */
    synchronized String join(WebSocketSession session, UUID family, String kid,
            String name, String avatar, String rocket) {
        if (kid == null || kid.isBlank() || kid.length() > 64) return "bad_message";
        for (Player p : players.values()) {
            if (p.familyId.equals(family) && p.kid.equals(kid) && !p.left) {
                // Same kid again (reconnect, or a second tab): take over.
                WebSocketSession old = p.session;
                p.session = session;
                p.disconnectedAt = null;
                if (old != null && old != session && old.isOpen()) closeQuietly(old);
                broadcast();
                return null;
            }
        }
        if (state != State.lobby) return "started";
        long active = players.values().stream().filter(p -> !p.left).count();
        if (active >= props.maxPlayers()) return "room_full";
        Player p = new Player("p" + nextId++, family, kid);
        p.name = cleanName(name);
        p.avatar = avatar != null && AVATAR.matcher(avatar).matches() ? avatar : "";
        p.rocket = rocket != null && ROCKET.matcher(rocket).matches() ? rocket : "rocket_orange";
        p.session = session;
        players.put(p.id, p);
        if (hostId == null && family.equals(hostFamily)) hostId = p.id;
        if (hostId == null) hostId = p.id;
        broadcast();
        return null;
    }

    synchronized void start(WebSocketSession from, Instant now) {
        Player p = bySession(from);
        if (p == null) return;
        if (!p.id.equals(hostId)) {
            send(p, Map.of("t", "error", "code", "not_host"));
            return;
        }
        if (state != State.lobby) return;
        long ready = players.values().stream().filter(x -> x.connected() && !x.left).count();
        if (ready < 2) {
            send(p, Map.of("t", "error", "code", "need_two"));
            return;
        }
        // Drop anyone who is not here right now.
        players.values().removeIf(x -> !x.connected() || x.left);
        state = State.countdown;
        startsAt = now.plus(props.countdown());
        broadcast();
    }

    /** "Đua lại!": the host brings everyone still here back to the lobby. */
    synchronized void again(WebSocketSession from) {
        Player p = bySession(from);
        if (p == null || !p.id.equals(hostId) || state != State.done) return;
        players.values().removeIf(x -> !x.connected() || x.left);
        for (Player x : players.values()) {
            x.steps = 0;
            x.rank = null;
            x.lastStep = Instant.EPOCH;
        }
        finished = 0;
        state = State.lobby;
        startsAt = null;
        raceStartedAt = null;
        doneAt = null;
        broadcast();
    }

    synchronized void step(WebSocketSession from, int n, Instant now) {
        Player p = bySession(from);
        if (p == null || state != State.racing || p.rank != null) return;
        int gain = n - p.steps;
        if (gain < 1 || gain > 2 || n > RACE_LENGTH) return;
        if (now.isBefore(p.lastStep.plus(props.minStepInterval()))) return;
        p.steps = n;
        p.lastStep = now;
        if (n == RACE_LENGTH) p.rank = ++finished;
        checkDone(now);
        broadcast();
    }

    synchronized void sticker(WebSocketSession from, String id, Instant now) {
        Player p = bySession(from);
        if (p == null || !STICKERS.contains(id)) return;
        if (now.isBefore(p.lastSticker.plusMillis(1500))) return;
        p.lastSticker = now;
        String msg = json.apply(Map.of("t", "sticker", "from", p.id, "id", id));
        for (Player x : players.values()) send(x, msg);
    }

    synchronized void leave(WebSocketSession from, Instant now) {
        Player p = bySession(from);
        if (p == null) return;
        if (state == State.lobby) {
            players.remove(p.id);
            if (p.id.equals(hostId)) hostId = players.keySet().stream().findFirst().orElse(null);
        } else {
            p.left = true;
            p.disconnectedAt = now;
        }
        p.session = null;
        closeQuietly(from);
        checkDone(now);
        broadcast();
    }

    synchronized void disconnected(WebSocketSession session, Instant now) {
        Player p = bySession(session);
        if (p == null) return;
        p.session = null;
        p.disconnectedAt = now;
        broadcast();
    }

    /** Time-driven changes; returns false when the room should be removed. */
    synchronized boolean tick(Instant now) {
        boolean changed = false;
        if (state == State.countdown && !now.isBefore(startsAt)) {
            state = State.racing;
            raceStartedAt = now;
            changed = true;
        }
        Instant cutoff = now.minus(props.reconnectGrace());
        if (state == State.lobby) {
            boolean hostGone = hostId != null && gone(players.get(hostId), cutoff);
            if (players.values().removeIf(p -> gone(p, cutoff))) changed = true;
            if (hostGone) hostId = players.keySet().stream().findFirst().orElse(null);
            if (now.isAfter(expiresAt())) {
                closeAll("expired");
                return false;
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
            closeAll(null);
            return false;
        }
        if (changed) broadcast();
        return true;
    }

    private boolean gone(Player p, Instant cutoff) {
        return p != null && !p.connected() && p.disconnectedAt != null && p.disconnectedAt.isBefore(cutoff);
    }

    private boolean checkDone(Instant now) {
        if (state != State.racing) return false;
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

    private void broadcast() {
        for (Player p : players.values()) {
            if (p.connected()) send(p, snapshot(p.id));
        }
    }

    Map<String, Object> snapshot(String you) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (Player p : players.values()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", p.id);
            m.put("name", p.name);
            m.put("avatar", p.avatar);
            m.put("rocket", p.rocket);
            m.put("steps", p.steps);
            m.put("rank", p.rank);
            m.put("connected", p.connected() && !p.left);
            list.add(m);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("t", "room");
        out.put("code", code);
        out.put("state", state.name());
        out.put("you", you);
        out.put("host", hostId);
        if (startsAt != null) out.put("startsAt", startsAt.toEpochMilli());
        out.put("players", list);
        return out;
    }

    private void send(Player p, Object msg) {
        if (!p.connected()) return;
        try {
            p.session.sendMessage(new TextMessage(msg instanceof String s ? s : json.apply(msg)));
        } catch (IOException | IllegalStateException e) {
            // A broken socket: the close callback marks the player disconnected.
        }
    }

    private void closeAll(String error) {
        for (Player p : players.values()) {
            if (!p.connected()) continue;
            if (error != null) send(p, Map.of("t", "error", "code", error));
            closeQuietly(p.session);
        }
    }

    static void closeQuietly(WebSocketSession s) {
        try {
            s.close(CloseStatus.NORMAL);
        } catch (IOException | IllegalStateException e) {
            // Already gone.
        }
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
