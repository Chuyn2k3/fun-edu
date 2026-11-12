import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/grader.dart';

Stroke line(double x0, double y0, double x1, double y1, int n) => Stroke([
      for (var i = 0; i < n; i++)
        Point2(x0 + (x1 - x0) * i / (n - 1), y0 + (y1 - y0) * i / (n - 1)),
    ]);

void main() {
  final ref = line(0.5, 0.1, 0.5, 0.9, 20);

  test('nét trùng mẫu → ok', () => expect(gradeStroke(ref, ref).ok, isTrue));

  test('nét rung ±0.03 (Random(42)) → ok', () {
    final rnd = Random(42);
    double j() => (rnd.nextDouble() * 2 - 1) * 0.03;
    final drawn = Stroke([
      for (final p in ref.points) Point2(p.x + j(), p.y + j()),
    ]);
    final r = gradeStroke(drawn, ref);
    expect(r.ok, isTrue);
    expect(r.error, isNull);
  });

  test('nét ngược chiều → wrongDirection', () {
    final drawn = Stroke(ref.points.reversed.toList());
    expect(gradeStroke(drawn, ref).error, StrokeError.wrongDirection);
  });

  test('nét dời sang phải 0.3 → offPath', () {
    final drawn = line(0.8, 0.1, 0.8, 0.9, 20);
    expect(gradeStroke(drawn, ref).error, StrokeError.offPath);
  });

  test('nửa nét đầu → tooShort', () {
    final drawn = line(0.5, 0.1, 0.5, 0.5, 10);
    expect(gradeStroke(drawn, ref).error, StrokeError.tooShort);
  });

  test('chạm một điểm cho nét dài → tooShort, deviation hữu hạn', () {
    final r = gradeStroke(const Stroke([Point2(0.5, 0.5)]), ref);
    expect(r.error, StrokeError.tooShort);
    expect(r.deviation.isNaN, isFalse);
    expect(r.deviation.isFinite, isTrue);
  });

  test('dấu chấm: gần → ok, xa → offPath', () {
    const dot = Stroke([Point2(0.5, 0.2)]);
    expect(gradeStroke(const Stroke([Point2(0.55, 0.22)]), dot).ok, isTrue);
    final far = gradeStroke(const Stroke([Point2(0.8, 0.8)]), dot);
    expect(far.ok, isFalse);
    expect(far.error, StrokeError.offPath);
  });

  test('empty drawn stroke is tooShort, not a crash', () {
    expect(gradeStroke(const Stroke([]), ref).error, StrokeError.tooShort);
  });
}
