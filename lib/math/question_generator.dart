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
