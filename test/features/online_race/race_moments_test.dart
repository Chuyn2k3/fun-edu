import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/features/online_race/room_result_screen.dart';
import 'package:funedu/game/engine/race.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/router.dart';

import '../game/game_test_helpers.dart';
import 'online_race_test.dart';

RoomPlayer _p(
  String id, {
  int steps = 0,
  int? rank,
  String name = '',
  String avatar = '',
  bool left = false,
}) =>
    RoomPlayer(
      id: id,
      name: name.isEmpty ? id : name,
      avatar: avatar.isEmpty ? kidAvatars[0] : avatar,
      rocket: 'rocket_orange',
      steps: steps,
      rank: rank,
      left: left,
    );

RoomState _room(
  RoomPhase phase, {
  String you = 'p1',
  String? endReason,
  List<RoomPlayer>? players,
}) =>
    RoomState(
      phase: phase,
      code: 'ABC234',
      you: you,
      host: you,
      endReason: endReason,
      players: players ?? [_p('p1', name: 'Na'), _p('p2', name: 'Bo')],
    );

void main() {
  testWidgets('overtake shows banner once and vibrates', (t) async {
    final haptics = <Object?>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final room = FakeRoom(_room(
      RoomPhase.racing,
      players: [
        _p('p1', steps: 0, name: 'Na'),
        _p('p2', steps: 2, name: 'Bo'),
      ],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    final scene = t.state<RaceSceneState>(find.byType(RaceScene));
    expect(scene.onlineOvertakeBanner, isNull);

    // Answer twice: Na climbs 0 -> 1 (still behind Bo at 2), then 1 -> 2 (overtakes to rank 1).
    await answerRight(t);
    expect(haptics, isEmpty);
    await answerRight(t);
    await t.pump();

    expect(scene.onlineOvertakeBanner, 'VƯỢT! 🚀 Con lên hạng 1');
    expect(scene.onlinePaintedLabels, contains('VƯỢT! 🚀 Con lên hạng 1'));
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    // Answering again while still rank 1 must not trigger another overtake haptic.
    await answerRight(t);
    await t.pump();
    expect(haptics, hasLength(1));

    // Banner disappears after 1.2 s.
    await t.pump(const Duration(milliseconds: 1250));
    expect(scene.onlineOvertakeBanner, isNull);
  });

  testWidgets('being overtaken shows small banner', (t) async {
    final room = FakeRoom(_room(
      RoomPhase.racing,
      players: [
        _p('p1', steps: 0, name: 'Na'),
        _p('p2', steps: 0, name: 'Bo'),
      ],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    await answerRight(t);
    final scene = t.state<RaceSceneState>(find.byType(RaceScene));

    // Bo jumps ahead of Na (1 step -> Bo 3 steps).
    room.set(_room(
      RoomPhase.racing,
      players: [
        _p('p1', steps: 1, name: 'Na'),
        _p('p2', steps: 3, name: 'Bo'),
      ],
    ));
    await t.pump();

    expect(scene.onlineOvertakeBanner, 'Bo vừa vượt con!');
    expect(scene.onlinePaintedLabels, contains('Bo vừa vượt con!'));

    await t.pump(const Duration(milliseconds: 1250));
    expect(scene.onlineOvertakeBanner, isNull);
  });

  testWidgets('three first-try answers show super speed', (t) async {
    final room = FakeRoom(_room(RoomPhase.racing));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    final scene = t.state<RaceSceneState>(find.byType(RaceScene));
    expect(scene.onlineSuperSpeedActive, isFalse);

    await answerRight(t);
    await answerRight(t);
    expect(scene.onlineSuperSpeedActive, isFalse);

    await answerRight(t);
    await t.pump();

    expect(raceState(t).comboStreak, 3);
    expect(scene.onlineSuperSpeedActive, isTrue);
    expect(
      scene.onlinePaintedLabels,
      contains('⚡ 3 câu đúng · SIÊU TỐC!'),
    );

    // Wrong answer resets combo and turns off super speed.
    await answerWrong(t);
    await t.pump();
    expect(raceState(t).comboStreak, 0);
    expect(scene.onlineSuperSpeedActive, isFalse);
  });

  testWidgets('stage cleared shows star gate for 2.5 s then the next question',
      (t) async {
    final room = FakeRoom(_room(
      RoomPhase.racing,
      players: [
        _p('p1', steps: 0, name: 'Na'),
        _p('p2', steps: 1, name: 'Bo'),
      ],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    while (raceState(t).kidSteps < 6) {
      await answerRight(t);
    }

    final scene = t.state<RaceSceneState>(find.byType(RaceScene));
    expect(raceState(t).starGateStage, 1);
    expect(scene.onlineStarGateStage, 1);
    expect(scene.onlinePaintedLabels, contains('✨ Cổng Sao chặng 1 ✨'));
    expect(scene.onlinePaintedLabels, contains('Đang dẫn: Na! 🏆'));
    expect(find.byKey(const ValueKey('star-gate-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('race-key-0')), findsNothing);

    // Still inside the 2.5 s Star Gate at +1.5 s.
    await t.pump(const Duration(milliseconds: 1500));
    expect(raceState(t).starGateStage, 1);
    expect(find.byKey(const ValueKey('race-key-0')), findsNothing);

    // After 2.5 s total, Star Gate closes and the next question appears.
    await t.pump(const Duration(milliseconds: 1100));
    expect(raceState(t).starGateStage, isNull);
    expect(scene.onlineStarGateStage, isNull);
    expect(find.byKey(const ValueKey('star-gate-board')), findsNothing);
    expect(find.byKey(const ValueKey('race-key-0')), findsOneWidget);
  });

  testWidgets('others_left during star gate ends race', (t) async {
    final room = FakeRoom(_room(
      RoomPhase.racing,
      players: [
        _p('p1', steps: 0, name: 'Na'),
        _p('p2', steps: 1, name: 'Bo'),
      ],
    ));
    await bootGame(t, extra: [roomControllerProvider.overrideWith(() => room)]);
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    while (raceState(t).kidSteps < 6) {
      await answerRight(t);
    }
    expect(raceState(t).starGateStage, 1);

    // Opponent leaves mid-gate -> room becomes done with others_left.
    room.set(_room(
      RoomPhase.done,
      endReason: 'others_left',
      players: [
        _p('p1', steps: 6, rank: 1, name: 'Na'),
        _p('p2', steps: 1, name: 'Bo', left: true),
      ],
    ));
    await t.pump(const Duration(milliseconds: 500));

    // Must wait out the 2.5 s Star Gate before ending the race.
    expect(find.byType(RaceScreen), findsOneWidget);
    expect(find.byType(RoomResultScreen), findsNothing);
    expect(raceState(t).starGateStage, 1);

    // Once the 2.5 s gate finishes, the race ends and opens RoomResultScreen.
    await t.pump(const Duration(milliseconds: 2200));
    await pumpReal(t, times: 10, step: const Duration(milliseconds: 300));

    expect(find.byType(RoomResultScreen), findsOneWidget);
    expect(
      find.text('Các bạn đã rời trận, con thắng rồi!'),
      findsOneWidget,
    );
  });

  testWidgets('sprint label in stage 3', (t) async {
    final room = FakeRoom(_room(RoomPhase.racing));
    await bootGame(
      t,
      size: const Size(320, 568),
      extra: [roomControllerProvider.overrideWith(() => room)],
    );
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(t, times: 8);

    expect(find.textContaining('Chặng 1 · Câu '), findsOneWidget);
    expect(find.byKey(const ValueKey('stage-progress-bar')), findsOneWidget);
    expect(find.text('Nước rút!'), findsNothing);

    while (raceState(t).kidSteps < onlineSprintFrom) {
      if (raceState(t).starGateActive) {
        await t.pump(const Duration(milliseconds: 2600));
        continue;
      }
      await answerRight(t);
    }
    // Wait out stage-2 Star Gate if triggered at step 12.
    if (raceState(t).starGateActive) {
      await t.pump(const Duration(milliseconds: 2600));
    }
    await t.pump();

    expect(raceState(t).stage, 3);
    expect(raceState(t).inSprint, isTrue);
    expect(find.textContaining('Chặng 3 · Câu '), findsOneWidget);
    expect(find.textContaining('/18'), findsOneWidget);
    expect(find.text('Nước rút!'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  group('result podium', () {
    for (final size in const [
      Size(320, 568),
      Size(1024, 1366),
      Size(1366, 1024),
    ]) {
      testWidgets('result podium shows avatars in rank order at $size',
          (t) async {
        final room = FakeRoom(_room(
          RoomPhase.done,
          players: [
            _p('p3', steps: 14, rank: 3, name: 'MiSiêuDàiTênBé', avatar: 'bad'),
            _p('p1', steps: 18, rank: 1, name: 'Na', avatar: kidAvatars[0]),
            _p('p2', steps: 16, rank: 2, name: 'Bo', avatar: kidAvatars[1]),
          ],
        ));
        await bootGame(
          t,
          size: size,
          extra: [roomControllerProvider.overrideWith(() => room)],
        );
        appRouter.go(
          '/game/room/result',
          extra: const RaceResultArgs(
            subject: RaceSubject.toan,
            outcome: RaceOutcome(
              won: true,
              kidTime: Duration(seconds: 40),
              firstTryCorrect: 12,
              cometsFirstTry: 2,
              answered: 12,
              missed: [],
            ),
            record: null,
            kidSteps: 18,
            rocket: 'rocket_orange',
            trail: 'trail_flame',
            online: true,
            rank: 1,
          ),
        );
        await pumpReal(t);

        final podium = find.byKey(const ValueKey('room-result-podium'));
        expect(podium, findsOneWidget);

        final r1 = find.byKey(const ValueKey('podium-rank-1'));
        final r2 = find.byKey(const ValueKey('podium-rank-2'));
        final r3 = find.byKey(const ValueKey('podium-rank-3'));
        expect(r1, findsOneWidget);
        expect(r2, findsOneWidget);
        expect(r3, findsOneWidget);

        // 1st place stands highest (smallest top dy), then 2nd, then 3rd.
        expect(t.getTopLeft(r1).dy, lessThan(t.getTopLeft(r2).dy));
        expect(t.getTopLeft(r2).dy, lessThan(t.getTopLeft(r3).dy));

        // 2nd on left, 1st center, 3rd on right.
        expect(t.getTopLeft(r2).dx, lessThan(t.getTopLeft(r1).dx));
        expect(t.getTopLeft(r1).dx, lessThan(t.getTopLeft(r3).dx));

        expect(find.descendant(of: r1, matching: find.text('#1')), findsOneWidget);
        expect(find.descendant(of: r2, matching: find.text('#2')), findsOneWidget);
        expect(find.descendant(of: r3, matching: find.text('#3')), findsOneWidget);
        expect(
          find.descendant(of: podium, matching: find.byType(Image)),
          findsNWidgets(4), // 3 avatars + 1 crown for #1
        );
        expect(t.takeException(), isNull);
      });
    }
  });
}
