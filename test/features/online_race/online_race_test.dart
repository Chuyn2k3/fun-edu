import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/engine/race.dart';
import 'package:funedu/features/online_race/room_lobby_screen.dart';
import 'package:funedu/features/online_race/room_result_screen.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/online_config.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/parent/parent_gate.dart';
import 'package:funedu/router.dart';

import '../game/game_test_helpers.dart';

class FakeRoom extends RoomController {
  FakeRoom(this.initial);

  final RoomState initial;
  final steps = <int>[];
  int starts = 0;
  bool left = false;

  @override
  RoomState build() => initial;

  void set(RoomState s) => state = s;

  @override
  void step(int n) => steps.add(n);

  @override
  void start() => starts++;

  @override
  Future<void> leave() async {
    left = true;
    state = const RoomState();
  }
}

RoomPlayer _p(String id, {int steps = 0, int? rank, String name = ''}) => RoomPlayer(
      id: id,
      name: name.isEmpty ? id : name,
      avatar: 'assets/images/chip-main.png',
      rocket: 'rocket_green',
      steps: steps,
      rank: rank,
    );

RoomState _room(RoomPhase phase, {String you = 'p1', String host = 'p1', List<RoomPlayer>? players}) =>
    RoomState(
      phase: phase,
      code: 'ABC234',
      you: you,
      host: host,
      players: players ?? [_p('p1', name: 'Na'), _p('p2', name: 'Bo')],
    );

void main() {
  testWidgets('racing a friend: their rocket replaces Chíp, steps go to the room',
      (t) async {
    final room = FakeRoom(_room(RoomPhase.racing));
    final h = await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    expect(find.byType(RaceScreen), findsOneWidget);
    final scene = t.widget<RaceScene>(find.byType(RaceScene));
    expect(scene.rivalRocket, 'rocket_green');
    expect(scene.rivalName, 'Bo');

    await answerRight(t);
    expect(room.steps, [1]);

    // Bo climbs: the second rocket follows the room, not Chíp's pacer.
    room.set(_room(RoomPhase.racing, players: [_p('p1', steps: 1, name: 'Na'), _p('p2', steps: 4, name: 'Bo')]));
    await t.pump();
    expect(t.widget<RaceScene>(find.byType(RaceScene)).chipSteps, 4);

    // Bo lands first: the kid keeps flying for second place.
    room.set(_room(RoomPhase.racing,
        players: [_p('p1', steps: 1, name: 'Na'), _p('p2', steps: 10, rank: 1, name: 'Bo')]));
    await pumpReal(t, times: 4);
    expect(find.byType(RaceScreen), findsOneWidget);

    while (room.steps.isEmpty || room.steps.last < 10) {
      await answerRight(t);
    }
    // The room ranks the kid second.
    room.set(_room(RoomPhase.done, players: [
      _p('p1', steps: 10, rank: 2, name: 'Na'),
      _p('p2', steps: 10, rank: 1, name: 'Bo'),
    ]));
    await pumpReal(t, times: 12, step: const Duration(milliseconds: 300));
    expect(find.byType(RoomResultScreen), findsOneWidget);
    expect(find.text('Về nhì'), findsOneWidget);
    // Second place: 5 stars (+ comets and lucky stars of this race).
    expect(find.byKey(const ValueKey('room-reward')), findsOneWidget);
    final rows = await t.runAsync(() => h.db.select(h.db.raceResults).get());
    expect(rows!.single.subject, 'online:toan');
    expect(rows.single.stars, greaterThanOrEqualTo(5));
  });

  testWidgets('a room that ends mid-race still gives the kid stars',
      (t) async {
    final room = FakeRoom(_room(RoomPhase.racing));
    final h = await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);
    await answerRight(t);
    room.set(_room(RoomPhase.done,
        players: [_p('p1', steps: 1, name: 'Na'), _p('p2', steps: 10, rank: 1, name: 'Bo')]));
    await pumpReal(t, times: 12, step: const Duration(milliseconds: 300));
    expect(find.byType(RoomResultScreen), findsOneWidget);
    final rows = await t.runAsync(() => h.db.select(h.db.raceResults).get());
    expect(rows!.single.stars, 3);
  });

  testWidgets('lobby: the host starts once two kids are in; the race opens',
      (t) async {
    final room = FakeRoom(_room(RoomPhase.lobby, players: [_p('p1', name: 'Na')]));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t);
    expect(find.byType(RoomLobbyScreen), findsOneWidget);
    expect(find.text('A B C 2 3 4'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('room-start')));
    await t.pump();
    expect(room.starts, 0, reason: 'alone in the room');

    room.set(_room(RoomPhase.lobby));
    await t.pump();
    expect(t.getSize(find.byKey(const ValueKey('room-start'))).height, greaterThanOrEqualTo(64));
    await t.tap(find.byKey(const ValueKey('room-start')));
    await t.pump();
    expect(room.starts, 1);

    room.set(_room(RoomPhase.racing));
    await pumpReal(t, times: 8);
    expect(find.byType(RaceScreen), findsOneWidget);
  });

  testWidgets('lobby: a guest waits for the host', (t) async {
    final room = FakeRoom(_room(RoomPhase.lobby, you: 'p2'));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t);
    expect(find.byKey(const ValueKey('room-start')), findsNothing);
    expect(find.text('Chờ chủ phòng bắt đầu nhé!'), findsOneWidget);
  });

  testWidgets('lobby: an ended room explains why and goes back', (t) async {
    final room = FakeRoom(const RoomState(phase: RoomPhase.error, error: 'not_found'));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/lobby');
    await pumpReal(t);
    expect(find.textContaining('Không tìm thấy phòng'), findsOneWidget);
  });

  testWidgets('with a server, "Mời bạn đua" asks for the parent gate first',
      (t) async {
    await bootGame(t, extra: [
      onlineConfigProvider.overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
    ]);
    appRouter.go('/game');
    await pumpReal(t);
    await t.tap(find.text('Mời bạn đua'));
    await pumpReal(t);
    expect(find.byType(ParentGate), findsOneWidget);
  });

  testWidgets('room entry: signed out, it points the parent to the account',
      (t) async {
    await bootGame(t, extra: [
      onlineConfigProvider.overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
    ]);
    appRouter.go('/game/room?mode=join');
    await pumpReal(t);
    expect(find.text('Cần Tài khoản gia đình'), findsOneWidget);
    expect(find.byKey(const ValueKey('room-code')), findsNothing);
  });

  testWidgets('room entry: signed in, a parent types the code and nickname',
      (t) async {
    await bootGame(t, extra: [
      onlineConfigProvider.overrideWithValue(const OnlineConfig(apiUrl: 'https://api.test')),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()
        ..session = const StoredSession(
            accessToken: 'a', refreshToken: 'r', familyId: 'f', provider: 'google')),
    ]);
    appRouter.go('/game/room?mode=join');
    await pumpReal(t);
    expect(find.byKey(const ValueKey('room-code')), findsOneWidget);
    // Prefilled with the kid's nickname.
    expect(find.widgetWithText(TextField, 'Na'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('room-code')), 'ab1');
    await t.tap(find.byKey(const ValueKey('room-go')));
    await pumpReal(t);
    expect(find.text('Mã phòng có 6 ký tự'), findsOneWidget);
  });

  testWidgets('the ranking shows the stars and a rare sticker drop', (t) async {
    final room = FakeRoom(_room(RoomPhase.done, players: [
      _p('p1', steps: 10, rank: 1, name: 'Na'),
      _p('p2', steps: 8, rank: 2, name: 'Bo'),
    ]));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/result',
        extra: const RaceResultArgs(
          subject: RaceSubject.toan,
          outcome: RaceOutcome(
            won: true,
            kidTime: Duration(seconds: 30),
            firstTryCorrect: 8,
            cometsFirstTry: 0,
            answered: 8,
            missed: [],
          ),
          record: null,
          kidSteps: 10,
          rocket: 'rocket_orange',
          trail: 'trail_flame',
          online: true,
          rank: 1,
          onlineRecord: OnlineRaceRecord(
            starsEarned: 7,
            totalStars: 7,
            milestonesCrossed: [],
            newBadges: [],
            rareSticker: 'rare_crown',
          ),
        ));
    await pumpReal(t);
    expect(find.text('Bé về nhất!'), findsOneWidget);
    expect(find.text('+7 sao vũ trụ'), findsOneWidget);
    expect(find.text('Sticker hiếm!'), findsOneWidget);
    expect(find.text('Vương miện vàng'), findsOneWidget);
  });

  testWidgets('the album shows an owned rare sticker with its gold label',
      (t) async {
    await bootGame(t, seed: (db, kid) async {
      await db.into(db.gameItems).insert(
          GameItemsCompanion.insert(kidId: kid, itemId: 'rare_comet'));
    });
    appRouter.go('/game/stickers');
    await pumpReal(t);
    final tile = find.byKey(const ValueKey('sticker-rare_comet'));
    await t.scrollUntilVisible(tile, 300, scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: tile, matching: find.text('Hiếm')), findsOneWidget);
    expect(find.descendant(of: tile, matching: find.text('Sao chổi rực rỡ')), findsOneWidget);
  });

  group('standings strip', () {
    RoomState three({int? boRank}) => _room(RoomPhase.racing, players: [
          _p('p1', steps: 2, name: 'Na'),
          _p('p2', steps: boRank == null ? 6 : 10, rank: boRank, name: 'Bo'),
          _p('p3', steps: 4, name: 'Mi'),
        ]);

    for (final size in const [Size(320, 568), Size(390, 844), Size(1024, 1366), Size(1366, 1024)]) {
      testWidgets('3 kids: everyone shows, no overflow at $size', (t) async {
        final room = FakeRoom(three());
        await bootGame(t, size: size, extra: [roomControllerProvider.overrideWith(() => room)]);
        appRouter.go('/game/room/race', extra: RaceSubject.toan);
        await pumpReal(t, times: 8);

        final strip = find.byKey(const ValueKey('race-standings'));
        expect(strip, findsOneWidget);
        expect(find.descendant(of: strip, matching: find.byType(LinearProgressIndicator)),
            findsNWidgets(3));
        expect(t.takeException(), isNull);

        // Bo lands first: his bar becomes "Nhất".
        room.set(three(boRank: 1));
        await pumpReal(t);
        expect(find.descendant(of: strip, matching: find.text('Nhất')), findsOneWidget);
        expect(find.descendant(of: strip, matching: find.byType(LinearProgressIndicator)),
            findsNWidgets(2));
      });
    }

    testWidgets('2 kids: no strip, the scene already shows both', (t) async {
      final room = FakeRoom(_room(RoomPhase.racing));
      await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
      appRouter.go('/game/room/race', extra: RaceSubject.toan);
      await pumpReal(t, times: 8);
      expect(find.byKey(const ValueKey('race-standings')), findsNothing);
    });

    testWidgets('racing Chíp: no strip', (t) async {
      await bootGame(t);
      appRouter.go('/game/race/toan');
      await pumpReal(t, times: 8);
      expect(find.byKey(const ValueKey('race-standings')), findsNothing);
    });
  });
}

