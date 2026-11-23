// Lobby socket transport and the providers tests override.
part of 'lobby_client.dart';

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
