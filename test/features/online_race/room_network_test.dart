import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/game_hub_screen.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/features/game/race_standings_strip.dart';
import 'package:funedu/features/online_race/room_lobby_screen.dart';
import 'package:funedu/features/online_race/room_result_screen.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/online/api_client.dart';
import 'package:funedu/online/net/network_status.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/parent/parent_gate.dart';
import 'package:funedu/router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../game/game_test_helpers.dart';
import 'online_race_test.dart';

class _OfflineConn implements ConnectivitySource {
  final _ctrl = StreamController<bool>.broadcast();

  @override
  Stream<bool> get hasConnection => _ctrl.stream;

  @override
  Future<bool> check() async => false;

  Future<void> dispose() => _ctrl.close();
}

class _OnlineConn implements ConnectivitySource {
  final _ctrl = StreamController<bool>.broadcast();

  @override
  Stream<bool> get hasConnection => _ctrl.stream;

  @override
  Future<bool> check() async => true;

  Future<void> dispose() => _ctrl.close();
}

RoomPlayer _rp(
  String id, {
  int steps = 0,
  int? rank,
  String name = '',
  bool connected = true,
  bool away = false,
  int? awayMsLeft,
  bool left = false,
}) =>
    RoomPlayer(
      id: id,
      name: name.isEmpty ? id : name,
      avatar: 'assets/images/chip-main.png',
      rocket: 'rocket_green',
      steps: steps,
      rank: rank,
      connected: connected,
      away: away,
      awayMsLeft: awayMsLeft,
      left: left,
    );

RoomState _rs(
  RoomPhase phase, {
  String you = 'p1',
  String host = 'p1',
  List<RoomPlayer>? players,
  bool reconnecting = false,
  String? endReason,
  String? error,
}) =>
    RoomState(
      phase: phase,
      code: 'ABC234',
      you: you,
      host: host,
      reconnecting: reconnecting,
      endReason: endReason,
      error: error,
      players: players ?? [_rp('p1', name: 'Na'), _rp('p2', name: 'Bo')],
    );

void main() {
  testWidgets('rival away shows waiting and toast, then rival back shows toast once',
      (t) async {
    final room = FakeRoom(_rs(RoomPhase.racing));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    // Bo becomes away
    room.set(_rs(
      RoomPhase.racing,
      players: [
        _rp('p1', steps: 2, name: 'Na'),
        _rp('p2', steps: 3, name: 'Bo', connected: false, away: true, awayMsLeft: 15000),
      ],
    ));
    await pumpReal(t, times: 4);

    expect(find.text('Đang chờ'), findsOneWidget);
    expect(
      find.text('Bo bị mất mạng, đang chờ Bo quay lại…'),
      findsOneWidget,
    );

    // Duplicate away update must not re-fire away toast
    room.set(_rs(
      RoomPhase.racing,
      players: [
        _rp('p1', steps: 3, name: 'Na'),
        _rp('p2', steps: 3, name: 'Bo', connected: false, away: true, awayMsLeft: 10000),
      ],
    ));
    await t.pump();
    expect(
      find.text('Bo bị mất mạng, đang chờ Bo quay lại…'),
      findsOneWidget,
    );

    // Bo returns -> toast "Bo đã quay lại!" once and waiting badge hides
    room.set(_rs(
      RoomPhase.racing,
      players: [
        _rp('p1', steps: 3, name: 'Na'),
        _rp('p2', steps: 3, name: 'Bo', connected: true, away: false),
      ],
    ));
    await pumpReal(t, times: 4);

    expect(find.text('Bo đã quay lại!'), findsOneWidget);
    expect(find.text('Đang chờ'), findsNothing);

    // Clear toast timer
    await pumpReal(t, times: 14, step: const Duration(milliseconds: 300));
  });

  testWidgets('rival left disappears from standings and shows toast', (t) async {
    final room = FakeRoom(_rs(
      RoomPhase.racing,
      players: [
        _rp('p1', steps: 2, name: 'Na'),
        _rp('p2', steps: 4, name: 'Bo'),
        _rp('p3', steps: 1, name: 'Chi'),
      ],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    expect(find.byType(RaceStandingsStrip), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

    // Bo leaves
    room.set(_rs(
      RoomPhase.racing,
      players: [
        _rp('p1', steps: 2, name: 'Na'),
        _rp('p2', steps: 4, name: 'Bo', connected: false, away: false, left: true),
        _rp('p3', steps: 1, name: 'Chi'),
      ],
    ));
    await pumpReal(t, times: 4);

    expect(find.text('Bo đã rời trận'), findsOneWidget);
    expect(find.text('Rời trận'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

    await pumpReal(t, times: 14, step: const Duration(milliseconds: 300));
  });

  testWidgets('last one standing wins with others_left title and saves stars',
      (t) async {
    final room = FakeRoom(_rs(RoomPhase.racing));
    final h = await bootGame(t, extra: [
      roomControllerProvider.overrideWith(() => room),
    ]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    await answerRight(t);
    room.set(_rs(
      RoomPhase.done,
      endReason: 'others_left',
      players: [
        _rp('p1', steps: 1, rank: 1, name: 'Na'),
        _rp('p2', steps: 0, name: 'Bo', connected: false, left: true),
      ],
    ));
    await pumpReal(t, times: 12, step: const Duration(milliseconds: 300));

    expect(find.byType(RoomResultScreen), findsOneWidget);
    expect(
      find.text('Các bạn đã rời trận, con thắng rồi!'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('room-reward')), findsOneWidget);
    expect(find.text('Rời trận'), findsOneWidget);

    final rows = await t.runAsync(() => h.db.select(h.db.raceResults).get());
    expect(rows, hasLength(1));
    expect(rows!.single.won, isTrue);
  });

  testWidgets(
      'self drop keeps race screen with banner and resumes cleanly when reconnected',
      (t) async {
    final room = FakeRoom(_rs(RoomPhase.racing));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    // Self drop -> reconnecting = true
    room.set(_rs(RoomPhase.racing, reconnecting: true));
    await pumpReal(t, times: 4);

    expect(find.byType(RaceScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('room-reconnecting-banner')), findsOneWidget);
    expect(find.text('Đang kết nối lại…'), findsOneWidget);

    // Answering while locked does not send step
    await answerRight(t);
    expect(room.steps, isEmpty);

    // Reconnects within 20s -> banner vanishes, answering works again
    room.set(_rs(RoomPhase.racing, reconnecting: false));
    await pumpReal(t, times: 4);
    expect(find.byKey(const ValueKey('room-reconnecting-banner')), findsNothing);

    await answerRight(t);
    expect(room.steps, [1]);
  });

  testWidgets('self drop past 20s shows gentle result without saving to DB',
      (t) async {
    final room = FakeRoom(_rs(RoomPhase.racing));
    final h = await bootGame(t, extra: [
      roomControllerProvider.overrideWith(() => room),
    ]);
    final starsBefore = await t.runAsync(
      () => GameRepository(h.db, kidId: 1).totalStars(),
    );

    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    await answerRight(t);
    expect(room.steps, [1]);

    // Exceeds 20 s retry limit -> error: 'network'
    room.set(_rs(RoomPhase.error, error: 'network'));
    await pumpReal(t, times: 12, step: const Duration(milliseconds: 300));

    expect(find.byType(RoomResultScreen), findsOneWidget);
    expect(
      find.text('Mạng chập chờn mất rồi, mình đua lại sau nhé!'),
      findsOneWidget,
    );
    expect(find.text('Về Góc Chơi'), findsOneWidget);

    // No race_results inserted and cosmicStars unchanged
    final rows = await t.runAsync(() => h.db.select(h.db.raceResults).get());
    expect(rows, isEmpty);
    final starsAfter = await t.runAsync(
      () => GameRepository(h.db, kidId: 1).totalStars(),
    );
    expect(starsAfter, starsBefore);
  });

  testWidgets('offline invite and join show need-network dialog without gate or HTTP',
      (t) async {
    final conn = _OfflineConn();
    addTearDown(conn.dispose);
    var networkCalls = 0;

    await bootGame(t, extra: [
      onlineConfigProvider
          .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
      connectivitySourceProvider.overrideWithValue(conn),
      httpClientProvider.overrideWithValue(MockClient((_) async {
        networkCalls++;
        return http.Response('', 500);
      })),
    ]);
    appRouter.go('/game');
    await pumpReal(t, times: 6);
    expect(find.byType(GameHubScreen), findsOneWidget);

    final c = ProviderScope.containerOf(t.element(find.byType(GameHubScreen)));
    c.read(networkStatusProvider.notifier).reportNetworkError();
    await pumpReal(t, times: 2);

    await t.tap(find.text('Mời bạn đua'));
    await pumpReal(t, times: 4);

    expect(find.byType(ParentGate), findsNothing);
    expect(find.text('Cần có mạng để đua với bạn nhé'), findsOneWidget);
    expect(find.text('Được rồi'), findsOneWidget);
    expect(networkCalls, 0);

    await t.tap(find.text('Được rồi'));
    await pumpReal(t, times: 4);
    expect(find.text('Cần có mạng để đua với bạn nhé'), findsNothing);

    await t.tap(find.text('Nhập mã'));
    await pumpReal(t, times: 4);
    expect(find.text('Cần có mạng để đua với bạn nhé'), findsOneWidget);
    expect(find.byType(ParentGate), findsNothing);
    expect(networkCalls, 0);
  });

  testWidgets('server unreachable invite shows trạm vũ trụ dialog without gate or HTTP',
      (t) async {
    final conn = _OnlineConn();
    addTearDown(conn.dispose);
    var networkCalls = 0;

    await bootGame(t, extra: [
      onlineConfigProvider
          .overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
      connectivitySourceProvider.overrideWithValue(conn),
      httpClientProvider.overrideWithValue(MockClient((_) async {
        networkCalls++;
        return http.Response('', 500);
      })),
    ]);
    appRouter.go('/game');
    await pumpReal(t, times: 6);
    expect(find.byType(GameHubScreen), findsOneWidget);

    final c = ProviderScope.containerOf(t.element(find.byType(GameHubScreen)));
    c.read(networkStatusProvider.notifier).reportNetworkError();
    await pumpReal(t, times: 2);

    await t.tap(find.text('Mời bạn đua'));
    await pumpReal(t, times: 4);

    expect(find.byType(ParentGate), findsNothing);
    expect(find.text('Chưa kết nối được với trạm vũ trụ'), findsOneWidget);
    expect(find.text('Máy chủ đang bận hoặc chưa bật, bạn thử lại sau nhé!'), findsOneWidget);
    expect(find.text('Được rồi'), findsOneWidget);
    expect(networkCalls, 0);

    await t.tap(find.text('Được rồi'));
    await pumpReal(t, times: 4);
    expect(find.text('Chưa kết nối được với trạm vũ trụ'), findsNothing);
  });

  testWidgets('lobby shows away countdown for disconnected friend', (t) async {
    final room = FakeRoom(_rs(
      RoomPhase.lobby,
      players: [
        _rp('p1', name: 'Na'),
        _rp('p2', name: 'Bo', connected: false, away: true, awayMsLeft: 14200),
      ],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t, times: 6);

    expect(find.byType(RoomLobbyScreen), findsOneWidget);
    expect(find.text('Đang kết nối lại… (15s)'), findsOneWidget);
  });
}
