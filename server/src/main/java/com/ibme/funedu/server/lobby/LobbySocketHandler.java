package com.ibme.funedu.server.lobby;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.auth.AuthFailedException;
import com.ibme.funedu.server.auth.AuthService;
import com.ibme.funedu.server.room.SocketSender;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.PongMessage;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;

/**
 * `/ws/lobby`, opened with the parent's bearer token for real-time friend
 * presence and race invites.
 */
@Component
public class LobbySocketHandler extends TextWebSocketHandler {

    private static final String FAMILY = "family";
    private static final String SAFE = "safe";
    private static final String REGISTERED = "registered";
    private static final String CLOSING = "closing";
    private static final String MSG_TIMES = "msgTimes";
    private static final String LAST_ACTIVITY = "lastActivity";

    private record SessionMeta(
            UUID family,
            WebSocketSession raw,
            WebSocketSession safe,
            AtomicReference<Instant> lastActivity) {}

    private final LobbyRegistry lobby;
    private final AuthService auth;
    private final ObjectMapper json;
    private final LobbyProperties props;
    private final ConcurrentHashMap<WebSocketSession, SessionMeta> activeSessions = new ConcurrentHashMap<>();

    public LobbySocketHandler(
            LobbyRegistry lobby, AuthService auth, ObjectMapper json, LobbyProperties props) {
        this.lobby = lobby;
        this.auth = auth;
        this.json = json;
        this.props = props;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        if (!(session.getPrincipal() instanceof JwtAuthenticationToken token)) {
            SocketSender.close(session, CloseStatus.POLICY_VIOLATION);
            return;
        }
        UUID family;
        try {
            family = auth.currentParent(token.getToken()).familyId();
        } catch (AuthFailedException e) {
            SocketSender.close(session, CloseStatus.POLICY_VIOLATION);
            return;
        }

        WebSocketSession safeSession = new ConcurrentWebSocketSessionDecorator(session, 2000, 64 * 1024);
        AtomicReference<Instant> lastActivity = new AtomicReference<>(lobby.now());
        session.getAttributes().put(FAMILY, family);
        session.getAttributes().put(SAFE, safeSession);
        session.getAttributes().put(CLOSING, new AtomicBoolean(false));
        session.getAttributes().put(MSG_TIMES, new ArrayDeque<Long>());
        session.getAttributes().put(LAST_ACTIVITY, lastActivity);
        session.getAttributes().put(REGISTERED, family);
        activeSessions.put(safeSession, new SessionMeta(family, session, safeSession, lastActivity));

        LobbyRegistry.RegisterStatus reg = lobby.register(family, safeSession, () -> isClosing(session));
        if (reg == LobbyRegistry.RegisterStatus.TOO_MANY) {
            markClosing(session);
            activeSessions.remove(safeSession);
            session.getAttributes().remove(REGISTERED);
            closeWithError(safeSession, "too_many", CloseStatus.POLICY_VIOLATION);
        } else if (reg == LobbyRegistry.RegisterStatus.CLOSED_EARLY) {
            markClosing(session);
            activeSessions.remove(safeSession);
            session.getAttributes().remove(REGISTERED);
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession raw, TextMessage message) {
        if (isClosing(raw)) return;
        WebSocketSession session = safe(raw);
        touchActivity(raw);
        if (!allowMessageRate(raw)) {
            markClosing(raw);
            closeWithError(session, "too_many", CloseStatus.POLICY_VIOLATION);
            return;
        }
        if (message.getPayloadLength() > 2048) {
            lobby.sendError(session, "bad_message");
            return;
        }
        JsonNode m;
        try {
            m = json.readTree(message.getPayload());
        } catch (Exception e) {
            lobby.sendError(session, "bad_message");
            return;
        }
        if (m == null || !m.isObject()) {
            lobby.sendError(session, "bad_message");
            return;
        }
        UUID family = (UUID) raw.getAttributes().get(FAMILY);
        if (family == null) {
            markClosing(raw);
            SocketSender.close(session, CloseStatus.POLICY_VIOLATION);
            return;
        }
        String type = m.path("t").asText("");
        switch (type) {
            case "ping" -> lobby.sendToSession(session, Map.of("t", "pong"));
            case "invite" -> lobby.createInvite(family, session, m);
            case "invite_reply" -> lobby.replyInvite(family, session, m);
            default -> lobby.sendError(session, "bad_message");
        }
    }

    @Override
    protected void handlePongMessage(WebSocketSession session, PongMessage message) {
        touchActivity(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession raw, CloseStatus status) {
        markClosing(raw);
        WebSocketSession safeSession = safe(raw);
        activeSessions.remove(safeSession);
        Object registered = raw.getAttributes().remove(REGISTERED);
        if (registered instanceof UUID family) {
            lobby.unregister(family, safeSession);
        }
        SocketSender.forget(safeSession);
        SocketSender.forget(raw);
    }

    @Scheduled(fixedDelay = 5000)
    void sweepIdleSessions() {
        sweepIdleSessions(lobby.now());
    }

    void sweepIdleSessions(Instant now) {
        Instant cutoff = now.minus(props.idleTimeout());
        List<SessionMeta> expired = new ArrayList<>();
        for (SessionMeta meta : activeSessions.values()) {
            if (meta.lastActivity().get().isBefore(cutoff)) {
                expired.add(meta);
            }
        }
        for (SessionMeta meta : expired) {
            markClosing(meta.raw());
            activeSessions.remove(meta.safe());
            Object registered = meta.raw().getAttributes().remove(REGISTERED);
            if (registered instanceof UUID family) {
                lobby.unregister(family, meta.safe());
            }
            SocketSender.close(meta.safe(), CloseStatus.NORMAL);
        }
    }

    @SuppressWarnings("unchecked")
    private void touchActivity(WebSocketSession raw) {
        Object attr = raw.getAttributes().get(LAST_ACTIVITY);
        if (attr instanceof AtomicReference<?> ref) {
            ((AtomicReference<Instant>) ref).set(lobby.now());
        }
    }

    @SuppressWarnings("unchecked")
    private boolean allowMessageRate(WebSocketSession raw) {
        Object attr = raw.getAttributes().get(MSG_TIMES);
        if (!(attr instanceof Deque<?>)) return true;
        Deque<Long> times = (Deque<Long>) attr;
        synchronized (times) {
            long now = lobby.now().toEpochMilli();
            long cutoff = now - 1000L;
            while (!times.isEmpty() && times.peekFirst() <= cutoff) {
                times.removeFirst();
            }
            if (times.size() >= props.maxMessagesPerSecond()) {
                return false;
            }
            times.addLast(now);
            return true;
        }
    }

    private boolean isClosing(WebSocketSession raw) {
        return raw.getAttributes().get(CLOSING) instanceof AtomicBoolean b && b.get();
    }

    private void markClosing(WebSocketSession raw) {
        if (raw.getAttributes().get(CLOSING) instanceof AtomicBoolean b) {
            b.set(true);
        }
    }

    private WebSocketSession safe(WebSocketSession raw) {
        Object s = raw.getAttributes().get(SAFE);
        return s instanceof WebSocketSession w ? w : raw;
    }

    private void closeWithError(WebSocketSession s, String code, CloseStatus status) {
        lobby.sendError(s, code);
        SocketSender.close(s, status);
    }
}
