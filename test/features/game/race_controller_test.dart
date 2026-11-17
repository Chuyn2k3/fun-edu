import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';

import '../setup_helpers.dart';

void main() {
  test(
      'when a race finishes with luckyStarsCollected > 0, recordRace awards bonus cosmic stars and RaceResultArgs includes luckyStarsCollected',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final kids = KidRepository(db);
    final kid =
        await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    await placeKid(db, kid);

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        raceRandomProvider.overrideWith((ref) => Random(7)),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(raceControllerProvider, (_, __) {});
    addTearDown(sub.close);

    final controller = container.read(raceControllerProvider.notifier);
    await controller.start(RaceSubject.toan);

    expect(container.read(raceControllerProvider).phase, RacePhase.racing);

    while (container.read(raceControllerProvider).phase == RacePhase.racing) {
      final s = container.read(raceControllerProvider);
      final q = s.current!;
      controller.answer(q.correctIndex);
      controller.advance(const Duration(milliseconds: 100));
      controller.showNext();
    }

    for (var i = 0;
        i < 50 &&
            container.read(raceControllerProvider).phase != RacePhase.done;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final res = container.read(raceControllerProvider).result;
    expect(res, isNotNull);
    expect(res!.luckyStarsCollected, greaterThan(0));
    expect(res.luckyStarsCollected, 2);

    // Base stars: win (5) + 2 comets first try (2) = 7.
    // Total stars: 7 + 2 lucky stars = 9.
    expect(res.record?.starsEarned, 9);

    final rows = await db.select(db.raceResults).get();
    expect(rows, hasLength(1));
    expect(rows.single.stars, 9);
  });
}
