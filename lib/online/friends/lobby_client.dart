import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../net/network_status.dart';
import '../online_config.dart';
import '../room/room_transport.dart';

/// Opens an authenticated WebSocket connection to `/ws/lobby`.
typedef LobbyConnector = Future<RoomTransport> Function(String accessToken);

class _IoLobbyTransport implements RoomTransport {
  _IoLobbyTransport(this._socket)
      : messages = _socket
            .where((m) => m is String)
            .map((m) {
              try {
                return jsonDecode(m as String);
              } on FormatException {
                return null;
              }
            })
            .where((m) => m is Map<String, Object?>)
            .cast<Map<String, Object?>>()
            .asBroadcastStream();

  final WebSocket _socket;

  @override
  final Stream<Map<String, Object?>> messages;

  @override
  void send(Map<String, Object?> message) {
    if (_socket.readyState == WebSocket.open) {
      _socket.add(jsonEncode(message));
    }
  }

  @override
  Future<void> close() => _socket.close();
}

/// Silent transport used by default under `flutter test` when a test boots
/// [App] without overriding [lobbyConnectorProvider].
class _NoopLobbyTransport implements RoomTransport {
  final _in = StreamController<Map<String, Object?>>.broadcast();

  @override
  Stream<Map<String, Object?>> get messages => _in.stream;

  @override
  void send(Map<String, Object?> message) {}

  @override
  Future<void> close() async {
    if (!_in.isClosed) {
      await _in.close();
    }
  }
}

/// `https://api.x` -> `wss://api.x/ws/lobby`.
Uri lobbySocketUri(OnlineConfig config) {
  final base = Uri.parse(config.apiUrl);
  return base.replace(
    scheme: base.scheme == 'https' ? 'wss' : 'ws',
    path: '${base.path}/ws/lobby',
    queryParameters: null,
  );
}

final lobbyConnectorProvider = Provider<LobbyConnector>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return (_) async => _NoopLobbyTransport();
  }
  final config = ref.watch(onlineConfigProvider);
  return (token) async {
    final socket = await WebSocket.connect(
      lobbySocketUri(config).toString(),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
    socket.pingInterval = const Duration(seconds: 15);
    return _IoLobbyTransport(socket);
  };
});

/// Clock used for invite expiry checks (tests override for deterministic time).
final lobbyClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Heartbeat interval for `/ws/lobby` pings.
final lobbyPingIntervalProvider =
    Provider<Duration>((_) => const Duration(seconds: 25));

/// Grace period after leaving `/game*`, `/collection`, or `/parent*` before
/// closing `/ws/lobby`.
final lobbyLeaveDelayProvider =
    Provider<Duration>((_) => const Duration(seconds: 30));

/// Reconnect backoff schedule on unexpected socket drops.
final lobbyRetryDelaysProvider = Provider<List<Duration>>(
  (_) => const [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 6),
    Duration(seconds: 10),
  ],
);

/// Set to `true` while the kid is in an active race or lesson so incoming
/// invites queue quietly instead of interrupting.
final lobbyBusyProvider = StateProvider<bool>((_) => false);

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

/// Manages the `/ws/lobby` WebSocket connection, friend presence, invite queue,
/// and lobby events. Connects only while signed in, in the foreground, online,
/// and on (or within 30 s of leaving) `/game*`, `/collection`, or `/parent*`.
class LobbyClient extends Notifier<LobbyState> {
  RoomTransport? _socket;
  StreamSubscription<Map<String, Object?>>? _sub;
  StreamSubscription<void>? _maybeBackSub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _expiryTimer;
  Timer? _leaveTimer;

  bool _disposed = false;
  bool _foreground = true;
  bool _networkOffline = false;
  bool _routeEligible = false;
  bool _withinLeaveGrace = false;
  bool _routeBusy = false;
  bool _providerBusy = false;
  bool _connecting = false;
  int _connectGen = 0;
  int _retryAttempt = 0;

  int _inviteReplySeq = 0;
  int _reactionSeq = 0;
  int _friendSeq = 0;
  int _errorSeq = 0;
  DateTime? _lastPongAt;

  final List<LobbyInvite> _queuedInvites = [];

  final _inviteRepliesController =
      StreamController<LobbyInviteReplyEvent>.broadcast();
  final _reactionsController =
      StreamController<LobbyReactionEvent>.broadcast();
  final _friendEventsController =
      StreamController<LobbyFriendEvent>.broadcast();
  final _errorsController = StreamController<LobbyErrorEvent>.broadcast();

  /// Broadcast stream of replies to invites sent by this family.
  Stream<LobbyInviteReplyEvent> get inviteReplies =>
      _inviteRepliesController.stream;

  /// Broadcast stream of showcase reactions pushed over `/ws/lobby`.
  Stream<LobbyReactionEvent> get reactions => _reactionsController.stream;

  /// Broadcast stream of friendship add/remove notifications.
  Stream<LobbyFriendEvent> get friendEvents => _friendEventsController.stream;

  /// Broadcast stream of server error codes from `/ws/lobby`.
  Stream<LobbyErrorEvent> get errors => _errorsController.stream;

  /// Timestamp of the most recent `pong` heartbeat response, if any.
  DateTime? get lastPongAt => _lastPongAt;

  @visibleForTesting
  int get queuedInviteCount => _queuedInvites.length;

  DateTime Function() get _clock => ref.read(lobbyClockProvider);
  bool get _isBusy => _routeBusy || _providerBusy;

  bool get _shouldBeConnected {
    if (_disposed || !_foreground || _networkOffline) return false;
    if (!(_routeEligible || _withinLeaveGrace)) return false;
    if (!ref.read(onlineConfigProvider).enabled) return false;
    if (ref.read(sessionProvider).valueOrNull == null) return false;
    return true;
  }

  @override
  LobbyState build() {
    _disposed = false;
    _foreground = true;
    _routeEligible = false;
    _withinLeaveGrace = false;
    _routeBusy = false;
    _socket = null;
    _sub = null;
    _maybeBackSub = null;
    _pingTimer = null;
    _reconnectTimer = null;
    _expiryTimer = null;
    _leaveTimer = null;
    _connecting = false;
    _connectGen = 0;
    _retryAttempt = 0;
    _networkOffline = ref.read(networkStatusProvider) == NetState.offline;
    _queuedInvites.clear();

    ref.onDispose(() {
      _disposed = true;
      unawaited(_maybeBackSub?.cancel());
      _maybeBackSub = null;
      _disconnect(clearInvites: true);
      unawaited(_inviteRepliesController.close());
      unawaited(_reactionsController.close());
      unawaited(_friendEventsController.close());
      unawaited(_errorsController.close());
    });

    ref.listen(sessionProvider, (prev, next) {
      final prevFamily = prev?.valueOrNull?.familyId;
      final nextSession = next.valueOrNull;
      if (prev == null) {
        if (nextSession != null) {
          _scheduleConnectAfterBuild();
        }
        return;
      }
      if (nextSession == null) {
        _disconnect(clearInvites: true);
      } else if (prevFamily != null && prevFamily != nextSession.familyId) {
        _disconnect(clearInvites: true);
        _scheduleConnectAfterBuild();
      } else if (prevFamily == null) {
        _scheduleConnectAfterBuild();
      }
    }, fireImmediately: true);

    ref.listen<NetState>(networkStatusProvider, (prev, next) {
      if (next == NetState.offline) {
        _networkOffline = true;
        _disconnect();
      } else {
        _networkOffline = false;
        if (prev == NetState.offline) {
          _scheduleConnectAfterBuild();
        }
      }
    });

    _maybeBackSub =
        ref.read(networkStatusProvider.notifier).maybeBack.listen((_) {
      _networkOffline = false;
      _scheduleConnectAfterBuild();
    });

    ref.listen<OnlineConfig>(onlineConfigProvider, (_, next) {
      if (!next.enabled) {
        _disconnect(clearInvites: true);
      } else {
        _scheduleConnectAfterBuild();
      }
    });

    ref.listen<bool>(lobbyBusyProvider, (prev, next) {
      _providerBusy = next;
      if (prev != null && !next) {
        _flushQueueIfReady();
      }
    }, fireImmediately: true);

    return const LobbyState();
  }

  void _scheduleConnectAfterBuild() {
    Future.microtask(() {
      if (!_disposed && _shouldBeConnected) {
        unawaited(_connect());
      }
    });
  }

  /// Called when the app returns to the foreground (`AppLifecycleState.resumed`).
  void onAppResumed() {
    if (_disposed) return;
    _foreground = true;
    _purgeExpiredInvites();
    if (_shouldBeConnected) {
      unawaited(_connect());
    }
  }

  /// Called when the app leaves the foreground (`paused`/`hidden`/`detached`).
  void onAppPaused() {
    if (_disposed) return;
    _foreground = false;
    _withinLeaveGrace = false;
    _leaveTimer?.cancel();
    _leaveTimer = null;
    _disconnect();
  }

  /// Marks whether the current route can host a `/ws/lobby` connection
  /// (`/game*`, `/collection`, `/parent*`). Leaving starts a 30 s grace timer
  /// before closing the socket.
  void setRouteEligible(bool eligible) {
    if (_disposed || _routeEligible == eligible) return;
    _routeEligible = eligible;
    if (eligible) {
      _withinLeaveGrace = false;
      _leaveTimer?.cancel();
      _leaveTimer = null;
      if (_shouldBeConnected) {
        unawaited(_connect());
      }
    } else if (_socket != null || _connecting || _reconnectTimer != null) {
      _withinLeaveGrace = true;
      _leaveTimer?.cancel();
      _leaveTimer = Timer(ref.read(lobbyLeaveDelayProvider), () {
        _leaveTimer = null;
        if (_disposed || _routeEligible) return;
        _withinLeaveGrace = false;
        _disconnect(clearInvites: true);
      });
    } else {
      _withinLeaveGrace = false;
    }
  }

  /// Marks whether the currently active route or sleep lock defers incoming
  /// invite dialogs (e.g. active lesson, writing trace, race, or SleepScreen).
  void setRouteBusy(bool busy) {
    if (_disposed || _routeBusy == busy) return;
    _routeBusy = busy;
    if (!busy) {
      _flushQueueIfReady();
    }
  }

  /// Sends a race invite to [toFamilyId] for [roomCode] from [kidUuid].
  void sendInvite({
    required String toFamilyId,
    required String roomCode,
    required String kidUuid,
  }) {
    _socket?.send({
      't': 'invite',
      'toFamilyId': toFamilyId,
      'roomCode': roomCode,
      'kidUuid': kidUuid,
    });
  }

  /// Replies to an incoming invite and clears it from [LobbyState.pendingInvite].
  void replyInvite({
    required String inviteId,
    required bool accept,
  }) {
    _socket?.send({
      't': 'invite_reply',
      'inviteId': inviteId,
      'accept': accept,
    });
    _clearInviteById(inviteId);
  }

  /// Dismisses the active [LobbyState.pendingInvite] without sending a reply
  /// and promotes the next valid queued invite if idle.
  void dismissPendingInvite() {
    final current = state.pendingInvite;
    if (current == null) return;
    _clearInviteById(current.inviteId);
  }

  Future<void> _connect() async {
    if (!_shouldBeConnected || _connecting || _socket != null) return;
    _connecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final gen = ++_connectGen;
    try {
      final session = ref.read(sessionProvider.notifier);
      final socket = await session.authorized(
        (token) => ref.read(lobbyConnectorProvider)(token),
      );
      if (_disposed || gen != _connectGen || !_shouldBeConnected) {
        await socket.close();
        return;
      }
      _socket = socket;
      _sub = socket.messages.listen(
        _onMessage,
        onError: (_) => _onSocketDone(gen),
        onDone: () => _onSocketDone(gen),
      );
      _startPingTimer();
      ref.read(networkStatusProvider.notifier).reportOk();
      state = state.copyWith(connected: true);
    } catch (_) {
      if (!_disposed && gen == _connectGen && _shouldBeConnected) {
        _scheduleReconnect();
      }
    } finally {
      if (gen == _connectGen) {
        _connecting = false;
      }
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    final interval = ref.read(lobbyPingIntervalProvider);
    _pingTimer = Timer.periodic(interval, (_) {
      if (_disposed || _socket == null) return;
      _socket?.send(const {'t': 'ping'});
    });
  }

  void _onSocketDone(int gen) {
    if (gen != _connectGen) return;
    _pingTimer?.cancel();
    _pingTimer = null;
    unawaited(_sub?.cancel());
    _sub = null;
    _socket = null;
    if (_disposed) return;
    state = state.copyWith(connected: false);
    if (_shouldBeConnected) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || !_shouldBeConnected || _reconnectTimer != null) return;
    final delays = ref.read(lobbyRetryDelaysProvider);
    final delay = delays.isEmpty
        ? const Duration(seconds: 10)
        : delays[_retryAttempt < delays.length
            ? _retryAttempt
            : delays.length - 1];
    _retryAttempt++;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_disposed && _shouldBeConnected) {
        unawaited(_connect());
      }
    });
  }

  void _disconnect({bool clearInvites = false}) {
    _connectGen++;
    _connecting = false;
    _retryAttempt = 0;
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _leaveTimer?.cancel();
    _leaveTimer = null;
    _withinLeaveGrace = false;
    final sub = _sub;
    _sub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      unawaited(socket.close());
    }
    if (clearInvites) {
      _queuedInvites.clear();
      _expiryTimer?.cancel();
      _expiryTimer = null;
    }
    if (_disposed) return;
    state = state.copyWith(
      connected: false,
      onlineFriends: const {},
      pendingInvite: clearInvites ? () => null : null,
    );
  }

  void _onMessage(Map<String, Object?> m) {
    if (_disposed) return;
    final type = m['t'];
    if (type is! String) return;

    switch (type) {
      case 'hello':
        _retryAttempt = 0;
        final rawOnline = m['friendsOnline'];
        final online = rawOnline is List
            ? rawOnline
                .whereType<String>()
                .where((id) => id.isNotEmpty)
                .toSet()
            : <String>{};
        state = state.copyWith(connected: true, onlineFriends: online);
      case 'presence':
        final familyId = m['familyId'];
        final online = m['online'];
        if (familyId is! String || familyId.isEmpty || online is! bool) return;
        final next = Set<String>.from(state.onlineFriends);
        if (online) {
          next.add(familyId);
        } else {
          next.remove(familyId);
        }
        state = state.copyWith(onlineFriends: next);
      case 'friend_added':
        final familyId = m['familyId'];
        if (familyId is! String || familyId.isEmpty) return;
        final nextOnline = Set<String>.from(state.onlineFriends);
        if (m['online'] == true) {
          nextOnline.add(familyId);
        }
        final event = LobbyFriendEvent(
          familyId: familyId,
          added: true,
          seq: ++_friendSeq,
        );
        state = state.copyWith(
          onlineFriends: nextOnline,
          lastFriendEvent: event,
        );
        _friendEventsController.add(event);
      case 'friend_removed':
        final familyId = m['familyId'];
        if (familyId is! String || familyId.isEmpty) return;
        final nextOnline = Set<String>.from(state.onlineFriends)
          ..remove(familyId);
        final event = LobbyFriendEvent(
          familyId: familyId,
          added: false,
          seq: ++_friendSeq,
        );
        state = state.copyWith(
          onlineFriends: nextOnline,
          lastFriendEvent: event,
        );
        _friendEventsController.add(event);
      case 'invite':
        _handleIncomingInvite(m);
      case 'invite_cancelled':
        final inviteId = m['inviteId'];
        if (inviteId is! String || inviteId.isEmpty) return;
        _clearInviteById(inviteId);
      case 'invite_reply':
        final inviteId = m['inviteId'];
        final accept = m['accept'];
        if (inviteId is! String || inviteId.isEmpty || accept is! bool) return;
        final event = LobbyInviteReplyEvent(
          inviteId: inviteId,
          accept: accept,
          seq: ++_inviteReplySeq,
        );
        state = state.copyWith(lastInviteReply: event);
        _inviteRepliesController.add(event);
      case 'reaction':
        final rawKidUuid = m['kidUuid'];
        final rawKind = m['kind'];
        final rawFromNickname = m['fromNickname'];
        final kidUuid = rawKidUuid is String ? rawKidUuid : '';
        final kind = rawKind is String ? rawKind : '';
        final fromNickname = rawFromNickname is String ? rawFromNickname : '';
        final event = LobbyReactionEvent(
          kidUuid: kidUuid,
          kind: kind,
          fromNickname: fromNickname,
          seq: ++_reactionSeq,
        );
        state = state.copyWith(lastReaction: event);
        _reactionsController.add(event);
      case 'pong':
        _lastPongAt = _clock();
      case 'error':
        final rawCode = m['code'];
        final code =
            rawCode is String && rawCode.isNotEmpty ? rawCode : 'unknown';
        final event = LobbyErrorEvent(code: code, seq: ++_errorSeq);
        state = state.copyWith(lastError: event);
        _errorsController.add(event);
    }
  }

  void _handleIncomingInvite(Map<String, Object?> m) {
    final inviteId = m['inviteId'];
    final roomCode = m['roomCode'];
    final from = m['from'];
    if (inviteId is! String ||
        inviteId.isEmpty ||
        roomCode is! String ||
        roomCode.isEmpty ||
        from is! Map) {
      return;
    }

    final now = _clock();
    final DateTime expiresAt;
    final rawExpiresAt = m['expiresAt'];
    final rawExpiresInMs = m['expiresInMs'];
    if (rawExpiresAt is num) {
      expiresAt =
          DateTime.fromMillisecondsSinceEpoch(rawExpiresAt.toInt());
    } else {
      final expiresInMs =
          rawExpiresInMs is num ? rawExpiresInMs.toInt() : 30000;
      expiresAt = now.add(Duration(milliseconds: expiresInMs));
    }
    if (!expiresAt.isAfter(now)) return;

    final rawFromFamily = from['familyId'];
    final rawKidUuid = from['kidUuid'];
    final rawNickname = from['nickname'];
    final rawAvatar = from['avatar'];
    final fromFamilyId = rawFromFamily is String ? rawFromFamily : '';
    final kidUuid = rawKidUuid is String ? rawKidUuid : '';
    final nickname = rawNickname is String ? rawNickname.trim() : '';
    final avatar = rawAvatar is String ? rawAvatar : '';

    final invite = LobbyInvite(
      inviteId: inviteId,
      fromFamilyId: fromFamilyId,
      kidUuid: kidUuid,
      nickname: nickname.isEmpty ? 'Bạn đua' : nickname,
      avatar: avatar,
      roomCode: roomCode.trim().toUpperCase(),
      expiresAt: expiresAt,
    );

    if (state.pendingInvite?.inviteId == inviteId ||
        _queuedInvites.any((i) => i.inviteId == inviteId)) {
      return;
    }

    _purgeExpiredFromQueue(now);
    final current = state.pendingInvite;
    if (current != null && current.isExpiredAt(now)) {
      state = state.copyWith(pendingInvite: () => null);
    }

    if (_isBusy || state.pendingInvite != null) {
      _queuedInvites.add(invite);
    } else {
      state = state.copyWith(pendingInvite: () => invite);
    }
    _rescheduleExpiryTimer();
  }

  void _clearInviteById(String inviteId) {
    _queuedInvites.removeWhere((i) => i.inviteId == inviteId);
    if (state.pendingInvite?.inviteId == inviteId) {
      final now = _clock();
      _purgeExpiredFromQueue(now);
      LobbyInvite? next;
      if (!_isBusy && _queuedInvites.isNotEmpty) {
        next = _queuedInvites.removeAt(0);
      }
      state = state.copyWith(pendingInvite: () => next);
    }
    _rescheduleExpiryTimer();
  }

  void _flushQueueIfReady() {
    if (_disposed) return;
    final now = _clock();
    _purgeExpiredFromQueue(now);

    final current = state.pendingInvite;
    if (current != null && current.isExpiredAt(now)) {
      state = state.copyWith(pendingInvite: () => null);
    }

    if (!_isBusy && state.pendingInvite == null && _queuedInvites.isNotEmpty) {
      final next = _queuedInvites.removeAt(0);
      state = state.copyWith(pendingInvite: () => next);
    }
    _rescheduleExpiryTimer();
  }

  void _purgeExpiredFromQueue(DateTime now) {
    _queuedInvites.removeWhere((i) => i.isExpiredAt(now));
  }

  void _purgeExpiredInvites() {
    if (_disposed) return;
    final now = _clock();
    _purgeExpiredFromQueue(now);
    final current = state.pendingInvite;
    if (current != null && current.isExpiredAt(now)) {
      LobbyInvite? next;
      if (!_isBusy && _queuedInvites.isNotEmpty) {
        next = _queuedInvites.removeAt(0);
      }
      state = state.copyWith(pendingInvite: () => next);
    }
    _rescheduleExpiryTimer();
  }

  void _rescheduleExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    DateTime? earliest = state.pendingInvite?.expiresAt;
    for (final inv in _queuedInvites) {
      if (earliest == null || inv.expiresAt.isBefore(earliest)) {
        earliest = inv.expiresAt;
      }
    }
    if (earliest == null) return;

    final delay = earliest.difference(_clock());
    if (delay <= Duration.zero) {
      Future.microtask(_purgeExpiredInvites);
    } else {
      _expiryTimer = Timer(delay, _purgeExpiredInvites);
    }
  }
}

final lobbyClientProvider =
    NotifierProvider<LobbyClient, LobbyState>(LobbyClient.new);
