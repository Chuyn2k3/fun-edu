// Lobby state and the events the lobby client emits.
part of 'lobby_client.dart';

/// An incoming race invite from a friend family.
@immutable
class LobbyInvite {
  const LobbyInvite({
    required this.inviteId,
    required this.fromFamilyId,
    required this.kidUuid,
    required this.nickname,
    required this.avatar,
    required this.roomCode,
    required this.expiresAt,
  });

  final String inviteId;
  final String fromFamilyId;
  final String kidUuid;
  final String nickname;
  final String avatar;
  final String roomCode;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LobbyInvite &&
          inviteId == other.inviteId &&
          fromFamilyId == other.fromFamilyId &&
          kidUuid == other.kidUuid &&
          nickname == other.nickname &&
          avatar == other.avatar &&
          roomCode == other.roomCode &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
        inviteId,
        fromFamilyId,
        kidUuid,
        nickname,
        avatar,
        roomCode,
        expiresAt,
      );
}

/// Reply sent back to the inviter for an outgoing invite.
@immutable
class LobbyInviteReplyEvent {
  const LobbyInviteReplyEvent({
    required this.inviteId,
    required this.accept,
    required this.seq,
  });

  final String inviteId;
  final bool accept;
  final int seq;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LobbyInviteReplyEvent &&
          inviteId == other.inviteId &&
          accept == other.accept &&
          seq == other.seq;

  @override
  int get hashCode => Object.hash(inviteId, accept, seq);
}

/// Real-time showcase reaction event pushed over `/ws/lobby`.
@immutable
class LobbyReactionEvent {
  const LobbyReactionEvent({
    required this.kidUuid,
    required this.kind,
    required this.fromNickname,
    required this.seq,
  });

  final String kidUuid;
  final String kind;
  final String fromNickname;
  final int seq;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LobbyReactionEvent &&
          kidUuid == other.kidUuid &&
          kind == other.kind &&
          fromNickname == other.fromNickname &&
          seq == other.seq;

  @override
  int get hashCode => Object.hash(kidUuid, kind, fromNickname, seq);
}

/// Friendship change pushed over `/ws/lobby`.
@immutable
class LobbyFriendEvent {
  const LobbyFriendEvent({
    required this.familyId,
    required this.added,
    required this.seq,
  });

  final String familyId;
  final bool added;
  final int seq;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LobbyFriendEvent &&
          familyId == other.familyId &&
          added == other.added &&
          seq == other.seq;

  @override
  int get hashCode => Object.hash(familyId, added, seq);
}

/// Server error pushed over `/ws/lobby`.
@immutable
class LobbyErrorEvent {
  const LobbyErrorEvent({
    required this.code,
    required this.seq,
  });

  final String code;
  final int seq;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LobbyErrorEvent && code == other.code && seq == other.seq;

  @override
  int get hashCode => Object.hash(code, seq);
}

/// Live lobby presence, pending invite, and sequence-tracked events.
@immutable
class LobbyState {
  const LobbyState({
    this.connected = false,
    this.onlineFriends = const {},
    this.pendingInvite,
    this.lastInviteReply,
    this.lastReaction,
    this.lastFriendEvent,
    this.lastError,
  });

  final bool connected;
  final Set<String> onlineFriends;
  final LobbyInvite? pendingInvite;
  final LobbyInviteReplyEvent? lastInviteReply;
  final LobbyReactionEvent? lastReaction;
  final LobbyFriendEvent? lastFriendEvent;
  final LobbyErrorEvent? lastError;

  LobbyState copyWith({
    bool? connected,
    Set<String>? onlineFriends,
    LobbyInvite? Function()? pendingInvite,
    LobbyInviteReplyEvent? lastInviteReply,
    LobbyReactionEvent? lastReaction,
    LobbyFriendEvent? lastFriendEvent,
    LobbyErrorEvent? lastError,
  }) =>
      LobbyState(
        connected: connected ?? this.connected,
        onlineFriends: onlineFriends ?? this.onlineFriends,
        pendingInvite:
            pendingInvite == null ? this.pendingInvite : pendingInvite(),
        lastInviteReply: lastInviteReply ?? this.lastInviteReply,
        lastReaction: lastReaction ?? this.lastReaction,
        lastFriendEvent: lastFriendEvent ?? this.lastFriendEvent,
        lastError: lastError ?? this.lastError,
      );
}
