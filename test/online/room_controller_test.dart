import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/auth/identity_providers.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/online_rival.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/online/room/room_transport.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'online_fakes.dart';

/// One fake socket: what the app sent, and a way to push server messages.
class FakeTransport implements RoomTransport {
  final sent = <Map<String, Object?>>[];
  final _in = StreamController<Map<String, Object?>>.broadcast();
  bool closed = false;

  void push(Map<String, Object?> m) => _in.add(jsonDecode(jsonEncode(m)) as Map<String, Object?>);
  Future<void> drop() => _in.close();

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

Map<String, Object?> roomMsg(String state, {String you = 'p1', String host = 'p1', List<Map<String, Object?>>? players}) => {
      't': 'room',
      'code': 'ABC234',
      'state': state,
      'you': you,
      'host': host,
      'players': players ??
          [
            {'id': 'p1', 'name': 'Na', 'avatar': '', 'rocket': 'rocket_blue', 'steps': 0, 'rank': null, 'connected': true},
          ],
    };

const kid = RoomKid(uuid: 'kid-1', name: 'Na', avatar: 'assets/images/chip-main.png', rocket: 'rocket_blue');

void main() {
  late List<http.Request> requests;
  late List<FakeTransport> sockets;
  late List<String> connectedCodes;
  late AppDatabase db;
  var connectFails = false;

  ProviderContainer container() {
    final store = MemoryTokenStore()
      ..session = const StoredSession(
          accessToken: 'a1', refreshToken: 'r1', familyId: 'fam-1', provider: 'google');
    final c = ProviderContainer(overrides: [
      onlineConfigProvider.overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
      httpClientProvider.overrideWithValue(MockClient((req) async {
        requests.add(req);
        if (req.url.path == '/api/v1/rooms') {
          return jsonResponse({'code': 'ABC234', 'expiresAt': 0});
        }
        return fakeServer(req);
      })),
      tokenStoreProvider.overrideWithValue(store),
      identityProvidersProvider.overrideWithValue(FakeIds()),
      databaseProvider.overrideWithValue(db),
      roomRetryDelaysProvider.overrideWithValue(const [Duration(milliseconds: 10), Duration(milliseconds: 10)]),
      roomConnectorProvider.overrideWithValue((code, token) async {
        if (connectFails) throw Exception('no network');
        connectedCodes.add('$code/$token');
        final s = FakeTransport();
        sockets.add(s);
        return s;
      }),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    requests = [];
    sockets = [];
    connectedCodes = [];
    connectFails = false;
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  test('creating a room asks the server for a code, then joins it', () async {
    final c = container();
    await c.read(roomControllerProvider.notifier).create(kid);
    expect(requests.single.url.path, '/api/v1/rooms');
    expect(requests.single.headers['Authorization'], 'Bearer a1');
    expect(connectedCodes, ['ABC234/a1']);
    expect(sockets.single.sent.single, {
      't': 'join',
      'kid': 'kid-1',
      'name': 'Na',
      'avatar': 'assets/images/chip-main.png',
      'rocket': 'rocket_blue',
    });

    sockets.single.push(roomMsg('lobby'));
    await Future<void>.delayed(Duration.zero);
    final s = c.read(roomControllerProvider);
    expect(s.phase, RoomPhase.lobby);
    expect(s.isHost, isTrue);
    expect(s.me!.name, 'Na');
  });

  test('a typed code is cleaned up before joining', () async {
    final c = container();
    await c.read(roomControllerProvider.notifier).join(' abc 234 ', kid);
    expect(connectedCodes, ['ABC234/a1']);
  });

  test('an unknown code ends in an error the screen can show', () async {
    final c = container();
    await c.read(roomControllerProvider.notifier).join('ZZZZZZ', kid);
    sockets.single.push({'t': 'error', 'code': 'not_found'});
    await sockets.single.drop();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final s = c.read(roomControllerProvider);
    expect(s.phase, RoomPhase.error);
    expect(s.error, 'not_found');
    expect(sockets, hasLength(1), reason: 'no reconnect after a refusal');
  });

  test('a button answer (not_host) keeps the room', () async {
    final c = container();
    await c.read(roomControllerProvider.notifier).join('ABC234', kid);
    sockets.single.push(roomMsg('lobby', host: 'p2'));
    sockets.single.push({'t': 'error', 'code': 'not_host'});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(roomControllerProvider).phase, RoomPhase.lobby);
    expect(c.read(roomControllerProvider).error, 'not_host');
  });

  test('a dropped connection rejoins with the same kid', () async {
    final c = container();
    await c.read(roomControllerProvider.notifier).join('ABC234', kid);
    sockets.single.push(roomMsg('racing'));
    await Future<void>.delayed(Duration.zero);
    await sockets.first.drop();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(sockets, hasLength(2));
    expect(sockets.last.sent.single['kid'], 'kid-1');
  });

  test('gives up after the last retry', () async {
    final c = container();
    await c.read(roomControllerProvider.notifier).join('ABC234', kid);
    sockets.single.push(roomMsg('racing'));
    await Future<void>.delayed(Duration.zero);
    connectFails = true;
    await sockets.single.drop();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(c.read(roomControllerProvider).phase, RoomPhase.error);
    expect(c.read(roomControllerProvider).error, 'network');
  });

  test('steps, stickers, start, again and leave go out as messages', () async {
    final c = container();
    final room = c.read(roomControllerProvider.notifier);
    await room.join('ABC234', kid);
    final s = sockets.single;
    room.start();
    room.step(2);
    room.sticker('cheer');
    room.sticker('not a sticker');
    room.again();
    await room.leave();
    expect(s.sent.skip(1).toList(), [
      {'t': 'start'},
      {'t': 'step', 'n': 2},
      {'t': 'sticker', 'id': 'cheer'},
      {'t': 'again'},
      {'t': 'leave'},
    ]);
    expect(s.closed, isTrue);
    expect(c.read(roomControllerProvider).phase, RoomPhase.idle);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(sockets, hasLength(1), reason: 'leaving never reconnects');
  });

  test('signed out: creating a room says so and opens nothing', () async {
    final c = ProviderContainer(overrides: [
      onlineConfigProvider.overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      databaseProvider.overrideWithValue(db),
      roomConnectorProvider.overrideWithValue((_, __) async => throw StateError('must not connect')),
    ]);
    addTearDown(c.dispose);
    await c.read(roomControllerProvider.notifier).create(kid);
    expect(c.read(roomControllerProvider).error, 'signed_out');
  });

  group('the rival shown in the race', () {
    RoomState room(List<Map<String, Object?>> players) => RoomState(
          phase: RoomPhase.racing,
          you: 'p1',
          players: players.map(RoomPlayer.fromJson).toList(),
        );
    Map<String, Object?> p(String id, int steps, [int? rank]) =>
        {'id': id, 'name': id, 'avatar': '', 'rocket': 'rocket_green', 'steps': steps, 'rank': rank};

    test('is the friend with the most steps', () {
      final v = OnlineRival.viewOf(room([p('p1', 5), p('p2', 3), p('p3', 7)]));
      expect(v.name, 'p3');
      expect(v.steps, 7);
      expect(v.myRank, isNull);
      expect(v.roomOver, isFalse);
      expect(v.players, 3);
    });

    test('a friend who landed comes first, but the kid races on', () {
      final v = OnlineRival.viewOf(room([p('p1', 9), p('p2', 10, 1), p('p3', 9)]));
      expect(v.name, 'p2');
      expect(v.roomOver, isFalse);
    });

    test('carries the kid\'s place once the room gives it', () {
      final v = OnlineRival.viewOf(room([p('p1', 10, 2), p('p2', 10, 1)]));
      expect(v.myRank, 2);
    });

    test('lists every racer in room order, marking the kid', () {
      final v = OnlineRival.viewOf(room([p('p1', 5), p('p2', 3), p('p3', 10, 1)]));
      expect(v.standings.map((s) => s.name), ['p1', 'p2', 'p3']);
      expect(v.standings.map((s) => s.isYou), [true, false, false]);
      expect(v.standings.last.rank, 1);
    });

    test('a finished room ends the kid\'s race', () {
      final s = RoomState(
        phase: RoomPhase.done,
        you: 'p1',
        players: [p('p1', 4), p('p2', 10, 1)].map(RoomPlayer.fromJson).toList(),
      );
      expect(OnlineRival.viewOf(s).roomOver, isTrue);
    });
  });
}
