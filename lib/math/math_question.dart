import 'math_level.dart';

enum CompareAsk { more, less }

enum Side { left, right }

bool _sameList(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A generated math question. Value equality lets the generator avoid
/// back-to-back duplicates.
sealed class MathQuestion {
  const MathQuestion();
  MathKind get kind;
  String get prompt;
}

class CountQuestion extends MathQuestion {
  const CountQuestion(this.n, this.choices);
  final int n;
  final List<int> choices;

  int get answer => n;

  @override
  MathKind get kind => MathKind.count;
  @override
  String get prompt => 'Có bao nhiêu ngôi sao?';

  @override
  bool operator ==(Object other) =>
      other is CountQuestion &&
      other.n == n &&
      _sameList(other.choices, choices);
  @override
  int get hashCode => Object.hash('count', n, Object.hashAll(choices));
}

class CompareQuestion extends MathQuestion {
  const CompareQuestion(this.left, this.right, this.ask);
  final int left;
  final int right;
  final CompareAsk ask;

  /// Unlike the other questions, the answer is a [Side], not an int.
  Side get answer {
    final leftWins = ask == CompareAsk.more ? left > right : left < right;
    return leftWins ? Side.left : Side.right;
  }

  @override
  MathKind get kind => MathKind.compare;
  @override
  String get prompt =>
      ask == CompareAsk.more ? 'Bên nào nhiều hơn?' : 'Bên nào ít hơn?';

  @override
  bool operator ==(Object other) =>
      other is CompareQuestion &&
      other.left == left &&
      other.right == right &&
      other.ask == ask;
  @override
  int get hashCode => Object.hash('compare', left, right, ask);
}

class MatchQuestion extends MathQuestion {
  const MatchQuestion(this.n, this.choices);
  final int n;
  final List<int> choices;

  int get answer => n;

  @override
  MathKind get kind => MathKind.match;
  @override
  String get prompt => 'Kéo số đúng vào ô nhé!';

  @override
  bool operator ==(Object other) =>
      other is MatchQuestion &&
      other.n == n &&
      _sameList(other.choices, choices);
  @override
  int get hashCode => Object.hash('match', n, Object.hashAll(choices));
}

class ArithmeticQuestion extends MathQuestion {
  const ArithmeticQuestion(this.a, this.b, this.plus, this.choices);
  final int a;
  final int b;
  final bool plus;
  final List<int> choices;

  int get answer => plus ? a + b : a - b;

  @override
  MathKind get kind => plus ? MathKind.add : MathKind.subtract;
  @override
  String get prompt => plus ? '$a + $b = ?' : '$a − $b = ?';

  @override
  bool operator ==(Object other) =>
      other is ArithmeticQuestion &&
      other.a == a &&
      other.b == b &&
      other.plus == plus &&
      _sameList(other.choices, choices);
  @override
  int get hashCode => Object.hash('arith', a, b, plus, Object.hashAll(choices));
}
