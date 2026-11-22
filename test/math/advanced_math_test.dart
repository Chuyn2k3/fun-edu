import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/math/question_generator.dart';

MathLevel _level(String id) => mathLevels.firstWhere((l) => l.id == id);

List<MathQuestion> _many(String id) => [
      for (var seed = 0; seed < 40; seed++)
        ...generateQuestions(_level(id), Random(seed), count: 5),
    ];

void main() {
  test('three advanced levels follow the 9 basic ones', () {
    expect(mathLevels, hasLength(12));
    expect(mathLevels.skip(9).map((l) => l.id), ['so-100', 'dong-ho', 'tien']);
    expect(mathLevels.skip(9).map((l) => l.title),
        ['Số đến 100', 'Xem đồng hồ', 'Tiền Việt Nam']);
  });

  test('số đến 100: tens and ones make the answer, choices are distinct', () {
    for (final q in _many('so-100').cast<TensOnesQuestion>()) {
      expect(q.answer, q.tens * 10 + q.ones);
      expect(q.answer, inInclusiveRange(10, 99));
      expect(q.tens, inInclusiveRange(1, 9));
      expect(q.choices.toSet(), hasLength(3));
      expect(q.choices, contains(q.answer));
      expect(q.choices.every((c) => c >= 10 && c <= 99), isTrue);
      expect(q.prompt, 'Có bao nhiêu que tính?');
    }
  });

  test('xem đồng hồ: on the hour and half past, readable labels', () {
    final qs = _many('dong-ho').cast<ClockQuestion>();
    expect(qs.any((q) => q.half), isTrue);
    expect(qs.any((q) => !q.half), isTrue);
    for (final q in qs) {
      expect(q.hour, inInclusiveRange(1, 12));
      expect(q.choices.toSet(), hasLength(3));
      expect(q.choices, contains(q.answer));
      expect(clockLabel(q.answer), q.half ? '${q.hour} giờ rưỡi' : '${q.hour} giờ');
    }
    expect(clockLabel(ClockQuestion.code(3, false)), '3 giờ');
    expect(clockLabel(ClockQuestion.code(12, true)), '12 giờ rưỡi');
  });

  test('tiền: 1-3 real note values, the total within 20 nghìn', () {
    for (final q in _many('tien').cast<MoneyQuestion>()) {
      expect(q.notes.length, inInclusiveRange(1, 3));
      expect(q.notes.every(vndNotes.contains), isTrue);
      expect(q.answer, q.notes.reduce((a, b) => a + b));
      expect(q.answer, lessThanOrEqualTo(20));
      expect(q.choices.toSet(), hasLength(3));
      expect(q.choices, contains(q.answer));
      expect(q.choices.every((c) => c >= 1), isTrue);
      expect(q.prompt, 'Có tất cả bao nhiêu nghìn đồng?');
    }
    expect(vndNotes, [1, 2, 5, 10]);
  });

  test('no two questions in a row look the same', () {
    for (final id in ['so-100', 'dong-ho', 'tien']) {
      for (var seed = 0; seed < 30; seed++) {
        final qs = generateQuestions(_level(id), Random(seed), count: 5);
        for (var i = 1; i < qs.length; i++) {
          expect(qs[i].prompt + qs[i].toString() == qs[i - 1].prompt + qs[i - 1].toString() &&
                  qs[i] == qs[i - 1],
              isFalse);
        }
      }
    }
  });
}
