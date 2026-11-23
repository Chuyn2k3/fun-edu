import 'dart:math';

import '../../learning/writing_ladder.dart';
import '../../math/math_level.dart';
import '../../math/math_question.dart';
import '../../math/question_generator.dart';
import '../../progress/progress_repository.dart';
import 'race_question.dart';

const int raceQuestionCount = 10;
const List<int> cometIndexes = [2, 5, 8, 11, 14, 17];

const List<String> firstLetterGroup = [
  'chu-i', 'chu-t', 'chu-u', 'chu-uw', 'chu-n', 'chu-m', 'chu-v', 'chu-r',
  'chu-s', //
];

const List<List<String>> confusableGroups = [
  ['chu-b', 'chu-d', 'chu-h', 'chu-l', 'chu-k'],
  ['chu-n', 'chu-m', 'chu-u', 'chu-uw', 'chu-v', 'chu-r'],
  [
    'chu-o', 'chu-oo', 'chu-ow', 'chu-a', 'chu-aw', 'chu-aa', 'chu-c',
    'chu-e', 'chu-ee', //
  ],
  ['chu-g', 'chu-y', 'chu-p', 'chu-q', 'chu-d'],
  ['chu-t', 'chu-i', 'chu-dd', 'chu-s', 'chu-x'],
];

const List<String> toneIds = [
  'dau-huyen', 'dau-sac', 'dau-nang', 'dau-hoi', 'dau-nga', //
];

/// Fraction of Tiếng Việt questions that are tone questions once unlocked.
const int toneQuestionCount = 3; // 30 % of 10

List<RaceQuestion> buildRaceQuestions({
  required RaceSubject subject,
  required int mathLevelIndex,
  required Map<String, GlyphStat> glyphStats,
  required int writingStartIndex,
  required Map<String, String> speechByGlyph,
  required Random rng,
  int count = raceQuestionCount,
}) {
  final List<RaceQuestion> qs = switch (subject) {
    RaceSubject.toan => _mathQuestions(mathLevelIndex, rng, count),
    RaceSubject.tiengViet =>
      _vietQuestions(glyphStats, writingStartIndex, speechByGlyph, rng, count),
  };
  return [
    for (var i = 0; i < qs.length; i++)
      qs[i].withComet(cometIndexes.contains(i)),
  ];
}

// ---------------------------------------------------------------- Toán

List<RaceQuestion> _mathQuestions(int levelIndex, Random rng, int count) {
  var level = mathLevels[levelIndex.clamp(0, mathLevels.length - 1)];
  // Compare questions have no number answer, so that level (which is all
  // compare) borrows the counting level up to 10 instead.
  if (level.kind == MathKind.compare) {
    level = mathLevels.firstWhere(
        (l) => l.kind == MathKind.count && l.max >= level.max,
        orElse: () => mathLevels.first);
  }
  // Sticks, clocks and banknotes need their own pictures: the race cockpit
  // only shows sums and stars, so the advanced levels race with the hardest
  // arithmetic level.
  if (const {MathKind.tensOnes, MathKind.clock, MathKind.money}.contains(level.kind)) {
    level = mathLevels.lastWhere((l) => l.kind == MathKind.addSubtract);
  }
  final out = <RaceQuestion>[];
  while (out.length < count) {
    for (final q in generateQuestions(level, rng, count: count)) {
      if (out.length >= count) break;
      final r = _toMathRace(q, level.max, rng);
      if (r != null) out.add(r);
    }
  }
  return out;
}

MathRaceQuestion? _toMathRace(MathQuestion q, int max, Random rng) {
  final (int answer, List<int> given) = switch (q) {
    CountQuestion c => (c.answer, c.choices),
    MatchQuestion m => (m.answer, m.choices),
    ArithmeticQuestion a => (a.answer, a.choices),
    CompareQuestion() ||
    TensOnesQuestion() ||
    ClockQuestion() ||
    MoneyQuestion() =>
      (-1, const <int>[]),
  };
  if (answer < 0) return null;
  if (given.length == 3 &&
      given.toSet().length == 3 &&
      given.contains(answer)) {
    return MathRaceQuestion(q, List.of(given));
  }
  // Build 3 distinct ints (>= 0) near the answer.
  final near = <int>[
    for (var d = -3; d <= 3; d++)
      if (d != 0 && answer + d >= 0) answer + d,
  ]..shuffle(rng);
  return MathRaceQuestion(q, [answer, near[0], near[1]]..shuffle(rng));
}

// --------------------------------------------------------- Tiếng Việt

int _progressIndex(Map<String, GlyphStat> stats, int writingStartIndex) {
  var h = writingStartIndex - 1;
  for (var i = 0; i < writingLadder.length; i++) {
    if ((stats[writingLadder[i]]?.completions ?? 0) > 0 && i > h) h = i;
  }
  return h;
}

List<RaceQuestion> _vietQuestions(
  Map<String, GlyphStat> stats,
  int writingStartIndex,
  Map<String, String> speech,
  Random rng,
  int count,
) {
  final h = _progressIndex(stats, writingStartIndex);
  final upTo = (h + 3).clamp(-1, writingLadder.length - 1);
  var pool = <String>[
    for (var i = 0; i <= upTo; i++)
      if (writingLadder[i].startsWith('chu-')) writingLadder[i],
  ];
  if (pool.length < 3) pool = List.of(firstLetterGroup);

  final toneUnlocked = h >= writingLadder.indexOf('dau-huyen');
  final toneAt = <int>{};
  if (toneUnlocked) {
    final toneCount =
        (count * toneQuestionCount / raceQuestionCount).round().clamp(0, count);
    final idx = List.generate(count, (i) => i)..shuffle(rng);
    toneAt.addAll(idx.take(toneCount));
  }

  final out = <RaceQuestion>[];
  String? lastLetter;
  String? lastTone;
  for (var i = 0; i < count; i++) {
    if (toneAt.contains(i)) {
      final candidates = toneIds.where((t) => t != lastTone).toList();
      final target = candidates[rng.nextInt(candidates.length)];
      lastTone = target;
      final others = toneIds.where((t) => t != target).toList()..shuffle(rng);
      out.add(ToneRaceQuestion(
          target, [target, others[0], others[1]]..shuffle(rng)));
    } else {
      final candidates = pool.where((g) => g != lastLetter).toList();
      final target = candidates[rng.nextInt(candidates.length)];
      lastLetter = target;
      out.add(LetterRaceQuestion(
        target,
        _letterChoices(target, pool, rng),
        speech: speech[target] ?? '',
      ));
    }
  }
  return out;
}

List<String> _letterChoices(String target, List<String> pool, Random rng) {
  final similar = <String>{
    for (final g in confusableGroups)
      if (g.contains(target)) ...g,
  }..remove(target);
  final preferred = pool.where(similar.contains).toList()..shuffle(rng);
  final rest = pool.where((g) => g != target && !similar.contains(g)).toList()
    ..shuffle(rng);
  final distractors = [...preferred, ...rest].take(2).toList();
  return [target, ...distractors]..shuffle(rng);
}
