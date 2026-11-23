package com.ibme.funedu.server.room;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.auth.AuthFailedException;
import com.ibme.funedu.server.auth.AuthService;
import java.util.Map;
import java.util.UUID;
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

    private static final String ROOM = "room";
    private static final String FAMILY = "family";
    private static final String SAFE = "safe";

    private final RoomRegistry rooms;
    private final AuthService auth;
    private final ObjectMapper json;

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
        try {
            session.getAttributes().put(FAMILY, auth.currentParent(token.getToken()).familyId());
        } catch (AuthFailedException e) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        // Rooms send from several threads; the decorator serialises sends.
        session.getAttributes().put(SAFE, new ConcurrentWebSocketSessionDecorator(session, 2000, 64 * 1024));
    }

    @Override
    protected void handleTextMessage(WebSocketSession raw, TextMessage message) throws Exception {
        WebSocketSession session = safe(raw);
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
            case "start" -> room.start(session, now);
            case "step" -> room.step(session, m.path("n").asInt(-1), now);
            case "sticker" -> room.sticker(session, m.path("id").asText(""), now);
            case "again" -> room.again(session, now);
            case "leave" -> room.leave(session, now);
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
        String err = room == null ? "not_found" : room.join(session, family,
                m.path("kid").asText(null), m.path("name").asText(null),
                m.path("avatar").asText(null), m.path("rocket").asText(null), rooms.now());
        if (err != null) {
            if ("not_found".equals(err)) rooms.failedJoin(family);
            error(session, err);
            session.close(CloseStatus.NORMAL);
            return;
        }
        raw.getAttributes().put(ROOM, room);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession raw, CloseStatus status) {
        Room room = (Room) raw.getAttributes().get(ROOM);
        if (room != null) room.disconnected(safe(raw), rooms.now());
    }

    private WebSocketSession safe(WebSocketSession raw) {
        Object s = raw.getAttributes().get(SAFE);
        return s instanceof WebSocketSession w ? w : raw;
    }

    private void error(WebSocketSession s, String code) throws Exception {
        if (s.isOpen()) s.sendMessage(new TextMessage(json.writeValueAsString(Map.of("t", "error", "code", code))));
    }
}
