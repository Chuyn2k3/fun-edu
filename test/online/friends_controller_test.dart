import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/friends/friends_api.dart';
import 'package:funedu/online/friends/friends_controller.dart';
import 'package:funedu/online/friends/lobby_client.dart';
import 'package:funedu/online/net/network_status.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/room_transport.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_sync_server.dart';
import 'online_fakes.dart';

class _FakeLobbyTransport implements RoomTransport {
  final _in = StreamController<Map<String, Object?>>.broadcast();

  void push(Map<String, Object?> m) =>
      _in.add(jsonDecode(jsonEncode(m)) as Map<String, Object?>);

  @override
  Stream<Map<String, Object?>> get messages => _in.stream;

  @override
  void send(Map<String, Object?> message) {}

  @override
  Future<void> close() async {
    if (!_in.isClosed) await _in.close();
  }
}

class _FakeConnectivity implements ConnectivitySource {
  bool online = true;
  final _ctrl = StreamController<bool>.broadcast();

  @override
  Stream<bool> get hasConnection => _ctrl.stream;

  @override
  Future<bool> check() async => online;

  Future<void> dispose() => _ctrl.close();
}

void main() {
  late AppDatabase db;
  late MemoryTokenStore store;
  late List<http.Request> requests;
  late FutureOr<http.Response> Function(http.Request) handler;
  late DateTime fakeNow;
  late _FakeConnectivity connectivity;
  late List<_FakeLobbyTransport> sockets;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = MemoryTokenStore();
    requests = [];
    fakeNow = DateTime.utc(2026, 11, 23, 12, 0);
    connectivity = _FakeConnectivity();
    sockets = [];
    handler = (req) => fakeServer(req);
  });

  tearDown(() async {
    await connectivity.dispose();
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
          return handler(req);
        }),
      ),
      tokenStoreProvider.overrideWithValue(store),
      identityProvidersProvider.overrideWithValue(FakeIds()),
      databaseProvider.overrideWithValue(db),
      connectivitySourceProvider.overrideWithValue(connectivity),
      friendsClockProvider.overrideWithValue(() => fakeNow),
      lobbyConnectorProvider.overrideWithValue((_) async {
        final s = _FakeLobbyTransport();
        sockets.add(s);
        return s;
      }),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('FriendsApi & FriendsController', () {
    test('guest mode makes zero network calls and keeps empty state', () async {
      final c = makeContainer(signedIn: false);
      final state = await c.read(friendsControllerProvider.future);
      expect(state.friends, isEmpty);
      expect(state.activeCode, isNull);
      expect(requests, isEmpty);

      final createRes =
          await c.read(friendsControllerProvider.notifier).createCode();
      expect(createRes.ok, isFalse);
      expect(createRes.errorCode, 'signed_out');

      final redeemRes =
          await c.read(friendsControllerProvider.notifier).redeemCode('AB23CD');
      expect(redeemRes.ok, isFalse);
      expect(redeemRes.errorCode, 'signed_out');
      expect(requests, isEmpty);
    });

    test('createCode parses response and auto-clears after expiry', () async {
      handler = (req) {
        if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
          return jsonResponse([]);
        }
        if (req.url.path == '/api/v1/friends/code' && req.method == 'POST') {
          return jsonResponse({
            'code': 'AB23CD',
            'expiresAt': fakeNow.add(const Duration(seconds: 1)).toIso8601String(),
          });
        }
        return fakeServer(req);
      };
      final c = makeContainer();
      await c.read(friendsControllerProvider.future);

      final res = await c.read(friendsControllerProvider.notifier).createCode();
      expect(res.ok, isTrue);
      expect(res.data!.code, 'AB23CD');
      expect(
        c.read(friendsControllerProvider).value!.activeCode!.code,
        'AB23CD',
      );

      // Advance fake clock past expiry and verify automatic cleanup + timer clear.
      fakeNow = fakeNow.add(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(c.read(friendsControllerProvider).value!.activeCode, isNull);
    });

    test('redeemCode normalizes whitespace/case and maps all server errors',
        () async {
      String? nextErrorCode;
      int nextErrorStatus = 409;
      handler = (req) {
        if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
          return jsonResponse([]);
        }
        if (req.url.path == '/api/v1/friends/redeem' && req.method == 'POST') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['code'], 'XY78KM');
          if (nextErrorCode != null) {
            return jsonResponse({'error': nextErrorCode}, nextErrorStatus);
          }
          return jsonResponse({
            'friend': {
              'familyId': 'fam-2',
              'online': true,
              'kids': [
                {
                  'kidUuid': 'k-2',
                  'nickname': 'Bi',
                  'avatar': kidAvatars[0],
                  'rocket': 'rocket_blue',
                }
              ],
            },
          });
        }
        return fakeServer(req);
      };

      final c = makeContainer();
      await c.read(friendsControllerProvider.future);
      final ctrl = c.read(friendsControllerProvider.notifier);

      final cases = <(String, int, String, String)>[
        ('code_invalid', 404, 'invalid_code', 'Mã không đúng hoặc đã hết hạn'),
        ('self', 409, 'self_code', 'Đây là mã của chính nhà mình'),
        ('already_friends', 409, 'already_friends', 'Hai nhà đã là bạn rồi'),
        ('too_many_friends', 409, 'limit_reached', 'Đã đủ 50 bạn'),
        ('too_many', 429, 'too_many', 'Thử nhiều lần quá'),
        ('bad_request', 400, 'invalid_code', 'Mã không đúng hoặc đã hết hạn'),
      ];

      for (final (serverCode, status, expectedCode, expectedText) in cases) {
        nextErrorCode = serverCode;
        nextErrorStatus = status;
        final err = await ctrl.redeemCode('  xy7 8km ');
        expect(err.ok, isFalse, reason: serverCode);
        expect(err.errorCode, expectedCode);
        expect(err.errorMessage, contains(expectedText));
      }

      nextErrorCode = null;
      final ok = await ctrl.redeemCode('  xy7 8km ');
      expect(ok.ok, isTrue);
      expect(ok.data, isA<FriendFamily>());
      expect(ok.data!.familyId, 'fam-2');
      expect(ok.data!.kids.single.nickname, 'Bi');
      expect(
        c.read(friendsProvider).value!.map((f) => f.familyId),
        ['fam-2'],
      );
    });

    test('redeemCode distinguishes offline network vs server_unreachable',
        () async {
      handler = (req) {
        if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
          return jsonResponse([]);
        }
        throw const SocketException('unreachable');
      };
      final c = makeContainer();
      await c.read(friendsControllerProvider.future);
      final ctrl = c.read(friendsControllerProvider.notifier);

      connectivity.online = true;
      c.read(networkStatusProvider.notifier).reportNetworkError(hasConnection: true);
      final serverErr = await ctrl.redeemCode('AB23CD');
      expect(serverErr.errorCode, 'server_unreachable');
      await Future<void>.delayed(Duration.zero);

      connectivity.online = false;
      c.read(networkStatusProvider.notifier).reportNetworkError(hasConnection: false);
      final netErr = await ctrl.redeemCode('AB23CD');
      expect(netErr.errorCode, 'network');
    });

    test('removeFriend deletes and updates state, preserving cached list when offline',
        () async {
      var failNextList = false;
      handler = (req) {
        if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
          if (failNextList) throw const SocketException('offline');
          return jsonResponse([
            {
              'familyId': 'fam-2',
              'online': false,
              'kids': [
                {
                  'kidUuid': 'k-2',
                  'nickname': 'Bin',
                  'avatar': kidAvatars[1],
                  'rocket': 'rocket_green',
                }
              ],
            },
            {
              'familyId': 'fam-3',
              'online': true,
              'kids': [
                {
                  'kidUuid': 'k-3',
                  'nickname': 'Mít',
                  'avatar': kidAvatars[2],
                  'rocket': 'rocket_purple',
                }
              ],
            },
          ]);
        }
        if (req.url.path == '/api/v1/friends/fam-2' && req.method == 'DELETE') {
          return http.Response('', 204);
        }
        return fakeServer(req);
      };

      final c = makeContainer();
      final initial = await c.read(friendsControllerProvider.future);
      expect(initial.friends.map((f) => f.familyId), ['fam-2', 'fam-3']);

      // Offline refresh keeps previously cached friends without crashing.
      failNextList = true;
      await c.read(friendsControllerProvider.notifier).refresh();
      final cachedState = c.read(friendsControllerProvider).value!;
      expect(cachedState.friends.map((f) => f.familyId), ['fam-2', 'fam-3']);
      expect(cachedState.errorMessage, isNotNull);

      // Remove friend deletes and updates list cleanly.
      failNextList = false;
      final res =
          await c.read(friendsControllerProvider.notifier).removeFriend('fam-2');
      expect(res.ok, isTrue);
      expect(
        c.read(friendsControllerProvider).value!.friends.map((f) => f.familyId),
        ['fam-3'],
      );
    });

    test('live lobby updates presence dots and friend_added/friend_removed events',
        () async {
      var friendList = [
        {
          'familyId': 'fam-2',
          'online': false,
          'kids': [
            {
              'kidUuid': 'k-2',
              'nickname': 'Bin',
              'avatar': kidAvatars[1],
              'rocket': 'rocket_orange',
            }
          ],
        },
      ];
      handler = (req) {
        if (req.url.path == '/api/v1/friends' && req.method == 'GET') {
          return jsonResponse(friendList);
        }
        return fakeServer(req);
      };

      final c = makeContainer();
      await c.read(friendsControllerProvider.future);
      c.read(lobbyClientProvider.notifier).setRouteEligible(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(sockets, hasLength(1));

      // Hello marks fam-2 online.
      sockets.single.push({
        't': 'hello',
        'friendsOnline': ['fam-2'],
      });
      await Future<void>.delayed(Duration.zero);
      expect(c.read(friendsProvider).value!.single.online, isTrue);

      // Presence off marks fam-2 offline.
      sockets.single.push({
        't': 'presence',
        'familyId': 'fam-2',
        'online': false,
      });
      await Future<void>.delayed(Duration.zero);
      expect(c.read(friendsProvider).value!.single.online, isFalse);

      // friend_added triggers refresh from server.
      friendList = [
        ...friendList,
        {
          'familyId': 'fam-4',
          'online': true,
          'kids': [
            {
              'kidUuid': 'k-4',
              'nickname': 'Sóc',
              'avatar': kidAvatars[3],
              'rocket': 'rocket_blue',
            }
          ],
        },
      ];
      sockets.single.push({
        't': 'friend_added',
        'familyId': 'fam-4',
        'online': true,
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        c.read(friendsProvider).value!.map((f) => f.familyId),
        ['fam-2', 'fam-4'],
      );

      // friend_removed removes fam-2 locally at once.
      sockets.single.push({
        't': 'friend_removed',
        'familyId': 'fam-2',
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        c.read(friendsProvider).value!.map((f) => f.familyId),
        ['fam-4'],
      );
    });

    test('showcaseOn and showcaseLearning sync per kid across devices', () async {
      final server = FakeSyncServer();
      final phone = AppDatabase(NativeDatabase.memory());
      final ipad = AppDatabase(NativeDatabase.memory());
      addTearDown(phone.close);
      addTearDown(ipad.close);

      final kidId = await KidRepository(phone)
          .addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
      await KidRepository(phone).setSetting(showcaseOnKey(kidId), 'false');
      await KidRepository(phone).setSetting(showcaseLearningKey(kidId), 'true');

      await SyncEngine(phone, server.handle).run();
      await SyncEngine(ipad, server.handle).run();

      final ipadKid = (await KidRepository(ipad).kids()).single;
      expect(await KidRepository(ipad).setting(showcaseOnKey(ipadKid.id)), 'false');
      expect(
        await KidRepository(ipad).setting(showcaseLearningKey(ipadKid.id)),
        'true',
      );
    });
  });
}
