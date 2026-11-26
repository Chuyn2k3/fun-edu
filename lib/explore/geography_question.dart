import 'geography_level.dart';

/// How a geography question is asked; the kid always answers with a picture.
enum GeoQuestionKind {
  /// "Đâu là Hồ Gươm?" then three pictures.
  pickImage,

  /// Chíp reads a riddle, then three pictures.
  listenClue,

  /// Chíp shows one picture and asks which goes with it.
  pairPick,
}

/// One generated question with three distinct picture choices.
class GeographyQuestion {
  const GeographyQuestion({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.speech,
    required this.choices,
    required this.correctIndex,
    this.focus,
    this.fact,
  })  : assert(choices.length == 3),
        assert(correctIndex >= 0 && correctIndex < 3);

  final String id;
  final GeoQuestionKind kind;

  /// Text shown in Chíp's speech bubble.
  final String prompt;

  /// Text read aloud in `vi-VN`.
  final String speech;

  final List<GeoItem> choices;
  final int correctIndex;

  /// The picture asked about ([GeoQuestionKind.pairPick] only).
  final GeoItem? focus;

  /// The pair's fact ([GeoQuestionKind.pairPick] only).
  final String? fact;

  GeoItem get answer => choices[correctIndex];

  /// What Chíp reads after the right answer.
  String get praise => kind == GeoQuestionKind.pairPick
      ? '${answer.speech}! $fact'
      : '${answer.speech}. ${answer.fact}';
}
