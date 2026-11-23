package com.ibme.funedu.server.lobby;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibme.funedu.server.friends.FriendService;
import com.ibme.funedu.server.friends.LobbyNotifier;
import com.ibme.funedu.server.friends.PresenceView;
import com.ibme.funedu.server.friends.SyncKidRecords;
import com.ibme.funedu.server.room.RoomRegistry;
import com.ibme.funedu.server.room.SocketSender;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.BooleanSupplier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.WebSocketSession;

/**
 * In-memory lobby presence and real-time race invites for friend families.
 * Each online family holds a {@link FamilyEntry} combining its open sessions
 * and cached friend set; SQL and WebSocket I/O always run outside locks.
 */
@Component
public class LobbyRegistry implements PresenceView, LobbyNotifier {

    enum RegisterStatus { OK, TOO_MANY, CLOSED_EARLY }

    private static final String FALLBACK_NICKNAME = "Bạn đua";

    private record PairKey(UUID first, UUID second) {
        static PairKey of(UUID a, UUID b) {
            UUID[] ordered = FriendService.orderedPair(a, b);
            return new PairKey(ordered[0], ordered[1]);
        }
    }

    private record Invite(
            String id,
            PairKey pair,
            UUID fromFamily,
            UUID toFamily,
            String roomCode,
            String kidUuid,
            Instant expiresAt) {}

    private record KidInfo(String nickname, String avatar) {}

    private record FriendDelta(boolean added, UUID peer) {}

    private static final class FamilyEntry {
        final Set<WebSocketSession> sessions = ConcurrentHashMap.newKeySet();
        Set<UUID> friends;
        boolean loading;
        boolean announcedOnline;
        CompletableFuture<Void> loadFuture;
        final List<FriendDelta> pendingDeltas = new ArrayList<>();
    }

    private final ConcurrentHashMap<UUID, FamilyEntry> families = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Invite> invites = new ConcurrentHashMap<>();
    private final ReentrantLock inviteLock = new ReentrantLock();

    private final JdbcTemplate jdbc;
    private final ObjectMapper json;
    private final RoomRegistry rooms;
    private final LobbyProperties props;
    private final Clock clock;

    public LobbyRegistry(JdbcTemplate jdbc, ObjectMapper json, RoomRegistry rooms, LobbyProperties props) {
        this.jdbc = jdbc;
        this.json = json;
        this.rooms = rooms;
        this.props = props;
        this.clock = Clock.systemUTC();
    }

    Instant now() {
        return clock.instant();
    }

    @Override
    public boolean isOnline(UUID familyId) {
        if (familyId == null) return false;
        FamilyEntry entry = families.get(familyId);
        if (entry == null || entry.sessions.isEmpty()) return false;
        for (WebSocketSession s : entry.sessions) {
            if (s.isOpen()) return true;
        }
        return false;
    }

    @Override
    public void notify(UUID familyId, Map<String, Object> message) {
        if (familyId == null || message == null) return;
        FamilyEntry entry = families.get(familyId);
        if (entry == null || entry.sessions.isEmpty()) return;
        notifySerialized(familyId, serialize(message));
    }

    @Override
    public void friendAdded(UUID familyA, UUID familyB) {
        if (familyA == null || familyB == null || familyA.equals(familyB)) return;
        applyFriendDelta(familyA, familyB, true);
        applyFriendDelta(familyB, familyA, true);

        boolean aOnline = isOnline(familyA);
        boolean bOnline = isOnline(familyB);
        if (aOnline) {
            notify(familyA, Map.of("t", "friend_added", "familyId", familyB.toString()));
            if (bOnline) {
                notify(familyA, Map.of("t", "presence", "familyId", familyB.toString(), "online", true));
            }
        }
        if (bOnline) {
            notify(familyB, Map.of("t", "friend_added", "familyId", familyA.toString()));
            if (aOnline) {
                notify(familyB, Map.of("t", "presence", "familyId", familyA.toString(), "online", true));
            }
        }
    }

    @Override
    public void friendRemoved(UUID familyA, UUID familyB) {
        if (familyA == null || familyB == null || familyA.equals(familyB)) return;
        applyFriendDelta(familyA, familyB, false);
        applyFriendDelta(familyB, familyA, false);

        PairKey pair = PairKey.of(familyA, familyB);
        List<Invite> cancelled = new ArrayList<>();
        inviteLock.lock();
        try {
            var it = invites.values().iterator();
            while (it.hasNext()) {
                Invite inv = it.next();
                if (inv.pair().equals(pair)) {
                    it.remove();
                    cancelled.add(inv);
                }
            }
        } finally {
            inviteLock.unlock();
        }
        for (Invite inv : cancelled) {
            notify(inv.toFamily(), Map.of("t", "invite_cancelled", "inviteId", inv.id()));
        }

        if (isOnline(familyA)) {
            notify(familyA, Map.of("t", "friend_removed", "familyId", familyB.toString()));
        }
        if (isOnline(familyB)) {
            notify(familyB, Map.of("t", "friend_removed", "familyId", familyA.toString()));
        }
    }

    @Override
    public void familyDeleted(UUID familyId) {
        if (familyId == null) return;
        AtomicReference<List<WebSocketSession>> toClose = new AtomicReference<>();
        families.computeIfPresent(familyId, (k, entry) -> {
            toClose.set(List.copyOf(entry.sessions));
            return null;
        });

        List<Invite> cancelled = new ArrayList<>();
        inviteLock.lock();
        try {
            var it = invites.values().iterator();
            while (it.hasNext()) {
                Invite inv = it.next();
                if (inv.fromFamily().equals(familyId) || inv.toFamily().equals(familyId)) {
                    it.remove();
                    cancelled.add(inv);
                }
            }
        } finally {
            inviteLock.unlock();
        }
        for (Invite inv : cancelled) {
            if (!inv.toFamily().equals(familyId)) {
                notify(inv.toFamily(), Map.of("t", "invite_cancelled", "inviteId", inv.id()));
            }
        }

        List<WebSocketSession> sessions = toClose.get();
        if (sessions != null) {
            for (WebSocketSession s : sessions) {
                SocketSender.close(s, CloseStatus.NORMAL);
            }
        }
    }

    RegisterStatus register(UUID family, WebSocketSession safeSession, BooleanSupplier isClosing) {
        AtomicReference<RegisterStatus> status = new AtomicReference<>(RegisterStatus.OK);
        AtomicReference<FamilyEntry> entryRef = new AtomicReference<>();
        AtomicBoolean needLoad = new AtomicBoolean(false);
        AtomicReference<CompletableFuture<Void>> waitFuture = new AtomicReference<>();

        families.compute(family, (k, existing) -> {
            if (isClosing.getAsBoolean() || !safeSession.isOpen()) {
                status.set(RegisterStatus.CLOSED_EARLY);
                return existing;
            }
            FamilyEntry entry = existing != null ? existing : new FamilyEntry();
            if (entry.sessions.size() >= props.maxConnectionsPerFamily()) {
                status.set(RegisterStatus.TOO_MANY);
                return existing;
            }
            entry.sessions.add(safeSession);
            if (entry.friends == null) {
                if (!entry.loading) {
                    entry.loading = true;
                    entry.loadFuture = new CompletableFuture<>();
                    needLoad.set(true);
                }
                waitFuture.set(entry.loadFuture);
            }
            entryRef.set(entry);
            return entry;
        });

        if (status.get() != RegisterStatus.OK) {
            return status.get();
        }

        FamilyEntry entry = entryRef.get();
        if (needLoad.get()) {
            try {
                List<UUID> dbFriends = queryFriends(family);
                families.computeIfPresent(family, (k, current) -> {
                    if (current != entry) return current;
                    Set<UUID> set = ConcurrentHashMap.newKeySet();
                    set.addAll(dbFriends);
                    for (FriendDelta delta : current.pendingDeltas) {
                        if (delta.added()) {
                            set.add(delta.peer());
                        } else {
                            set.remove(delta.peer());
                        }
                    }
                    current.pendingDeltas.clear();
                    current.friends = set;
                    current.loading = false;
                    if (isClosing.getAsBoolean() || !safeSession.isOpen()) {
                        current.sessions.remove(safeSession);
                    }
                    return current.sessions.isEmpty() ? null : current;
                });
            } catch (RuntimeException ex) {
                families.computeIfPresent(family, (k, current) -> {
                    if (current != entry) return current;
                    current.loading = false;
                    current.pendingDeltas.clear();
                    current.sessions.remove(safeSession);
                    return current.sessions.isEmpty() ? null : current;
                });
                entry.loadFuture.completeExceptionally(ex);
                throw ex;
            }
            entry.loadFuture.complete(null);
        } else if (waitFuture.get() != null) {
            waitFuture.get().join();
        }

        AtomicBoolean stillPresent = new AtomicBoolean(false);
        AtomicBoolean aborted = new AtomicBoolean(false);
        AtomicBoolean announceOnline = new AtomicBoolean(false);
        AtomicReference<Set<UUID>> friendsSnapshot = new AtomicReference<>(Set.of());

        families.computeIfPresent(family, (k, current) -> {
            stillPresent.set(true);
            if (current != entry || isClosing.getAsBoolean() || !safeSession.isOpen()) {
                aborted.set(true);
                if (current == entry) {
                    current.sessions.remove(safeSession);
                    return current.sessions.isEmpty() ? null : current;
                }
                return current;
            }
            friendsSnapshot.set(current.friends != null ? Set.copyOf(current.friends) : Set.of());
            if (!current.announcedOnline) {
                current.announcedOnline = true;
                announceOnline.set(true);
            }
            return current;
        });

        if (!stillPresent.get() || aborted.get()) {
            return RegisterStatus.CLOSED_EARLY;
        }

        Set<UUID> friends = friendsSnapshot.get();
        List<String> friendsOnline = new ArrayList<>();
        for (UUID f : friends) {
            if (isOnline(f)) {
                friendsOnline.add(f.toString());
            }
        }
        SocketSender.send(safeSession, serialize(Map.of("t", "hello", "friendsOnline", friendsOnline)));

        if (announceOnline.get() && !friends.isEmpty()) {
            String presenceJson = serialize(Map.of(
                    "t", "presence",
                    "familyId", family.toString(),
                    "online", true));
            for (UUID friendId : friends) {
                notifySerialized(friendId, presenceJson);
            }
        }
        return RegisterStatus.OK;
    }

    /** Unregisters a lobby session; notifies online friends only when the last session closes. */
    void unregister(UUID family, WebSocketSession safeSession) {
        if (family == null || safeSession == null) return;
        AtomicReference<Set<UUID>> offlineFriends = new AtomicReference<>();

        families.computeIfPresent(family, (k, entry) -> {
            if (!entry.sessions.remove(safeSession)) {
                return entry;
            }
            if (entry.sessions.isEmpty()) {
                if (entry.announcedOnline && entry.friends != null) {
                    offlineFriends.set(Set.copyOf(entry.friends));
                }
                return null;
            }
            return entry;
        });

        Set<UUID> friends = offlineFriends.get();
        if (friends != null && !friends.isEmpty()) {
            String presenceJson = serialize(Map.of(
                    "t", "presence",
                    "familyId", family.toString(),
                    "online", false));
            for (UUID friendId : friends) {
                notifySerialized(friendId, presenceJson);
            }
        }
    }

    void createInvite(UUID callerFamily, WebSocketSession callerSession, JsonNode m) {
        JsonNode toNode = m.path("toFamilyId");
        JsonNode codeNode = m.path("roomCode");
        JsonNode kidNode = m.path("kidUuid");
        if (!toNode.isTextual() || !codeNode.isTextual() || !kidNode.isTextual()) {
            sendError(callerSession, "bad_message");
            return;
        }
        String toRaw = toNode.asText();
        String rawCode = codeNode.asText();
        String kidUuid = kidNode.asText();
        if (hasControlChars(toRaw) || hasControlChars(rawCode) || hasControlChars(kidUuid)) {
            sendError(callerSession, "bad_message");
            return;
        }

        UUID toFamily;
        try {
            toFamily = UUID.fromString(toRaw);
        } catch (IllegalArgumentException e) {
            toFamily = null;
        }
        if (toFamily == null
                || toFamily.equals(callerFamily)
                || rawCode.isBlank() || rawCode.length() > 16
                || kidUuid.isBlank() || kidUuid.length() > 64) {
            sendError(callerSession, "bad_message");
            return;
        }
        String roomCode = rawCode.trim().toUpperCase(Locale.ROOT);
        PairKey pair = PairKey.of(callerFamily, toFamily);

        if (!isFriend(callerFamily, toFamily)) {
            sendError(callerSession, "not_friends");
            return;
        }
        if (!isOnline(toFamily)) {
            sendError(callerSession, "friend_offline");
            return;
        }
        if (!rooms.isFamilyInRoom(roomCode, callerFamily)) {
            sendError(callerSession, "not_in_room");
            return;
        }

        Instant now = now();
        if (hasLivePendingInvite(pair, now)) {
            sendError(callerSession, "invite_pending");
            return;
        }

        KidInfo kid = resolveKidInfo(callerFamily, kidUuid);

        Invite expiredExisting = null;
        Invite created = null;
        String errorCode = null;
        Instant commitNow = now();
        inviteLock.lock();
        try {
            if (!isFriend(callerFamily, toFamily)) {
                errorCode = "not_friends";
            } else if (!isOnline(toFamily)) {
                errorCode = "friend_offline";
            } else if (!rooms.isFamilyInRoom(roomCode, callerFamily)) {
                errorCode = "not_in_room";
            } else {
                var it = invites.values().iterator();
                while (it.hasNext()) {
                    Invite existing = it.next();
                    if (existing.pair().equals(pair)) {
                        if (existing.expiresAt().isAfter(commitNow)) {
                            errorCode = "invite_pending";
                            break;
                        } else {
                            it.remove();
                            expiredExisting = existing;
                        }
                    }
                }
                if (errorCode == null) {
                    String id = UUID.randomUUID().toString();
                    created = new Invite(
                            id, pair, callerFamily, toFamily, roomCode, kidUuid, commitNow.plus(props.inviteTtl()));
                    invites.put(id, created);
                }
            }
        } finally {
            inviteLock.unlock();
        }

        if (expiredExisting != null) {
            notify(expiredExisting.toFamily(), Map.of("t", "invite_cancelled", "inviteId", expiredExisting.id()));
        }
        if (errorCode != null) {
            sendError(callerSession, errorCode);
            return;
        }

        // Re-check friendship & online status before notifying to close concurrent friendRemoved TOCTOU.
        String abortError = null;
        if (!isFriend(callerFamily, toFamily)) {
            abortError = "not_friends";
        } else if (!isOnline(toFamily)) {
            abortError = "friend_offline";
        }
        if (abortError != null) {
            inviteLock.lock();
            try {
                invites.remove(created.id(), created);
            } finally {
                inviteLock.unlock();
            }
            sendError(callerSession, abortError);
            return;
        }

        Map<String, Object> from = Map.of(
                "familyId", callerFamily.toString(),
                "kidUuid", kidUuid,
                "nickname", kid.nickname(),
                "avatar", kid.avatar());
        notify(toFamily, Map.of(
                "t", "invite",
                "inviteId", created.id(),
                "from", from,
                "roomCode", roomCode,
                "expiresInMs", props.inviteTtl().toMillis()));
    }

    void replyInvite(UUID callerFamily, WebSocketSession callerSession, JsonNode m) {
        JsonNode idNode = m.path("inviteId");
        JsonNode acceptNode = m.path("accept");
        if (!idNode.isTextual() || !acceptNode.isBoolean()) {
            sendError(callerSession, "bad_message");
            return;
        }
        String inviteId = idNode.asText();
        if (inviteId.isBlank() || inviteId.length() > 64 || hasControlChars(inviteId)) {
            sendError(callerSession, "bad_message");
            return;
        }
        boolean accept = acceptNode.asBoolean();
        Instant now = now();
        Invite removed = null;
        inviteLock.lock();
        try {
            Invite existing = invites.get(inviteId);
            if (existing != null && existing.toFamily().equals(callerFamily)) {
                invites.remove(inviteId);
                removed = existing;
            }
        } finally {
            inviteLock.unlock();
        }
        if (removed == null) {
            return;
        }
        if (!removed.expiresAt().isAfter(now)) {
            notify(callerFamily, Map.of("t", "invite_cancelled", "inviteId", inviteId));
            return;
        }
        notify(removed.fromFamily(), Map.of("t", "invite_reply", "inviteId", inviteId, "accept", accept));
    }

    @Scheduled(fixedDelay = 1000)
    void purgeExpiredInvites() {
        purgeExpiredInvites(now());
    }

    void purgeExpiredInvites(Instant now) {
        List<Invite> expired = new ArrayList<>();
        inviteLock.lock();
        try {
            var it = invites.values().iterator();
            while (it.hasNext()) {
                Invite inv = it.next();
                if (!inv.expiresAt().isAfter(now)) {
                    it.remove();
                    expired.add(inv);
                }
            }
        } finally {
            inviteLock.unlock();
        }
        for (Invite inv : expired) {
            notify(inv.toFamily(), Map.of("t", "invite_cancelled", "inviteId", inv.id()));
        }
    }

    void sendError(WebSocketSession session, String code) {
        SocketSender.send(session, serialize(Map.of("t", "error", "code", code)));
    }

    void sendToSession(WebSocketSession session, Map<String, Object> message) {
        SocketSender.send(session, serialize(message));
    }

    private void applyFriendDelta(UUID owner, UUID peer, boolean added) {
        families.computeIfPresent(owner, (k, entry) -> {
            if (entry.friends != null) {
                if (added) {
                    entry.friends.add(peer);
                } else {
                    entry.friends.remove(peer);
                }
            } else if (entry.loading) {
                entry.pendingDeltas.add(new FriendDelta(added, peer));
            }
            return entry;
        });
    }

    private boolean isFriend(UUID owner, UUID candidate) {
        FamilyEntry entry = families.get(owner);
        if (entry == null) return false;
        Set<UUID> friends = entry.friends;
        return friends != null && friends.contains(candidate);
    }

    private boolean hasLivePendingInvite(PairKey pair, Instant now) {
        inviteLock.lock();
        try {
            for (Invite inv : invites.values()) {
                if (inv.pair().equals(pair) && inv.expiresAt().isAfter(now)) {
                    return true;
                }
            }
            return false;
        } finally {
            inviteLock.unlock();
        }
    }

    private List<UUID> queryFriends(UUID family) {
        return jdbc.query("""
                SELECT CASE WHEN family_a = ? THEN family_b ELSE family_a END
                FROM friendships
                WHERE family_a = ? OR family_b = ?
                """,
                (rs, i) -> rs.getObject(1, UUID.class),
                family, family, family);
    }

    private KidInfo resolveKidInfo(UUID familyId, String kidUuid) {
        SyncKidRecords.FamilyRecords recs =
                SyncKidRecords.load(jdbc, json, List.of(familyId), false).get(familyId);
        String nickname = null;
        String avatar = "";
        if (recs != null) {
            nickname = recs.raceNicknames.get(kidUuid);
            for (SyncKidRecords.KidRecord k : recs.kids) {
                if (kidUuid.equals(k.kidUuid())) {
                    if (nickname == null || nickname.isBlank()) {
                        nickname = k.nickname();
                    }
                    if (k.avatar() != null) {
                        avatar = k.avatar();
                    }
                    break;
                }
            }
        }
        if (nickname == null || nickname.isBlank()) {
            nickname = FALLBACK_NICKNAME;
        }
        return new KidInfo(nickname, avatar);
    }

    private void notifySerialized(UUID familyId, String payload) {
        FamilyEntry entry = families.get(familyId);
        if (entry == null || entry.sessions.isEmpty()) return;
        for (WebSocketSession s : entry.sessions) {
            if (s.isOpen()) {
                SocketSender.send(s, payload);
            }
        }
    }

    private static boolean hasControlChars(String s) {
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c < 0x20 || c == 0x7F) {
                return true;
            }
        }
        return false;
    }

    private String serialize(Object message) {
        try {
            return json.writeValueAsString(message);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }
}
