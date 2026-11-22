import '../../math/math_question.dart';

enum RaceSubject { toan, tiengViet }

/// One multiple-choice question of a rocket race: always exactly 3 distinct
/// choices. Questions at 0-based indexes 2, 5 and 8 are comets (worth +2).
sealed class RaceQuestion {
  const RaceQuestion({this.comet = false});

  /// What Chíp reads aloud when the question appears.
  String get spoken;
  int get correctIndex;
  final bool comet;

  /// A copy flagged (or not) as a comet question.
  RaceQuestion withComet(bool comet);
}

class MathRaceQuestion extends RaceQuestion {
  MathRaceQuestion(this.question, this.choices, {super.comet}) {
    assert(question is! CompareQuestion, 'compare has no int answer');
    assert(choices.length == 3 && choices.toSet().length == 3);
    assert(choices.contains(answer));
  }

  final MathQuestion question;
  final List<int> choices;

  int get answer => switch (question) {
        CountQuestion q => q.answer,
        MatchQuestion q => q.answer,
        ArithmeticQuestion q => q.answer,
        CompareQuestion() => throw StateError('compare has no int answer'),
        // Advanced levels race with arithmetic (question_source.dart).
        TensOnesQuestion() || ClockQuestion() || MoneyQuestion() =>
          throw StateError('not a race question'),
      };

  @override
  String get spoken => question.prompt;
  @override
  int get correctIndex => choices.indexOf(answer);
  @override
  RaceQuestion withComet(bool comet) =>
      MathRaceQuestion(question, choices, comet: comet);
}

class LetterRaceQuestion extends RaceQuestion {
  LetterRaceQuestion(
    this.targetGlyphId,
    this.choiceGlyphIds, {
    this.speech = '',
    super.comet,
  }) : assert(choiceGlyphIds.length == 3 &&
            choiceGlyphIds.toSet().length == 3 &&
            choiceGlyphIds.contains(targetGlyphId));

  final String targetGlyphId;
  final List<String> choiceGlyphIds;

  /// The target glyph's `speech` string ("chữ bờ", ...).
  final String speech;

  @override
  String get spoken => speech;
  @override
  int get correctIndex => choiceGlyphIds.indexOf(targetGlyphId);
  @override
  RaceQuestion withComet(bool comet) =>
      LetterRaceQuestion(targetGlyphId, choiceGlyphIds,
          speech: speech, comet: comet);
}

/// Tone-mark labels, used as spoken text ("dấu sắc").
const Map<String, String> toneLabels = {
  'dau-huyen': 'dấu huyền',
  'dau-sac': 'dấu sắc',
  'dau-nang': 'dấu nặng',
  'dau-hoi': 'dấu hỏi',
  'dau-nga': 'dấu ngã',
};

class ToneRaceQuestion extends RaceQuestion {
  ToneRaceQuestion(this.targetMarkId, this.choiceMarkIds, {super.comet})
      : assert(choiceMarkIds.length == 3 &&
            choiceMarkIds.toSet().length == 3 &&
            choiceMarkIds.contains(targetMarkId));

  final String targetMarkId;
  final List<String> choiceMarkIds;

  @override
  String get spoken => toneLabels[targetMarkId] ?? targetMarkId;
  @override
  int get correctIndex => choiceMarkIds.indexOf(targetMarkId);
  @override
  RaceQuestion withComet(bool comet) =>
      ToneRaceQuestion(targetMarkId, choiceMarkIds, comet: comet);
}
