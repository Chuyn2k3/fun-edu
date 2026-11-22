import 'dart:math';

import 'math_level.dart';
import 'math_question.dart';

/// Generates [count] questions for [level]; deterministic for a given [rng]
/// state. No two adjacent questions show the same content (choices and their
/// order are not part of what the child sees as "the question").
List<MathQuestion> generateQuestions(
  MathLevel level,
  Random rng, {
  int count = 5,
}) {
  final result = <MathQuestion>[];
  while (result.length < count) {
    final q = _generateOne(level, rng);
    if (result.isNotEmpty && _sameContent(result.last, q)) continue;
    result.add(q);
  }
  return result;
}

/// True when the child would see the same question: count/match by `n`,
/// compare by sides and ask, arithmetic by operands and operator.
bool _sameContent(MathQuestion x, MathQuestion y) => switch ((x, y)) {
      (CountQuestion a, CountQuestion b) => a.n == b.n,
      (MatchQuestion a, MatchQuestion b) => a.n == b.n,
      (CompareQuestion a, CompareQuestion b) =>
        a.left == b.left && a.right == b.right && a.ask == b.ask,
      (ArithmeticQuestion a, ArithmeticQuestion b) =>
        a.a == b.a && a.b == b.b && a.plus == b.plus,
      (TensOnesQuestion a, TensOnesQuestion b) => a.answer == b.answer,
      (ClockQuestion a, ClockQuestion b) => a.answer == b.answer,
      (MoneyQuestion a, MoneyQuestion b) => _same(a.notes, b.notes),
      _ => false,
    };

MathQuestion _generateOne(MathLevel level, Random rng) {
  final max = level.max;
  switch (level.kind) {
    case MathKind.count:
      final n = 1 + rng.nextInt(max);
      return CountQuestion(n, _choices(n, max, rng, minValue: 1));
    case MathKind.match:
      final n = 1 + rng.nextInt(max);
      return MatchQuestion(n, _choices(n, max, rng, minValue: 1));
    case MathKind.compare:
      final left = 1 + rng.nextInt(max);
      var right = 1 + rng.nextInt(max - 1);
      if (right >= left) right++; // skip `left` so the sides differ
      final ask = rng.nextBool() ? CompareAsk.more : CompareAsk.less;
      return CompareQuestion(left, right, ask);
    case MathKind.add:
      return _arithmetic(max, true, rng);
    case MathKind.subtract:
      return _arithmetic(max, false, rng);
    case MathKind.addSubtract:
      return _arithmetic(max, rng.nextBool(), rng);
    case MathKind.tensOnes:
      return _tensOnes(rng);
    case MathKind.clock:
      return _clock(rng);
    case MathKind.money:
      return _money(max, rng);
  }
}

bool _same(List<int> a, List<int> b) =>
    a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

/// Three distinct values: [answer] and two picked from [candidates].
List<int> _pick(int answer, Iterable<int> candidates, Random rng) {
  final pool = candidates.where((c) => c != answer).toSet().toList()..shuffle(rng);
  return [answer, pool[0], pool[1]]..shuffle(rng);
}

TensOnesQuestion _tensOnes(Random rng) {
  final tens = 1 + rng.nextInt(9);
  final ones = rng.nextInt(10);
  final n = tens * 10 + ones;
  // Typical slips: swapped digits, one bundle more/less, one stick more/less.
  final swapped = ones * 10 + tens;
  final cands = <int>[
    if (ones > 0 && swapped != n && swapped >= 10) swapped,
    n + 10, n - 10, n + 1, n - 1,
  ].where((c) => c >= 10 && c <= 99);
  return TensOnesQuestion(tens, ones, _pick(n, cands, rng));
}

ClockQuestion _clock(Random rng) {
  final hour = 1 + rng.nextInt(12);
  final half = rng.nextBool();
  int wrap(int h) => (h - 1) % 12 + 1;
  final cands = [
    ClockQuestion.code(hour, !half),
    ClockQuestion.code(wrap(hour + 1), half),
    ClockQuestion.code(wrap(hour + 11), half),
    // Reading the hands the other way round.
    if (!half) ClockQuestion.code(wrap(hour + 6), half),
  ];
  return ClockQuestion(hour, half, _pick(ClockQuestion.code(hour, half), cands, rng));
}

MoneyQuestion _money(int max, Random rng) {
  while (true) {
    final count = 1 + rng.nextInt(3);
    final notes = [for (var i = 0; i < count; i++) vndNotes[rng.nextInt(vndNotes.length)]]
      ..sort((a, b) => b - a);
    final total = notes.fold(0, (a, b) => a + b);
    if (total > max) continue;
    // Slips: counting notes instead of values, off by one or two.
    final cands = [count, total + 1, total - 1, total + 2, total - 2, total + 5]
        .where((c) => c >= 1 && c <= max + 5);
    return MoneyQuestion(notes, _pick(total, cands, rng));
  }
}

ArithmeticQuestion _arithmetic(int max, bool plus, Random rng) {
  final int a;
  final int b;
  if (plus) {
    a = 1 + rng.nextInt(max - 1); // 1..max-1 leaves room for b >= 1
    b = 1 + rng.nextInt(max - a);
  } else {
    a = 1 + rng.nextInt(max);
    b = 1 + rng.nextInt(a); // 1..a: never subtract 0, but a - a = 0 is fine
  }
  final answer = plus ? a + b : a - b;
  return ArithmeticQuestion(a, b, plus, _choices(answer, max, rng));
}

/// Three distinct values in [minValue]..[max]: the answer plus two
/// distractors within +-3 of it, shuffled.
List<int> _choices(int answer, int max, Random rng, {int minValue = 0}) {
  final near = <int>[
    for (var d = -3; d <= 3; d++)
      if (d != 0 && answer + d >= minValue && answer + d <= max) answer + d,
  ]..shuffle(rng);
  return [answer, near[0], near[1]]..shuffle(rng);
}
