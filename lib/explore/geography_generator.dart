import 'dart:math';

import 'geography_level.dart';
import 'geography_question.dart';

/// [count] questions for [level]: distinct answers while the level has
/// enough items, each with two other items of the level as wrong choices.
/// Clue levels ask about half of them as riddles.
List<GeographyQuestion> generateGeographyQuestions(
  GeographyLevel level,
  Random random, {
  int count = 5,
}) {
  if (level.pairs.isNotEmpty) return _pairQuestions(level, random, count);
  final items = level.items;
  final answers = <GeoItem>[];
  while (answers.length < count) {
    answers.addAll([...items]..shuffle(random));
  }
  answers.length = count;

  final clueSlots = <int>{};
  if (level.clues) {
    final clueCount = count ~/ 2 + random.nextInt(2);
    clueSlots.addAll((List.generate(count, (i) => i)..shuffle(random))
        .take(clueCount));
  }

  return [
    for (var i = 0; i < count; i++)
      _question(level, answers[i], i, clueSlots.contains(i), random),
  ];
}

GeographyQuestion _question(
  GeographyLevel level,
  GeoItem answer,
  int index,
  bool clue,
  Random random,
) {
  final others = level.items.where((it) => it.id != answer.id).toList()
    ..shuffle(random);
  final choices = [answer, ...others.take(2)]..shuffle(random);
  return GeographyQuestion(
    id: '${level.id}-$index-${answer.id}',
    kind: clue ? GeoQuestionKind.listenClue : GeoQuestionKind.pickImage,
    prompt: clue ? answer.clue : 'Đâu là ${answer.name}?',
    speech: clue ? answer.clue : 'Đâu là ${answer.speech}?',
    choices: choices,
    correctIndex: choices.indexOf(answer),
  );
}

List<GeographyQuestion> _pairQuestions(
  GeographyLevel level,
  Random random,
  int count,
) {
  final asked = <PairItem>[];
  while (asked.length < count) {
    asked.addAll([...level.pairs]..shuffle(random));
  }
  asked.length = count;
  return [
    for (var i = 0; i < count; i++) _pairQuestion(level, asked[i], i, random),
  ];
}

GeographyQuestion _pairQuestion(
  GeographyLevel level,
  PairItem pair,
  int index,
  Random random,
) {
  final wrong = [
    for (final p in level.pairs)
      if (p.answer.id != pair.answer.id && !pair.alsoRight.contains(p.answer.id))
        p.answer,
  ]..shuffle(random);
  final choices = [pair.answer, ...wrong.take(2)]..shuffle(random);
  return GeographyQuestion(
    id: '${level.id}-$index-${pair.id}',
    kind: GeoQuestionKind.pairPick,
    prompt: pair.question,
    speech: pair.questionSpeech ?? pair.question,
    choices: choices,
    correctIndex: choices.indexOf(pair.answer),
    focus: pair.ask,
    fact: pair.fact,
  );
}
