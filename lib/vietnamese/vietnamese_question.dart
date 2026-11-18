/// Visual layout style of a Vietnamese exercise card.
enum VietnameseDisplayKind {
  /// Big speaker button + prompt text; child picks the matching letter/word.
  listenPick,

  /// Syllable equation `[left] + [right] = [result]` with one side missing (`null`).
  equationBuild,

  /// Short phrase with one blank slot (`before ___ after`).
  phraseFill,
}

/// One generated Vietnamese question with 3 distinct answer choices.
class VietnameseQuestion {
  const VietnameseQuestion({
    required this.id,
    required this.displayKind,
    required this.prompt,
    required this.speech,
    required this.celebrationSpeech,
    required this.choices,
    required this.correctIndex,
    this.equationLeft,
    this.equationRight,
    this.equationResult,
    this.phraseBefore,
    this.phraseAfter,
    this.emojiHint,
  }) : assert(choices.length == 3),
       assert(correctIndex >= 0 && correctIndex < 3);

  final String id;
  final VietnameseDisplayKind displayKind;

  /// Short Vietnamese instruction shown on screen.
  final String prompt;

  /// Spoken aloud automatically via [Speaker] and when tapping the audio button.
  final String speech;

  /// Spoken praise + reading of the completed item when answered right.
  final String celebrationSpeech;

  /// Always 3 distinct Vietnamese answer labels.
  final List<String> choices;
  final int correctIndex;

  /// Equation fields for [VietnameseDisplayKind.equationBuild].
  /// Exactly one of [equationLeft] or [equationRight] is null (the blank).
  final String? equationLeft;
  final String? equationRight;
  final String? equationResult;

  /// Phrase fields for [VietnameseDisplayKind.phraseFill].
  final String? phraseBefore;
  final String? phraseAfter;

  /// Optional friendly visual cue (clean word badge/icon tag, no broken tofu).
  final String? emojiHint;

  String get correctChoice => choices[correctIndex];
}
