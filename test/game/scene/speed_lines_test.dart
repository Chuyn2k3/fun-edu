import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/speed_lines.dart';

void main() {
  group('SpeedLines', () {
    const speedLines = SpeedLines();

    test('default duration is 0.45s', () {
      expect(speedLines.duration, 0.45);
    });

    test('isActive returns true only for 0 <= age < duration', () {
      expect(speedLines.isActive(-0.1), isFalse);
      expect(speedLines.isActive(0.0), isTrue);
      expect(speedLines.isActive(0.2), isTrue);
      expect(speedLines.isActive(0.449), isTrue);
      expect(speedLines.isActive(0.45), isFalse);
      expect(speedLines.isActive(1.0), isFalse);
    });

    test('opacity rises quickly in first 20% then fades out to 0', () {
      expect(speedLines.opacityAt(-0.1), 0.0);
      expect(speedLines.opacityAt(0.0), closeTo(0.0, 1e-5));

      // At 10% of duration (halfway through rise phase)
      final midRise = speedLines.duration * 0.1;
      expect(speedLines.opacityAt(midRise), closeTo(0.5, 1e-5));

      // At 20% of duration (peak opacity)
      final peak = speedLines.duration * 0.2;
      expect(speedLines.opacityAt(peak), closeTo(1.0, 1e-5));

      // At 60% of duration (halfway through decay phase: 0.2 + 0.8 * 0.5)
      final midDecay = speedLines.duration * 0.6;
      expect(speedLines.opacityAt(midDecay), closeTo(0.5, 1e-5));

      // At end of duration
      expect(speedLines.opacityAt(speedLines.duration), closeTo(0.0, 1e-5));
      expect(speedLines.opacityAt(0.5), 0.0);
    });

    test('paint does not throw on zero or active opacity', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(390, 844);

      // Inactive before start
      expect(() => speedLines.paint(canvas, size, -0.1, seed: 42), returnsNormally);

      // At start (opacity 0)
      expect(() => speedLines.paint(canvas, size, 0.0, seed: 42), returnsNormally);

      // At peak opacity
      expect(() => speedLines.paint(canvas, size, 0.09, seed: 42), returnsNormally);

      // During fade out
      expect(() => speedLines.paint(canvas, size, 0.25, seed: 42), returnsNormally);

      // Past duration
      expect(() => speedLines.paint(canvas, size, 0.5, seed: 42), returnsNormally);

      // Zero size
      expect(() => speedLines.paint(canvas, Size.zero, 0.09, seed: 42), returnsNormally);
    });
  });
}
