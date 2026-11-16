import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/flame_painter.dart';
import 'package:funedu/game/scene/trails.dart';

double _paintLength(FlamePainter p) {
  final recorder = ui.PictureRecorder();
  p.paint(Canvas(recorder), const Size(64, 160));
  recorder.endRecording().dispose();
  return p.lastLength!;
}

void main() {
  test('shouldRepaint is true when time changes, false when nothing does', () {
    const a = FlamePainter(time: 0, intensity: 1);
    expect(const FlamePainter(time: 0.016, intensity: 1).shouldRepaint(a),
        isTrue);
    expect(const FlamePainter(time: 0, intensity: 1.8).shouldRepaint(a),
        isTrue);
    expect(const FlamePainter(time: 0, intensity: 1).shouldRepaint(a),
        isFalse);
  });

  test('flame flickers: lengths at t=0 and t=1 s differ, within 25% of base',
      () {
    const p0 = FlamePainter(time: 0, intensity: 1);
    const p1 = FlamePainter(time: 1, intensity: 1);
    final l0 = _paintLength(p0);
    final l1 = _paintLength(p1);
    expect(l0, isNot(closeTo(l1, 0.5)));
    final base = p0.lastBaseLength!;
    for (final l in [l0, l1]) {
      expect((l / base - 1).abs(), lessThanOrEqualTo(0.25));
    }
    // Over many frames the flicker never leaves the ±25 % band.
    for (var t = 0.0; t < 10; t += 1 / 60) {
      final p = FlamePainter(time: t, intensity: 1, seed: 3);
      final l = _paintLength(p);
      expect((l / p.lastBaseLength! - 1).abs(), lessThanOrEqualTo(0.25));
    }
  });

  test('boost (1.8) makes the flame longer than normal', () {
    final normal = _paintLength(const FlamePainter(time: 0.3, intensity: 1));
    final boost = _paintLength(const FlamePainter(time: 0.3, intensity: 1.8));
    expect(boost, greaterThan(normal * 1.5));
  });

  test('every trail palette paints without error', () {
    for (final style in TrailStyle.values) {
      _paintLength(FlamePainter(time: 0.5, intensity: 1, palette: style.palette));
    }
  });
}
