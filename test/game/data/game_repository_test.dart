import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/game/data/badges.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/engine/race.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/progress_repository.dart';

RaceOutcome outcome({
  bool won = true,
  int seconds = 40,
  int first = 8,
  int comets = 0,
  List<RaceQuestion> missed = const [],
}) =>
    RaceOutcome(
      won: won,
      kidTime: Duration(seconds: seconds),
      firstTryCorrect: first,
      cometsFirstTry: comets,
      missed: missed,
    );

final _aMiss = ToneRaceQuestion('dau-sac', const ['dau-sac', 'dau-hoi', 'dau-nga']);

void main() {
  late AppDatabase db;
  late GameRepository repo;
  var tick = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tick = 0;
    repo = GameRepository(db,
        kidId: 1, now: () => DateTime(2026, 11, 16).add(Duration(minutes: tick++)));
  });
  tearDown(() => db.close());

  Future<RaceRecordResult> race(GameRepository r, RaceSubject s, RaceOutcome o,
          {bool retry = false}) =>
      r.recordRace(s, o, wasRetryAfterLoss: retry);

  test('win gives 5 stars, +comets; lose gives 3', () async {
    final a = await race(repo, RaceSubject.toan, outcome(comets: 2));
    expect(a.starsEarned, 7);
    expect(a.beatRecord, isFalse);
    expect(a.previousBest, isNull);
    expect(a.totalStars, 7);
    final b = await race(repo, RaceSubject.toan, outcome(won: false));
    expect(b.starsEarned, 3);
    expect(b.totalStars, 10);
    expect(b.milestonesCrossed, [10]);
  });

  test('record: +2 only after the first won race of that subject', () async {
    await race(repo, RaceSubject.toan, outcome(seconds: 40));
    // other subject is independent: no previous, no record
    final tv = await race(repo, RaceSubject.tiengViet, outcome(seconds: 30));
    expect(tv.beatRecord, isFalse);
    final slower = await race(repo, RaceSubject.toan, outcome(seconds: 50));
    expect(slower.beatRecord, isFalse);
    expect(slower.previousBest, const Duration(seconds: 40));
    final faster = await race(repo, RaceSubject.toan, outcome(seconds: 35));
    expect(faster.beatRecord, isTrue);
    expect(faster.previousBest, const Duration(seconds: 40));
    expect(faster.starsEarned, 7);
  });

  test('lost races never set or beat a record', () async {
    await race(repo, RaceSubject.toan, outcome(won: false, seconds: 20));
    final w = await race(repo, RaceSubject.toan, outcome(seconds: 40));
    expect(w.beatRecord, isFalse);
    expect(w.previousBest, isNull);
    final s = await repo.stats(RaceSubject.toan);
    expect(s.races, 2);
    expect(s.wins, 1);
    expect(s.bestTime, const Duration(seconds: 40));
  });

  test('never touches lesson completions or other learning tables', () async {
    await ProgressRepository(db, kidId: 1).recordLessonCompleted(itemsCompleted: 2);
    await race(repo, RaceSubject.toan, outcome());
    await race(repo, RaceSubject.tiengViet, outcome(won: false));
    expect(await db.select(db.lessonCompletions).get(), hasLength(1));
    expect(await ProgressRepository(db, kidId: 1).totalStars(), 4);
    expect(await db.select(db.subjectLevels).get(), isEmpty);
    expect(await db.select(db.glyphProgress).get(), isEmpty);
    expect(await db.select(db.dailyUsage).get(), isEmpty);
  });

  test('stats count first-try correct per subject', () async {
    await race(repo, RaceSubject.toan, outcome(first: 7));
    await race(repo, RaceSubject.toan, outcome(first: 9, won: false));
    await race(repo, RaceSubject.tiengViet, outcome(first: 4));
    expect((await repo.stats(RaceSubject.toan)).firstTryCorrect, 16);
    expect((await repo.stats(RaceSubject.tiengViet)).firstTryCorrect, 4);
    final fresh = await repo.stats(RaceSubject.tiengViet);
    expect(fresh.bestTime, const Duration(seconds: 40));
  });

  group('offers', () {
    Future<void> setStars(int n) => db.into(db.gameProfile).insertOnConflictUpdate(
        GameProfileCompanion(kidId: Value(1), cosmicStars: Value(n)));

    test('no offer below the first milestone', () async {
      await setStars(9);
      expect(await repo.pendingOffer(), isEmpty);
    });

    test('offers come one after another; unpicked item returns first',
        () async {
      await setStars(41); // 10, 25, 40 reached, none picked
      expect(await repo.pendingOffer(), ['rocket_blue', 'trail_rainbow']);
      await repo.pick('trail_rainbow');
      expect(await repo.pendingOffer(), ['rocket_blue', 'sticker_clap']);
      await repo.pick('sticker_clap');
      expect(await repo.pendingOffer(), ['rocket_blue', 'rocket_green']);
      await repo.pick('rocket_blue');
      expect(await repo.pendingOffer(), isEmpty);
      expect(await repo.owned(), containsAll([
        'rocket_orange', 'trail_flame', 'trail_rainbow', 'sticker_clap', 'rocket_blue'
      ]));
    });

    test('pick rejects an item that is not on offer', () async {
      await setStars(10);
      expect(() => repo.pick('rocket_purple'), throwsStateError);
      await repo.pick('rocket_blue');
      expect(() => repo.pick('trail_rainbow'), throwsStateError);
    });

    test('recordRace crossing a milestone creates a pending offer', () async {
      await setStars(8);
      final r = await race(repo, RaceSubject.toan, outcome());
      expect(r.milestonesCrossed, [10]);
      expect(await repo.pendingOffer(), ['rocket_blue', 'trail_rainbow']);
    });

    test('select needs an owned item', () async {
      expect(() => repo.select(rocket: 'rocket_blue'), throwsStateError);
      await setStars(10);
      await repo.pick('rocket_blue');
      await repo.select(rocket: 'rocket_blue');
      expect(await repo.selected(), (rocket: 'rocket_blue', trail: 'trail_flame'));
      await repo.select(trail: 'trail_flame');
      expect(await repo.selected(), (rocket: 'rocket_blue', trail: 'trail_flame'));
    });

    test('empty pool gives no offer', () async {
      await setStars(10);
      for (final id in [
        'rocket_blue', 'trail_rainbow', 'sticker_clap', 'rocket_green',
        'trail_sparkle', 'sticker_laugh', 'rocket_purple', 'trail_blue_flame',
      ]) {
        await db.into(db.gameItems).insert(GameItemsCompanion.insert(kidId: 1, itemId: id));
      }
      expect(await repo.pendingOffer(), isEmpty);
    });
  });

  group('badges', () {
    test('speed_king after 3 records, earned once', () async {
      var t = 100;
      final got = <GameBadge>[];
      for (var i = 0; i < 5; i++) {
        final r = await race(repo, RaceSubject.toan, outcome(seconds: t--));
        got.addAll(r.newBadges);
      }
      // race 1 sets the record, races 2-4 beat it
      expect(got.where((b) => b == GameBadge.speedKing), hasLength(1));
      expect(await repo.badges(), contains(GameBadge.speedKing));
    });

    test('speed_king not yet at 2 records', () async {
      await race(repo, RaceSubject.toan, outcome(seconds: 50));
      await race(repo, RaceSubject.toan, outcome(seconds: 49));
      final r = await race(repo, RaceSubject.toan, outcome(seconds: 48));
      expect(r.newBadges, isEmpty);
      final r4 = await race(repo, RaceSubject.toan, outcome(seconds: 47));
      expect(r4.newBadges, [GameBadge.speedKing]);
    });

    // Comets (+2) end a perfect race after 8 questions, so "all correct
    // on the first try" means a won race with no question missed.
    test('scholar needs a won race with every question right first try',
        () async {
      final miss = await race(
          repo, RaceSubject.toan, outcome(first: 7, missed: [_aMiss]));
      expect(miss.newBadges, isNot(contains(GameBadge.scholar)));
      final lost =
          await race(repo, RaceSubject.toan, outcome(won: false, first: 7));
      expect(lost.newBadges, isNot(contains(GameBadge.scholar)));
      final perfect = await race(repo, RaceSubject.toan, outcome(first: 8));
      expect(perfect.newBadges, contains(GameBadge.scholar));
      final again = await race(repo, RaceSubject.toan, outcome(first: 8));
      expect(again.newBadges, isNot(contains(GameBadge.scholar)));
      expect(GameBadge.scholar.howTo, 'Về đích mà không sai câu nào');
    });

    test('comet_hunter at 10 cumulative comets', () async {
      await race(repo, RaceSubject.toan, outcome(comets: 3));
      await race(repo, RaceSubject.tiengViet, outcome(comets: 3));
      final r = await race(repo, RaceSubject.toan, outcome(comets: 3));
      expect(r.newBadges, isNot(contains(GameBadge.cometHunter)));
      final r2 = await race(repo, RaceSubject.toan, outcome(comets: 1));
      expect(r2.newBadges, contains(GameBadge.cometHunter));
    });

    test('never_give_up counts only retries after a loss', () async {
      for (var i = 0; i < 5; i++) {
        await race(repo, RaceSubject.toan, outcome(won: false));
      }
      expect(await repo.badges(), isNot(contains(GameBadge.neverGiveUp)));
      await race(repo, RaceSubject.toan, outcome(won: false), retry: true);
      await race(repo, RaceSubject.toan, outcome(won: false), retry: true);
      final r = await race(repo, RaceSubject.toan, outcome(won: false), retry: true);
      expect(r.newBadges, [GameBadge.neverGiveUp]);
    });

    test('chip_buddy at 5 wins, losses do not count', () async {
      for (var i = 0; i < 4; i++) {
        await race(repo, RaceSubject.toan, outcome(seconds: 40 + i));
      }
      await race(repo, RaceSubject.toan, outcome(won: false));
      expect(await repo.badges(), isNot(contains(GameBadge.chipBuddy)));
      final r = await race(repo, RaceSubject.tiengViet, outcome());
      expect(r.newBadges, contains(GameBadge.chipBuddy));
    });

    test('math_whiz and letter_master count per subject at 50', () async {
      for (var i = 0; i < 5; i++) {
        await race(repo, RaceSubject.toan, outcome(first: 9, won: false));
      }
      expect(await repo.badges(), isNot(contains(GameBadge.mathWhiz)));
      final r = await race(repo, RaceSubject.toan, outcome(first: 5, won: false));
      expect(r.newBadges, contains(GameBadge.mathWhiz));
      expect(r.newBadges, isNot(contains(GameBadge.letterMaster)));
      for (var i = 0; i < 5; i++) {
        await race(repo, RaceSubject.tiengViet, outcome(first: 10, won: false));
      }
      expect(await repo.badges(), contains(GameBadge.letterMaster));
    });

    test('pilot at 20 races', () async {
      for (var i = 0; i < 19; i++) {
        await race(repo, RaceSubject.toan, outcome(won: false, first: 0));
      }
      expect(await repo.badges(), isNot(contains(GameBadge.pilot)));
      final r = await race(repo, RaceSubject.toan, outcome(won: false, first: 0));
      expect(r.newBadges, [GameBadge.pilot]);
    });
  });

  group('pacing', () {
    test('mean answer defaults to 6 s and is a running average of race means',
        () async {
      expect(await repo.meanAnswer(), const Duration(seconds: 6));
      await race(repo, RaceSubject.toan, outcome(seconds: 40)); // mean 4000
      expect(await repo.meanAnswer(), const Duration(milliseconds: 4000));
      await race(repo, RaceSubject.toan, outcome(seconds: 80)); // 8000
      expect(await repo.meanAnswer(), const Duration(milliseconds: 6000));
    });

    test('race mean is clamped to [1500, 15000]', () async {
      await race(repo, RaceSubject.toan, outcome(seconds: 2)); // 200 -> 1500
      expect(await repo.meanAnswer(), const Duration(milliseconds: 1500));
      await race(repo, RaceSubject.toan, outcome(seconds: 500)); // 50000 -> 15000
      expect(await repo.meanAnswer(), const Duration(milliseconds: 8250));
    });

    test('slowdown set by a loss, read purely, consumed once, cleared by win',
        () async {
      expect(await repo.nextSlowdown(), 1.0);
      await race(repo, RaceSubject.toan, outcome(won: false));
      expect(await repo.nextSlowdown(), 1.15);
      expect(await repo.nextSlowdown(), 1.15);
      expect(await repo.consumeSlowdown(), 1.15);
      expect(await repo.nextSlowdown(), 1.0);
      expect(await repo.consumeSlowdown(), 1.0);
      await race(repo, RaceSubject.toan, outcome(won: false));
      await race(repo, RaceSubject.toan, outcome());
      expect(await repo.nextSlowdown(), 1.0);
    });
  });

  group('per kid', () {
    test('kid B does not see kid A data; deleting A removes game rows',
        () async {
      final kids = KidRepository(db);
      final a = await kids.addKid(nickname: 'A', avatar: 'x', age: 5);
      final b = await kids.addKid(nickname: 'B', avatar: 'x', age: 5);
      final ra = GameRepository(db, kidId: a);
      final rb = GameRepository(db, kidId: b);
      for (var i = 0; i < 3; i++) {
        await race(ra, RaceSubject.toan, outcome(first: 10, comets: 3));
      }
      expect((await ra.stats(RaceSubject.toan)).races, 3);
      expect((await rb.stats(RaceSubject.toan)).races, 0);
      expect(await rb.badges(), isEmpty);
      expect(await rb.pendingOffer(), isEmpty);
      expect(await rb.meanAnswer(), const Duration(seconds: 6));
      expect(await ra.pendingOffer(), isNotEmpty);
      await ra.pick('rocket_blue');

      await kids.deleteKid(a);
      expect(await db.select(db.raceResults).get(), isEmpty);
      expect(await db.select(db.gameProfile).get(), isEmpty);
      expect(await db.select(db.gameItems).get(), isEmpty);
      expect(await db.select(db.gameBadges).get(), isEmpty);
      expect(await db.select(db.gameCounters).get(), isEmpty);
    });

    test('deleteAllData wipes game rows', () async {
      await race(repo, RaceSubject.toan, outcome(first: 10));
      await KidRepository(db).deleteAllData();
      expect(await db.select(db.raceResults).get(), isEmpty);
      expect(await db.select(db.gameProfile).get(), isEmpty);
      expect(await db.select(db.gameBadges).get(), isEmpty);
      expect(await db.select(db.gameCounters).get(), isEmpty);
    });

    test('null kid reads empty and writes throw', () async {
      final none = GameRepository(db, kidId: null);
      expect(await none.owned(), {'rocket_orange', 'trail_flame'});
      expect(await none.pendingOffer(), isEmpty);
      expect(await none.nextSlowdown(), 1.0);
      expect(() => race(none, RaceSubject.toan, outcome()), throwsStateError);
    });
  });
  group('garage and cabinet reads', () {
    test('badgeDates gives when each badge was earned', () async {
      await race(repo, RaceSubject.toan, outcome(first: 8));
      final dates = await repo.badgeDates();
      expect(dates.keys, [GameBadge.scholar]);
      // The clock ticks a minute per read: finishedAt, then earnedAt.
      expect(dates[GameBadge.scholar], DateTime(2026, 11, 16, 0, 1));
    });

    test('new garage items: owned rockets and trails not yet seen', () async {
      expect(await repo.newGarageItems(), isEmpty);
      for (final id in ['rocket_blue', 'trail_rainbow', 'sticker_clap']) {
        await db
            .into(db.gameItems)
            .insert(GameItemsCompanion.insert(kidId: 1, itemId: id));
      }
      // Stickers are not garage items; starters are never "new".
      expect(await repo.newGarageItems(), {'rocket_blue', 'trail_rainbow'});
      await repo.markSeen(['rocket_blue']);
      expect(await repo.newGarageItems(), {'trail_rainbow'});
      await repo.select(trail: 'trail_rainbow');
      expect(await repo.newGarageItems(), isEmpty);
      // Kept per kid.
      final other = GameRepository(db, kidId: 2);
      expect(await other.newGarageItems(), isEmpty);
    });
  });
}
