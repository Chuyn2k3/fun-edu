import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/grader.dart';
import 'package:funedu/stroke/glyph_session.dart';

Stroke _line(double x1, double y1, double x2, double y2, [int n = 24]) =>
    Stroke([
      for (var i = 0; i < n; i++)
        Point2(x1 + (x2 - x1) * i / (n - 1), y1 + (y2 - y1) * i / (n - 1)),
    ]);

Stroke _arc() => Stroke([
      for (var i = 0; i < 24; i++)
        Point2(
          0.55 + 0.15 * math.cos((180 + 360 * i / 23) * math.pi / 180),
          0.72 + 0.15 * math.sin((180 + 360 * i / 23) * math.pi / 180),
        ),
    ]);

final _stem = _line(0.4, 0.1, 0.4, 0.9);

Glyph _glyphB() => Glyph(id: 'b', label: 'b', strokes: [_stem, _arc()]);

void main() {
  test('correct strokes in order complete the glyph', () {
    final s = GlyphSession(_glyphB());
    expect(s.currentIndex, 0);
    expect(s.isComplete, isFalse);
    expect(s.submit(_stem).ok, isTrue);
    expect(s.currentIndex, 1);
    expect(s.submit(_arc()).ok, isTrue);
    expect(s.currentIndex, 2);
    expect(s.isComplete, isTrue);
    expect(s.history.length, 2);
  });

  test('drawing stroke 2 first yields wrongOrder and does not advance', () {
    final s = GlyphSession(_glyphB());
    final r = s.submit(_arc());
    expect(r.ok, isFalse);
    expect(r.error, StrokeError.wrongOrder);
    expect(s.currentIndex, 0);
    expect(r.deviation,
        gradeStroke(_arc(), _stem).deviation);
  });

  test('stroke 2 drawn in wrong direction first is also wrongOrder', () {
    final s = GlyphSession(_glyphB());
    final r = s.submit(Stroke(_arc().points.reversed.toList()));
    expect(r.error, StrokeError.wrongOrder);
    expect(s.currentIndex, 0);
  });

  test('lifting the pen midway gives tooShort without throwing', () {
    final s = GlyphSession(_glyphB());
    final first = s.submit(_line(0.4, 0.1, 0.4, 0.5));
    expect(first.ok, isFalse);
    expect(first.error, StrokeError.tooShort);
    expect(s.currentIndex, 0);
    final second = s.submit(_line(0.4, 0.5, 0.4, 0.9));
    expect(second.ok, isFalse);
    expect(s.currentIndex, 0);
  });

  test('wrong strokes do not advance; history records every submission', () {
    final s = GlyphSession(_glyphB());
    s.submit(_line(0.9, 0.1, 0.9, 0.9)); // off path
    s.submit(Stroke(_stem.points.reversed.toList())); // wrong direction
    expect(s.currentIndex, 0);
    expect(s.history.length, 2);
    expect(s.history[1].error, StrokeError.wrongDirection);
    expect(() => s.history.add(const StrokeResult(ok: true, deviation: 0)),
        throwsUnsupportedError);
  });

  test('reset returns to start and clears history', () {
    final s = GlyphSession(_glyphB());
    s.submit(_stem);
    s.reset();
    expect(s.currentIndex, 0);
    expect(s.history, isEmpty);
    expect(s.isComplete, isFalse);
  });

  test('submit after completion throws StateError', () {
    final s = GlyphSession(_glyphB());
    s.submit(_stem);
    s.submit(_arc());
    expect(() => s.submit(_stem), throwsStateError);
  });
}
