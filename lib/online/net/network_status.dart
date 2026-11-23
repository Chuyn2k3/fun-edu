import 'dart:async';
import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../online_config.dart';

enum NetState {
  unknown,
  offline,
  serverUnreachable,
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
  Stream<bool> get hasConnection => _connectivity.onConnectivityChanged
      .map((results) =>
          results.isNotEmpty && !results.contains(ConnectivityResult.none))
      .handleError((Object _) {});

  @override
  Future<bool> check() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}

class _NoopConnectivitySource implements ConnectivitySource {
  const _NoopConnectivitySource();
  @override
  Stream<bool> get hasConnection => const Stream.empty();
  @override
  Future<bool> check() async => true;
}

final connectivitySourceProvider = Provider<ConnectivitySource>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return const _NoopConnectivitySource();
  }
  return PluginConnectivitySource();
});

class NetworkStatus extends Notifier<NetState> {
  final _maybeBackController = StreamController<void>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  bool _hasPhysicalConn = true;

  Stream<void> get maybeBack => _maybeBackController.stream;

  @override
  NetState build() {
    ref.onDispose(() {
      _connectivitySub?.cancel();
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
    unawaited(source.check().then((hasConn) {
      _hasPhysicalConn = hasConn;
      if (!hasConn) {
        state = NetState.offline;
      }
    }));
    _connectivitySub = source.hasConnection.listen((hasConn) {
      _hasPhysicalConn = hasConn;
      if (!hasConn) {
        state = NetState.offline;
      } else {
        if (!_maybeBackController.isClosed) {
          _maybeBackController.add(null);
        }
      }
    }, onError: (_) {});
  }

  void _stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  void reportOk() {
    _hasPhysicalConn = true;
    state = NetState.online;
  }

  void reportNetworkError({bool? hasConnection}) {
    if (hasConnection != null) {
      _hasPhysicalConn = hasConnection;
      state = hasConnection ? NetState.serverUnreachable : NetState.offline;
      return;
    }
    final source = ref.read(connectivitySourceProvider);
    unawaited(source.check().then((hasConn) {
      _hasPhysicalConn = hasConn;
      state = hasConn ? NetState.serverUnreachable : NetState.offline;
    }));
    state = _hasPhysicalConn ? NetState.serverUnreachable : NetState.offline;
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatus, NetState>(NetworkStatus.new);
