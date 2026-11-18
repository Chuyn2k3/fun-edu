import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/english/english_generator.dart';
import 'package:funedu/english/english_level.dart';
import 'package:funedu/english/english_question.dart';

void main() {
  test('englishLevels defines 9 unique levels', () {
    expect(englishLevels.length, 9);
    expect(englishLevels.map((l) => l.id).toSet().length, 9);
    expect(englishLevels.map((l) => l.kind).toSet().length, 9);
  });

  for (final level in englishLevels) {
    test('generates 5 valid unique questions for ${level.id}', () {
      final qs = generateEnglishQuestions(level, Random(42), count: 5);
      expect(qs.length, 5);
      expect(qs.map((q) => q.id).toSet().length, 5);
      for (final q in qs) {
        expect(q.choices.length, 3);
        expect(q.choices.toSet().length, 3);
        expect(q.correctIndex, inInclusiveRange(0, 2));
        expect(q.englishSpeech.trim(), isNotEmpty);
        expect(q.vietnameseMeaning.trim(), isNotEmpty);
        if (q.displayKind == EnglishDisplayKind.countPick) {
          expect(q.countValue, inInclusiveRange(1, 10));
        }
        if (q.displayKind == EnglishDisplayKind.colorPick) {
          expect(q.swatchColor, isNotNull);
        }
        if (q.displayKind == EnglishDisplayKind.phonicsBuild) {
          expect(q.phonicsTail, isNotEmpty);
        }
        if (q.displayKind == EnglishDisplayKind.phraseFill) {
          expect(q.phraseBefore, isNotNull);
        }
      }
    });
  }
}
