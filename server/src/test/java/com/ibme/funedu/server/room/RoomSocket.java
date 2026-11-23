package com.ibme.funedu.server.room;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.function.Predicate;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.handler.TextWebSocketHandler;

/** A test client for /ws/room that records every message it receives. */
public class RoomSocket extends TextWebSocketHandler implements AutoCloseable {

    static final ObjectMapper JSON = new ObjectMapper();

    public final BlockingQueue<Map<String, Object>> inbox = new LinkedBlockingQueue<>();
    public volatile CloseStatus closed;
    WebSocketSession session;

    public static RoomSocket open(int port, String code, String accessToken) throws Exception {
        RoomSocket s = new RoomSocket();
        var headers = new WebSocketHttpHeaders();
        if (accessToken != null) headers.setBearerAuth(accessToken);
        s.session = new StandardWebSocketClient()
                .execute(s, headers, URI.create("ws://localhost:" + port + "/ws/room?code=" + code))
                .get(5, TimeUnit.SECONDS);
        return s;
    }

    public void send(Map<String, Object> msg) throws Exception {
        session.sendMessage(new TextMessage(JSON.writeValueAsString(msg)));
    }

    public void join(String kid, String name) throws Exception {
        send(Map.of("t", "join", "kid", kid, "name", name,
                "avatar", "assets/images/avatar_cat.png", "rocket", "rocket_blue"));
    }

    /** Waits for the first message matching [match], skipping others. */
    @SuppressWarnings("unchecked")
    public Map<String, Object> await(Predicate<Map<String, Object>> match) throws Exception {
        long end = System.currentTimeMillis() + 5000;
        while (System.currentTimeMillis() < end) {
            Map<String, Object> m = inbox.poll(100, TimeUnit.MILLISECONDS);
            if (m != null && match.test(m)) return m;
        }
        throw new AssertionError("no matching message; closed=" + closed);
    }

    public Map<String, Object> awaitRoom(Predicate<Map<String, Object>> match) throws Exception {
        return await(m -> "room".equals(m.get("t")) && match.test(m));
    }

    public CloseStatus awaitClosed() throws Exception {
        long end = System.currentTimeMillis() + 3000;
        while (closed == null && System.currentTimeMillis() < end) {
            Thread.sleep(20);
        }
        if (closed == null) {
            throw new AssertionError("room socket was not closed");
        }
        return closed;
    }

    @SuppressWarnings("unchecked")
    public static java.util.List<Map<String, Object>> players(Map<String, Object> room) {
        return (java.util.List<Map<String, Object>>) room.get("players");
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void handleTextMessage(WebSocketSession s, TextMessage message) throws Exception {
        inbox.add(JSON.readValue(message.getPayload(), Map.class));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession s, CloseStatus status) {
        closed = status;
    }

    @Override
    public void close() throws Exception {
        if (session != null && session.isOpen()) session.close();
    }
}
