import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/badge_popup.dart';
import 'package:funedu/features/game/glyph_view.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_result_screen.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/features/game/reward_offer_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/engine/race.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/screen_time/screen_time_service.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/router.dart';

import '../setup_helpers.dart';
import 'game_test_helpers.dart';

Future<List<RaceResult>> results(WidgetTester t, AppDatabase db) async =>
    (await t.runAsync(() => db.select(db.raceResults).get()))!;

Future<void> skipCutScene(WidgetTester t) async {
  expect(find.byKey(const ValueKey('landing-cutscene')), findsOneWidget);
  await t.tap(find.byKey(const ValueKey('landing-cutscene')));
  await pumpReal(t, times: 6);
  expect(find.byKey(const ValueKey('landing-cutscene')), findsNothing);
}

/// A repository whose writes can fail.
class _FlakyRepo extends GameRepository {
  _FlakyRepo(super.db, {required super.kidId, this.failRecord = false, this.failPick = false});

  final bool failRecord;
  final bool failPick;

  @override
  Future<RaceRecordResult> recordRace(RaceSubject subject, RaceOutcome o,
      {required bool wasRetryAfterLoss}) {
    if (failRecord) throw StateError('disk full');
    return super.recordRace(subject, o, wasRetryAfterLoss: wasRetryAfterLoss);
  }

  @override
  Future<void> pick(String itemId) async {
    if (failPick) throw StateError('disk full');
    return super.pick(itemId);
  }
}

void main() {
  testWidgets('winning a Toán race stores one result and shows the stars',
      (t) async {
    final h = await bootGame(t);
    await openRace(t, 'toan');
    expect(find.text('Câu 1/10'), findsOneWidget);
    await winRace(t);

    expect(find.byType(RaceResultScreen), findsOneWidget);
    final rows = await results(t, h.db);
    expect(rows, hasLength(1));
    expect(rows.single.won, isTrue);
    // 5 for the win + 2 comets (questions 3 and 6) right on the first try
    // + 2 lucky stars collected on track = 9 stars;
    // the perfect race ends at question 8, before the third comet.
    await skipCutScene(t);
    // First race ever, all first try: the scholar badge pops up first.
    await t.tap(find.text('Tuyệt quá!'));
    await pumpReal(t, times: 6);
    expect(find.text('+9'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('Đua lại!'), findsOneWidget);
    expect(find.text('Về Góc Chơi'), findsOneWidget);
  });

  testWidgets('the landing cut-scene ends by itself after about 3 s',
      (t) async {
    await bootGame(t);
    await openRace(t, 'toan');
    await winRace(t);
    expect(find.byKey(const ValueKey('landing-cutscene')), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    await pumpReal(t);
    expect(find.byKey(const ValueKey('landing-cutscene')), findsNothing);
  });

  testWidgets('the landing cut-scene waits while the app is in the background',
      (t) async {
    final h = await bootGame(t);
    await openRace(t, 'toan');
    await winRace(t);
    expect(find.byKey(const ValueKey('landing-cutscene')), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final spoken = h.speaker.spoken.length;
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    await pumpReal(t);
    // Still on the cut-scene: no badge popup, no gift sheet, no speech.
    expect(find.byKey(const ValueKey('landing-cutscene')), findsOneWidget);
    expect(find.byType(BadgePopup), findsNothing);
    expect(h.speaker.spoken.length, spoken);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Back in front: the cut-scene still has its time left to play.
    await t.pump(const Duration(seconds: 1));
    await pumpReal(t);
    expect(find.byKey(const ValueKey('landing-cutscene')), findsOneWidget);
    expect(find.byType(BadgePopup), findsNothing);
    await t.pump(const Duration(seconds: 3));
    await pumpReal(t);
    expect(find.byKey(const ValueKey('landing-cutscene')), findsNothing);
    expect(find.byType(BadgePopup), findsOneWidget);
  });

  testWidgets(
      'losing shows Suýt nữa thôi, the missed question, and Đua lại '
      'starts a slowed retry', (t) async {
    final h = await bootGame(t);
    await openRace(t, 'toan');
    final missed = raceState(t).current!;
    await answerWrong(t);
    expect(find.text('Thử lại nhé!'), findsOneWidget);
    while (raceState(t).kidSteps < 8) {
      await answerRight(t);
    }
    // Chíp catches up and lands while the kid waits.
    for (var i = 0;
        i < 60 && find.byType(RaceScreen).evaluate().isNotEmpty;
        i++) {
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
    await pumpReal(t, times: 10, step: const Duration(milliseconds: 300));

    expect(find.byType(RaceResultScreen), findsOneWidget);
    expect(find.text('Suýt nữa thôi!'), findsOneWidget);
    expect(find.text('Chỉ còn 2 bước!'), findsOneWidget);
    expect(find.text('Bí kíp của Chíp'), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-question')), findsOneWidget);
    final answerText =
        '${(missed as dynamic).answer}'; // math question: its number answer
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('tip-answer')),
            matching: find.text(answerText)),
        findsOneWidget);
    expect(h.speaker.spoken.any((s) => s.contains('Bí kíp')), isTrue);
    final rows = await results(t, h.db);
    expect(rows.single.won, isFalse);

    await t.ensureVisible(find.text('Đua lại!'));
    await pumpReal(t);
    await t.tap(find.text('Đua lại!'));
    await pumpReal(t, times: 8);
    final s = raceState(t);
    expect(s.phase, RacePhase.racing);
    expect(s.slowdown, 1.15);
    expect(s.wasRetryAfterLoss, isTrue);
    expect(s.kidSteps, 0);
  });

  testWidgets(
      'system back mid-race opens the pause overlay; leaving from it '
      'records nothing', (t) async {
    final h = await bootGame(t);
    await openRace(t, 'toan');
    await answerRight(t);
    final steps = raceState(t).kidSteps;
    // Android back / iOS edge swipe: pause, never a silent exit.
    await t.binding.handlePopRoute();
    await pumpReal(t, times: 6);
    expect(find.byType(RaceScreen), findsOneWidget);
    expect(raceState(t).paused, isTrue);
    expect(find.text('Tạm dừng'), findsOneWidget);
    // A second back keeps the overlay; the race is still there.
    await t.binding.handlePopRoute();
    await pumpReal(t, times: 4);
    expect(find.byType(RaceScreen), findsOneWidget);
    expect(raceState(t).kidSteps, steps);
    // "Đua tiếp" resumes.
    await t.tap(find.text('Đua tiếp'));
    await pumpReal(t);
    expect(raceState(t).paused, isFalse);
    // The overlay's "Về Góc Chơi" is the explicit exit.
    await t.binding.handlePopRoute();
    await pumpReal(t, times: 4);
    await t.tap(find.text('Về Góc Chơi'));
    await pumpReal(t, times: 6);
    expect(find.byType(RaceScreen), findsNothing);
    await t.pump(const Duration(minutes: 2));
    await pumpReal(t);
    expect(await results(t, h.db), isEmpty);
    final repo = GameRepository(h.db, kidId: h.kid);
    expect(await t.runAsync(repo.totalStars), 0);
  });

  testWidgets(
      'the bedtime/limit screen covers the race: nothing advances or '
      'records', (t) async {
    final h = await bootGame(t, seed: (db, kid) async {
      final kids = KidRepository(db);
      await kids.setSetting('dailyLimitMinutes.$kid', '15');
      await ScreenTimeService(db, kids)
          .addUsage(kid, const Duration(minutes: 15));
    });
    appRouter.go('/game/race/toan');
    await pumpReal(t, times: 8);
    expect(find.text('Chíp Chíp buồn ngủ rồi. Mai mình học tiếp nhé!'),
        findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(seconds: 2));
    }
    await pumpReal(t);
    final state = raceOf(t);
    expect(state?.chipSteps ?? 0, 0);
    expect(await results(t, h.db), isEmpty);
  });

  testWidgets('two milestones waiting -> two offer sheets, picks are owned',
      (t) async {
    final h = await bootGame(t, seed: (db, kid) async {
      await db.into(db.gameProfile).insert(GameProfileCompanion.insert(
          kidId: Value(kid), cosmicStars: const Value(24)));
    });
    await openRace(t, 'toan');
    await winRace(t);
    await skipCutScene(t);
    await t.tap(find.text('Tuyệt quá!')); // scholar badge
    await pumpReal(t, times: 6);

    expect(find.byType(RewardOfferSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('offer-rocket_blue')), findsOneWidget);
    expect(find.byKey(const ValueKey('offer-trail_rainbow')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('offer-rocket_blue')));
    await pumpReal(t, times: 8);

    expect(find.byType(RewardOfferSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('offer-trail_rainbow')), findsOneWidget);
    expect(find.byKey(const ValueKey('offer-sticker_clap')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('offer-sticker_clap')));
    await pumpReal(t, times: 8);
    expect(find.byType(RewardOfferSheet), findsNothing);

    final owned =
        await t.runAsync(() => GameRepository(h.db, kidId: h.kid).owned());
    expect(owned, containsAll(['rocket_blue', 'sticker_clap']));
    expect(owned!.contains('trail_rainbow'), isFalse);
  });

  testWidgets('a new badge pops up with its exact title', (t) async {
    final h = await bootGame(t);
    await openRace(t, 'toan');
    await winRace(t);
    await skipCutScene(t);
    expect(find.byType(BadgePopup), findsOneWidget);
    expect(find.text('Nhà Thông Thái'), findsOneWidget);
    expect(h.speaker.spoken.any((s) => s.contains('Nhà Thông Thái')), isTrue);
  });

  testWidgets('Tiếng Việt race draws glyph keys and speaks chữ …', (t) async {
    final h = await bootGame(t);
    await openRace(t, 'tieng-viet');
    expect(find.byType(GlyphView), findsNWidgets(3));
    expect(h.speaker.spoken.any((s) => s.startsWith('chữ ')), isTrue);
    expect(find.bySemanticsLabel('Nghe câu hỏi'), findsWidgets);
  });

  testWidgets('iPad rotation mid-race keeps steps and question', (t) async {
    await bootGame(t, size: const Size(1366, 1024));
    await openRace(t, 'toan');
    await answerRight(t);
    await answerRight(t);
    final before = raceState(t);
    setSize(t, 1024, 1366);
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    final after = raceState(t);
    expect(t.takeException(), isNull);
    expect(after.kidSteps, before.kidSteps);
    expect(after.questionIndex, before.questionIndex);
    expect(find.text('Câu 3/10'), findsOneWidget);
    // Keys are at least 80 pt on a tablet.
    final key = t.getSize(find.byKey(const ValueKey('race-key-0')));
    expect(key.height, greaterThanOrEqualTo(80));
  });

  testWidgets('home data is unchanged by a race', (t) async {
    await bootGame(t);
    final c = containerOf(t);
    Future<HomeSummary> read() async {
      final f = c.read(homeSummaryProvider.future);
      HomeSummary? v;
      f.then((x) => v = x);
      for (var i = 0; i < 40 && v == null; i++) {
        await pumpReal(t, times: 1);
      }
      return v!;
    }

    final before = await read();
    await openRace(t, 'toan');
    await winRace(t);
    c.invalidate(homeSummaryProvider);
    final after = await read();
    expect(after.totalStars, before.totalStars);
    expect(after.learnedDaysThisWeek, before.learnedDaysThisWeek);
    expect(after.masteredWriting, before.masteredWriting);
    expect(after.mathLevelIndex, before.mathLevelIndex);
    expect(after.lessonsToday, before.lessonsToday);
  });

  testWidgets('subject picker opens a race for each subject', (t) async {
    await bootGame(t);
    appRouter.go('/game/pick');
    await settle(t);
    expect(find.text('Toán'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    await t.tap(find.text('Toán'));
    await pumpReal(t, times: 8);
    expect(find.byType(RaceScreen), findsOneWidget);
    expect(raceState(t).subjectName, 'toan');
  });

  testWidgets('a failed save still leaves the race, gently', (t) async {
    late AppDatabase db;
    final h = await bootGame(t, seed: (d, _) async => db = d,
        extra: [gameRepositoryProvider.overrideWith((ref) async => _FlakyRepo(
            db,
            kidId: await ref.watch(currentKidIdProvider.future),
            failRecord: true))]);
    await openRace(t, 'toan');
    await winRace(t);
    expect(find.byType(RaceScreen), findsNothing);
    expect(find.byType(RaceResultScreen), findsOneWidget);
    if (find.byKey(const ValueKey('landing-cutscene')).evaluate().isNotEmpty) {
      await skipCutScene(t);
    }
    expect(find.textContaining('Chíp chưa ghi được'), findsOneWidget);
    expect(find.textContaining('sao vũ trụ'), findsNothing);
    expect(find.text('Đua lại!'), findsOneWidget);
    expect(await results(t, h.db), isEmpty);
  });

  testWidgets('a double tap on an offer picks once and keeps the result',
      (t) async {
    final h = await bootGame(t, seed: (db, kid) async {
      await db.into(db.gameProfile).insert(GameProfileCompanion.insert(
          kidId: Value(kid), cosmicStars: const Value(24)));
    });
    await openRace(t, 'toan');
    await winRace(t);
    await skipCutScene(t);
    await t.tap(find.text('Tuyệt quá!'));
    await pumpReal(t, times: 6);
    final card = find.byKey(const ValueKey('offer-rocket_blue'));
    await t.tap(card);
    await t.tap(card, warnIfMissed: false);
    await pumpReal(t, times: 8);
    expect(find.byType(RaceResultScreen), findsOneWidget);
    // The second milestone's sheet is up; the first pick happened once.
    expect(find.byType(RewardOfferSheet), findsOneWidget);
    final owned =
        await t.runAsync(() => GameRepository(h.db, kidId: h.kid).owned());
    expect(owned, contains('rocket_blue'));
  });

  testWidgets('a failed pick closes the sheet and the result carries on',
      (t) async {
    late AppDatabase db;
    final h = await bootGame(t, seed: (d, kid) async {
      db = d;
      await d.into(d.gameProfile).insert(GameProfileCompanion.insert(
          kidId: Value(kid), cosmicStars: const Value(24)));
    }, extra: [gameRepositoryProvider.overrideWith((ref) async => _FlakyRepo(
        db,
        kidId: await ref.watch(currentKidIdProvider.future),
        failPick: true))]);
    await openRace(t, 'toan');
    await winRace(t);
    await skipCutScene(t);
    await t.tap(find.text('Tuyệt quá!'));
    await pumpReal(t, times: 6);
    await t.tap(find.byKey(const ValueKey('offer-rocket_blue')));
    await pumpReal(t, times: 8);
    expect(t.takeException(), isNull);
    expect(find.byType(RewardOfferSheet), findsNothing);
    expect(find.byType(RaceResultScreen), findsOneWidget);
    expect(h.speaker.spoken.any((s) => s.startsWith('Bé được')), isTrue);
  });

  testWidgets('a letter that fails to load is still spoken by its name',
      (t) async {
    final h = await bootGame(t, extra: [
      glyphProvider.overrideWith((ref, id) async => throw StateError('gone')),
    ]);
    await openRace(t, 'tieng-viet');
    final q = raceState(t).current!;
    expect(q.spoken, isNotEmpty);
    expect(h.speaker.spoken.last, isNotEmpty);
    if (q is LetterRaceQuestion) expect(q.speech, startsWith('chữ '));
  });

  testWidgets('a Chíp step does not rebuild the question card', (t) async {
    await bootGame(t);
    await openRace(t, 'toan');
    final before = debugQuestionCardBuilds;
    final chip0 = raceState(t).chipSteps;
    for (var i = 0; i < 100 && raceState(t).chipSteps == chip0; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(raceState(t).chipSteps, greaterThan(chip0));
    expect(debugQuestionCardBuilds, before);
  });

  testWidgets('race time follows the clock, not the number of ticks',
      (t) async {
    await bootGame(t);
    await openRace(t, 'toan');
    final c = ProviderScope.containerOf(t.element(find.byType(RaceScreen)))
        .read(raceControllerProvider.notifier);
    final start = c.now;
    // Two long frames (jank): race time still moves by the real elapsed
    // time, capped per step so a resume never jumps.
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 200));
    expect(c.now - start, const Duration(milliseconds: 400));
    c.setPaused(true);
    await t.pump(const Duration(seconds: 5));
    expect(c.now - start, const Duration(milliseconds: 400));
    c.setPaused(false);
    await t.pump(const Duration(milliseconds: 16));
    // The paused 5 s never count, not even as one big step.
    expect(c.now - start,
        lessThanOrEqualTo(const Duration(milliseconds: 400 + 16)));
  });
}

RaceState? raceOf(WidgetTester t) {
  final f = find.byType(RaceScreen, skipOffstage: false);
  if (f.evaluate().isEmpty) return null;
  return ProviderScope.containerOf(t.element(f)).read(raceControllerProvider);
}
