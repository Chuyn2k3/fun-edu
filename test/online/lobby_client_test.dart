import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/session_controller.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/friends/lobby_client.dart';
import 'package:funedu/online/net/network_status.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/room_transport.dart';
import 'package:http/testing.dart';

import 'online_fakes.dart';

class FakeLobbyTransport implements RoomTransport {
  final sent = <Map<String, Object?>>[];
  final _in = StreamController<Map<String, Object?>>.broadcast();
  bool closed = false;

  void push(Map<String, Object?> m) =>
      _in.add(jsonDecode(jsonEncode(m)) as Map<String, Object?>);

  void pushRaw(Map<String, Object?> m) => _in.add(m);

  Future<void> drop() async {
    if (!_in.isClosed) await _in.close();
  }

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

class _MutableConnectivity implements ConnectivitySource {
  final _ctrl = StreamController<bool>.broadcast();
  bool current = true;

  @override
  Stream<bool> get hasConnection => _ctrl.stream;

  @override
  Future<bool> check() async => current;

  void setOnline(bool online) {
    current = online;
    _ctrl.add(online);
  }

  Future<void> dispose() => _ctrl.close();
}

void main() {
  late AppDatabase db;
  late MemoryTokenStore store;
  late List<FakeLobbyTransport> sockets;
  late List<String> connectedTokens;
  late DateTime fakeNow;
  late _MutableConnectivity connectivity;
  var failConnect = false;

  ProviderContainer makeContainer({
    bool signedIn = true,
    bool enabled = true,
    bool autoDispose = true,
    Duration pingInterval = const Duration(seconds: 25),
    Duration leaveDelay = const Duration(seconds: 30),
    List<Duration> retryDelays = const [
      Duration(milliseconds: 10),
      Duration(milliseconds: 20),
      Duration(milliseconds: 30),
      Duration(milliseconds: 40),
    ],
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
        MockClient((req) async => fakeServer(req)),
      ),
      tokenStoreProvider.overrideWithValue(store),
      identityProvidersProvider.overrideWithValue(FakeIds()),
      databaseProvider.overrideWithValue(db),
      connectivitySourceProvider.overrideWithValue(connectivity),
      lobbyClockProvider.overrideWithValue(() => fakeNow),
      lobbyPingIntervalProvider.overrideWithValue(pingInterval),
      lobbyLeaveDelayProvider.overrideWithValue(leaveDelay),
      lobbyRetryDelaysProvider.overrideWithValue(retryDelays),
      lobbyConnectorProvider.overrideWithValue((token) async {
        if (failConnect) throw Exception('connect failed');
        connectedTokens.add(token);
        final s = FakeLobbyTransport();
        sockets.add(s);
        return s;
      }),
    ]);
    if (autoDispose) addTearDown(c.dispose);
    return c;
  }

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    store = MemoryTokenStore();
    sockets = [];
    connectedTokens = [];
    fakeNow = DateTime.utc(2026, 11, 23, 12, 0, 0);
    connectivity = _MutableConnectivity();
    addTearDown(connectivity.dispose);
    failConnect = false;
  });

  test('guest mode never connects to /ws/lobby even on eligible route',
      () async {
    final c = makeContainer(signedIn: false);
    c.read(lobbyClientProvider);
    await c.read(sessionProvider.future);
    await flush();

    c.read(lobbyClientProvider.notifier).setRouteEligible(true);
    c.read(lobbyClientProvider.notifier).onAppResumed();
    await flush();

    expect(sockets, isEmpty);
    expect(connectedTokens, isEmpty);
    expect(c.read(lobbyClientProvider).connected, isFalse);
  });

  test('signed-in does not connect until on an eligible route', () async {
    final c = makeContainer(signedIn: true);
    c.read(lobbyClientProvider);
    await c.read(sessionProvider.future);
    await flush();

    expect(sockets, isEmpty);
    expect(c.read(lobbyClientProvider).connected, isFalse);

    c.read(lobbyClientProvider.notifier).setRouteEligible(true);
    await flush();

    expect(sockets, hasLength(1));
    expect(connectedTokens, ['tok-1']);
    expect(c.read(lobbyClientProvider).connected, isTrue);
  });

  testWidgets('closes 30 s after leaving an eligible route', (t) async {
    final c = makeContainer(signedIn: true, autoDispose: false);
    expect(c.read(lobbyLeaveDelayProvider), const Duration(seconds: 30));

    final lobby = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    lobby.setRouteEligible(true);
    await t.pump();
    await t.pump();
    expect(sockets, hasLength(1));
    expect(c.read(lobbyClientProvider).connected, isTrue);

    // Leave eligible route: stays connected during the 30s grace window.
    lobby.setRouteEligible(false);
    await t.pump(const Duration(seconds: 15));
    expect(sockets.single.closed, isFalse);
    expect(c.read(lobbyClientProvider).connected, isTrue);

    // Returning before 30s cancels the leave timer.
    lobby.setRouteEligible(true);
    await t.pump(const Duration(seconds: 20));
    expect(sockets.single.closed, isFalse);
    expect(c.read(lobbyClientProvider).connected, isTrue);

    // Leaving for the full 30s closes the socket.
    lobby.setRouteEligible(false);
    await t.pump(const Duration(seconds: 30));
    expect(sockets.single.closed, isTrue);
    expect(c.read(lobbyClientProvider).connected, isFalse);

    c.dispose();
  });

  test('signed-in connects on resume and closes on pause and sign-out',
      () async {
    final c = makeContainer(signedIn: true);
    final lobby = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    lobby.setRouteEligible(true);
    await flush();

    expect(sockets, hasLength(1));
    expect(connectedTokens, ['tok-1']);
    expect(c.read(lobbyClientProvider).connected, isTrue);

    lobby.onAppPaused();
    await flush();
    expect(sockets.single.closed, isTrue);
    expect(c.read(lobbyClientProvider).connected, isFalse);

    lobby.onAppResumed();
    await flush();
    expect(sockets, hasLength(2));
    expect(c.read(lobbyClientProvider).connected, isTrue);

    await c.read(sessionProvider.notifier).signOut();
    await flush();
    expect(sockets[1].closed, isTrue);
    expect(c.read(lobbyClientProvider).connected, isFalse);
  });

  test('disconnects when network goes offline and reconnects when back',
      () async {
    final c = makeContainer(signedIn: true);
    c.read(networkStatusProvider);
    final lobby = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    lobby.setRouteEligible(true);
    await flush();

    expect(sockets, hasLength(1));

    connectivity.setOnline(false);
    await flush();
    expect(sockets.single.closed, isTrue);
    expect(c.read(lobbyClientProvider).connected, isFalse);

    connectivity.setOnline(true);
    await flush();
    expect(sockets, hasLength(2));
    expect(c.read(lobbyClientProvider).connected, isTrue);
  });

  test('hello, presence, friend_added, friend_removed update onlineFriends',
      () async {
    final c = makeContainer(signedIn: true);
    final events = <LobbyFriendEvent>[];
    final lobby = c.read(lobbyClientProvider.notifier);
    final sub = lobby.friendEvents.listen(events.add);
    addTearDown(sub.cancel);

    await c.read(sessionProvider.future);
    lobby.setRouteEligible(true);
    await flush();

    final sock = sockets.single;
    sock.push({
      't': 'hello',
      'friendsOnline': ['fam-2', 'fam-3'],
    });
    await flush();
    expect(c.read(lobbyClientProvider).onlineFriends, {'fam-2', 'fam-3'});

    sock.push({'t': 'presence', 'familyId': 'fam-4', 'online': true});
    sock.push({'t': 'presence', 'familyId': 'fam-2', 'online': false});
    await flush();
    expect(c.read(lobbyClientProvider).onlineFriends, {'fam-3', 'fam-4'});

    sock.push({'t': 'friend_added', 'familyId': 'fam-5'});
    sock.push({'t': 'friend_removed', 'familyId': 'fam-3'});
    await flush();
    expect(c.read(lobbyClientProvider).onlineFriends, {'fam-4'});
    expect(events.map((e) => (e.familyId, e.added)), [
      ('fam-5', true),
      ('fam-3', false),
    ]);
  });

  // A slow socket can swap two presence messages: the later count wins,
  // and anything not newer than hello is already in hello's list.
  test('a presence message older than what is known is ignored', () async {
    final c = makeContainer(signedIn: true);
    final lobby = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    lobby.setRouteEligible(true);
    await flush();

    final sock = sockets.single;
    sock.push({'t': 'hello', 'friendsOnline': ['fam-2'], 'v': 10});
    sock.push({'t': 'presence', 'familyId': 'fam-2', 'online': false, 'v': 9});
    await flush();
    expect(c.read(lobbyClientProvider).onlineFriends, {'fam-2'});

    sock.push({'t': 'presence', 'familyId': 'fam-3', 'online': true, 'v': 12});
    sock.push({'t': 'presence', 'familyId': 'fam-3', 'online': false, 'v': 14});
    sock.push({'t': 'presence', 'familyId': 'fam-3', 'online': true, 'v': 13});
    await flush();
    expect(c.read(lobbyClientProvider).onlineFriends, {'fam-2'});
  });

  testWidgets('25s heartbeat sends ping, handles pong, and reconnects on drop',
      (t) async {
    final c = makeContainer(
      signedIn: true,
      autoDispose: false,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 3),
        Duration(seconds: 6),
        Duration(seconds: 10),
      ],
    );
    expect(c.read(lobbyPingIntervalProvider), const Duration(seconds: 25));

    final lobby = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    lobby.setRouteEligible(true);
    await t.pump();
    await t.pump();

    expect(sockets, hasLength(1));
    final first = sockets.single;

    // 25s elapsed -> sends ping.
    await t.pump(const Duration(seconds: 25));
    expect(first.sent, [const {'t': 'ping'}]);

    first.push({'t': 'pong'});
    await t.pump();
    expect(lobby.lastPongAt, isNotNull);

    // Unexpected socket drop -> reconnects after 1s backoff.
    await first.drop();
    await t.pump();
    expect(c.read(lobbyClientProvider).connected, isFalse);

    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(sockets, hasLength(2));
    expect(c.read(lobbyClientProvider).connected, isTrue);

    c.dispose();
  });

  test('sendInvite, replyInvite, reaction, invite_reply, and error events',
      () async {
    final c = makeContainer(signedIn: true);
    final replies = <LobbyInviteReplyEvent>[];
    final reactions = <LobbyReactionEvent>[];
    final errors = <LobbyErrorEvent>[];
    final notifier = c.read(lobbyClientProvider.notifier);
    final s1 = notifier.inviteReplies.listen(replies.add);
    final s2 = notifier.reactions.listen(reactions.add);
    final s3 = notifier.errors.listen(errors.add);
    addTearDown(() async {
      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
    });

    await c.read(sessionProvider.future);
    notifier.setRouteEligible(true);
    await flush();

    notifier.sendInvite(
      toFamilyId: 'fam-2',
      roomCode: 'ABC234',
      kidUuid: 'kid-1',
    );
    expect(sockets.single.sent.last, {
      't': 'invite',
      'toFamilyId': 'fam-2',
      'roomCode': 'ABC234',
      'kidUuid': 'kid-1',
    });

    sockets.single.push({
      't': 'invite',
      'inviteId': 'inv-1',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': 'assets/images/avatars/fox.png',
      },
      'roomCode': 'ABC234',
      'expiresInMs': 30000,
    });
    sockets.single
        .push({'t': 'invite_reply', 'inviteId': 'inv-9', 'accept': true});
    sockets.single.push({
      't': 'reaction',
      'kidUuid': 'kid-1',
      'kind': 'clap',
      'fromNickname': 'Bin',
    });
    sockets.single.push({'t': 'error', 'code': 'friend_offline'});
    await flush();

    expect(c.read(lobbyClientProvider).pendingInvite?.inviteId, 'inv-1');
    expect(replies.single.inviteId, 'inv-9');
    expect(replies.single.accept, isTrue);
    expect(reactions.single.kind, 'clap');
    expect(reactions.single.fromNickname, 'Bin');
    expect(errors.single.code, 'friend_offline');

    notifier.replyInvite(inviteId: 'inv-1', accept: false);
    expect(c.read(lobbyClientProvider).pendingInvite, isNull);
    expect(sockets.single.sent.last, {
      't': 'invite_reply',
      'inviteId': 'inv-1',
      'accept': false,
    });
  });

  test('malformed JSON fields are ignored without throwing', () async {
    final c = makeContainer(signedIn: true);
    final notifier = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    notifier.setRouteEligible(true);
    await flush();

    final sock = sockets.single;
    sock.pushRaw({'t': 123});
    sock.pushRaw({'t': 'hello', 'friendsOnline': 'not-a-list'});
    sock.pushRaw({'t': 'presence', 'familyId': 99, 'online': 'yes'});
    sock.pushRaw({
      't': 'invite',
      'inviteId': 42,
      'from': 'bad',
      'roomCode': 123,
    });
    sock.pushRaw({'t': 'invite_reply', 'inviteId': 'x', 'accept': 'maybe'});
    sock.pushRaw({'t': 'invite_cancelled', 'inviteId': 999});
    sock.pushRaw({'t': 'friend_added', 'familyId': null});
    sock.pushRaw({'t': 'friend_removed', 'familyId': 1});
    sock.pushRaw({'t': 'reaction', 'kind': 5, 'fromNickname': 7});
    sock.pushRaw({'t': 'error', 'code': 500});
    await flush();

    expect(c.read(lobbyClientProvider).connected, isTrue);
    expect(c.read(lobbyClientProvider).onlineFriends, isEmpty);
    expect(c.read(lobbyClientProvider).pendingInvite, isNull);
  });

  test('invite_cancelled drops active or queued invite', () async {
    final c = makeContainer(signedIn: true);
    final notifier = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    notifier.setRouteEligible(true);
    await flush();

    sockets.single.push({
      't': 'invite',
      'inviteId': 'inv-1',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': '',
      },
      'roomCode': 'ABC234',
      'expiresInMs': 30000,
    });
    await flush();
    expect(c.read(lobbyClientProvider).pendingInvite?.inviteId, 'inv-1');

    sockets.single.push({'t': 'invite_cancelled', 'inviteId': 'inv-1'});
    await flush();
    expect(c.read(lobbyClientProvider).pendingInvite, isNull);
  });

  test(
      'queued invite waits while busy and expired queued invite is dropped (Review Focus 3)',
      () async {
    final c = makeContainer(signedIn: true);
    final notifier = c.read(lobbyClientProvider.notifier);
    await c.read(sessionProvider.future);
    notifier.setRouteEligible(true);
    await flush();

    // Kid is inside a race/lesson.
    c.read(lobbyBusyProvider.notifier).state = true;

    // Invite 1 arrives and will expire in 30s.
    sockets.single.push({
      't': 'invite',
      'inviteId': 'inv-expired',
      'from': {
        'familyId': 'fam-2',
        'kidUuid': 'kid-2',
        'nickname': 'Bin',
        'avatar': '',
      },
      'roomCode': 'AAA111',
      'expiresInMs': 30000,
    });
    await flush();

    expect(c.read(lobbyClientProvider).pendingInvite, isNull);
    expect(notifier.queuedInviteCount, 1);

    // 31s elapse while kid is still in lesson -> expired!
    fakeNow = fakeNow.add(const Duration(seconds: 31));
    c.read(lobbyBusyProvider.notifier).state = false;
    await flush();

    expect(c.read(lobbyClientProvider).pendingInvite, isNull);
    expect(notifier.queuedInviteCount, 0);

    // Invite 2 arrives while busy, only 10s elapse -> still valid when returning!
    c.read(lobbyBusyProvider.notifier).state = true;
    sockets.single.push({
      't': 'invite',
      'inviteId': 'inv-fresh',
      'from': {
        'familyId': 'fam-3',
        'kidUuid': 'kid-3',
        'nickname': 'Bông',
        'avatar': '',
      },
      'roomCode': 'BBB222',
      'expiresInMs': 30000,
    });
    await flush();
    expect(c.read(lobbyClientProvider).pendingInvite, isNull);

    fakeNow = fakeNow.add(const Duration(seconds: 10));
    c.read(lobbyBusyProvider.notifier).state = false;
    await flush();

    expect(c.read(lobbyClientProvider).pendingInvite?.inviteId, 'inv-fresh');
    expect(c.read(lobbyClientProvider).pendingInvite?.roomCode, 'BBB222');
  });
}
