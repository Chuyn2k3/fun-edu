import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/link/link_controller.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'online_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;
  late MemoryTokenStore store;
  late FakeIds ids;
  late AppDatabase db;

  ProviderContainer container({String apiUrl = 'https://api.test'}) {
    final c = ProviderContainer(overrides: [
      onlineConfigProvider.overrideWithValue(OnlineConfig(apiUrl: apiUrl)),
      httpClientProvider.overrideWithValue(MockClient((req) async {
        requests.add(req);
        return handler(req);
      })),
      tokenStoreProvider.overrideWithValue(store),
      identityProvidersProvider.overrideWithValue(ids),
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    requests = [];
    store = MemoryTokenStore();
    ids = FakeIds();
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    handler = fakeServer;
  });

  test('empty device links fresh and restores', () async {
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {
            'hasData': true,
            'kids': [
              {'nickname': 'Na', 'avatar': 'chip', 'stars': 10},
              {'nickname': 'Bo', 'avatar': 'chip', 'stars': 20},
            ],
          },
        });
      }
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({'linked': true});
      }
      if (req.url.path == '/api/v1/sync') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final since = (body['since'] as num?)?.toInt() ?? 0;
        if (since >= 2) {
          return jsonResponse({'version': 2, 'hasMore': false, 'conflicts': [], 'records': []});
        }
        return jsonResponse({
          'version': 2,
          'hasMore': false,
          'conflicts': [],
          'records': [
            {
              'key': 'kid:uuid-na',
              'payload': {'nickname': 'Na', 'avatar': 'chip', 'age': 5, 'createdAt': 1700000000},
              'deleted': false,
              'version': 1,
            },
            {
              'key': 'kid:uuid-bo',
              'payload': {'nickname': 'Bo', 'avatar': 'chip', 'age': 4, 'createdAt': 1700000001},
              'deleted': false,
              'version': 2,
            },
          ],
        });
      }
      return fakeServer(req);
    };

    final c = container();
    final res = await c.read(sessionProvider.notifier).signIn('google');
    await c.read(linkControllerProvider.notifier).afterSignIn(res);

    expect(c.read(linkControllerProvider), isA<LinkIdle>());
    final kids = await KidRepository(db).kids();
    expect(kids, hasLength(2));
    expect(kids.first.nickname, 'Na');
    expect(kids.last.nickname, 'Bo');
    expect(await KidRepository(db).currentKidId(), kids.first.id);
    expect(await KidRepository(db).setting(restorePendingKey), isNull);
    expect(await KidRepository(db).setting(dataOwnerKey), 'fam-1');
  });

  test('guest data into empty account uploads without asking', () async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);

    var linkModeCalled = '';
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {'hasData': false, 'kids': []},
        });
      }
      if (req.url.path == '/api/v1/sync/link') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        linkModeCalled = body['mode'] as String;
        return jsonResponse({'linked': true});
      }
      return fakeServer(req);
    };

    final c = container();
    final res = await c.read(sessionProvider.notifier).signIn('google');
    await c.read(linkControllerProvider.notifier).afterSignIn(res);

    expect(linkModeCalled, 'upload');
    expect(c.read(linkControllerProvider), isA<LinkIdle>());
    expect(c.read(sessionProvider).value!.linked, isTrue);
    expect(await KidRepository(db).setting(dataOwnerKey), 'fam-1');
  });

  test('guest data into account with data needs warning', () async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);

    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {
            'hasData': true,
            'kids': [
              {'nickname': 'CloudKid', 'avatar': 'chip', 'stars': 50},
            ],
          },
        });
      }
      return fakeServer(req);
    };

    final c = container();
    final res = await c.read(sessionProvider.notifier).signIn('google');
    await c.read(linkControllerProvider.notifier).afterSignIn(res);

    final state = c.read(linkControllerProvider);
    expect(state, isA<LinkNeedsWarning>());
    final warning = state as LinkNeedsWarning;
    expect(warning.account.kids.single.nickname, 'CloudKid');
    expect(warning.local.single.nickname, 'GuestKid');
  });

  test('upload refused shows warning with server numbers', () async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);

    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {'hasData': false, 'kids': []},
        });
      }
      if (req.url.path == '/api/v1/sync/link' && req.method == 'POST') {
        return jsonResponse({'error': 'account_not_empty'}, 409);
      }
      if (req.url.path == '/api/v1/sync/link' && req.method == 'GET') {
        return jsonResponse({
          'linked': false,
          'account': {
            'hasData': true,
            'kids': [
              {'nickname': 'ConcurrentKid', 'avatar': 'chip', 'stars': 100},
            ],
          },
        });
      }
      return fakeServer(req);
    };

    final c = container();
    final res = await c.read(sessionProvider.notifier).signIn('google');
    await c.read(linkControllerProvider.notifier).afterSignIn(res);

    final state = c.read(linkControllerProvider);
    expect(state, isA<LinkNeedsWarning>());
    final warning = state as LinkNeedsWarning;
    expect(warning.account.kids.single.nickname, 'ConcurrentKid');
    expect(warning.local.single.nickname, 'GuestKid');
  });

  test('cancel signs out and keeps guest data', () async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);

    final c = container();
    await c.read(sessionProvider.notifier).signIn('google');
    expect(c.read(sessionProvider).valueOrNull, isNotNull);

    await c.read(linkControllerProvider.notifier).cancelReplace();

    expect(c.read(sessionProvider).valueOrNull, isNull);
    expect(await KidRepository(db).kids(), hasLength(1));
    expect((await KidRepository(db).kids()).single.nickname, 'GuestKid');
  });

  test('confirm replaces local data', () async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);
    await KidRepository(db).setSetting('deviceId', 'dev-uuid-1');
    await KidRepository(db).setSetting('consentAt', '2026-11-20T10:00:00Z');

    var linkModeCalled = '';
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link' && req.method == 'POST') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        linkModeCalled = body['mode'] as String;
        return jsonResponse({'linked': true});
      }
      if (req.url.path == '/api/v1/sync') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final since = (body['since'] as num?)?.toInt() ?? 0;
        if (since >= 1) {
          return jsonResponse({'version': 1, 'hasMore': false, 'conflicts': [], 'records': []});
        }
        return jsonResponse({
          'version': 1,
          'hasMore': false,
          'conflicts': [],
          'records': [
            {
              'key': 'kid:uuid-cloud',
              'payload': {'nickname': 'CloudKid', 'avatar': 'chip', 'age': 6, 'createdAt': 1700000000},
              'deleted': false,
              'version': 1,
            },
          ],
        });
      }
      return fakeServer(req);
    };

    final c = container();
    await c.read(sessionProvider.notifier).signIn('google');
    await c.read(linkControllerProvider.notifier).confirmReplace();

    expect(linkModeCalled, 'replace_local');
    expect(c.read(linkControllerProvider), isA<LinkIdle>());
    final kids = await KidRepository(db).kids();
    expect(kids, hasLength(1));
    expect(kids.single.nickname, 'CloudKid');
    expect(await KidRepository(db).setting('deviceId'), 'dev-uuid-1');
    expect(await KidRepository(db).setting('consentAt'), '2026-11-20T10:00:00Z');
    expect(await KidRepository(db).setting(dataOwnerKey), 'fam-1');
  });

  test('already linked device just syncs', () async {
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'familyId': 'fam-1',
          'device': {'linked': true},
          'account': {'hasData': true, 'kids': []},
        });
      }
      return fakeServer(req);
    };

    final c = container();
    final res = await c.read(sessionProvider.notifier).signIn('google');
    await c.read(linkControllerProvider.notifier).afterSignIn(res);

    expect(c.read(linkControllerProvider), isA<LinkIdle>());
    expect(c.read(sessionProvider).value!.linked, isTrue);
  });

  test('restore resumes after restart', () async {
    await KidRepository(db).setSetting(restorePendingKey, 'true');

    handler = (req) {
      if (req.url.path == '/api/v1/sync') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final since = (body['since'] as num?)?.toInt() ?? 0;
        if (since >= 1) {
          return jsonResponse({'version': 1, 'hasMore': false, 'conflicts': [], 'records': []});
        }
        return jsonResponse({
          'version': 1,
          'hasMore': false,
          'conflicts': [],
          'records': [
            {
              'key': 'kid:uuid-resumed',
              'payload': {'nickname': 'ResumedKid', 'avatar': 'chip', 'age': 5, 'createdAt': 1700000000},
              'deleted': false,
              'version': 1,
            },
          ],
        });
      }
      return fakeServer(req);
    };

    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      linked: true,
    );

    final c = container();
    await c.read(sessionProvider.future);
    await c.read(linkControllerProvider.notifier).resumeIfPending();

    expect(c.read(linkControllerProvider), isA<LinkIdle>());
    final kids = await KidRepository(db).kids();
    expect(kids, hasLength(1));
    expect(kids.single.nickname, 'ResumedKid');
    expect(await KidRepository(db).setting(restorePendingKey), isNull);
  });

  test('sync is not pushed while unlinked', () async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      linked: false,
    );

    final c = container();
    await c.read(sessionProvider.future);
    await c.read(syncControllerProvider.notifier).syncNow();

    // Verify no /api/v1/sync request was made
    expect(requests.where((r) => r.url.path == '/api/v1/sync'), isEmpty);
  });

  test('resume after crash between link and wipe never pushes guest data', () async {
    await KidRepository(db).addKid(nickname: 'GuestKid', avatar: kidAvatars[0], age: 5);
    await KidRepository(db).setSetting(restorePendingKey, 'replace');

    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      linked: false,
    );

    var totalPushedChanges = 0;
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link') {
        return jsonResponse({'linked': true});
      }
      if (req.url.path == '/api/v1/sync') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final changes = body['changes'] as List? ?? [];
        totalPushedChanges += changes.length;
        final since = (body['since'] as num?)?.toInt() ?? 0;
        if (since >= 1) {
          return jsonResponse({'version': 1, 'hasMore': false, 'conflicts': [], 'records': []});
        }
        return jsonResponse({
          'version': 1,
          'hasMore': false,
          'conflicts': [],
          'records': [
            {
              'key': 'kid:uuid-cloud',
              'payload': {'nickname': 'CloudKid', 'avatar': 'chip', 'age': 6, 'createdAt': 1700000000},
              'deleted': false,
              'version': 1,
            },
          ],
        });
      }
      return fakeServer(req);
    };

    final c = container();
    await c.read(sessionProvider.future);
    await c.read(linkControllerProvider.notifier).resumeIfPending();

    expect(totalPushedChanges, 0);
    final kids = await KidRepository(db).kids();
    expect(kids, hasLength(1));
    expect(kids.single.nickname, 'CloudKid');
    expect(await KidRepository(db).setting(restorePendingKey), isNull);
    expect(await KidRepository(db).setting(dataOwnerKey), 'fam-1');
  });

  test('resume after wipe only pulls', () async {
    await KidRepository(db).setSetting(restorePendingKey, 'pull');

    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      linked: true,
    );

    var totalPushedChanges = 0;
    var linkEndpointCalled = false;
    handler = (req) {
      if (req.url.path == '/api/v1/sync/link') {
        linkEndpointCalled = true;
        return jsonResponse({'linked': true});
      }
      if (req.url.path == '/api/v1/sync') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final changes = body['changes'] as List? ?? [];
        totalPushedChanges += changes.length;
        final since = (body['since'] as num?)?.toInt() ?? 0;
        if (since >= 1) {
          return jsonResponse({'version': 1, 'hasMore': false, 'conflicts': [], 'records': []});
        }
        return jsonResponse({
          'version': 1,
          'hasMore': false,
          'conflicts': [],
          'records': [
            {
              'key': 'kid:uuid-cloud',
              'payload': {'nickname': 'CloudKid', 'avatar': 'chip', 'age': 6, 'createdAt': 1700000000},
              'deleted': false,
              'version': 1,
            },
          ],
        });
      }
      return fakeServer(req);
    };

    final c = container();
    await c.read(sessionProvider.future);
    await c.read(linkControllerProvider.notifier).resumeIfPending();

    expect(totalPushedChanges, 0);
    expect(linkEndpointCalled, isFalse);
    final kids = await KidRepository(db).kids();
    expect(kids, hasLength(1));
    expect(kids.single.nickname, 'CloudKid');
    expect(await KidRepository(db).setting(restorePendingKey), isNull);
  });

  test('retry after failed fresh link links the device', () async {
    var linkAttempt = 0;
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a1',
          'refreshToken': 'r1',
          'familyId': 'fam-1',
          'device': {'linked': false},
          'account': {'hasData': true, 'kids': []},
        });
      }
      if (req.url.path == '/api/v1/sync/link') {
        linkAttempt++;
        if (linkAttempt == 1) {
          return http.Response('server error', 500);
        }
        return jsonResponse({'linked': true});
      }
      if (req.url.path == '/api/v1/sync') {
        return jsonResponse({'version': 1, 'hasMore': false, 'conflicts': [], 'records': []});
      }
      return fakeServer(req);
    };

    final c = container();
    final res = await c.read(sessionProvider.notifier).signIn('google');
    await c.read(linkControllerProvider.notifier).afterSignIn(res);

    expect(c.read(linkControllerProvider), isA<LinkRestoreFailed>());
    expect(await KidRepository(db).setting(restorePendingKey), 'fresh');
    expect(c.read(sessionProvider).value!.linked, isFalse);

    // Now retry
    await c.read(linkControllerProvider.notifier).retryRestore();

    expect(c.read(linkControllerProvider), isA<LinkIdle>());
    expect(linkAttempt, 2);
    expect(c.read(sessionProvider).value!.linked, isTrue);
    expect(await KidRepository(db).setting(restorePendingKey), isNull);
  });
}
