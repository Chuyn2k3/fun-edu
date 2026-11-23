package com.ibme.funedu.server.room;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Live rooms, in memory: rooms last minutes and one server instance is
 * enough for this app, so nothing about them is stored in the database.
 */
@Component
public class RoomRegistry {

    /** No 0/O or 1/I: a parent reads the code out loud or types it. */
    static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    public static class TooManyRooms extends RuntimeException {
        TooManyRooms() {
            super(null, null, false, false);
        }
    }

    private record Counter(long window, AtomicInteger count) {}

    private final Map<String, Room> rooms = new ConcurrentHashMap<>();
    private final Map<UUID, Counter> creates = new ConcurrentHashMap<>();
    private final Map<UUID, Counter> failedJoins = new ConcurrentHashMap<>();
    private final RoomProperties props;
    private final ObjectMapper json;
    private final Clock clock;
    private final SecureRandom random = new SecureRandom();

    public RoomRegistry(RoomProperties props, ObjectMapper json) {
        this.props = props;
        this.json = json;
        this.clock = Clock.systemUTC();
    }

    Instant now() {
        return clock.instant();
    }

    public Room create(UUID family) {
        if (!allow(creates, family, 3_600_000, props.createsPerHour())) throw new TooManyRooms();
        while (true) {
            StringBuilder code = new StringBuilder();
            for (int i = 0; i < 6; i++) code.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
            Room room = new Room(code.toString(), family, now(), props, this::write);
            if (rooms.putIfAbsent(room.code, room) == null) return room;
        }
    }

    Room find(String code) {
        return code == null ? null : rooms.get(code.toUpperCase(java.util.Locale.ROOT));
    }

    public boolean isFamilyInRoom(String code, UUID family) {
        if (code == null || family == null) return false;
        Room r = find(code);
        return r != null && r.hasActiveFamily(family);
    }

    /** Guessing codes: each family may miss only a few times a minute. */
    boolean mayTryJoin(UUID family) {
        Counter c = failedJoins.get(family);
        long minute = System.currentTimeMillis() / 60_000;
        return c == null || c.window() != minute || c.count().get() < props.failedJoinsPerMinute();
    }

    void failedJoin(UUID family) {
        allow(failedJoins, family, 60_000, Integer.MAX_VALUE);
    }

    @Scheduled(fixedDelay = 100)
    void tick() {
        Instant now = now();
        List<Room.Outbox> outboxes = new ArrayList<>();
        var it = rooms.values().iterator();
        while (it.hasNext()) {
            Room r = it.next();
            Room.TickResult res = r.tick(now);
            if (!res.outbox().isEmpty()) outboxes.add(res.outbox());
            if (!res.alive()) {
                it.remove();
            } else {
                Room.Outbox flushed = r.flush(now);
                if (!flushed.isEmpty()) outboxes.add(flushed);
            }
        }
        for (Room.Outbox outbox : outboxes) {
            Room.deliver(outbox);
        }
        long hour = System.currentTimeMillis() / 3_600_000;
        creates.values().removeIf(c -> c.window() != hour);
        long minute = System.currentTimeMillis() / 60_000;
        failedJoins.values().removeIf(c -> c.window() != minute);
    }

    private static boolean allow(Map<UUID, Counter> map, UUID family, long windowMs, int limit) {
        long w = System.currentTimeMillis() / windowMs;
        Counter c = map.compute(family,
                (k, old) -> old == null || old.window() != w ? new Counter(w, new AtomicInteger()) : old);
        return c.count().incrementAndGet() <= limit;
    }

    private String write(Object msg) {
        try {
            return json.writeValueAsString(msg);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }
}
