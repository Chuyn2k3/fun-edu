package com.ibme.funedu.server.room;

import java.io.IOException;
import java.util.Queue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicBoolean;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.SessionLimitExceededException;

/**
 * Dispatches WebSocket sends and closes outside any domain lock on virtual
 * threads so one slow or blocked client never stalls rooms, lobby, or ticks.
 */
public final class SocketSender {

    private static final long BLOCKED_SEND_THRESHOLD_NS = 25_000_000L;
    private static final ConcurrentHashMap<WebSocketSession, SessionQueue> SESSION_QUEUES =
            new ConcurrentHashMap<>();

    private SocketSender() {}

    public static void send(WebSocketSession session, String text) {
        if (session == null || text == null || !session.isOpen()) return;
        queueFor(session).submit(new Action.Send(session, text));
    }

    public static void close(WebSocketSession session) {
        close(session, CloseStatus.NORMAL);
    }

    public static void close(WebSocketSession session, CloseStatus status) {
        if (session == null || !session.isOpen()) return;
        queueFor(session).submit(new Action.Close(session, status != null ? status : CloseStatus.NORMAL));
    }

    public static void forget(WebSocketSession session) {
        if (session != null) {
            SESSION_QUEUES.remove(session);
        }
    }

    public static void closeQuietly(WebSocketSession session) {
        closeQuietly(session, CloseStatus.NORMAL);
    }

    public static void closeQuietly(WebSocketSession session, CloseStatus status) {
        try {
            if (session != null && session.isOpen()) {
                session.close(status);
            }
        } catch (IOException | IllegalStateException ignored) {
            // Already gone.
        }
    }

    private static SessionQueue queueFor(WebSocketSession session) {
        return SESSION_QUEUES.computeIfAbsent(session, k -> new SessionQueue());
    }

    private sealed interface Action permits Action.Send, Action.Close {
        record Send(WebSocketSession session, String text) implements Action {}
        record Close(WebSocketSession session, CloseStatus status) implements Action {}
    }

    private static final class SessionQueue {
        private final Queue<Action> queue = new ConcurrentLinkedQueue<>();
        private final AtomicBoolean workerRunning = new AtomicBoolean(false);
        private volatile long sendStartedAtNanos;

        void submit(Action action) {
            long started = sendStartedAtNanos;
            if (started != 0 && System.nanoTime() - started > BLOCKED_SEND_THRESHOLD_NS) {
                // An earlier send is stuck in the underlying socket; invoke the decorator
                // directly on a virtual thread so its time/buffer limits trigger immediately.
                Thread.startVirtualThread(() -> execute(action));
                return;
            }
            queue.add(action);
            if (workerRunning.compareAndSet(false, true)) {
                Thread.startVirtualThread(this::drain);
            }
        }

        private void drain() {
            try {
                while (true) {
                    Action a;
                    while ((a = queue.poll()) != null) {
                        if (a instanceof Action.Send) {
                            sendStartedAtNanos = System.nanoTime();
                            try {
                                execute(a);
                            } finally {
                                sendStartedAtNanos = 0;
                            }
                        } else {
                            execute(a);
                        }
                    }
                    workerRunning.set(false);
                    if (queue.isEmpty() || !workerRunning.compareAndSet(false, true)) {
                        return;
                    }
                }
            } catch (Throwable t) {
                sendStartedAtNanos = 0;
                workerRunning.set(false);
            }
        }

        private static void execute(Action action) {
            if (action instanceof Action.Send s) {
                if (!s.session().isOpen()) {
                    SESSION_QUEUES.remove(s.session());
                    return;
                }
                try {
                    s.session().sendMessage(new TextMessage(s.text()));
                } catch (SessionLimitExceededException e) {
                    closeQuietly(s.session());
                    SESSION_QUEUES.remove(s.session());
                } catch (IOException | IllegalStateException e) {
                    // A broken or closed socket: drop queued reference and let close callback clean up.
                    SESSION_QUEUES.remove(s.session());
                }
            } else if (action instanceof Action.Close c) {
                closeQuietly(c.session(), c.status());
                SESSION_QUEUES.remove(c.session());
            }
        }
    }
}
