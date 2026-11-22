// Shot harness for the online standings column (room of 4). Usage:
//   mkdir -p test/_shot && cp tools/shot/standings_shot_test.dart test/_shot/
//   flutter test test/_shot/standings_shot_test.dart --update-goldens
//   (PNGs in test/_shot/goldens/), then rm -rf test/_shot
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/online/room/room_controller.dart';
import 'package:funedu/router.dart';

import '../../test/features/game/game_test_helpers.dart';

class FakeRoom extends RoomController {
  FakeRoom(this.initial);
  final RoomState initial;
  @override
  RoomState build() => initial;
  @override
  void step(int n) {}
}

RoomPlayer _p(String id, String name, String avatar, int steps, [int? rank]) => RoomPlayer(
    id: id, name: name, avatar: avatar, rocket: 'rocket_green', steps: steps, rank: rank);

void main() {
  for (final size in const [Size(390, 844), Size(1366, 1024)]) {
    testWidgets('standings shot $size', (t) async {
      await t.runAsync(() async {
        final loader = FontLoader('Nunito');
        for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
          loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
        }
        await loader.load();
      });
      final room = FakeRoom(RoomState(
        phase: RoomPhase.racing,
        code: 'ABC234',
        you: 'p1',
        host: 'p1',
        players: [
          _p('p1', 'Na', 'assets/images/chip-main.png', 3),
          _p('p2', 'Bo', 'assets/images/ic-crown.png', 10, 1),
          _p('p3', 'Mi', 'assets/images/ic-star.png', 6),
          _p('p4', 'Tí', 'assets/images/ic-toan.png', 2),
        ],
      ));
      await bootGame(t, size: size, extra: [roomControllerProvider.overrideWith(() => room)]);
      appRouter.go('/game/room/race', extra: RaceSubject.toan);
      await pumpReal(t, times: 10);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump();
      await expectLater(find.byType(RaceScreen), matchesGoldenFile('goldens/standings-${size.width.toInt()}.png'));
    });
  }
}
