import '../math/math_question.dart';

const _words = [
  'không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín', //
  'mười',
];

/// Vietnamese words for 0–20.
String numberToVietnamese(int n) {
  if (n < 0 || n > 20) throw RangeError.range(n, 0, 20, 'n');
  if (n <= 10) return _words[n];
  if (n == 20) return 'hai mươi';
  final unit = n == 15 ? 'lăm' : _words[n - 10];
  return 'mười $unit';
}

/// The text read aloud for [q].
String spokenQuestion(MathQuestion q) => switch (q) {
      ArithmeticQuestion() =>
        '${numberToVietnamese(q.a)} ${q.plus ? 'cộng' : 'trừ'} '
            '${numberToVietnamese(q.b)} bằng mấy?',
      _ => q.prompt,
    };
