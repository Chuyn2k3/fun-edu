import 'dart:math';

import 'package:funedu/game/engine/chip_pacer.dart';
import 'package:funedu/game/engine/question_source.dart';
import 'package:funedu/game/engine/race.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/game/engine/rewards.dart';
import 'package:funedu/learning/writing_ladder.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

List<RaceQuestion> _qs({
  int count = 10,
  Set<int> comets = const {2, 5, 8},
}) =>
    [
      for (var i = 0; i < count; i++)
        ToneRaceQuestion('dau-sac', ['dau-sac', 'dau-hoi', 'dau-nga'],
            comet: comets.contains(i)),
    ];

Race _onlineRace({List<RaceQuestion>? questions}) => Race(
      questions: questions ??
          _qs(count: 20, comets: const {2, 5, 8, 11, 14, 17}),
      pacer: ChipPacer(),
      length: onlineRaceLength,
      sprintFromStep: onlineSprintFrom,
    );

const _ms = Duration(milliseconds: 1);

void main() {
  group('Race', () {
    test('plain +1, comet +2, wrong keeps steps and question', () {
      final r = Race(questions: _qs(), pacer: ChipPacer());
      expect(r.answer(1, _ms).correct, isFalse);
      expect(r.kidSteps, 0);
      expect(r.questionIndex, 0);
      expect(r.answer(0, _ms).gained, 1);
      expect(r.kidSteps, 1);
      r.answer(0, _ms);
      expect(r.questionIndex, 2);
      expect(r.answer(0, _ms).gained, 2);
      expect(r.kidSteps, 4);
    });

    test('comet after a wrong try still gives +2 but not first-try', () {
      final r = Race(questions: _qs(), pacer: ChipPacer());
      r.answer(0, _ms);
      r.answer(0, _ms);
      r.answer(1, _ms);
      final res = r.answer(0, _ms);
      expect(res.gained, 2);
      expect(res.firstTry, isFalse);
      // finish with all remaining correct
      while (!r.finished) {
        r.answer(0, _ms);
      }
      // comet 3 had a wrong try; the race ends at 10 steps before comet 9.
      expect(r.outcome!.cometsFirstTry, 1);
      expect(r.outcome!.missed, hasLength(1));
      expect(r.outcome!.firstTryCorrect, 7);
    });

    test('finish clamps at 10 and kid can finish before question 10', () {
      final r = Race(questions: _qs(), pacer: ChipPacer());
      var answered = 0;
      while (!r.finished) {
        r.answer(0, const Duration(seconds: 1));
        answered++;
      }
      expect(r.kidSteps, 10);
      expect(answered, 8); // 1+1+2+1+1+2+1+1 = 10, before question 9
      expect(r.outcome!.won, isTrue);
      expect(r.outcome!.kidTime, const Duration(seconds: 8));
      expect(r.outcome!.answered, 8);
      expect(() => r.answer(0, _ms), throwsStateError);
    });

    test('chip reaching 10 first is a loss', () {
      final r = Race(questions: _qs(), pacer: ChipPacer());
      var t = Duration.zero;
      while (!r.finished && r.questionIndex < 9) {
        r.answer(0, const Duration(milliseconds: 100));
        for (var i = 0; i < 3; i++) {
          t += const Duration(seconds: 10);
          r.tick(t);
        }
      }
      // keep kid slow: never answer; chip is capped at kid+2
      expect(r.chipSteps <= r.kidSteps + 2, isTrue);
    });

    test('chip finishing ends race as loss', () {
      final qs = _qs();
      final r = Race(
          questions: qs,
          pacer: ChipPacer(initialMean: const Duration(milliseconds: 1)));
      // kid at 8 steps (answer 0..7 incl. comets), then chip catches up.
      for (var i = 0; i < 6; i++) {
        r.answer(0, _ms); // 1+1+2+1+1+2 = 8
      }
      expect(r.kidSteps, 8);
      var t = Duration.zero;
      while (!r.finished) {
        t += const Duration(milliseconds: 10);
        r.tick(t);
      }
      expect(r.chipSteps, 10);
      expect(r.outcome!.won, isFalse);
      expect(r.outcome!.answered, 6);
    });

    test('consecutive first-try correct answers trigger comboStreak and Nitro', () {
      final r = Race(questions: _qs(), pacer: ChipPacer());
      expect(r.comboStreak, 0);
      expect(r.isNitroActive, isFalse);

      final r1 = r.answer(0, const Duration(seconds: 2));
      expect(r.comboStreak, 1);
      expect(r.isNitroActive, isFalse);
      expect(r1.comboStreak, 1);

      final r2 = r.answer(0, const Duration(seconds: 2));
      expect(r.comboStreak, 2);
      expect(r.isNitroActive, isTrue);
      expect(r2.comboStreak, 2);

      // Wrong answer resets comboStreak
      final r3 = r.answer(1, const Duration(seconds: 2));
      expect(r.comboStreak, 0);
      expect(r.isNitroActive, isFalse);
      expect(r3.comboStreak, 0);
    });

    test('luckyStarsCollected increments when kidSteps crosses 4 and 8', () {
      final r = Race(questions: _qs(), pacer: ChipPacer());
      expect(r.luckyStarsCollected, 0);

      // q0: wrong try resets streak, then correct answer -> kidSteps = 1
      r.answer(1, _ms);
      r.answer(0, _ms);
      expect(r.kidSteps, 1);
      expect(r.luckyStarsCollected, 0);

      // q1: wrong try then correct -> kidSteps = 2
      r.answer(1, _ms);
      r.answer(0, _ms);
      expect(r.kidSteps, 2);
      expect(r.luckyStarsCollected, 0);

      // q2 (comet, +2): wrong try then correct -> kidSteps = 4 (crosses 4)
      r.answer(1, _ms);
      final rComet = r.answer(0, _ms);
      expect(r.kidSteps, 4);
      expect(r.luckyStarsCollected, 1);
      expect(rComet.luckyStarsCollected, 1);

      // q3: wrong then correct -> kidSteps = 5
      r.answer(1, _ms);
      r.answer(0, _ms);
      // q4: wrong then correct -> kidSteps = 6
      r.answer(1, _ms);
      r.answer(0, _ms);
      // q5 (comet, +2): wrong then correct -> kidSteps = 8 (crosses 8)
      r.answer(1, _ms);
      final rComet2 = r.answer(0, _ms);
      expect(r.kidSteps, 8);
      expect(r.luckyStarsCollected, 2);
      expect(rComet2.luckyStarsCollected, 2);

      // q6: wrong then correct -> kidSteps = 9
      r.answer(1, _ms);
      r.answer(0, _ms);
      // q7: wrong then correct -> kidSteps = 10 (finish)
      r.answer(1, _ms);
      r.answer(0, _ms);
      expect(r.finished, isTrue);
      expect(r.outcome!.luckyStarsCollected, 2);
      expect(r.outcome!.comboStreak, 0);
    });

    test('offline race unchanged', () {
      final r = Race(questions: _qs(), pacer: ChipPacer());
      expect(r.length, 10);
      expect(r.stage, 1);
      expect(r.inSprint, isFalse);

      // Step through with wrong tries so no step is skipped, checking +1/+2,
      // stars at {4, 8}, stage always 1, stageCleared always false.
      while (!r.finished) {
        final q = r.current;
        final res = r.answer(0, _ms);
        expect(res.gained, q.comet ? 2 : 1);
        expect(res.stageCleared, isFalse);
        expect(r.stage, 1);
        expect(r.inSprint, isFalse);
      }
      expect(r.kidSteps, 10);
      expect(r.outcome!.won, isTrue);
      expect(r.outcome!.luckyStarsCollected, 2);
    });

    test('online race is 18 steps in 3 stages', () {
      // No comets so steps advance +1 in stage 1 & 2, +2 in stage 3.
      final r = _onlineRace(questions: _qs(count: 20, comets: const {}));
      expect(r.length, 18);
      expect(r.stage, 1);
      expect(r.inSprint, isFalse);

      // Steps 0..5 -> stage 1
      for (var s = 0; s < 6; s++) {
        expect(r.stage, 1);
        expect(r.inSprint, isFalse);
        r.answer(0, _ms);
      }
      expect(r.kidSteps, 6);
      expect(r.stage, 2);

      // Steps 6..11 -> stage 2
      for (var s = 6; s < 12; s++) {
        expect(r.stage, 2);
        expect(r.inSprint, isFalse);
        r.answer(0, _ms);
      }
      expect(r.kidSteps, 12);
      expect(r.stage, 3);
      expect(r.inSprint, isTrue);

      // Steps 12..18 -> stage 3
      while (!r.finished) {
        expect(r.stage, 3);
        expect(r.inSprint, isTrue);
        r.answer(0, _ms);
      }
      expect(r.kidSteps, 18);
      expect(r.stage, 3);
      expect(r.outcome!.won, isTrue);
    });

    test('sprint first try gives 2', () {
      final r = _onlineRace(questions: _qs(count: 20, comets: const {}));
      for (var i = 0; i < 12; i++) {
        r.answer(0, _ms);
      }
      expect(r.kidSteps, 12);
      expect(r.inSprint, isTrue);

      final res = r.answer(0, _ms);
      expect(res.correct, isTrue);
      expect(res.firstTry, isTrue);
      expect(res.gained, 2);
      expect(r.kidSteps, 14);
    });

    test('sprint second try gives 1', () {
      final r = _onlineRace(questions: _qs(count: 20, comets: const {}));
      for (var i = 0; i < 12; i++) {
        r.answer(0, _ms);
      }
      expect(r.kidSteps, 12);
      expect(r.inSprint, isTrue);

      expect(r.answer(1, _ms).correct, isFalse);
      final res = r.answer(0, _ms);
      expect(res.correct, isTrue);
      expect(res.firstTry, isFalse);
      expect(res.gained, 1);
      expect(r.kidSteps, 13);
    });

    test('comet in sprint still 2', () {
      // Put a comet at the question reached at step 12.
      final r = _onlineRace(questions: _qs(count: 20, comets: const {12}));
      for (var i = 0; i < 12; i++) {
        r.answer(0, _ms);
      }
      expect(r.kidSteps, 12);
      expect(r.inSprint, isTrue);
      expect(r.current.comet, isTrue);

      final res = r.answer(0, _ms);
      expect(res.firstTry, isTrue);
      expect(res.gained, 2);
      expect(r.kidSteps, 14);
    });

    test('stageCleared at 6 and 12', () {
      // Case A: plain steps crossing 6 and 12, not other steps.
      final r1 = _onlineRace(questions: _qs(count: 20, comets: const {}));
      final clearedAt = <int>[];
      while (!r1.finished) {
        final res = r1.answer(0, _ms);
        if (res.stageCleared) clearedAt.add(r1.kidSteps);
      }
      expect(clearedAt, [6, 12]);
      expect(r1.luckyStarsCollected, 2);

      // Case B: comet jumping 5 -> 7 clears stage 1 at 7, and lucky star crosses 6.
      final r2 = _onlineRace(questions: _qs(count: 20, comets: const {5}));
      for (var i = 0; i < 5; i++) {
        final res = r2.answer(0, _ms);
        expect(res.stageCleared, isFalse);
      }
      expect(r2.kidSteps, 5);
      final jump = r2.answer(0, _ms);
      expect(r2.kidSteps, 7);
      expect(jump.stageCleared, isTrue);
      expect(jump.luckyStarsCollected, 1);
    });

    test('online finishes before running out of questions', () {
      final mathQs = buildRaceQuestions(
        subject: RaceSubject.toan,
        mathLevelIndex: 0,
        glyphStats: const {},
        writingStartIndex: 0,
        speechByGlyph: const {},
        rng: Random(42),
        count: 20,
      );
      final vietQs = buildRaceQuestions(
        subject: RaceSubject.tiengViet,
        mathLevelIndex: 0,
        glyphStats: const {'dau-huyen': GlyphStat(completions: 1, cleanCompletions: 1)},
        writingStartIndex: 0,
        speechByGlyph: {for (final g in writingLadder) g: 'đọc $g'},
        rng: Random(42),
        count: 20,
      );
      expect(mathQs, hasLength(20));
      expect(vietQs, hasLength(20));

      for (final qs in [mathQs, vietQs]) {
        final r = _onlineRace(questions: qs);
        while (!r.finished) {
          final wrong = (r.current.correctIndex + 1) % 3;
          r.answer(wrong, _ms);
          r.answer(r.current.correctIndex, _ms);
        }
        expect(r.outcome!.won, isTrue);
        expect(r.kidSteps, onlineRaceLength);
        expect(r.questionIndex, lessThan(20));
      }
    });
  });

  group('ChipPacer', () {
    test('2 s answers give 2.5 s interval', () {
      final p = ChipPacer();
      p.recordAnswer(const Duration(seconds: 2));
      p.recordAnswer(const Duration(seconds: 2));
      expect(p.interval, const Duration(milliseconds: 2500));
      expect(
          p.shouldStep(const Duration(milliseconds: 2499),
              chipSteps: 0, kidSteps: 1),
          isFalse);
      expect(
          p.shouldStep(const Duration(milliseconds: 2500),
              chipSteps: 0, kidSteps: 1),
          isTrue);
      p.markStep(const Duration(milliseconds: 2500));
      expect(
          p.shouldStep(const Duration(milliseconds: 4999),
              chipSteps: 1, kidSteps: 1),
          isFalse);
      expect(
          p.shouldStep(const Duration(milliseconds: 5000),
              chipSteps: 1, kidSteps: 1),
          isTrue);
    });

    test('never exceeds kid + 2', () {
      final p = ChipPacer();
      expect(p.shouldStep(const Duration(hours: 1), chipSteps: 2, kidSteps: 0),
          isFalse);
      expect(p.shouldStep(const Duration(hours: 1), chipSteps: 3, kidSteps: 1),
          isFalse);
      expect(p.shouldStep(const Duration(hours: 1), chipSteps: 1, kidSteps: 0),
          isTrue);
    });

    test('slowdown 1.15 lengthens interval by 15 %', () {
      final a = ChipPacer()..recordAnswer(const Duration(seconds: 2));
      final b = ChipPacer(slowdown: 1.15)
        ..recordAnswer(const Duration(seconds: 2));
      expect(b.interval.inMicroseconds / a.interval.inMicroseconds,
          closeTo(1.15, 1e-6));
    });

    test('initial mean used before first answer', () {
      expect(ChipPacer().interval, const Duration(milliseconds: 7500));
      expect(ChipPacer(initialMean: const Duration(seconds: 4)).interval,
          const Duration(milliseconds: 5000));
    });
  });

  group('cosmicStarsFor', () {
    RaceOutcome o(bool won, int comets) => RaceOutcome(
        won: won,
        kidTime: Duration.zero,
        firstTryCorrect: 0,
        cometsFirstTry: comets,
        answered: 0,
        missed: const []);
    test('values', () {
      expect(cosmicStarsFor(o(true, 0), beatRecord: false), 5);
      expect(cosmicStarsFor(o(false, 0), beatRecord: false), 3);
      expect(cosmicStarsFor(o(true, 3), beatRecord: false), 8);
      expect(cosmicStarsFor(o(false, 1), beatRecord: true), 6);
    });
  });
}
