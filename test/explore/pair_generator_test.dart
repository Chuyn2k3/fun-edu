import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/explore/geography_generator.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/explore/geography_question.dart';

GeoItem _p(String id, String name) =>
    GeoItem(id: id, name: name, speech: name, fact: '', clue: '', prefix: 'bio');

final _pairs = [
  PairItem(
      id: 'tho',
      ask: _p('tho', 'Thỏ'),
      answer: _p('ca-rot', 'Cà rốt'),
      question: 'Thỏ thích ăn gì?',
      fact: 'Thỏ gặm cà rốt giòn tan.',
      alsoRight: const ['co']),
  PairItem(
      id: 'khi',
      ask: _p('khi', 'Khỉ'),
      answer: _p('chuoi', 'Chuối'),
      question: 'Khỉ thích ăn gì?',
      questionSpeech: 'Chú khỉ thích ăn gì?',
      fact: 'Khỉ bóc vỏ rồi mới ăn.'),
  PairItem(
      id: 'meo',
      ask: _p('meo', 'Mèo'),
      answer: _p('dia-ca', 'Đĩa cá'),
      question: 'Mèo thích ăn gì?',
      fact: 'Mèo thích cá nấu chín.'),
  PairItem(
      id: 'bo',
      ask: _p('bo', 'Bò'),
      answer: _p('co', 'Bó cỏ'),
      question: 'Bò thích ăn gì?',
      fact: 'Bò nhai cỏ cả ngày.',
      alsoRight: const ['ca-rot']),
  PairItem(
      id: 'ong',
      ask: _p('ong', 'Ong'),
      answer: _p('hoa', 'Hoa'),
      question: 'Ong thích gì?',
      fact: 'Ong hút mật từ hoa.'),
];

final _level = GeographyLevel(
    id: 'an-gi',
    title: 'Con gì ăn gì?',
    subtitle: '',
    items: const [],
    clues: false,
    pairs: _pairs);

void main() {
  test('pair levels ask five pair questions with three distinct answers', () {
    final qs = generateGeographyQuestions(_level, Random(3));
    expect(qs.length, 5);
    expect(qs.map((q) => q.answer.id).toSet().length, 5);
    for (final q in qs) {
      expect(q.kind, GeoQuestionKind.pairPick);
      expect(q.focus, isNotNull);
      expect(q.choices.map((c) => c.id).toSet().length, 3);
      final pair = _pairs.singleWhere((p) => p.ask.id == q.focus!.id);
      expect(q.answer.id, pair.answer.id);
      expect(q.prompt, pair.question);
      expect(q.speech, pair.questionSpeech ?? pair.question);
      expect(q.praise, '${pair.answer.speech}! ${pair.fact}');
    }
  });

  test('an answer that is also right is never offered as wrong', () {
    for (var seed = 0; seed < 50; seed++) {
      for (final q in generateGeographyQuestions(_level, Random(seed))) {
        final pair = _pairs.singleWhere((p) => p.ask.id == q.focus!.id);
        for (var i = 0; i < 3; i++) {
          if (i == q.correctIndex) continue;
          expect(pair.alsoRight, isNot(contains(q.choices[i].id)),
              reason: 'seed $seed ${pair.id}');
        }
      }
    }
  });

  test('picture questions praise with name and fact', () {
    final level = GeographyLevel(
        id: 't', title: '', subtitle: '', clues: false, items: [
      for (var i = 0; i < 5; i++)
        GeoItem(id: 'i$i', name: 'N$i', speech: 'S$i', fact: 'F$i', clue: 'C$i'),
    ]);
    final q = generateGeographyQuestions(level, Random(1)).first;
    expect(q.praise, '${q.answer.speech}. ${q.answer.fact}');
  });
}
