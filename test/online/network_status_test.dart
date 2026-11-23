import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/net/network_status.dart';
import 'package:funedu/online/online_config.dart';

class FakeConnectivitySource implements ConnectivitySource {
  final _controller = StreamController<bool>.broadcast();
  int listenCount = 0;
  int checkCount = 0;
  bool current = true;

  @override
  Stream<bool> get hasConnection {
    return _controller.stream.asBroadcastStream(
      onListen: (_) => listenCount++,
    );
  }

  @override
  Future<bool> check() async {
    checkCount++;
    return current;
  }

  void emit(bool hasConn) {
    current = hasConn;
    _controller.add(hasConn);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeConnectivitySource fakeConnectivity;
  late MemoryTokenStore tokenStore;
  late AppDatabase db;

  setUp(() {
    fakeConnectivity = FakeConnectivitySource();
    tokenStore = MemoryTokenStore();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    fakeConnectivity.dispose();
    await db.close();
  });

  ProviderContainer makeContainer({
    bool onlineConfigEnabled = true,
  }) {
    return ProviderContainer(
      overrides: [
        onlineConfigProvider.overrideWithValue(
          OnlineConfig(apiUrl: onlineConfigEnabled ? 'https://api.test' : ''),
        ),
        tokenStoreProvider.overrideWithValue(tokenStore),
        connectivitySourceProvider.overrideWithValue(fakeConnectivity),
        databaseProvider.overrideWithValue(db),
      ],
    );
  }

  test('guest mode does not touch connectivity', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    // Initial state is NetState.unknown
    final state = container.read(networkStatusProvider);
    expect(state, NetState.unknown);

    // Give microtasks a turn
    await Future<void>.delayed(Duration.zero);

    expect(fakeConnectivity.listenCount, equals(0));
    expect(fakeConnectivity.checkCount, equals(0));
  });

  test('signed in: source false -> offline; source true keeps state and emits maybeBack; reportOk -> online', () async {
    tokenStore.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    // Read session so it's initialized
    await container.read(sessionProvider.future);

    // Read network status to activate notifier
    expect(container.read(networkStatusProvider), NetState.unknown);
    await Future<void>.delayed(Duration.zero);

    expect(fakeConnectivity.listenCount, greaterThan(0));

    // When connectivity drops: state becomes offline
    fakeConnectivity.emit(false);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(networkStatusProvider), NetState.offline);

    // When connectivity is back: state stays unchanged (does not jump to online yet), emits maybeBack
    var maybeBackEmitted = false;
    final sub = container.read(networkStatusProvider.notifier).maybeBack.listen((_) {
      maybeBackEmitted = true;
    });
    addTearDown(sub.cancel);

    fakeConnectivity.emit(true);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(networkStatusProvider), NetState.offline);
    expect(maybeBackEmitted, isTrue);

    // Successful request sets state to online
    container.read(networkStatusProvider.notifier).reportOk();
    expect(container.read(networkStatusProvider), NetState.online);

    // Network error when physical connection is present sets state to serverUnreachable
    container.read(networkStatusProvider.notifier).reportNetworkError();
    expect(container.read(networkStatusProvider), NetState.serverUnreachable);

    // When physical connection drops: state becomes offline
    fakeConnectivity.emit(false);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(networkStatusProvider), NetState.offline);

    // Network error when physical connection is missing sets state to offline
    container.read(networkStatusProvider.notifier).reportNetworkError();
    expect(container.read(networkStatusProvider), NetState.offline);
  });

  test('sign out stops listening to connectivity', () async {
    tokenStore.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(sessionProvider.future);
    container.read(networkStatusProvider);
    await Future<void>.delayed(Duration.zero);

    expect(fakeConnectivity.listenCount, greaterThan(0));

    // Sign out
    await container.read(sessionProvider.notifier).signOut();
    await Future<void>.delayed(Duration.zero);

    fakeConnectivity.emit(false);
    await Future<void>.delayed(Duration.zero);

    // Should not trigger state changes since signed out
    expect(container.read(networkStatusProvider), NetState.unknown);
  });
}
