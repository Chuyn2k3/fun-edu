import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';

void main() {
  test('resample a straight segment into 5 even points', () {
    final r = resample(const [Point2(0, 0), Point2(1, 0)], 5);
    expect(r.map((p) => p.x).toList(), [0, 0.25, 0.5, 0.75, 1]);
    expect(r.every((p) => p.y == 0), isTrue);
  });

  test('resample a single point gives 5 copies', () {
    final r = resample(const [Point2(0.3, 0.4)], 5);
    expect(r.length, 5);
    expect(r.every((p) => p == const Point2(0.3, 0.4)), isTrue);
  });

  test('resample empty list throws ArgumentError', () {
    expect(() => resample(const [], 5), throwsArgumentError);
  });

  test('pathLength of an L-shaped polyline is 2', () {
    expect(
        pathLength(const [Point2(0, 0), Point2(0, 1), Point2(1, 1)]), 2.0);
  });

  test('meanDistance/maxDistance of identical lists is 0', () {
    const a = [Point2(0, 0), Point2(1, 1)];
    expect(meanDistance(a, a), 0);
    expect(maxDistance(a, a), 0);
  });

  test('meanDistance and maxDistance differ as expected', () {
    const a = [Point2(0, 0), Point2(0, 0)];
    const b = [Point2(0, 0), Point2(0, 2)];
    expect(meanDistance(a, b), 1);
    expect(maxDistance(a, b), 2);
  });

  test('Point2 equality', () {
    expect(const Point2(1, 2), const Point2(1, 2));
    expect(const Point2(1, 2).hashCode, const Point2(1, 2).hashCode);
    expect(const Point2(1, 2) == const Point2(2, 1), isFalse);
  });
}
