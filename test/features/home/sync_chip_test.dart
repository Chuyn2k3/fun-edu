import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/features/online/sync_toast_listener.dart';
import 'package:funedu/learning/lesson_item.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/net/network_status.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:funedu/online/sync/sync_health.dart';
import 'package:funedu/parent/parent_gate.dart';
import 'package:funedu/parent/screens/family_account_card.dart';
import 'package:funedu/parent/screens/parent_home.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/rewards/reward_repository.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/voice/voice_lines.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';

import '../../online/online_fakes.dart';

class _StubSyncHealth extends SyncHealthNotifier {
  _StubSyncHealth(this._initial);

  final SyncHealth _initial;

  @override
  SyncHealth build() => _initial;

  void setHealth(SyncHealth next) {
    state = next;
  }

  @override
  void setRunning(bool running) {}

  @override
  void setPending(int pending) {}

  @override
  Future<void> refreshPending() async {}

  @override
  void recordSyncFailure({int? pending}) {}
}

Future<void> _solveParentGate(WidgetTester t) async {
  final q = t.widget<Text>(find.byKey(const Key('parent-gate-question'))).data!;
  final body = q.substring('Nhập kết quả: '.length);
  final parts = body.split(' nhân ');
  int numOf(String w) =>
      [for (var n = 3; n <= 9; n++) n].firstWhere((n) => numberToVietnamese(n) == w);
  final ans = numOf(parts[0]) * numOf(parts[1]);
  for (final d in ans.toString().split('')) {
    await t.tap(find.byKey(Key('gate-key-$d')));
    await t.pump();
  }
  await t.tap(find.text('Xác nhận'));
}

void main() {
  late AppDatabase db;
  late MemoryTokenStore tokenStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tokenStore = MemoryTokenStore();
  });

  tearDown(() => db.close());

  List<Override> baseOverrides({
    SyncHealth? health,
    _StubSyncHealth? stubHealth,
    DateTime? now,
    bool signedIn = true,
    bool offlineHttp = false,
  }) {
    if (signedIn) {
      tokenStore.session = const StoredSession(
        accessToken: 'a1',
        refreshToken: 'r1',
        familyId: 'fam-1',
        provider: 'google',
        email: 'me@x.vn',
        linked: true,
      );
    } else {
      tokenStore.session = null;
    }
    return [
      onlineConfigProvider
          .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
      tokenStoreProvider.overrideWithValue(tokenStore),
      identityProvidersProvider.overrideWithValue(FakeIds()),
      httpClientProvider.overrideWithValue(MockClient((req) async {
        if (offlineHttp) throw const SocketException('offline');
        return fakeServer(req);
      })),
      databaseProvider.overrideWithValue(db),
      if (now != null) syncHealthClockProvider.overrideWithValue(() => now),
      if (stubHealth != null)
        syncHealthProvider.overrideWith(() => stubHealth)
      else if (health != null)
        syncHealthProvider.overrideWith(() => _StubSyncHealth(health)),
      kidsProvider.overrideWith((_) async => [
            KidProfile(
              id: 1,
              nickname: 'Bảo Ngọc',
              avatar: AppImages.chipMain,
              age: 5,
              createdAt: DateTime(2026, 11, 1),
            ),
          ]),
      currentKidIdProvider.overrideWith((_) async => 1),
      homeSummaryProvider.overrideWith((_) async => const HomeSummary(
            totalStars: 42,
            learnedDaysThisWeek: 3,
            masteredWriting: 5,
            lessonsToday: 1,
            learnedWeekdays: {1, 2, 3},
          )),
      todayLessonProvider
          .overrideWith((_) async => const [WritingItem('so-1')]),
      glyphProvider('so-1').overrideWith(
        (_) async => const Glyph(
          id: 'so-1',
          label: '1',
          strokes: [],
        ),
      ),
      pendingRewardProvider.overrideWith((_) async => null),
    ];
  }

  Widget routerApp({
    required List<Override> overrides,
    GoRouter? router,
    String initialLocation = '/',
    String Function()? pathResolver,
  }) {
    final navKey = GlobalKey<NavigatorState>();
    final goRouter = router ??
        GoRouter(
          navigatorKey: navKey,
          initialLocation: initialLocation,
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(
              path: '/lesson',
              builder: (_, __) => const Scaffold(body: Text('lesson screen')),
            ),
            GoRoute(
              path: '/trace/:id',
              builder: (_, __) => const Scaffold(body: Text('trace screen')),
            ),
            GoRoute(
              path: '/parent',
              builder: (_, s) =>
                  ParentHome(focus: s.uri.queryParameters['focus']),
            ),
          ],
        );
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: goRouter,
        builder: (context, child) => SyncToastListener(
          navigatorKey: navKey,
          pathResolver: pathResolver ??
              () => goRouter.routerDelegate.currentConfiguration.uri.path,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('chip hidden in guest mode', (t) async {
    await t.pumpWidget(
      routerApp(overrides: baseOverrides(signedIn: false)),
    );
    await t.pumpAndSettle();

    expect(find.byKey(const ValueKey('sync-chip')), findsNothing);
    expect(find.byKey(const ValueKey('sync-reminder-banner')), findsNothing);
  });

  testWidgets('chip shows three states and collapses saved label after 3s',
      (t) async {
    final stub = _StubSyncHealth(const SyncHealth(running: true));
    await t.pumpWidget(
      routerApp(overrides: baseOverrides(stubHealth: stub)),
    );
    await t.pump();
    await t.pump();

    expect(find.text('Đang lưu…'), findsOneWidget);

    stub.setHealth(const SyncHealth(running: false, pending: 4));
    await t.pump();
    expect(find.text('4 bài chưa lưu'), findsOneWidget);

    stub.setHealth(const SyncHealth(running: false, pending: 0));
    await t.pump();
    expect(find.text('Đã lưu'), findsOneWidget);

    // Collapses text after 3s, leaving cloud icon visible & >= 48 tall.
    await t.pump(const Duration(seconds: 3));
    expect(find.text('Đã lưu'), findsNothing);
    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    expect(t.getSize(find.byKey(const ValueKey('sync-chip'))).height,
        greaterThanOrEqualTo(48));
  });

  testWidgets('chip at least 48 tall in every state', (t) async {
    await t.pumpWidget(
      routerApp(
        overrides: baseOverrides(
          health: const SyncHealth(pending: 2),
        ),
      ),
    );
    await t.pumpAndSettle();
    final size = t.getSize(find.byKey(const ValueKey('sync-chip')));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  testWidgets('chip tap opens parent gate then account card showing offline status',
      (t) async {
    final now = DateTime(2026, 11, 23, 12, 0);
    await t.pumpWidget(
      routerApp(
        overrides: baseOverrides(
          health: SyncHealth(
            pending: 3,
            net: NetState.offline,
            lastOkAt: now.subtract(const Duration(hours: 2)),
          ),
          now: now,
          offlineHttp: true,
        ),
      ),
    );
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('sync-chip')));
    await t.pumpAndSettle();
    expect(find.byType(ParentGate), findsOneWidget);

    await _solveParentGate(t);
    await t.pumpAndSettle();

    expect(find.byType(FamilyAccountCard), findsOneWidget);
    expect(
      find.text('Đang offline · 3 bài chưa lưu, sẽ tự lưu khi có mạng'),
      findsOneWidget,
    );
    final c = ProviderScope.containerOf(t.element(find.byType(FamilyAccountCard)));
    c.read(syncControllerProvider.notifier).stop();
  });

  testWidgets('banner appears after 24 h with pending and disappears on sync',
      (t) async {
    final now = DateTime(2026, 11, 23, 12, 0);
    final stub = _StubSyncHealth(
      SyncHealth(
        pending: 5,
        lastOkAt: now.subtract(const Duration(hours: 25)),
        net: NetState.offline,
      ),
    );
    await t.pumpWidget(
      routerApp(overrides: baseOverrides(stubHealth: stub, now: now)),
    );
    await t.pumpAndSettle();

    expect(find.byKey(const ValueKey('sync-reminder-banner')), findsOneWidget);
    expect(
      find.text(
          'Ba mẹ ơi, tiến độ 2 ngày nay chưa lưu online. Kiểm tra mạng giúp bé nhé'),
      findsOneWidget,
    );

    // Sync finishes -> pending 0, lastOkAt now -> banner hides immediately.
    stub.setHealth(SyncHealth(pending: 0, lastOkAt: now, net: NetState.online));
    await t.pump();
    expect(find.byKey(const ValueKey('sync-reminder-banner')), findsNothing);
  });

  testWidgets('banner hidden while learning on /lesson and /trace/*', (t) async {
    final now = DateTime(2026, 11, 23, 12, 0);
    final health = SyncHealth(
      pending: 5,
      lastOkAt: now.subtract(const Duration(hours: 48)),
      net: NetState.offline,
    );

    await t.pumpWidget(
      routerApp(
        initialLocation: '/lesson',
        overrides: baseOverrides(health: health, now: now),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('sync-reminder-banner')), findsNothing);

    await t.pumpWidget(
      routerApp(
        initialLocation: '/trace/so-1',
        overrides: baseOverrides(health: health, now: now),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('sync-reminder-banner')), findsNothing);
  });

  testWidgets(
      'toast shown after being offline >= 1m on /; suppressed on /lesson; flapping shows at most once',
      (t) async {
    var now = DateTime(2026, 11, 23, 10, 0, 0);
    final conn = _TestConnSource();
    var currentPath = '/lesson';
    addTearDown(conn.dispose);

    await t.pumpWidget(
      routerApp(
        overrides: [
          ...baseOverrides(now: now),
          connectivitySourceProvider.overrideWithValue(conn),
        ],
        pathResolver: () => currentPath,
      ),
    );
    await t.pumpAndSettle();
    final container =
        ProviderScope.containerOf(t.element(find.byType(HomeScreen)));
    final notifier = container.read(syncHealthProvider.notifier);
    final netNotifier = container.read(networkStatusProvider.notifier);

    // Offline at 10:00, sync succeeds at 10:02 while on /lesson -> toast NOT shown
    conn.emit(false);
    await t.pump();
    now = DateTime(2026, 11, 23, 10, 2, 0);
    netNotifier.reportOk();
    notifier.recordSyncSuccess(pending: 0, at: now);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Đã lưu online tiến độ của bé ✓'), findsNothing);

    // Switch to '/', go offline for >= 1m with flapping, then sync succeeds
    currentPath = '/';
    now = DateTime(2026, 11, 23, 10, 5, 0);
    conn.emit(false);
    await t.pump();
    now = DateTime(2026, 11, 23, 10, 5, 20);
    conn.emit(true);
    await t.pump();
    now = DateTime(2026, 11, 23, 10, 5, 40);
    conn.emit(false);
    await t.pump();
    now = DateTime(2026, 11, 23, 10, 6, 10);
    netNotifier.reportOk();
    notifier.recordSyncSuccess(pending: 0, at: now);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Đã lưu online tiến độ của bé ✓'), findsOneWidget);

    // Wait for toast to dismiss, verify rapid second sync shows NO second toast
    await t.pump(const Duration(seconds: 3));
    await t.pumpAndSettle();
    expect(find.text('Đã lưu online tiến độ của bé ✓'), findsNothing);
    notifier.recordSyncSuccess(pending: 0, at: now);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Đã lưu online tiến độ của bé ✓'), findsNothing);
  });

  testWidgets(
      'no overflow at 320x568 phone and portrait/landscape tablet with chip and banner',
      (t) async {
    final now = DateTime(2026, 11, 23, 12, 0);
    final health = SyncHealth(
      pending: 99,
      lastOkAt: now.subtract(const Duration(hours: 30)),
      net: NetState.offline,
    );

    for (final size in const [
      Size(320, 568),
      Size(800, 1200),
      Size(1280, 800),
    ]) {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);

      await t.pumpWidget(
        routerApp(overrides: baseOverrides(health: health, now: now)),
      );
      await t.pumpAndSettle();

      expect(t.takeException(), isNull, reason: 'No overflow at $size');
      expect(find.byKey(const ValueKey('sync-chip')), findsOneWidget);
      expect(find.byKey(const ValueKey('sync-reminder-banner')), findsOneWidget);
    }
  });
}

class _TestConnSource implements ConnectivitySource {
  final ctrl = StreamController<bool>.broadcast();
  bool current = true;

  @override
  Stream<bool> get hasConnection => ctrl.stream;

  @override
  Future<bool> check() async => current;

  void emit(bool v) {
    current = v;
    ctrl.add(v);
  }

  Future<void> dispose() => ctrl.close();
}
