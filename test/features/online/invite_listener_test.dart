import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/online/invite_listener.dart';
import 'package:funedu/features/online_race/room_lobby_screen.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/friends/lobby_client.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/online/room/room_transport.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/screen_time/screen_time_guard.dart';
import 'package:http/testing.dart';

import '../../online/online_fakes.dart';
import '../setup_helpers.dart';

class _FakeTransport implements RoomTransport {
  final sent = <Map<String, Object?>>[];
  final _in = StreamController<Map<String, Object?>>.broadcast();
  bool closed = false;

  void push(Map<String, Object?> m) =>
      _in.add(jsonDecode(jsonEncode(m)) as Map<String, Object?>);

  @override
  Stream<Map<String, Object?>> get messages => _in.stream;

  @override
  void send(Map<String, Object?> message) => sent.add(message);

  @override
  Future<void> close() async {
    closed = true;
    if (!_in.isClosed) await _in.close();
  }
}

class _ErrorOnJoinRoomController extends RoomController {
  @override
  Future<void> join(String code, RoomKid kid) async {
    state = RoomState(
      phase: RoomPhase.error,
      code: code,
      error: 'not_found',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MemoryTokenStore store;
  late List<_FakeTransport> lobbySockets;
  late List<(_FakeTransport, String)> roomSockets;
  late DateTime fakeNow;

  Future<void> pumpOnlineApp(
    WidgetTester t, {
    bool signedIn = true,
    String initialLocation = '/game',
    Size size = const Size(375, 667),
  }) async {
    setSize(t, size.width, size.height);
    await t.runAsync(() async {
      final id = await KidRepository(db).addKid(
        nickname: 'Bé Na',
        avatar: kidAvatars.first,
        age: 5,
      );
      await placeKid(db, id);
    });
    if (signedIn) {
      store.session = const StoredSession(
        accessToken: 'a1',
        refreshToken: 'r1',
        familyId: 'fam-1',
        provider: 'google',
        email: 'me@x.vn',
        linked: true,
      );
    }
    appRouter.go(initialLocation);
    addTearDown(() => appRouter.go('/'));
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          onlineConfigProvider.overrideWithValue(
            const OnlineConfig(apiUrl: 'https://api.test'),
          ),
          httpClientProvider.overrideWithValue(
            MockClient((req) async => fakeServer(req)),
          ),
          tokenStoreProvider.overrideWithValue(store),
          identityProvidersProvider.overrideWithValue(FakeIds()),
          databaseProvider.overrideWithValue(db),
          lobbyClockProvider.overrideWithValue(() => fakeNow),
          lobbyConnectorProvider.overrideWithValue((_) async {
            final s = _FakeTransport();
            lobbySockets.add(s);
            return s;
          }),
          roomConnectorProvider.overrideWithValue((code, _) async {
            final s = _FakeTransport();
            roomSockets.add((s, code));
            return s;
          }),
        ],
        child: const App(),
      ),
    );
    await settle(t);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    store = MemoryTokenStore();
    lobbySockets = [];
    roomSockets = [];
    fakeNow = DateTime.utc(2026, 11, 23, 12, 0, 0);
  });

  testWidgets('guest mode makes zero /ws/lobby connections', (t) async {
    await pumpOnlineApp(t, signedIn: false, initialLocation: '/game');

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(t);

    expect(lobbySockets, isEmpty);
  });

  testWidgets('connects only on game, collection, and parent screens in foreground',
      (t) async {
    expect(isLobbyEligibleRoute('/'), isFalse);
    expect(isLobbyEligibleRoute('/house'), isFalse);
    expect(isLobbyEligibleRoute('/lesson'), isFalse);
    expect(isLobbyEligibleRoute('/game'), isTrue);
    expect(isLobbyEligibleRoute('/game/room/lobby'), isTrue);
    expect(isLobbyEligibleRoute('/collection'), isTrue);
    expect(isLobbyEligibleRoute('/parent'), isTrue);

    await pumpOnlineApp(t, signedIn: true, initialLocation: '/');
    expect(lobbySockets, isEmpty);

    appRouter.go('/game');
    await settle(t);
    expect(lobbySockets, hasLength(1));

    // Leaving /game stays open for 30s, then disconnects.
    appRouter.go('/');
    await settle(t);
    expect(lobbySockets.single.closed, isFalse);

    await t.pump(const Duration(seconds: 30));
    await t.pump();
    expect(lobbySockets.single.closed, isTrue);

    // Visiting /collection opens a connection.
    appRouter.go('/collection');
    await settle(t);
    expect(lobbySockets, hasLength(2));
  });

  testWidgets(
      'AppLifecycleState.inactive keeps socket open; paused closes and resumed reconnects',
      (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');
    expect(lobbySockets, hasLength(1));

    // Transient inactive state (e.g. notification shade / OAuth sheet) stays connected.
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(lobbySockets.single.closed, isFalse);

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(lobbySockets.single.closed, isTrue);

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(t);
    expect(lobbySockets, hasLength(2));
  });

  testWidgets(
      'accepting invite replies true, joins room, and navigates to room lobby',
      (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');
    expect(lobbySockets, hasLength(1));

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-1',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'XYZ789',
      'expiresInMs': 30000,
    });
    await settle(t);

    expect(find.text('Bin mời con đua tên lửa!'), findsOneWidget);
    expect(find.text('Vào đua'), findsOneWidget);
    expect(find.text('Để sau'), findsOneWidget);

    final acceptBtnSize =
        t.getSize(find.byKey(const ValueKey('invite-accept')));
    expect(acceptBtnSize.height, greaterThanOrEqualTo(64));

    await t.tap(find.byKey(const ValueKey('invite-accept')));
    await t.pump();
    await t.pump();

    expect(
      lobbySockets.single.sent,
      contains(equals({
        't': 'invite_reply',
        'inviteId': 'inv-1',
        'accept': true,
      })),
    );
    expect(roomSockets, hasLength(1));
    expect(roomSockets.single.$2, 'XYZ789');

    roomSockets.single.$1.push({
      't': 'joined',
      'you': 'p2',
    });
    roomSockets.single.$1.push({
      't': 'room',
      'code': 'XYZ789',
      'state': 'lobby',
      'host': 'p1',
      'players': [
        {
          'id': 'p1',
          'name': 'Bin',
          'avatar': kidAvatars[1],
          'rocket': 'rocket_orange',
          'steps': 0,
          'connected': true,
        },
        {
          'id': 'p2',
          'name': 'Bé Na',
          'avatar': kidAvatars.first,
          'rocket': 'rocket_blue',
          'steps': 0,
          'connected': true,
        },
      ],
    });
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(RoomLobbyScreen), findsOneWidget);
    expect(appRouter.routerDelegate.state.uri.path, '/game/room/lobby');
  });

  testWidgets(
      'room.join returning RoomPhase.error shows toast without navigating to lobby',
      (t) async {
    setSize(t, 375, 667);
    await t.runAsync(() async {
      final id = await KidRepository(db).addKid(
        nickname: 'Bé Na',
        avatar: kidAvatars.first,
        age: 5,
      );
      await placeKid(db, id);
    });
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: true,
    );
    appRouter.go('/game');
    addTearDown(() => appRouter.go('/'));

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          onlineConfigProvider.overrideWithValue(
            const OnlineConfig(apiUrl: 'https://api.test'),
          ),
          httpClientProvider.overrideWithValue(
            MockClient((req) async => fakeServer(req)),
          ),
          tokenStoreProvider.overrideWithValue(store),
          identityProvidersProvider.overrideWithValue(FakeIds()),
          databaseProvider.overrideWithValue(db),
          lobbyClockProvider.overrideWithValue(() => fakeNow),
          lobbyConnectorProvider.overrideWithValue((_) async {
            final s = _FakeTransport();
            lobbySockets.add(s);
            return s;
          }),
          roomControllerProvider.overrideWith(_ErrorOnJoinRoomController.new),
        ],
        child: const App(),
      ),
    );
    await settle(t);

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-err',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'BAD999',
      'expiresInMs': 30000,
    });
    await settle(t);

    await t.tap(find.byKey(const ValueKey('invite-accept')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.byType(RoomLobbyScreen), findsNothing);
    expect(appRouter.routerDelegate.state.uri.path, '/game');
    expect(
      find.text('Không tìm thấy phòng. Ba mẹ kiểm tra lại mã nhé'),
      findsOneWidget,
    );

    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
  });

  testWidgets(
      'simultaneous tap Vào đua and invite_cancelled does not double-pop or swallow accept',
      (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-race',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'RACE11',
      'expiresInMs': 30000,
    });
    await settle(t);

    // User taps accept, and in the same frame invite_cancelled arrives.
    await t.tap(find.byKey(const ValueKey('invite-accept')));
    lobbySockets.single.push({
      't': 'invite_cancelled',
      'inviteId': 'inv-race',
    });
    await t.pump();
    await t.pump();

    expect(
      lobbySockets.single.sent,
      contains(equals({
        't': 'invite_reply',
        'inviteId': 'inv-race',
        'accept': true,
      })),
    );
    expect(roomSockets, hasLength(1));
    expect(appRouter.routerDelegate.state.uri.path, '/game/room/lobby');
  });

  testWidgets('room.join failing synchronously shows error toast and stays off lobby',
      (t) async {
    setSize(t, 375, 667);
    await t.runAsync(() async {
      final id = await KidRepository(db).addKid(
        nickname: 'Bé Na',
        avatar: kidAvatars.first,
        age: 5,
      );
      await placeKid(db, id);
    });
    store.session = const StoredSession(
      accessToken: 'a1',
      refreshToken: 'r1',
      familyId: 'fam-1',
      provider: 'google',
      email: 'me@x.vn',
      linked: true,
    );
    appRouter.go('/game');
    addTearDown(() => appRouter.go('/'));

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          onlineConfigProvider.overrideWithValue(
            const OnlineConfig(apiUrl: 'https://api.test'),
          ),
          httpClientProvider.overrideWithValue(
            MockClient((req) async => fakeServer(req)),
          ),
          tokenStoreProvider.overrideWithValue(store),
          identityProvidersProvider.overrideWithValue(FakeIds()),
          databaseProvider.overrideWithValue(db),
          lobbyClockProvider.overrideWithValue(() => fakeNow),
          roomRetryDelaysProvider.overrideWithValue(const []),
          lobbyConnectorProvider.overrideWithValue((_) async {
            final s = _FakeTransport();
            lobbySockets.add(s);
            return s;
          }),
          roomConnectorProvider.overrideWithValue(
            (_, __) async => throw Exception('offline'),
          ),
        ],
        child: const App(),
      ),
    );
    await settle(t);

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-fail',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'FAIL01',
      'expiresInMs': 30000,
    });
    await settle(t);

    await t.tap(find.byKey(const ValueKey('invite-accept')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.byType(RoomLobbyScreen), findsNothing);
    expect(appRouter.routerDelegate.state.uri.path, '/game');
    expect(find.textContaining('Không kết nối được'), findsOneWidget);

    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
  });

  testWidgets('declining invite sends accept: false and closes dialog',
      (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-2',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'XYZ789',
      'expiresInMs': 30000,
    });
    await settle(t);

    expect(find.text('Bin mời con đua tên lửa!'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('invite-decline')));
    await settle(t);

    expect(find.text('Bin mời con đua tên lửa!'), findsNothing);
    expect(
      lobbySockets.single.sent,
      contains(equals({
        't': 'invite_reply',
        'inviteId': 'inv-2',
        'accept': false,
      })),
    );
    expect(roomSockets, isEmpty);
  });

  testWidgets('invite_cancelled closes open invite dialog automatically',
      (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-3',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': '',
      },
      'roomCode': 'XYZ789',
      'expiresInMs': 30000,
    });
    await settle(t);

    expect(find.text('Bin mời con đua tên lửa!'), findsOneWidget);

    lobbySockets.single.push({
      't': 'invite_cancelled',
      'inviteId': 'inv-3',
    });
    await settle(t);

    expect(find.text('Bin mời con đua tên lửa!'), findsNothing);
    expect(lobbySockets.single.sent, isEmpty);
  });

  testWidgets(
      'queued invite while writing waits within 30s grace and expired queued invite is dropped (Review Focus 3)',
      (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');
    expect(lobbySockets, hasLength(1));

    // Kid moves from /game to /trace/chu-a: socket remains open during 30s grace.
    appRouter.go('/trace/chu-a');
    await settle(t);

    // Invite 1 arrives while tracing and expires in 20s before kid returns.
    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-old',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'OLD111',
      'expiresInMs': 20000,
    });
    await t.pump();
    expect(find.text('Bin mời con đua tên lửa!'), findsNothing);

    // 25s pass while still on /trace/chu-a -> invite expires and is dropped.
    fakeNow = fakeNow.add(const Duration(seconds: 25));
    await t.pump(const Duration(seconds: 25));

    appRouter.go('/game');
    await settle(t);
    expect(find.text('Bin mời con đua tên lửa!'), findsNothing);

    // Return to /trace/chu-a; Invite 2 arrives and kid returns within 10s -> shows!
    appRouter.go('/trace/chu-a');
    await settle(t);

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-new',
      'from': {
        'familyId': 'fam-3',
        'kidUuid': 'kid-3',
        'nickname': 'Bông',
        'avatar': kidAvatars[2],
      },
      'roomCode': 'NEW222',
      'expiresInMs': 30000,
    });
    await t.pump();
    expect(find.text('Bông mời con đua tên lửa!'), findsNothing);

    fakeNow = fakeNow.add(const Duration(seconds: 10));
    await t.pump(const Duration(seconds: 10));

    appRouter.go('/game');
    await settle(t);

    expect(find.text('Bông mời con đua tên lửa!'), findsOneWidget);

    // Cleanly dismiss before test end.
    await t.tap(find.byKey(const ValueKey('invite-decline')));
    await settle(t);
  });

  testWidgets('tablet invite dialog buttons are >= 80pt tall', (t) async {
    await pumpOnlineApp(
      t,
      signedIn: true,
      initialLocation: '/game',
      size: const Size(1024, 1366),
    );

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-tab',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'TAB123',
      'expiresInMs': 30000,
    });
    await settle(t);

    expect(find.text('Bin mời con đua tên lửa!'), findsOneWidget);
    expect(
      t.getSize(find.byKey(const ValueKey('invite-accept'))).height,
      greaterThanOrEqualTo(80),
    );
    expect(
      t.getSize(find.byKey(const ValueKey('invite-decline'))).height,
      greaterThanOrEqualTo(80),
    );

    await t.tap(find.byKey(const ValueKey('invite-decline')));
    await settle(t);
  });

  testWidgets('sleep lock defers invite dialog until extra time is granted',
      (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');
    final container = ProviderScope.containerOf(t.element(find.byType(App)));

    container.read(screenTimeBlockedProvider.notifier).state = true;
    await t.pump();

    lobbySockets.single.push({
      't': 'invite',
      'inviteId': 'inv-sleep',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': kidAvatars[1],
      },
      'roomCode': 'SLP123',
      'expiresInMs': 30000,
    });
    await settle(t);
    expect(find.text('Bin mời con đua tên lửa!'), findsNothing);

    container.read(screenTimeBlockedProvider.notifier).state = false;
    await settle(t);
    expect(find.text('Bin mời con đua tên lửa!'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('invite-decline')));
    await settle(t);
  });

  testWidgets('reaction and invite_reply show warm toasts', (t) async {
    await pumpOnlineApp(t, signedIn: true, initialLocation: '/game');

    lobbySockets.single.push({
      't': 'reaction',
      'kidUuid': 'kid-1',
      'kind': 'clap',
      'fromNickname': 'Bin',
    });
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Bin vừa vỗ tay'), findsOneWidget);

    lobbySockets.single.push({
      't': 'invite_reply',
      'inviteId': 'inv-host',
      'accept': true,
    });
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Bạn đang vào phòng đua cùng bé!'), findsOneWidget);

    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
  });
}
