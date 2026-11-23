import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/friends/showcase.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'online_fakes.dart';

void main() {
  late AppDatabase db;
  late MemoryTokenStore store;
  late List<http.Request> requests;
  late DateTime fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = MemoryTokenStore();
    requests = [];
    fakeNow = DateTime.utc(2026, 11, 23, 12, 0);
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer makeContainer({
    bool signedIn = true,
    bool enabled = true,
  }) {
    if (signedIn) {
      store.session = const StoredSession(
        accessToken: 'tok-1',
        refreshToken: 'ref-1',
        familyId: 'fam-1',
        provider: 'google',
        linked: true,
      );
    }
    final c = ProviderContainer(overrides: [
      onlineConfigProvider.overrideWithValue(
        OnlineConfig(apiUrl: enabled ? 'https://api.test' : ''),
      ),
      httpClientProvider.overrideWithValue(
        MockClient((req) async {
          requests.add(req);
          if ((req.method == 'PUT' || req.method == 'DELETE') &&
              req.url.path.startsWith('/api/v1/showcase/')) {
            return http.Response('', 204);
          }
          return http.Response('{"error":"not_found"}', 404);
        }),
      ),
      tokenStoreProvider.overrideWithValue(store),
      identityProvidersProvider.overrideWithValue(FakeIds()),
      databaseProvider.overrideWithValue(db),
      showcaseClockProvider.overrideWithValue(() => fakeNow),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<int> insertKid(AppDatabase db, {String name = 'Bé Bắp'}) async {
    return KidRepository(db).addKid(
      nickname: name,
      avatar: kidAvatars[1],
      age: 5,
    );
  }

  test('guest mode or signed-out makes no showcase sync request', () async {
    final c = makeContainer(signedIn: false);
    final sync = c.read(showcaseSyncProvider);
    final res = await sync.request();
    expect(res, isFalse);
    expect(requests, isEmpty);
  });

  test('sync is coalesced to once per 5 minutes per kid', () async {
    final kidId = await insertKid(db);
    final c = makeContainer();
    final repo = c.read(kidRepositoryProvider);
    await repo.setSetting('showcaseOn.$kidId', 'true');

    final sync = c.read(showcaseSyncProvider);

    // First request should succeed and send PUT
    final res1 = await sync.request(kidId: kidId);
    expect(res1, isTrue);
    expect(requests.length, 1);
    expect(requests.first.method, 'PUT');
    expect(requests.first.url.path, startsWith('/api/v1/showcase/'));

    // Second request right away within 5 minutes should be coalesced (skipped)
    fakeNow = fakeNow.add(const Duration(minutes: 2));
    final res2 = await sync.request(kidId: kidId);
    expect(res2, isFalse);
    expect(requests.length, 1); // No new request sent

    // Advance clock past 5 minutes (5 min + 1 sec) -> next request should succeed
    fakeNow = fakeNow.add(const Duration(minutes: 3, seconds: 1));
    final res3 = await sync.request(kidId: kidId);
    expect(res3, isTrue);
    expect(requests.length, 2);
  });

  test('sync skips when showcaseOn is false', () async {
    final kidId = await insertKid(db);
    final c = makeContainer();
    final repo = c.read(kidRepositoryProvider);
    await repo.setSetting('showcaseOn.$kidId', 'false');

    final sync = c.read(showcaseSyncProvider);
    final res = await sync.request(kidId: kidId);
    expect(res, isFalse);
    expect(requests, isEmpty);
  });

  test('payload excludes learning when showcaseLearning is false', () async {
    final kidId = await insertKid(db);
    final c = makeContainer();
    final repo = c.read(kidRepositoryProvider);
    await repo.setSetting('showcaseOn.$kidId', 'true');
    await repo.setSetting('showcaseLearning.$kidId', 'false');

    final sync = c.read(showcaseSyncProvider);
    final res = await sync.request(kidId: kidId);
    expect(res, isTrue);
    expect(requests.length, 1);

    final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
    expect(body['nickname'], 'Bé Bắp');
    expect(body.containsKey('learning'), isFalse);
  });

  test('payload includes learning when showcaseLearning is true', () async {
    final kidId = await insertKid(db);
    final c = makeContainer();
    final repo = c.read(kidRepositoryProvider);
    await repo.setSetting('showcaseOn.$kidId', 'true');
    await repo.setSetting('showcaseLearning.$kidId', 'true');

    final sync = c.read(showcaseSyncProvider);
    final res = await sync.request(kidId: kidId);
    expect(res, isTrue);
    expect(requests.length, 1);

    final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
    expect(body['learning'], isNotNull);
    final learning = body['learning'] as Map<String, dynamic>;
    expect(learning.containsKey('glyphs'), isTrue);
    expect(learning.containsKey('lessons'), isTrue);
    expect(learning.containsKey('stars'), isTrue);
  });

  Map<String, dynamic> lastBody() =>
      jsonDecode(requests.last.body) as Map<String, dynamic>;

  test('payload shows the rocket and trail in use and counts stickers only',
      () async {
    final kidId = await insertKid(db);
    final c = makeContainer();
    await c.read(kidRepositoryProvider).setSetting('showcaseOn.$kidId', 'true');
    await db.into(db.gameProfile).insert(GameProfileCompanion.insert(
          kidId: Value(kidId),
          selectedRocket: const Value('rocket_blue'),
          selectedTrail: const Value('trail_rainbow'),
        ));
    for (final item in ['sticker_clap', 'rare_crown', 'rocket_blue']) {
      await db
          .into(db.gameItems)
          .insert(GameItemsCompanion.insert(kidId: kidId, itemId: item));
    }

    expect(await c.read(showcaseSyncProvider).request(kidId: kidId), isTrue);
    final body = lastBody();
    expect(body['rocket'], 'rocket_blue');
    expect(body['trail'], 'trail_rainbow');
    expect(body['stickers'], 2, reason: 'a rocket is not a sticker');
  });

  test('learning numbers are those of the kid being sent, not the current one',
      () async {
    final current = await insertKid(db, name: 'Na');
    final other = await insertKid(db, name: 'Bin');
    await KidRepository(db).setCurrentKid(current);
    for (var i = 0; i < 2; i++) {
      await db.into(db.lessonCompletions).insert(LessonCompletionsCompanion.insert(
          kidId: other,
          completedAt: DateTime(2026, 11, 20 + i),
          starsEarned: 7));
    }
    final c = makeContainer();
    final repo = c.read(kidRepositoryProvider);
    await repo.setSetting('showcaseOn.$other', 'true');
    await repo.setSetting('showcaseLearning.$other', 'true');

    expect(await c.read(showcaseSyncProvider).request(kidId: other), isTrue);
    final learning = lastBody()['learning'] as Map<String, dynamic>;
    expect(learning['lessons'], 2);
    expect(learning['stars'], 14);
    expect(lastBody()['nickname'], 'Bin');
  });

  test('turning the showcase off takes it down on the server', () async {
    final kidId = await insertKid(db);
    final c = makeContainer();
    final uuid = (await KidRepository(db).kids()).single.uuid;

    expect(await c.read(showcaseSyncProvider).takeDown(kidId), isTrue);
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, '/api/v1/showcase/$uuid');
  });

  test('a switch change is sent at once, even inside the 5 minutes', () async {
    final kidId = await insertKid(db);
    final c = makeContainer();
    await c.read(kidRepositoryProvider).setSetting('showcaseOn.$kidId', 'true');
    final sync = c.read(showcaseSyncProvider);

    expect(await sync.request(kidId: kidId), isTrue);
    fakeNow = fakeNow.add(const Duration(minutes: 1));
    expect(await sync.request(kidId: kidId), isFalse);
    expect(await sync.request(kidId: kidId, force: true), isTrue);
    expect(requests.where((r) => r.method == 'PUT'), hasLength(2));
  });
}
