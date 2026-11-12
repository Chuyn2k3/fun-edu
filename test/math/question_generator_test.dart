import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/math/question_generator.dart';

/// What the child sees, ignoring choices and their order.
List<Object> _content(MathQuestion q) => switch (q) {
      CountQuestion() => ['count', q.n],
      MatchQuestion() => ['match', q.n],
      CompareQuestion() => ['compare', q.left, q.right, q.ask],
      ArithmeticQuestion() => ['arith', q.a, q.b, q.plus],
    };

void main() {
  test('mathLevels matches the ladder table', () {
    const expected = [
      ('dem-5', 'Đếm đến 5', MathKind.count, 5),
      ('dem-10', 'Đếm đến 10', MathKind.count, 10),
      ('so-sanh-10', 'So sánh', MathKind.compare, 10),
      ('ghep-so-10', 'Ghép số', MathKind.match, 10),
      ('cong-5', 'Cộng trong 5', MathKind.add, 5),
      ('tru-5', 'Trừ trong 5', MathKind.subtract, 5),
      ('cong-10', 'Cộng trong 10', MathKind.add, 10),
      ('tru-10', 'Trừ trong 10', MathKind.subtract, 10),
      ('cong-tru-20', 'Cộng trừ trong 20', MathKind.addSubtract, 20),
    ];
    expect(mathLevels.length, 9);
    for (var i = 0; i < 9; i++) {
      final l = mathLevels[i];
      expect((l.id, l.title, l.kind, l.max), expected[i]);
    }
  });

  void checkChoices(List<int> choices, int answer, int max,
      {bool noZero = false}) {
    expect(choices.length, 3);
    expect(choices.toSet().length, 3);
    expect(choices, contains(answer));
    for (final c in choices) {
      expect(c, inInclusiveRange(noZero ? 1 : 0, max));
    }
  }

  for (final level in mathLevels) {
    group(level.id, () {
      test('questions are valid for seeds 0..199', () {
        for (var seed = 0; seed < 200; seed++) {
          final qs = generateQuestions(level, Random(seed), count: 5);
          expect(qs.length, 5);
          for (var i = 0; i < qs.length; i++) {
            final q = qs[i];
            if (i > 0) expect(q, isNot(equals(qs[i - 1])));
            switch (q) {
              case CountQuestion():
                expect(q.kind, MathKind.count);
                expect(q.prompt, 'Có bao nhiêu ngôi sao?');
                expect(q.n, inInclusiveRange(1, level.max));
                checkChoices(q.choices, q.n, level.max, noZero: true);
              case MatchQuestion():
                expect(q.kind, MathKind.match);
                expect(q.prompt, 'Kéo số đúng vào ô nhé!');
                expect(q.n, inInclusiveRange(1, level.max));
                checkChoices(q.choices, q.n, level.max, noZero: true);
              case CompareQuestion():
                expect(q.kind, MathKind.compare);
                expect(q.left, isNot(q.right));
                expect(q.left, inInclusiveRange(1, level.max));
                expect(q.right, inInclusiveRange(1, level.max));
                expect(
                    q.prompt,
                    q.ask == CompareAsk.more
                        ? 'Bên nào nhiều hơn?'
                        : 'Bên nào ít hơn?');
                final leftWins = q.ask == CompareAsk.more
                    ? q.left > q.right
                    : q.left < q.right;
                expect(q.answer, leftWins ? Side.left : Side.right);
              case ArithmeticQuestion():
                expect(q.kind, q.plus ? MathKind.add : MathKind.subtract);
                if (level.kind == MathKind.add) expect(q.plus, isTrue);
                if (level.kind == MathKind.subtract) expect(q.plus, isFalse);
                if (q.plus) {
                  expect(q.a, greaterThanOrEqualTo(1));
                  expect(q.b, greaterThanOrEqualTo(1));
                  expect(q.a + q.b, lessThanOrEqualTo(level.max));
                  expect(q.answer, q.a + q.b);
                  expect(q.prompt, '${q.a} + ${q.b} = ?');
                } else {
                  expect(q.a, lessThanOrEqualTo(level.max));
                  expect(q.b, inInclusiveRange(1, q.a));
                  expect(q.answer, q.a - q.b);
                  expect(q.prompt, '${q.a} − ${q.b} = ?');
                }
                checkChoices(q.choices, q.answer, level.max);
            }
          }
        }
      });

      test('adjacent questions never share visible content (seeds 0..199)',
          () {
        for (var seed = 0; seed < 200; seed++) {
          final qs = generateQuestions(level, Random(seed), count: 5);
          for (var i = 1; i < qs.length; i++) {
            expect(_content(qs[i]), isNot(_content(qs[i - 1])),
                reason: 'seed $seed, index $i');
          }
        }
      });

      test('same seed gives same questions', () {
        expect(generateQuestions(level, Random(7)),
            generateQuestions(level, Random(7)));
      });

      test('handles count 20 without adjacent duplicates', () {
        final qs = generateQuestions(level, Random(3), count: 20);
        expect(qs.length, 20);
        for (var i = 1; i < qs.length; i++) {
          expect(qs[i], isNot(equals(qs[i - 1])));
        }
      });
    });
  }

  test('answer 0 stays possible when b == a', () {
    final qs = [
      for (var seed = 0; seed < 50; seed++)
        ...generateQuestions(mathLevels[5], Random(seed)),
    ].cast<ArithmeticQuestion>();
    expect(qs.any((q) => q.answer == 0), isTrue);
  });

  test('addSubtract mixes plus and minus', () {
    final qs = generateQuestions(mathLevels.last, Random(1), count: 20)
        .cast<ArithmeticQuestion>();
    expect(qs.any((q) => q.plus), isTrue);
    expect(qs.any((q) => !q.plus), isTrue);
  });
}
