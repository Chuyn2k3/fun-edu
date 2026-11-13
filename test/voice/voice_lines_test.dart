import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/voice/voice_lines.dart';

void main() {
  test('numberToVietnamese', () {
    const expected = {
      0: 'không',
      1: 'một',
      4: 'bốn',
      5: 'năm',
      10: 'mười',
      11: 'mười một',
      14: 'mười bốn',
      15: 'mười lăm',
      20: 'hai mươi',
    };
    expected.forEach((n, w) => expect(numberToVietnamese(n), w));
  });

  test('spokenQuestion', () {
    expect(spokenQuestion(const ArithmeticQuestion(3, 2, true, [5])),
        'ba cộng hai bằng mấy?');
    expect(spokenQuestion(const ArithmeticQuestion(5, 1, false, [4])),
        'năm trừ một bằng mấy?');
    expect(
        spokenQuestion(const CountQuestion(3, [3])), 'Có bao nhiêu ngôi sao?');
    expect(spokenQuestion(const CompareQuestion(1, 2, CompareAsk.less)),
        'Bên nào ít hơn?');
    expect(
        spokenQuestion(const MatchQuestion(3, [3])), 'Kéo số đúng vào ô nhé!');
  });
}
