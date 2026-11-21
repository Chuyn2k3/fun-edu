import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/game/data/badges.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/data/reward_pool.dart';
import 'package:funedu/game/engine/race.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/game/engine/rewards.dart';

RaceOutcome outcome({bool won = true, int comets = 0, int lucky = 0}) => RaceOutcome(
      won: won,
      kidTime: const Duration(seconds: 30),
      firstTryCorrect: 8,
      cometsFirstTry: comets,
      answered: 8,
      missed: const [],
      luckyStarsCollected: lucky,
    );

/// nextInt always answers [value] (clamped to the range).
class FixedRandom implements Random {
  FixedRandom(this.value);
  int value;
  @override
  int nextInt(int max) => value.clamp(0, max - 1);
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

void main() {
  group('stars for a race with friends', () {
    test('everyone earns; first places earn more; comets add', () {
      expect(onlineCosmicStarsFor(outcome(), rank: 1), 7);
      expect(onlineCosmicStarsFor(outcome(), rank: 2), 5);
      expect(onlineCosmicStarsFor(outcome(), rank: 3), 4);
      expect(onlineCosmicStarsFor(outcome(), rank: 4), 4);
      expect(onlineCosmicStarsFor(outcome(won: false), rank: null), 3);
      expect(onlineCosmicStarsFor(outcome(comets: 2), rank: 1), 9);
    });
  });

  group('rare sticker drop', () {
    test('lucky roll gives an unowned sticker', () {
      final s = rareStickerDrop(
          owned: {rareStickers[0]}, racesWithoutRare: 0, rank: 2, rng: FixedRandom(0));
      expect(s, rareStickers[1]);
    });

    test('unlucky roll gives nothing', () {
      expect(
          rareStickerDrop(owned: {}, racesWithoutRare: 0, rank: 2, rng: FixedRandom(3)),
          isNull);
    });

    test('winners roll 1 in 3, others 1 in 5', () {
      final rng = _CountingRandom();
      rareStickerDrop(owned: {}, racesWithoutRare: 0, rank: 1, rng: rng);
      rareStickerDrop(owned: {}, racesWithoutRare: 0, rank: 3, rng: rng);
      expect(rng.maxes.take(1), [3]);
      expect(rng.maxes.contains(5), isTrue);
    });

    test('the sixth race without one always brings one', () {
      expect(
          rareStickerDrop(
              owned: {}, racesWithoutRare: rareStickerPity - 1, rank: null, rng: FixedRandom(4)),
          isNotNull);
    });

    test('nothing once every rare sticker is owned', () {
      expect(
          rareStickerDrop(
              owned: rareStickers.toSet(), racesWithoutRare: 99, rank: 1, rng: FixedRandom(0)),
          isNull);
    });
  });

  group('recordOnlineRace', () {
    late AppDatabase db;
    late GameRepository repo;
    var tick = 0;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      tick = 0;
      repo = GameRepository(db,
          kidId: 1, now: () => DateTime(2026, 11, 21).add(Duration(minutes: tick++)));
    });
    tearDown(() => db.close());

    Future<OnlineRaceRecord> online({int? rank = 1, int players = 2, int roll = 4, RaceOutcome? o}) =>
        repo.recordOnlineRace(RaceSubject.toan, o ?? outcome(),
            rank: rank, players: players, rng: FixedRandom(roll));

    test('adds cosmic stars (with lucky stars) but leaves Chíp alone', () async {
      final before = await repo.meanAnswer();
      final r = await online(rank: 2, o: outcome(lucky: 2));
      expect(r.starsEarned, 7);
      expect(await repo.totalStars(), 7);
      expect(await repo.meanAnswer(), before);
      expect(await repo.nextSlowdown(), 1.0);
      // Not counted as a race against Chíp.
      final stats = await repo.stats(RaceSubject.toan);
      expect(stats.races, 0);
      final row = await db.select(db.raceResults).getSingle();
      expect(row.subject, 'online:toan');
      expect(row.won, isFalse);
    });

    test('online badges: 5 races, 3 wins, a full room, 20 cheers', () async {
      final r1 = await online(players: 4);
      expect(r1.newBadges, [GameBadge.bigRace]);
      for (var i = 0; i < 3; i++) {
        await online(rank: 1);
      }
      final r5 = await online(rank: 2);
      expect(r5.newBadges, [GameBadge.friendRacer]);
      expect((await repo.badges()), containsAll([GameBadge.friendChampion, GameBadge.bigRace]));

      for (var i = 0; i < 20; i++) {
        await repo.countStickerSent();
      }
      final r6 = await online(rank: 3);
      expect(r6.newBadges, [GameBadge.cheerleader]);
      // Chíp's badges are not given by online races.
      expect(await repo.badges(), isNot(contains(GameBadge.pilot)));
    });

    test('a rare sticker drops at the latest on the sixth race, and is owned', () async {
      String? got;
      for (var i = 0; i < rareStickerPity && got == null; i++) {
        got = (await online(rank: 3, roll: 4)).rareSticker;
      }
      expect(got, isNotNull);
      expect(await repo.owned(), contains(got));
      // The streak starts again after a drop.
      expect((await online(rank: 3, roll: 4)).rareSticker, isNull);
    });
  });
}

class _CountingRandom implements Random {
  final maxes = <int>[];
  @override
  int nextInt(int max) {
    maxes.add(max);
    return max - 1;
  }

  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}
