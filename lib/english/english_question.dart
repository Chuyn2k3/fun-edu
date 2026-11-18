import 'package:flutter/material.dart';

/// Visual layout style of an English question card.
enum EnglishDisplayKind {
  /// Big English speaker button + Vietnamese meaning cue; child picks English item.
  listenPick,

  /// Displays a numeral + dot grid alongside audio; child picks the English number word.
  countPick,

  /// Displays a bold round color swatch alongside audio; child picks the English color word.
  colorPick,

  /// Phonics word with missing initial letter (`[ ? ] + [ pple ]`) + Vietnamese meaning.
  phonicsBuild,

  /// Short English phrase with one missing word (`Good ___!`) + Vietnamese meaning.
  phraseFill,
}

/// One generated English question with 3 distinct answer choices.
class EnglishQuestion {
  const EnglishQuestion({
    required this.id,
    required this.displayKind,
    required this.prompt,
    required this.englishSpeech,
    required this.vietnameseMeaning,
    required this.choices,
    required this.correctIndex,
    this.countValue,
    this.swatchColor,
    this.phonicsTail,
    this.phraseBefore,
    this.phraseAfter,
  })  : assert(choices.length == 3),
        assert(correctIndex >= 0 && correctIndex < 3);

  final String id;
  final EnglishDisplayKind displayKind;

  /// Short Vietnamese instruction shown in Chíp's speech bubble.
  final String prompt;

  /// English text spoken aloud in `'en-US'`.
  final String englishSpeech;

  /// Vietnamese meaning shown as cue/reinforcement (e.g. `'con mèo'`, `'màu đỏ'`).
  final String vietnameseMeaning;

  /// Always 3 distinct answer choices.
  final List<String> choices;
  final int correctIndex;

  /// For [EnglishDisplayKind.countPick]: 1..10.
  final int? countValue;

  /// For [EnglishDisplayKind.colorPick]: visual swatch color from `EnglishSwatchColors`.
  final Color? swatchColor;

  /// For [EnglishDisplayKind.phonicsBuild]: remaining letters after the missing initial.
  final String? phonicsTail;

  /// For [EnglishDisplayKind.phraseFill]: text before and after the blank.
  final String? phraseBefore;
  final String? phraseAfter;

  String get correctChoice => choices[correctIndex];
}
