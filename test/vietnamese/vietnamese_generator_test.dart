import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/vietnamese/vietnamese_generator.dart';
import 'package:funedu/vietnamese/vietnamese_level.dart';
import 'package:funedu/vietnamese/vietnamese_question.dart';

void main() {
  test('vietnameseLevels defines exactly 9 unique levels', () {
    expect(vietnameseLevels.length, 9);
    expect(vietnameseLevels.map((l) => l.id).toSet().length, 9);
    expect(vietnameseLevels.map((l) => l.kind).toSet().length, 9);
  });

  for (final level in vietnameseLevels) {
    test('generates 5 valid unique questions for ${level.id}', () {
      final qs = generateVietnameseQuestions(level, Random(42), count: 5);
      expect(qs.length, 5);
      expect(qs.map((q) => q.id).toSet().length, 5);
      for (final q in qs) {
        expect(q.choices.length, 3);
        expect(q.choices.toSet().length, 3);
        expect(q.correctIndex, inInclusiveRange(0, 2));
        expect(q.speech.trim(), isNotEmpty);
        expect(q.celebrationSpeech.trim(), isNotEmpty);
        if (q.displayKind == VietnameseDisplayKind.equationBuild) {
          expect(q.equationResult, isNotEmpty);
          expect(
            (q.equationLeft == null) != (q.equationRight == null),
            isTrue,
            reason: 'Exactly one side of equation must be blank',
          );
        }
        if (q.displayKind == VietnameseDisplayKind.phraseFill) {
          expect(q.phraseBefore, isNotNull);
        }
      }
    });
  }
}
