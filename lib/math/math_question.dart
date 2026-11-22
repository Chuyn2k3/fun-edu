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

/// Sticks to count: [tens] bundles of ten and [ones] single sticks.
class TensOnesQuestion extends MathQuestion {
  const TensOnesQuestion(this.tens, this.ones, this.choices);
  final int tens;
  final int ones;
  final List<int> choices;

  int get answer => tens * 10 + ones;

  @override
  MathKind get kind => MathKind.tensOnes;
  @override
  String get prompt => 'Có bao nhiêu que tính?';

  @override
  bool operator ==(Object other) =>
      other is TensOnesQuestion &&
      other.tens == tens &&
      other.ones == ones &&
      _sameList(other.choices, choices);
  @override
  int get hashCode => Object.hash('tens', tens, ones, Object.hashAll(choices));
}

/// An analogue clock at [hour] o'clock or half past. Choices are codes
/// (see [ClockQuestion.code]) shown with [clockLabel].
class ClockQuestion extends MathQuestion {
  const ClockQuestion(this.hour, this.half, this.choices);
  final int hour;
  final bool half;
  final List<int> choices;

  /// One int per time: hour * 2, + 1 for half past.
  static int code(int hour, bool half) => hour * 2 + (half ? 1 : 0);

  int get answer => code(hour, half);

  @override
  MathKind get kind => MathKind.clock;
  @override
  String get prompt => 'Đồng hồ chỉ mấy giờ?';

  @override
  bool operator ==(Object other) =>
      other is ClockQuestion &&
      other.hour == hour &&
      other.half == half &&
      _sameList(other.choices, choices);
  @override
  int get hashCode => Object.hash('clock', hour, half, Object.hashAll(choices));
}

/// "3 giờ" / "3 giờ rưỡi" for a [ClockQuestion.code].
String clockLabel(int code) => code.isOdd ? '${code ~/ 2} giờ rưỡi' : '${code ~/ 2} giờ';

/// Banknotes in nghìn đồng the money level uses (drawn flat in the app).
const List<int> vndNotes = [1, 2, 5, 10];

/// Some banknotes; how many nghìn đồng in all?
class MoneyQuestion extends MathQuestion {
  const MoneyQuestion(this.notes, this.choices);

  /// Note values in nghìn đồng, from [vndNotes].
  final List<int> notes;
  final List<int> choices;

  int get answer => notes.fold(0, (a, b) => a + b);

  @override
  MathKind get kind => MathKind.money;
  @override
  String get prompt => 'Có tất cả bao nhiêu nghìn đồng?';

  @override
  bool operator ==(Object other) =>
      other is MoneyQuestion &&
      _sameList(other.notes, notes) &&
      _sameList(other.choices, choices);
  @override
  int get hashCode => Object.hash('money', Object.hashAll(notes), Object.hashAll(choices));
}
