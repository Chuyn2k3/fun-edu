import 'dart:math';

import 'package:funedu/game/engine/question_source.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/learning/writing_ladder.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

List<RaceQuestion> _viet(
  Map<String, GlyphStat> stats,
  int start,
  int seed,
) =>
    buildRaceQuestions(
      subject: RaceSubject.tiengViet,
      mathLevelIndex: 0,
      glyphStats: stats,
      writingStartIndex: start,
      speechByGlyph: {for (final g in writingLadder) g: 'đọc $g'},
      rng: Random(seed),
    );

GlyphStat _done() => const GlyphStat(completions: 1, cleanCompletions: 1);

void _checkShape(List<RaceQuestion> qs) {
  expect(qs, hasLength(10));
  for (var i = 0; i < qs.length; i++) {
    expect(qs[i].comet, const {2, 5, 8}.contains(i));
    final choices = switch (qs[i]) {
      MathRaceQuestion q => q.choices,
      LetterRaceQuestion q => q.choiceGlyphIds,
      ToneRaceQuestion q => q.choiceMarkIds,
    };
    expect(choices, hasLength(3));
    expect(choices.toSet(), hasLength(3));
    expect(qs[i].correctIndex, inInclusiveRange(0, 2));
  }
}

void main() {
  group('Toán', () {
    for (var level = 0; level < mathLevels.length; level++) {
      test('level $level: no compare, 3 distinct choices with answer', () {
        for (var seed = 0; seed < 200; seed++) {
          final qs = buildRaceQuestions(
            subject: RaceSubject.toan,
            mathLevelIndex: level,
            glyphStats: const {},
            writingStartIndex: 0,
            speechByGlyph: const {},
            rng: Random(seed),
          );
          _checkShape(qs);
          for (final q in qs.cast<MathRaceQuestion>()) {
            expect(q.question, isNot(isA<CompareQuestion>()));
            expect(q.choices[q.correctIndex], q.answer);
            expect(q.choices.every((c) => c >= 0), isTrue);
          }
        }
      });
    }
  });

  group('Tiếng Việt', () {
    test('no progress: targets in first group, no tones', () {
      for (var seed = 0; seed < 200; seed++) {
        final qs = _viet(const {}, 0, seed);
        _checkShape(qs);
        for (final q in qs) {
          expect(q, isA<LetterRaceQuestion>());
          final l = q as LetterRaceQuestion;
          expect(firstLetterGroup, contains(l.targetGlyphId));
          expect(l.spoken, 'đọc ${l.targetGlyphId}');
        }
      }
    });

    test('writing start 15 (nothing done) stays in first group', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final q in _viet(const {}, 15, seed).cast<LetterRaceQuestion>()) {
          expect(firstLetterGroup, contains(q.targetGlyphId));
        }
      }
    });

    test('progress to chu-a: targets within ladder up to chu-a + 3', () {
      final aIdx = writingLadder.indexOf('chu-a');
      final allowed = {
        for (var i = 0; i <= aIdx + 3; i++)
          if (writingLadder[i].startsWith('chu-')) writingLadder[i],
      };
      final stats = {'chu-a': _done()};
      for (var seed = 0; seed < 200; seed++) {
        final qs = _viet(stats, 0, seed);
        _checkShape(qs);
        for (final q in qs.cast<LetterRaceQuestion>()) {
          expect(allowed, contains(q.targetGlyphId));
          expect(allowed.containsAll(q.choiceGlyphIds), isTrue);
        }
      }
    });

    test('no tone question before dau-huyen reached', () {
      final stats = {'chu-p': _done()};
      for (var seed = 0; seed < 100; seed++) {
        expect(
            _viet(stats, 0, seed).any((q) => q is ToneRaceQuestion), isFalse);
      }
    });

    test('tones appear (3 of 10) once dau-huyen reached', () {
      final stats = {'dau-huyen': _done()};
      for (var seed = 0; seed < 100; seed++) {
        final qs = _viet(stats, 0, seed);
        _checkShape(qs);
        final tones = qs.whereType<ToneRaceQuestion>().toList();
        expect(tones, hasLength(3));
        for (final t in tones) {
          expect(t.spoken, startsWith('dấu '));
          expect(t.spoken, t.spoken.toLowerCase());
          expect(t.choiceMarkIds.every((m) => m.startsWith('dau-')), isTrue);
        }
      }
    });

    test('writingStartIndex past dau-huyen unlocks tones', () {
      final qs = _viet(const {}, 45, 1);
      expect(qs.whereType<ToneRaceQuestion>(), isNotEmpty);
    });

    test('distractors of chu-b come from {d h l k} when in pool', () {
      final stats = {'chu-p': _done()};
      var seen = 0;
      for (var seed = 0; seed < 300; seed++) {
        for (final q in _viet(stats, 0, seed).cast<LetterRaceQuestion>()) {
          if (q.targetGlyphId != 'chu-b') continue;
          seen++;
          for (final c in q.choiceGlyphIds.where((c) => c != 'chu-b')) {
            expect(const ['chu-d', 'chu-h', 'chu-l', 'chu-k'], contains(c));
          }
        }
      }
      expect(seen, greaterThan(0));
    });
  });
}
