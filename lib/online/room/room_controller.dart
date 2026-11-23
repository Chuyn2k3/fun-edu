import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/game_repository.dart';
import '../api_client.dart';
import '../auth/session_controller.dart';
import '../net/network_status.dart';
import 'room_transport.dart';

enum RoomPhase { idle, connecting, lobby, countdown, racing, done, error }

/// Stickers a kid can send: the server relays only these ids.
const roomStickers = ['cheer', 'wow', 'love', 'fast', 'hi', 'gg'];

class RoomPlayer {
  const RoomPlayer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rocket,
    required this.steps,
    this.rank,
    this.connected = true,
    this.away = false,
    this.awayMsLeft,
    this.left = false,
  });

  final String id;
  final String name;
  final String avatar;
  final String rocket;
  final int steps;

  /// Finish position (1 = first), null while racing.
  final int? rank;
  final bool connected;
  final bool away;
  final int? awayMsLeft;
  final bool left;

  static RoomPlayer fromJson(Map<String, Object?> j) => RoomPlayer(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
        rocket: j['rocket'] as String? ?? 'rocket_orange',
        steps: (j['steps'] as num?)?.toInt() ?? 0,
        rank: (j['rank'] as num?)?.toInt(),
        connected: j['connected'] != false,
        away: j['away'] == true,
        awayMsLeft: (j['awayMsLeft'] as num?)?.toInt(),
        left: j['left'] == true,
      );
}

class RoomSticker {
  const RoomSticker(this.from, this.id, this.seq);
  final String from;
  final String id;
  final int seq;
}

class RoomState {
  const RoomState({
    this.phase = RoomPhase.idle,
    this.code,
    this.you,
    this.host,
    this.players = const [],
    this.startsAt,
    this.error,
    this.sticker,
    this.reconnecting = false,
    this.endReason,
  });

  final RoomPhase phase;
  final String? code;
  final String? you;
  final String? host;
  final List<RoomPlayer> players;
  final DateTime? startsAt;

  /// Server error code (`not_found`, `room_full`, `started`, ...) or
  /// `network`, `signed_out`.
  final String? error;
  final RoomSticker? sticker;
  final bool reconnecting;
  final String? endReason;

  bool get isHost => you != null && you == host;
  RoomPlayer? get me => players.where((p) => p.id == you).firstOrNull;
  List<RoomPlayer> get others => players.where((p) => p.id != you).toList();
  int get connectedCount => players.where((p) => p.connected).length;

  RoomState copyWith({
    RoomPhase? phase,
    String? code,
    String? error,
    RoomSticker? sticker,
    bool? reconnecting,
    String? endReason,
  }) =>
      RoomState(
        phase: phase ?? this.phase,
        code: code ?? this.code,
        you: you,
        host: host,
        players: players,
        startsAt: startsAt,
        error: error,
        sticker: sticker ?? this.sticker,
        reconnecting: reconnecting ?? this.reconnecting,
        endReason: endReason ?? this.endReason,
      );
}

/// Who is joining: the current kid as the room should show them.
class RoomKid {
  const RoomKid({
    required this.uuid,
    required this.name,
    required this.avatar,
    required this.rocket,
  });

  final String uuid;
  final String name;
  final String avatar;
  final String rocket;
}

/// The live room this device is in (one at a time). Reconnects a few times
/// when the connection drops; the server keeps the kid's place for 20 s.
class RoomController extends Notifier<RoomState> {
  RoomTransport? _socket;
  StreamSubscription<Map<String, Object?>>? _sub;
  RoomKid? _kid;
  bool _leaving = false;
  bool _disposed = false;
  int _retries = 0;
  int _stickerSeq = 0;

  List<Duration> get _retryDelays => ref.read(roomRetryDelaysProvider);

  @override
  RoomState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _closeSocket();
    });
    return const RoomState();
  }

  /// A parent opens a new room and the kid joins it as host.
  Future<void> create(RoomKid kid) async {
    state = const RoomState(phase: RoomPhase.connecting);
    final Map<String, Object?>? res;
    try {
      res = await ref.read(sessionProvider.notifier).authorized((t) =>
          ref.read(apiClientProvider).post('/api/v1/rooms', const {}, accessToken: t));
    } on ApiException catch (e) {
      final isOffline = ref.read(networkStatusProvider) == NetState.offline;
      state = RoomState(
          phase: RoomPhase.error,
          error: e.unauthorized
              ? 'signed_out'
              : (e.status == 429
                  ? 'too_many'
                  : (isOffline ? 'network' : 'server_unreachable')));
      return;
    }
    final code = res?['code'] as String?;
    if (code == null) {
      final isOffline = ref.read(networkStatusProvider) == NetState.offline;
      state = RoomState(
        phase: RoomPhase.error,
        error: isOffline ? 'network' : 'server_unreachable',
      );
      return;
    }
    await join(code, kid);
  }

  /// Joins the room [code] (letters are upper-cased, spaces ignored).
  Future<void> join(String code, RoomKid kid) async {
    await _closeSocket();
    _kid = kid;
    _leaving = false;
    _retries = 0;
    final clean = code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    state = RoomState(phase: RoomPhase.connecting, code: clean);
    await _connect(clean);
  }

  Future<void> _connect(String code) async {
    final kid = _kid!;
    try {
      final session = ref.read(sessionProvider.notifier);
      final socket = await session.authorized(
          (token) => ref.read(roomConnectorProvider)(code, token));
      _socket = socket;
      _sub = socket.messages.listen(_onMessage, onDone: () => _onClosed(code));
      socket.send({
        't': 'join',
        'kid': kid.uuid,
        'name': kid.name,
        'avatar': kid.avatar,
        'rocket': kid.rocket,
      });
    } catch (_) {
      await _retryOrFail(code);
    }
  }

  void _onMessage(Map<String, Object?> m) {
    if (_disposed) return;
    switch (m['t']) {
      case 'room':
        _retries = 0;
        final startsAt = (m['startsAt'] as num?)?.toInt();
        state = RoomState(
          phase: switch (m['state']) {
            'countdown' => RoomPhase.countdown,
            'racing' => RoomPhase.racing,
            'done' => RoomPhase.done,
            _ => RoomPhase.lobby,
          },
          code: m['code'] as String? ?? state.code,
          you: m['you'] as String?,
          host: m['host'] as String?,
          players: (m['players'] as List? ?? const [])
              .whereType<Map>()
              .map((p) => RoomPlayer.fromJson(p.cast<String, Object?>()))
              .toList(),
          startsAt: startsAt == null ? null : DateTime.fromMillisecondsSinceEpoch(startsAt),
          sticker: state.sticker,
          reconnecting: false,
          endReason: m['endReason'] as String?,
        );
      case 'sticker':
        state = state.copyWith(
          sticker: RoomSticker(m['from'] as String? ?? '', m['id'] as String? ?? '', ++_stickerSeq),
          phase: state.phase,
          error: state.error,
        );
      case 'error':
        final code = m['code'] as String? ?? 'network';
        // not_host / need_two are answers to a button, not the end of the room.
        if (code == 'not_host' || code == 'need_two') {
          state = state.copyWith(error: code);
        } else {
          _leaving = true;
          state = RoomState(phase: RoomPhase.error, code: state.code, error: code);
        }
    }
  }

  Future<void> _onClosed(String code) async {
    _socket = null;
    if (_disposed || _leaving || state.phase == RoomPhase.error || state.phase == RoomPhase.idle) {
      return;
    }
    if (state.phase != RoomPhase.connecting) {
      state = state.copyWith(reconnecting: true);
    }
    await _retryOrFail(code);
  }

  Future<void> _retryOrFail(String code) async {
    if (_disposed || _leaving) return;
    if (_retries >= _retryDelays.length) {
      final isOffline = ref.read(networkStatusProvider) == NetState.offline;
      state = state.copyWith(
        phase: RoomPhase.error,
        code: code,
        error: isOffline ? 'network' : 'server_unreachable',
        reconnecting: false,
      );
      return;
    }
    await Future<void>.delayed(_retryDelays[_retries++]);
    if (_disposed || _leaving) return;
    await _connect(code);
  }

  void start() => _socket?.send(const {'t': 'start'});
  void again() => _socket?.send(const {'t': 'again'});

  /// The kid's rocket climbed to [steps] (0..10).
  void step(int steps) => _socket?.send({'t': 'step', 'n': steps});

  void sticker(String id) {
    final socket = _socket;
    if (!roomStickers.contains(id) || socket == null) return;
    socket.send({'t': 'sticker', 'id': id});
    // Counts toward the "Cổ Vũ Nhiệt Tình" badge; a failure is harmless.
    unawaited(ref
        .read(gameRepositoryProvider.future)
        .then((repo) => repo.countStickerSent())
        .catchError((Object _) {}));
  }

  Future<void> leave() async {
    _leaving = true;
    _socket?.send(const {'t': 'leave'});
    await _closeSocket();
    state = const RoomState();
  }

  Future<void> _closeSocket() async {
    await _sub?.cancel();
    _sub = null;
    final s = _socket;
    _socket = null;
    await s?.close();
  }
}

/// Waits before each reconnect after a dropped connection (tests shorten it).
/// Total = 20 s, matching the server's reconnect grace period.
final roomRetryDelaysProvider = Provider<List<Duration>>((_) => const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 6),
      Duration(seconds: 5),
      Duration(seconds: 5),
    ]);

final roomControllerProvider =
    NotifierProvider<RoomController, RoomState>(RoomController.new);
