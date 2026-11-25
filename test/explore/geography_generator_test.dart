import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/explore/geography_generator.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/explore/geography_question.dart';

void main() {
  for (var li = 0; li < geographyLevels.length; li++) {
    final level = geographyLevels[li];
    test('five valid questions for ${level.id}', () {
      final qs = generateGeographyQuestions(level, Random(42));
      expect(qs.length, 5);
      for (final q in qs) {
        expect(q.choices.length, 3);
        expect(q.choices.map((c) => c.id).toSet().length, 3);
        for (final c in q.choices) {
          expect(level.items, contains(c));
        }
        expect(q.correctIndex, inInclusiveRange(0, 2));
        expect(q.answer, q.choices[q.correctIndex]);
        if (q.kind == GeoQuestionKind.pickImage) {
          expect(q.prompt, 'Đâu là ${q.answer.name}?');
          expect(q.speech, 'Đâu là ${q.answer.speech}?');
        } else {
          expect(q.prompt, q.answer.clue);
          expect(q.speech, q.answer.clue);
        }
      }
      expect(qs.map((q) => q.answer.id).toSet().length, 5);
      final clues =
          qs.where((q) => q.kind == GeoQuestionKind.listenClue).length;
      if (li < 3) {
        expect(clues, 0);
      } else {
        expect(clues, inInclusiveRange(2, 3));
      }
    });
  }

  test('same seed, same questions', () {
    List<String> ids(int seed) => [
          for (final q
              in generateGeographyQuestions(geographyLevels[4], Random(seed)))
            q.id
        ];
    expect(ids(7), ids(7));
  });

  test('both clue counts happen across seeds', () {
    final counts = <int>{
      for (var s = 0; s < 40; s++)
        generateGeographyQuestions(geographyLevels[3], Random(s))
            .where((q) => q.kind == GeoQuestionKind.listenClue)
            .length
    };
    expect(counts, {2, 3});
  });
}
