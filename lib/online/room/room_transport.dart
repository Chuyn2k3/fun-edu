import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../online_config.dart';

/// One open connection to `/ws/room`: JSON objects in and out.
abstract class RoomTransport {
  Stream<Map<String, Object?>> get messages;
  void send(Map<String, Object?> message);
  Future<void> close();
}

/// Opens a connection to the room [code] with the parent's [accessToken].
typedef RoomConnector = Future<RoomTransport> Function(String code, String accessToken);

class _IoRoomTransport implements RoomTransport {
  _IoRoomTransport(this._socket)
      : messages = _socket
            .where((m) => m is String)
            .map((m) => jsonDecode(m as String))
            .where((m) => m is Map<String, Object?>)
            .cast<Map<String, Object?>>()
            .asBroadcastStream();

  final WebSocket _socket;

  @override
  final Stream<Map<String, Object?>> messages;

  @override
  void send(Map<String, Object?> message) {
    if (_socket.readyState == WebSocket.open) _socket.add(jsonEncode(message));
  }

  @override
  Future<void> close() => _socket.close();
}

/// `https://api.x` -> `wss://api.x/ws/room?code=...`.
Uri roomSocketUri(OnlineConfig config, String code) {
  final base = Uri.parse(config.apiUrl);
  return base.replace(
    scheme: base.scheme == 'https' ? 'wss' : 'ws',
    path: '${base.path}/ws/room',
    queryParameters: {'code': code},
  );
}

final roomConnectorProvider = Provider<RoomConnector>((ref) {
  final config = ref.watch(onlineConfigProvider);
  return (code, token) async {
    final socket = await WebSocket.connect(
      roomSocketUri(config, code).toString(),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
    socket.pingInterval = const Duration(seconds: 15);
    return _IoRoomTransport(socket);
  };
});
