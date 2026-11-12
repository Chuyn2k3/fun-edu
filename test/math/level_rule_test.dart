import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/math/level_rule.dart';

int n(int current, int ok, {int total = 5, int count = 9}) => nextLevelIndex(
      current: current,
      firstTryCorrect: ok,
      total: total,
      levelCount: count,
    );

void main() {
  test('5/5 and 4/5 move up', () {
    expect(n(2, 5), 3);
    expect(n(2, 4), 3);
  });
  test('3/5 stays', () => expect(n(2, 3), 2));
  test('2/5 and 0/5 move down', () {
    expect(n(2, 2), 1);
    expect(n(2, 0), 1);
  });
  test('clamped at the ends', () {
    expect(n(0, 0), 0);
    expect(n(8, 5), 8);
  });
  test('empty session stays', () => expect(n(2, 0, total: 0), 2));
  test('non-5 totals', () {
    expect(n(2, 3, total: 4), 2);
    expect(n(2, 8, total: 10), 3);
  });
}
