package com.ibme.funedu.server.room;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.auth.AuthFailedException;
import com.ibme.funedu.server.auth.AuthService;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * `/ws/room?code=XXXXXX`, opened with the parent's bearer token. Messages
 * are small JSON objects with a `t` type: join, start, step, sticker,
 * again, leave. The first message must be `join`.
 */
@Component
public class RoomSocketHandler extends TextWebSocketHandler {

    static final int MAX_SOCKETS_PER_FAMILY = 5;
    static final int MAX_MESSAGES_PER_SECOND = 20;

    private static final String ROOM = "room";
    private static final String FAMILY = "family";
    private static final String SAFE = "safe";
    private static final String COUNTED = "counted";
    private static final String MSG_TIMES = "msgTimes";

    private final RoomRegistry rooms;
    private final AuthService auth;
    private final ObjectMapper json;
    private final ConcurrentHashMap<UUID, AtomicInteger> activeSockets = new ConcurrentHashMap<>();

    public RoomSocketHandler(RoomRegistry rooms, AuthService auth, ObjectMapper json) {
        this.rooms = rooms;
        this.auth = auth;
        this.json = json;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        if (!(session.getPrincipal() instanceof JwtAuthenticationToken token)) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        UUID family;
        try {
            family = auth.currentParent(token.getToken()).familyId();
        } catch (AuthFailedException e) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        // Rooms send from several threads; the decorator serialises sends.
        WebSocketSession safeSession = new ConcurrentWebSocketSessionDecorator(session, 2000, 64 * 1024);
        session.getAttributes().put(FAMILY, family);
        session.getAttributes().put(SAFE, safeSession);

        AtomicInteger counter = activeSockets.computeIfAbsent(family, k -> new AtomicInteger());
        if (counter.incrementAndGet() > MAX_SOCKETS_PER_FAMILY) {
            counter.decrementAndGet();
            error(safeSession, "too_many");
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        session.getAttributes().put(COUNTED, family);
        session.getAttributes().put(MSG_TIMES, new ArrayDeque<Long>());
    }

    @Override
    protected void handleTextMessage(WebSocketSession raw, TextMessage message) throws Exception {
        WebSocketSession session = safe(raw);
        if (!allowMessageRate(raw)) {
            error(session, "too_many");
            raw.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        if (message.getPayloadLength() > 2048) {
            error(session, "bad_message");
            return;
        }
        JsonNode m;
        try {
            m = json.readTree(message.getPayload());
        } catch (Exception e) {
            error(session, "bad_message");
            return;
        }
        String type = m.path("t").asText("");
        Room room = (Room) raw.getAttributes().get(ROOM);
        var now = rooms.now();
        if (room == null) {
            if (!"join".equals(type)) {
                error(session, "bad_message");
                return;
            }
            join(raw, session, m);
            return;
        }
        switch (type) {
            case "start" -> Room.deliver(room.start(session, now));
            case "step" -> Room.deliver(room.step(session, m.path("n").asInt(-1), now));
            case "sticker" -> Room.deliver(room.sticker(session, m.path("id").asText(""), now));
            case "again" -> Room.deliver(room.again(session, now));
            case "leave" -> Room.deliver(room.leave(session, now));
            default -> error(session, "bad_message");
        }
    }

    private void join(WebSocketSession raw, WebSocketSession session, JsonNode m) throws Exception {
        UUID family = (UUID) raw.getAttributes().get(FAMILY);
        if (!rooms.mayTryJoin(family)) {
            error(session, "too_many");
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        String code = UriComponentsBuilder.fromUri(raw.getUri()).build().getQueryParams().getFirst("code");
        Room room = rooms.find(code);
        Room.JoinResult res = room == null
                ? new Room.JoinResult("not_found", Room.Outbox.EMPTY)
                : room.join(session, family,
                        m.path("kid").asText(null), m.path("name").asText(null),
                        m.path("avatar").asText(null), m.path("rocket").asText(null), rooms.now());
        if (res.error() != null) {
            if ("not_found".equals(res.error())) rooms.failedJoin(family);
            error(session, res.error());
            session.close(CloseStatus.NORMAL);
            return;
        }
        raw.getAttributes().put(ROOM, room);
        Room.deliver(res.outbox());
    }

    @Override
    public void afterConnectionClosed(WebSocketSession raw, CloseStatus status) {
        Object counted = raw.getAttributes().remove(COUNTED);
        if (counted instanceof UUID family) {
            AtomicInteger c = activeSockets.get(family);
            if (c != null && c.decrementAndGet() <= 0) {
                activeSockets.remove(family, c);
            }
        }
        Room room = (Room) raw.getAttributes().get(ROOM);
        if (room != null) Room.deliver(room.disconnected(safe(raw), rooms.now()));
    }

    @SuppressWarnings("unchecked")
    private boolean allowMessageRate(WebSocketSession raw) {
        Object attr = raw.getAttributes().get(MSG_TIMES);
        if (!(attr instanceof Deque<?>)) return true;
        Deque<Long> times = (Deque<Long>) attr;
        long now = rooms.now().toEpochMilli();
        synchronized (times) {
            long cutoff = now - 1000L;
            while (!times.isEmpty() && times.peekFirst() <= cutoff) {
                times.removeFirst();
            }
            if (times.size() >= MAX_MESSAGES_PER_SECOND) {
                return false;
            }
            times.addLast(now);
            return true;
        }
    }

    private WebSocketSession safe(WebSocketSession raw) {
        Object s = raw.getAttributes().get(SAFE);
        return s instanceof WebSocketSession w ? w : raw;
    }

    private void error(WebSocketSession s, String code) throws Exception {
        if (s.isOpen()) s.sendMessage(new TextMessage(json.writeValueAsString(Map.of("t", "error", "code", code))));
    }
}
