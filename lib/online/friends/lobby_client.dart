import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../net/network_status.dart';
import '../online_config.dart';
import '../room/room_transport.dart';

part 'lobby_models.dart';
part 'lobby_transport.dart';

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

  /// Presence counts from the server: a slow socket can swap two presence
  /// messages, so a family's dot follows only the larger count. [_helloV]
  /// covers every family listed (or not) in the last hello.
  int _helloV = 0;
  final Map<String, int> _presenceV = {};
  int _errorSeq = 0;
  DateTime? _lastPongAt;

  final List<LobbyInvite> _queuedInvites = [];

  final _inviteRepliesController =
      StreamController<LobbyInviteReplyEvent>.broadcast();
  final _reactionsController = StreamController<LobbyReactionEvent>.broadcast();
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
        : delays[
            _retryAttempt < delays.length ? _retryAttempt : delays.length - 1];
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
        _helloV = (m['v'] as num?)?.toInt() ?? 0;
        _presenceV.clear();
        final rawOnline = m['friendsOnline'];
        final online = rawOnline is List
            ? rawOnline.whereType<String>().where((id) => id.isNotEmpty).toSet()
            : <String>{};
        state = state.copyWith(connected: true, onlineFriends: online);
      case 'presence':
        final familyId = m['familyId'];
        final online = m['online'];
        if (familyId is! String || familyId.isEmpty || online is! bool) return;
        final v = (m['v'] as num?)?.toInt();
        if (v != null) {
          final known = _presenceV[familyId] ?? _helloV;
          if (v <= known) return;
          _presenceV[familyId] = v;
        }
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
      expiresAt = DateTime.fromMillisecondsSinceEpoch(rawExpiresAt.toInt());
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
