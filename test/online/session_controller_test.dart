import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/sync/sync_engine.dart';
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

  test('signed out, nothing ever touches the network', () async {
    final c = container();
    expect(await c.read(sessionProvider.future), isNull);
    c.read(syncControllerProvider);
    await c.read(syncControllerProvider.notifier).syncNow();
    expect(requests, isEmpty);
  });

  test('a build without a server URL refuses every call without a request', () async {
    final c = container(apiUrl: '');
    await expectLater(c.read(apiClientProvider).get('/api/v1/me'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)));
    expect(requests, isEmpty);
  });

  test('Google sign-in stores the session and sends the id token and deviceId', () async {
    final c = container();
    await c.read(sessionProvider.future);
    final res = await c.read(sessionProvider.notifier).signIn('google');

    final s = c.read(sessionProvider).value!;
    expect(s.familyId, 'fam-1');
    expect(s.email, 'me@x.vn');
    expect(s.linked, isFalse);
    expect(res.linked, isFalse);
    expect(store.session!.refreshToken, 'r1');
    final signIn = requests.firstWhere((r) => r.url.path == '/api/v1/auth/google');
    final body = jsonDecode(signIn.body) as Map<String, dynamic>;
    expect(body['idToken'], 'google-id-token');
    expect(body['deviceId'], isNotEmpty);
  });

  test('Apple sign-in uses the Apple endpoint and sends deviceId', () async {
    final c = container();
    await c.read(sessionProvider.future);
    await c.read(sessionProvider.notifier).signIn('apple');
    expect(requests.first.url.path, '/api/v1/auth/apple');
    final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
    expect(body['idToken'], 'apple-id-token');
    expect(body['authorizationCode'], 'apple-code');
    expect(body['deviceId'], isNotEmpty);
    expect(c.read(sessionProvider).value!.provider, 'apple');
  });

  test('sign-in sends deviceId and returns link state and account summary', () async {
    handler = (req) {
      if (req.url.path == '/api/v1/auth/google') {
        return jsonResponse({
          'accessToken': 'a-new',
          'refreshToken': 'r-new',
          'familyId': 'fam-na',
          'device': {'linked': false},
          'account': {
            'hasData': true,
            'kids': [
              {
                'nickname': 'Na',
                'avatar': 'chip',
                'stars': 120,
                'glyphs': 10,
                'pages': 8,
                'items': 3,
                'badges': 2,
              }
            ],
          },
        });
      }
      return fakeServer(req);
    };

    final c = container();
    await c.read(sessionProvider.future);
    final res = await c.read(sessionProvider.notifier).signIn('google');

    expect(res.linked, isFalse);
    expect(res.account.hasData, isTrue);
    expect(res.account.kids, hasLength(1));
    expect(res.account.kids.first.nickname, 'Na');
    expect(res.account.kids.first.stars, 120);

    final signIn = requests.firstWhere((r) => r.url.path == '/api/v1/auth/google');
    final body = jsonDecode(signIn.body) as Map<String, dynamic>;
    expect(body['deviceId'], isNotEmpty);
  });

  test('markLinked persists', () async {
    final c = container();
    await c.read(sessionProvider.future);
    await c.read(sessionProvider.notifier).signIn('google');

    expect(c.read(sessionProvider).value!.linked, isFalse);
    expect(store.session!.linked, isFalse);

    await c.read(sessionProvider.notifier).markLinked();

    expect(c.read(sessionProvider).value!.linked, isTrue);
    expect(store.session!.linked, isTrue);
  });

  test('cancelling the Google sheet makes no request', () async {
    ids.google = null;
    final c = container();
    await c.read(sessionProvider.future);
    await expectLater(c.read(sessionProvider.notifier).signIn('google'),
        throwsA(isA<SignInException>().having((e) => e.failure, 'f', SignInFailure.cancelled)));
    expect(requests, isEmpty);
    expect(store.session, isNull);
  });

  test('a rejected id token is reported and nothing is stored', () async {
    handler = (_) => jsonResponse({'error': 'unauthorized'}, 401);
    final c = container();
    await c.read(sessionProvider.future);
    await expectLater(c.read(sessionProvider.notifier).signIn('google'),
        throwsA(isA<SignInException>().having((e) => e.failure, 'f', SignInFailure.rejected)));
    expect(store.session, isNull);
  });

  test('an expired access token is refreshed once and the call retried', () async {
    store.session = const StoredSession(
        accessToken: 'old', refreshToken: 'r1', familyId: 'fam-1', provider: 'google');
    final base = handler;
    handler = (req) => req.url.path == '/api/v1/me' && req.headers['Authorization'] == 'Bearer old'
        ? jsonResponse({'error': 'unauthorized'}, 401)
        : base(req);
    final c = container();
    await c.read(sessionProvider.future);
    final me = await c.read(sessionProvider.notifier).authorized(
        (t) => c.read(apiClientProvider).get('/api/v1/me', accessToken: t));
    expect(me!['familyId'], 'fam-1');
    expect(store.session!.accessToken, 'a2');
    expect(store.session!.refreshToken, 'r2');
  });

  test('a refused refresh signs the parent out on this device', () async {
    store.session = const StoredSession(
        accessToken: 'old', refreshToken: 'stolen', familyId: 'fam-1', provider: 'google');
    handler = (_) => jsonResponse({'error': 'unauthorized'}, 401);
    final c = container();
    await c.read(sessionProvider.future);
    await expectLater(
        c.read(sessionProvider.notifier).authorized(
            (t) => c.read(apiClientProvider).get('/api/v1/me', accessToken: t)),
        throwsA(isA<ApiException>()));
    expect(c.read(sessionProvider).value, isNull);
    expect(store.session, isNull);
  });

  test('deleting the account calls the server and forgets the session', () async {
    store.session = const StoredSession(
        accessToken: 'a1', refreshToken: 'r1', familyId: 'fam-1', provider: 'google');
    await db.into(db.syncedRecords).insert(SyncedRecordsCompanion.insert(key: 'kid:x', version: 3));
    final c = container();
    await c.read(sessionProvider.future);
    await c.read(sessionProvider.notifier).deleteAccount();
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, '/api/v1/account');
    expect(store.session, isNull);
    expect(await db.select(db.syncedRecords).get(), isEmpty);
  });

  test('signing out keeps the data on the device but forgets sync history',
      () async {
    store.session = const StoredSession(
        accessToken: 'a1', refreshToken: 'r1', familyId: 'fam-1', provider: 'google');
    await db.into(db.syncedRecords).insert(SyncedRecordsCompanion.insert(key: 'kid:x', version: 3));
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(key: SyncEngine.cursorKey, value: '3'));
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(key: 'voiceEnabled', value: 'true'));
    final c = container();
    await c.read(sessionProvider.future);
    await c.read(sessionProvider.notifier).signOut();
    expect(requests.single.url.path, '/api/v1/auth/logout');
    expect(await db.select(db.syncedRecords).get(), isEmpty);
    final keys = (await db.select(db.appSettings).get()).map((r) => r.key);
    expect(keys, ['voiceEnabled']);
    expect(ids.signOuts, 1);
  });

  test('signing in starts a sync right away', () async {
    final c = container();
    c.read(syncControllerProvider);
    await c.read(sessionProvider.future);
    await c.read(sessionProvider.notifier).signIn('google');
    await Future<void>.delayed(Duration.zero);
    await c.read(syncControllerProvider.notifier).syncNow();
    expect(requests.where((r) => r.url.path == '/api/v1/sync'), isNotEmpty);
    expect(c.read(syncControllerProvider).lastAt, isNotNull);
  });

  test('already signed in at launch: the first sync runs on its own', () async {
    store.session = const StoredSession(
        accessToken: 'a1', refreshToken: 'r1', familyId: 'fam-1', provider: 'google');
    final c = container();
    await c.read(sessionProvider.future);
    c.read(syncControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(requests.where((r) => r.url.path == '/api/v1/sync'), hasLength(1));
    expect(c.read(syncControllerProvider).lastAt, isNotNull);
  });

  group('why a Google sign-in failed', () {
    Future<SignInException> failure(ProviderContainer c) async {
      await c.read(sessionProvider.future);
      try {
        await c.read(sessionProvider.notifier).signIn('google');
      } on SignInException catch (e) {
        return e;
      }
      fail('sign-in should have failed');
    }

    test('app not registered in Google Cloud (ApiException 10) is a setup problem', () async {
      ids.googleError = PlatformException(code: 'sign_in_failed', message: 'ApiException: 10: ');
      final e = await failure(container());
      expect(e.failure, SignInFailure.setup);
      expect(e.detail, contains('ApiException: 10'));
      expect(requests, isEmpty);
    });

    test('closing the Google sheet (12501) is a cancel, not an error', () async {
      ids.googleError = PlatformException(code: 'sign_in_canceled', message: 'ApiException: 12501');
      expect((await failure(container())).failure, SignInFailure.cancelled);
    });

    test('no id token (build without GOOGLE_SERVER_CLIENT_ID) is a setup problem', () async {
      ids.googleError = const MissingIdTokenException('GOOGLE_SERVER_CLIENT_ID chưa được truyền khi build');
      final e = await failure(container());
      expect(e.failure, SignInFailure.setup);
      expect(e.detail, contains('GOOGLE_SERVER_CLIENT_ID'));
    });

    test('server unreachable says which URL', () async {
      handler = (_) => throw const SocketException('refused');
      final e = await failure(container());
      expect(e.failure, SignInFailure.network);
      expect(e.detail, contains('https://api.test'));
    });

    test('server refusing the token says the status', () async {
      handler = (_) => jsonResponse({'error': 'unauthorized'}, 401);
      final e = await failure(container());
      expect(e.failure, SignInFailure.rejected);
      expect(e.detail, contains('401'));
    });
  });
}

