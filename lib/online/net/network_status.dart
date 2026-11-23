import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../online_config.dart';

enum NetState {
  unknown,
  offline,
  online,
}

abstract class ConnectivitySource {
  Stream<bool> get hasConnection;
  Future<bool> check();
}

class PluginConnectivitySource implements ConnectivitySource {
  final Connectivity _connectivity;

  PluginConnectivitySource([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<bool> get hasConnection =>
      _connectivity.onConnectivityChanged.map((results) =>
          results.isNotEmpty && !results.contains(ConnectivityResult.none));

  @override
  Future<bool> check() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}

final connectivitySourceProvider = Provider<ConnectivitySource>(
  (ref) => PluginConnectivitySource(),
);

class NetworkStatus extends Notifier<NetState> {
  final _maybeBackController = StreamController<void>.broadcast();
  StreamSubscription<bool>? _connectivitySub;

  Stream<void> get maybeBack => _maybeBackController.stream;

  @override
  NetState build() {
    ref.onDispose(() {
      _connectivitySub?.cancel();
      _maybeBackController.close();
    });

    final session = ref.watch(sessionProvider).valueOrNull;
    final enabled = ref.watch(onlineConfigProvider).enabled;

    if (session != null && enabled) {
      _startListening();
    } else {
      _stopListening();
    }

    return NetState.unknown;
  }

  void _startListening() {
    _connectivitySub?.cancel();
    final source = ref.read(connectivitySourceProvider);
    _connectivitySub = source.hasConnection.listen((hasConn) {
      if (!hasConn) {
        state = NetState.offline;
      } else {
        _maybeBackController.add(null);
      }
    });
  }

  void _stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  void reportOk() {
    state = NetState.online;
  }

  void reportNetworkError() {
    state = NetState.offline;
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatus, NetState>(NetworkStatus.new);
