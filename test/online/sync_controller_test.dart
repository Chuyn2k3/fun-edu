import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/net/network_status.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeConnectivitySource implements ConnectivitySource {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get hasConnection => _controller.stream;
  @override
  Future<bool> check() async => true;
  void emit(bool val) => _controller.add(val);
  void dispose() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeConnectivitySource fakeConnectivity;
  late MemoryTokenStore tokenStore;
  late AppDatabase db;
  late int syncCalls;
  Future<http.Response> Function(http.Request)? responseHandler;

  setUp(() {
    fakeConnectivity = _FakeConnectivitySource();
    tokenStore = MemoryTokenStore();
    db = AppDatabase(NativeDatabase.memory());
    syncCalls = 0;
    responseHandler = (req) async => http.Response(
          '{"records": [], "version": 1, "hasMore": false, "conflicts": []}',
          200,
        );
  });

  tearDown(() async {
    fakeConnectivity.dispose();
    await db.close();
  });

  ProviderContainer makeContainer({bool linked = true}) {
    if (linked) {
      tokenStore.session = const StoredSession(
        accessToken: 'acc-token',
        refreshToken: 'ref-token',
        familyId: 'fam-1',
        provider: 'google',
        linked: true,
      );
    }
    final mockHttp = MockClient((req) async {
      if (req.url.path.contains('/api/v1/sync')) {
        syncCalls++;
        return responseHandler!(req);
      }
      return http.Response('{}', 200);
    });

    return ProviderContainer(
      overrides: [
        onlineConfigProvider.overrideWithValue(
          const OnlineConfig(apiUrl: 'https://api.test'),
        ),
        tokenStoreProvider.overrideWithValue(tokenStore),
        connectivitySourceProvider.overrideWithValue(fakeConnectivity),
        databaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(
          ApiClient(
            const OnlineConfig(apiUrl: 'https://api.test'),
            mockHttp,
          ),
        ),
      ],
    );
  }

  testWidgets('back online syncs after 2 s once', (tester) async {
    final container = makeContainer();
    final sub = container.listen(syncControllerProvider, (_, __) {});
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(sessionProvider.future);
    container.read(networkStatusProvider);

    // Let initial launch sync finish
    await tester.pump();
    final initialCalls = syncCalls;

    // Emit 3 maybeBack events in quick succession
    fakeConnectivity.emit(false);
    await tester.pump(const Duration(milliseconds: 100));
    fakeConnectivity.emit(true);
    await tester.pump(const Duration(milliseconds: 100));
    fakeConnectivity.emit(true);
    await tester.pump(const Duration(milliseconds: 100));
    fakeConnectivity.emit(true);

    // After 1 second: should not have synced yet
    await tester.pump(const Duration(seconds: 1));
    expect(syncCalls, equals(initialCalls));

    // After total 2 seconds from last emit: exactly one sync should fire
    await tester.pump(const Duration(seconds: 2));
    expect(syncCalls, equals(initialCalls + 1));

    controller.stop();
    sub.close();
    container.dispose();
    await tester.pump();
  });

  testWidgets('lesson done requests a sync; race result requests a sync', (tester) async {
    final container = makeContainer();
    final sub = container.listen(syncControllerProvider, (_, __) {});
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(sessionProvider.future);
    await tester.pump();
    final initialCalls = syncCalls;

    // Simulate lesson done triggering requestSync
    controller.requestSync();
    await tester.pump(const Duration(seconds: 3));
    expect(syncCalls, equals(initialCalls + 1));

    // Simulate race result triggering requestSync
    controller.requestSync();
    await tester.pump(const Duration(seconds: 3));
    expect(syncCalls, equals(initialCalls + 2));

    controller.stop();
    sub.close();
    container.dispose();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('requests within 3 s coalesce', (tester) async {
    final container = makeContainer();
    final sub = container.listen(syncControllerProvider, (_, __) {});
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(sessionProvider.future);
    await tester.pump();
    final initialCalls = syncCalls;

    controller.requestSync();
    await tester.pump(const Duration(seconds: 1));
    controller.requestSync();
    await tester.pump(const Duration(seconds: 1));
    controller.requestSync();

    // After 2 seconds total: 0 new syncs
    expect(syncCalls, equals(initialCalls));

    // After 3 seconds from the first request: exactly 1 sync fires
    await tester.pump(const Duration(seconds: 2));
    expect(syncCalls, equals(initialCalls + 1));

    controller.stop();
    sub.close();
    container.dispose();
    await tester.pump();
  });

  testWidgets('retry backs off and resets', (tester) async {
    responseHandler = (req) async => http.Response('{"error": "fail"}', 500);

    final container = makeContainer();
    final sub = container.listen(syncControllerProvider, (_, __) {});
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(sessionProvider.future);

    // Initial sync fails
    await tester.pump();
    expect(syncCalls, equals(1));
    expect(controller.retryStep, equals(1));

    // Should wait 30s for next retry
    await tester.pump(const Duration(seconds: 29));
    expect(syncCalls, equals(1));
    await tester.pump(const Duration(seconds: 1));
    expect(syncCalls, equals(2));
    expect(controller.retryStep, equals(2));

    // 2nd retry waits 60s
    await tester.pump(const Duration(seconds: 59));
    expect(syncCalls, equals(2));
    await tester.pump(const Duration(seconds: 1));
    expect(syncCalls, equals(3));
    expect(controller.retryStep, equals(3));

    // 3rd retry succeeds!
    responseHandler = (req) async => http.Response(
          '{"records": [], "version": 1, "hasMore": false, "conflicts": []}',
          200,
        );
    // 3rd retry waits 120s
    await tester.pump(const Duration(seconds: 120));
    expect(syncCalls, equals(4));
    expect(controller.retryStep, equals(0)); // Reset!

    controller.stop();
    sub.close();
    container.dispose();
    await tester.pump();
  });

  testWidgets('trigger while running runs exactly one more', (tester) async {
    final completer = Completer<http.Response>();
    responseHandler = (req) {
      if (syncCalls == 1) {
        return completer.future;
      }
      return Future.value(http.Response(
        '{"records": [], "version": 1, "hasMore": false, "conflicts": []}',
        200,
      ));
    };

    final container = makeContainer();
    final sub = container.listen(syncControllerProvider, (_, __) {});
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(sessionProvider.future);

    // Initial microtask triggers first sync, which will wait on completer
    final firstSync = controller.syncNow();
    await tester.pump();
    expect(syncCalls, equals(1));

    // Multiple triggers while running
    unawaited(controller.syncNow());
    unawaited(controller.syncNow());
    unawaited(controller.syncNow());

    // Still 1 call because first is still in progress
    expect(syncCalls, equals(1));

    // Complete the first call
    completer.complete(http.Response(
      '{"records": [], "version": 1, "hasMore": false, "conflicts": []}',
      200,
    ));
    // Wait for the full loop (both syncs) to finish
    await firstSync;
    await tester.pump();

    // Exactly one more call ran!
    expect(syncCalls, equals(2));

    controller.stop();
    sub.close();
    container.dispose();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('background cancels timers', (tester) async {
    responseHandler = (req) async => http.Response('{"error": "fail"}', 500);

    final container = makeContainer();
    final sub = container.listen(syncControllerProvider, (_, __) {});
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(sessionProvider.future);
    await tester.pump(); // Initial failed sync
    expect(syncCalls, equals(1));
    expect(controller.retryStep, equals(1));

    // Trigger app hide (background)
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();

    // Advance by 35 seconds (would have triggered 30s retry)
    await tester.pump(const Duration(seconds: 35));
    // No new sync because timers were canceled in background
    expect(syncCalls, equals(1));

    // Resume app: should trigger syncNow
    responseHandler = (req) async => http.Response(
          '{"records": [], "version": 1, "hasMore": false, "conflicts": []}',
          200,
        );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(syncCalls, equals(2));

    controller.stop();
    sub.close();
    container.dispose();
    await tester.pump();
  });

  testWidgets('429 is retried quietly', (tester) async {
    responseHandler = (req) async => http.Response('{"error": "too_many_requests"}', 429);

    final container = makeContainer();
    final sub = container.listen(syncControllerProvider, (_, __) {});
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(sessionProvider.future);
    await tester.pump(); // Initial sync returns 429

    expect(container.read(syncControllerProvider).failed, isTrue);
    expect(controller.retryStep, equals(1));

    controller.stop();
    sub.close();
    container.dispose();
    await tester.pump(const Duration(milliseconds: 50));
  });
}
