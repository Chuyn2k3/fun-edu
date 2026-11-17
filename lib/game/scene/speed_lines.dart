import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Warp speed lines effect: vertical streaks along screen borders that appear
/// during bursts of speed (correct answers, comet boosts).
class SpeedLines {
  const SpeedLines({this.duration = 0.45});

  /// Duration of the effect in seconds.
  final double duration;

  /// Whether the speed lines are currently active at [age] seconds.
  bool isActive(double age) => age >= 0 && age < duration;

  /// Returns the normalized opacity (0..1) at [age].
  /// Rises quickly in the first 20% of [duration], then fades out to 0.
  double opacityAt(double age) {
    if (age < 0 || age >= duration) return 0.0;
    final t = age / duration;
    if (t < 0.2) {
      return (t / 0.2).clamp(0.0, 1.0);
    } else {
      return (1.0 - (t - 0.2) / 0.8).clamp(0.0, 1.0);
    }
  }

  /// Draws 6-8 vertical streaks on the left and right borders with round
  /// stroke caps and white color with varying alpha.
  void paint(Canvas canvas, Size size, double age, {required int seed}) {
    if (!isActive(age)) return;
    final masterOpacity = opacityAt(age);
    if (masterOpacity <= 0 || size.width <= 0 || size.height <= 0) return;

    final rng = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const streakCount = 8;
    for (var i = 0; i < streakCount; i++) {
      final isLeft = i < streakCount ~/ 2;
      final xFrac = rng.nextDouble();
      final x = isLeft
          ? size.width * (0.02 + 0.12 * xFrac)
          : size.width * (0.98 - 0.12 * xFrac);

      final yFrac = rng.nextDouble();
      final lenFrac = 0.12 + 0.20 * rng.nextDouble();
      final speedMult = 0.9 + 0.6 * rng.nextDouble();
      final strokeWidth = 1.5 + 2.0 * rng.nextDouble();
      final baseAlpha = 0.35 + 0.55 * rng.nextDouble();

      // Vertical speed streaks rush downwards as rocket moves up
      final travel = (yFrac + age * speedMult * 1.5) % 1.2 - 0.2;
      final y1 = travel * size.height;
      final y2 = y1 + lenFrac * size.height;

      final alpha = (baseAlpha * masterOpacity).clamp(0.0, 1.0);
      paint.strokeWidth = strokeWidth;
      paint.color = const Color(0xFFFFFFFF).withOpacity(alpha);

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }
}
