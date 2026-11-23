import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/router.dart';

import '../features/game/game_test_helpers.dart';
import '../features/online_race/online_race_test.dart';

class _BuildCounterQuestionPanel extends StatelessWidget {
  const _BuildCounterQuestionPanel({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const SizedBox(
      height: 180,
      child: Center(child: Text('1 + 1 = ?')),
    );
  }
}

void main() {
  testWidgets(
      '4 online racers, 120 frames with snapshots every 100ms: '
      '0 question panel rebuilds, 0 forbidden widgets, 1 ticker',
      (tester) async {
    var questionBuilds = 0;
    final racersNotifier = ValueNotifier<List<OnlineRacer>>([
      OnlineRacer(
        id: 'p1',
        name: 'Na',
        avatar: kidAvatars[0],
        rocket: 'rocket_orange',
        steps: 0,
        me: true,
      ),
      OnlineRacer(
        id: 'p2',
        name: 'Bo',
        avatar: kidAvatars[1],
        rocket: 'rocket_blue',
        steps: 0,
      ),
      OnlineRacer(
        id: 'p3',
        name: 'Mi',
        avatar: kidAvatars[2],
        rocket: 'rocket_green',
        steps: 0,
      ),
      OnlineRacer(
        id: 'p4',
        name: 'Su',
        avatar: kidAvatars[3],
        rocket: 'rocket_purple',
        steps: 0,
      ),
    ]);
    addTearDown(racersNotifier.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<OnlineRacer>>(
                  valueListenable: racersNotifier,
                  builder: (context, racers, _) => RaceScene(
                    kidSteps: racers.first.steps,
                    chipSteps: racers[1].steps,
                    kidRocket: 'rocket_orange',
                    kidTrail: 'trail_flame',
                    boosting: false,
                    won: false,
                    onlineRacers: racers,
                    raceSteps: 18,
                  ),
                ),
              ),
              RepaintBoundary(
                child: _BuildCounterQuestionPanel(
                  onBuild: () => questionBuilds++,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final buildsAtStart = questionBuilds;
    expect(buildsAtStart, 1);

    final sceneState = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(sceneState.debugTickersCreated, 1);

    // 120 frames at 16 ms (~1.92 s); new snapshot every ~96 ms (~100 ms).
    for (var frame = 1; frame <= 120; frame++) {
      if (frame % 6 == 0) {
        final step = (frame ~/ 6).clamp(0, 18);
        racersNotifier.value = [
          OnlineRacer(
            id: 'p1',
            name: 'Na',
            avatar: kidAvatars[0],
            rocket: 'rocket_orange',
            steps: step,
            me: true,
          ),
          OnlineRacer(
            id: 'p2',
            name: 'Bo',
            avatar: kidAvatars[1],
            rocket: 'rocket_blue',
            steps: (step - 1).clamp(0, 18),
          ),
          OnlineRacer(
            id: 'p3',
            name: 'Mi',
            avatar: kidAvatars[2],
            rocket: 'rocket_green',
            steps: (step ~/ 2).clamp(0, 18),
          ),
          OnlineRacer(
            id: 'p4',
            name: 'Su',
            avatar: kidAvatars[3],
            rocket: 'rocket_purple',
            steps: (step + 1).clamp(0, 18),
          ),
        ];
      }
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(questionBuilds, buildsAtStart);
    expect(sceneState.debugTickersCreated, 1);
    expect(
      find.descendant(of: find.byType(RaceScene), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(
      find.descendant(
          of: find.byType(RaceScene), matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(
      find.descendant(
          of: find.byType(RaceScene), matching: find.byType(ShaderMask)),
      findsNothing,
    );
    expect(
      find.descendant(
          of: find.byType(RaceScene), matching: find.byType(RepaintBoundary)),
      findsNWidgets(4),
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'full RaceScreen with 4 online players: QuestionCard builds 0 times across 120 frames',
      (tester) async {
    RoomPlayer p(String id, String name, int steps) => RoomPlayer(
          id: id,
          name: name,
          avatar: kidAvatars[0],
          rocket: 'rocket_orange',
          steps: steps,
        );

    final room = FakeRoom(RoomState(
      phase: RoomPhase.racing,
      code: 'ABC234',
      you: 'p1',
      host: 'p1',
      players: [
        p('p1', 'Na', 0),
        p('p2', 'Bo', 0),
        p('p3', 'Mi', 0),
        p('p4', 'Su', 0),
      ],
    ));

    await bootGame(
      tester,
      reduceMotion: false,
      extra: [roomControllerProvider.overrideWith(() => room)],
    );
    appRouter.go('/game/room/race', extra: RaceSubject.toan);
    await pumpReal(tester, times: 8);

    expect(find.byType(RaceScreen), findsOneWidget);
    final buildsBefore = debugQuestionCardBuilds;
    final sceneState = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(sceneState.debugTickersCreated, 1);

    for (var frame = 1; frame <= 120; frame++) {
      if (frame % 6 == 0) {
        final step = (frame ~/ 6).clamp(0, 17);
        room.set(RoomState(
          phase: RoomPhase.racing,
          code: 'ABC234',
          you: 'p1',
          host: 'p1',
          players: [
            p('p1', 'Na', 0),
            p('p2', 'Bo', step),
            p('p3', 'Mi', (step - 1).clamp(0, 17)),
            p('p4', 'Su', (step ~/ 2).clamp(0, 17)),
          ],
        ));
      }
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(debugQuestionCardBuilds, buildsBefore);
    expect(sceneState.debugTickersCreated, 1);
    expect(
      find.descendant(of: find.byType(RaceScene), matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(
      find.descendant(
          of: find.byType(RaceScene), matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(
      find.descendant(
          of: find.byType(RaceScene), matching: find.byType(ShaderMask)),
      findsNothing,
    );
  });
}
