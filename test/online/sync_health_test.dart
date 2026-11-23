import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/net/network_status.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_health.dart';
import 'package:funedu/online/sync/sync_store.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/assets.dart';
import 'package:http/testing.dart';

import 'online_fakes.dart';

class _FakeConnectivitySource implements ConnectivitySource {
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

StoredSession _fakeSession({bool linked = true}) => StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: linked,
    );

void main() {
  test('countDisplayablePending counts only lesson, glyph and race non-deletes',
      () {
    const changes = [
      SyncChange('kid:k1', {'nickname': 'Na'}, null),
      SyncChange('setting:k1:dailyLimitMinutes', {'value': '30'}, null),
      SyncChange('lesson:k1:1000', {'stars': 5}, null),
      SyncChange('glyph:k1:so-1', {'by': {}}, null),
      SyncChange('race:k1:2000', {'stars': 5}, null),
      SyncChange('lesson:k1:900', null, 1), // deletion ignored
    ];
    expect(countDisplayablePending(changes), 3);
  });

  test('guest mode keeps empty SyncHealth', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final conn = _FakeConnectivitySource();
    addTearDown(() async {
      await conn.dispose();
      await db.close();
    });

    final container = ProviderContainer(
      overrides: [
        onlineConfigProvider
            .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
        tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
        identityProvidersProvider.overrideWithValue(FakeIds()),
        databaseProvider.overrideWithValue(db),
        connectivitySourceProvider.overrideWithValue(conn),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionProvider.future);
    final h = container.read(syncHealthProvider);
    expect(h.pending, 0);
    expect(h.lastOkAt, isNull);
    expect(h.net, NetState.unknown);
  });

  test('offline >= 1 minute then sync success emits one toast; flapping stays at most one',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final conn = _FakeConnectivitySource();
    final store = MemoryTokenStore()..session = _fakeSession(linked: true);
    var now = DateTime(2026, 11, 23, 10, 0, 0);
    addTearDown(() async {
      await conn.dispose();
      await db.close();
    });

    final container = ProviderContainer(
      overrides: [
        onlineConfigProvider
            .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
        tokenStoreProvider.overrideWithValue(store),
        identityProvidersProvider.overrideWithValue(FakeIds()),
        httpClientProvider.overrideWithValue(
            MockClient((req) async => fakeServer(req))),
        databaseProvider.overrideWithValue(db),
        connectivitySourceProvider.overrideWithValue(conn),
        syncHealthClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionProvider.future);
    final health = container.read(syncHealthProvider.notifier);
    var toastCount = 0;
    final sub = health.onSavedAfterOffline.listen((_) => toastCount++);
    addTearDown(sub.cancel);

    // Go offline at 10:00:00
    conn.emit(false);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(syncHealthProvider).net, NetState.offline);
    expect(container.read(syncHealthProvider).offlineSince, now);

    // Flapping before sync succeeds: 10:00:20, 10:00:40, 10:01:05
    now = DateTime(2026, 11, 23, 10, 0, 20);
    conn.emit(true);
    await Future<void>.delayed(Duration.zero);
    now = DateTime(2026, 11, 23, 10, 0, 40);
    conn.emit(false);
    await Future<void>.delayed(Duration.zero);
    now = DateTime(2026, 11, 23, 10, 1, 5);
    conn.emit(true);
    await Future<void>.delayed(Duration.zero);

    // Sync completes at 10:01:10 -> >= 1 minute -> 1 toast emitted, offlineSince cleared.
    now = DateTime(2026, 11, 23, 10, 1, 10);
    health.recordSyncSuccess(pending: 0, at: now);
    await Future<void>.delayed(Duration.zero);
    expect(toastCount, 1);
    expect(container.read(syncHealthProvider).offlineSince, isNull);

    // Second immediate sync or brief < 1m flap does NOT trigger another toast.
    now = DateTime(2026, 11, 23, 10, 1, 15);
    conn.emit(false);
    await Future<void>.delayed(Duration.zero);
    now = DateTime(2026, 11, 23, 10, 1, 30);
    health.recordSyncSuccess(pending: 0, at: now);
    await Future<void>.delayed(Duration.zero);
    expect(toastCount, 1);
  });

  test('refreshPending reflects displayable unsaved progress while offline',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final conn = _FakeConnectivitySource()..current = false;
    final store = MemoryTokenStore()..session = _fakeSession(linked: true);
    addTearDown(() async {
      await conn.dispose();
      await db.close();
    });

    final kidId = await KidRepository(db)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    await ProgressRepository(db, kidId: kidId)
        .recordGlyphCompleted('so-1', failedStrokes: 0);
    await ProgressRepository(db, kidId: kidId)
        .recordLessonCompleted(itemsCompleted: 3);

    final container = ProviderContainer(
      overrides: [
        onlineConfigProvider
            .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
        tokenStoreProvider.overrideWithValue(store),
        identityProvidersProvider.overrideWithValue(FakeIds()),
        httpClientProvider.overrideWithValue(
            MockClient((req) async => fakeServer(req))),
        databaseProvider.overrideWithValue(db),
        connectivitySourceProvider.overrideWithValue(conn),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionProvider.future);
    await container.read(syncHealthProvider.notifier).refreshPending();
    expect(container.read(syncHealthProvider).pending, 2);
  });
}
