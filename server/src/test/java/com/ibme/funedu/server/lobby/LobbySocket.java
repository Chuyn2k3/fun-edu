package com.ibme.funedu.server.lobby;

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

/** A test client for /ws/lobby that records every message it receives. */
class LobbySocket extends TextWebSocketHandler implements AutoCloseable {

    static final ObjectMapper JSON = new ObjectMapper();

    final BlockingQueue<Map<String, Object>> inbox = new LinkedBlockingQueue<>();
    volatile CloseStatus closed;
    WebSocketSession session;

    static LobbySocket open(int port, String accessToken) throws Exception {
        LobbySocket s = new LobbySocket();
        var headers = new WebSocketHttpHeaders();
        if (accessToken != null) headers.setBearerAuth(accessToken);
        s.session = new StandardWebSocketClient()
                .execute(s, headers, URI.create("ws://localhost:" + port + "/ws/lobby"))
                .get(5, TimeUnit.SECONDS);
        return s;
    }

    void send(Map<String, Object> msg) throws Exception {
        session.sendMessage(new TextMessage(JSON.writeValueAsString(msg)));
    }

    void sendRaw(String raw) throws Exception {
        session.sendMessage(new TextMessage(raw));
    }

    Map<String, Object> await(Predicate<Map<String, Object>> match) throws Exception {
        long end = System.currentTimeMillis() + 5000;
        while (System.currentTimeMillis() < end) {
            Map<String, Object> m = inbox.poll(50, TimeUnit.MILLISECONDS);
            if (m != null && match.test(m)) return m;
        }
        throw new AssertionError("no matching message; closed=" + closed);
    }

    void assertNoMessage(Predicate<Map<String, Object>> match, long waitMs) throws Exception {
        long end = System.currentTimeMillis() + waitMs;
        while (System.currentTimeMillis() < end) {
            Map<String, Object> m = inbox.poll(30, TimeUnit.MILLISECONDS);
            if (m != null && match.test(m)) {
                throw new AssertionError("unexpected message received: " + m);
            }
        }
    }

    CloseStatus awaitClosed() throws Exception {
        long end = System.currentTimeMillis() + 3000;
        while (closed == null && System.currentTimeMillis() < end) {
            Thread.sleep(20);
        }
        if (closed == null) {
            throw new AssertionError("socket was not closed");
        }
        return closed;
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
