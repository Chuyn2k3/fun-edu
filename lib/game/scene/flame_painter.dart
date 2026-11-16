import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'trails.dart';

/// Rocket exhaust drawn in code, in four layers (back to front): a soft glow
/// around the nozzle, an outer flame whose radial gradient fades
/// orange → red → transparent, a yellow middle and a white-cream core.
///
/// Every layer is a fixed path in a unit box (nozzle at the origin, tip at
/// y = 1, half width ≈ 0.5) built once. Flicker and boost only change the
/// canvas transform, so painting a frame allocates no Paint, Path or Shader.
abstract final class FlameRenderer {
  /// Low-frequency flicker of the outer length, a sum of three incommensurate
  /// sines (1.7, 4.3, 9.1 Hz). Always within 1 ± 0.19.
  static double lengthFlicker(double t, double seed) =>
      1 +
      0.09 * math.sin(_tau * 1.7 * t + seed) +
      0.06 * math.sin(_tau * 4.3 * t + 1.3 * seed + 0.7) +
      0.04 * math.sin(_tau * 9.1 * t + 2.1 * seed + 1.9);

  static double _widthFlicker(double t, double seed) =>
      1 +
      0.06 * math.sin(_tau * 2.3 * t + 1.7 * seed + 0.4) +
      0.04 * math.sin(_tau * 6.7 * t + 0.6 * seed + 2.2);

  static double _sway(double t, double seed) =>
      0.07 * math.sin(_tau * 1.3 * t + 0.9 * seed + 1.1) +
      0.04 * math.sin(_tau * 3.7 * t + 1.9 * seed);

  /// Paints a flame pointing down from [nozzle]. [width] is the full width of
  /// the outer layer and [length] its length at intensity 1 without flicker.
  /// Returns the outer length actually drawn.
  static double paint(
    Canvas canvas, {
    required Offset nozzle,
    required double width,
    required double length,
    required double time,
    required double intensity,
    FlamePalette palette = FlamePalette.classic,
    double seed = 0,
  }) {
    final p = _paintsFor(palette);
    final boost = intensity - 1;
    final widthBoost = 1 + 0.22 * boost;
    final outerLen = length * intensity * lengthFlicker(time, seed);
    final outerW = width * widthBoost * _widthFlicker(time, seed);

    canvas.save();
    canvas.translate(nozzle.dx, nozzle.dy);

    // Glow: a radial-gradient oval around the nozzle (cheaper than a blur
    // and identical on every renderer).
    canvas.save();
    final glowPulse = 1 + 0.06 * math.sin(_tau * 3.1 * time + seed);
    canvas.translate(0, length * 0.2);
    canvas.scale(width * 1.25 * widthBoost * glowPulse,
        length * (0.42 + 0.12 * boost) * glowPulse);
    canvas.drawPath(_unitCircle, p.glow);
    canvas.restore();

    // Outer layer, softly blurred, tip swaying.
    canvas.save();
    canvas.scale(outerW, outerLen);
    canvas.skew(_sway(time, seed), 0);
    canvas.drawPath(_outer, p.outer);
    canvas.restore();

    // Middle (yellow).
    canvas.save();
    canvas.scale(
      width * widthBoost * _widthFlicker(time + 0.37, seed + 1.1),
      length * (1 + 0.7 * boost) * lengthFlicker(time + 0.37, seed + 1.1),
    );
    canvas.skew(0.7 * _sway(time + 0.11, seed), 0);
    canvas.drawPath(_mid, p.mid);
    canvas.restore();

    // Core (white-cream).
    canvas.save();
    canvas.scale(
      width * _widthFlicker(time + 0.71, seed + 2.3),
      length * (1 + 0.4 * boost) * lengthFlicker(time + 0.71, seed + 2.3),
    );
    canvas.skew(0.4 * _sway(time + 0.2, seed), 0);
    canvas.drawPath(_core, p.core);
    canvas.restore();

    canvas.restore();
    return outerLen;
  }

  static const _tau = 2 * math.pi;

  // Paths from the approved mockup (SVG box 64×120, nozzle near y = 9),
  // mapped to the unit box: x' = (x − 32) / 36, y' = (y − 9) / 107.
  static Path _svg(void Function(Path p, Offset Function(double, double) m) b) {
    Offset m(double x, double y) => Offset((x - 32) / 36, (y - 9) / 107);
    final p = Path();
    b(p, m);
    return p..close();
  }

  static void _cubic(Path p, Offset a, Offset b, Offset c) =>
      p.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
  static void _quad(Path p, Offset a, Offset b) =>
      p.quadraticBezierTo(a.dx, a.dy, b.dx, b.dy);

  static final Path _outer = _svg((p, m) {
    final s = m(32, 116);
    p.moveTo(s.dx, s.dy);
    _cubic(p, m(14, 92), m(10, 52), m(18, 16));
    _quad(p, m(32, 2), m(46, 16));
    _cubic(p, m(54, 52), m(50, 92), m(32, 116));
  });

  static final Path _mid = _svg((p, m) {
    final s = m(32, 84);
    p.moveTo(s.dx, s.dy);
    _cubic(p, m(22, 66), m(21, 40), m(25, 18));
    _quad(p, m(32, 10), m(39, 18));
    _cubic(p, m(43, 40), m(42, 66), m(32, 84));
  });

  static final Path _core = _svg((p, m) {
    final s = m(32, 52);
    p.moveTo(s.dx, s.dy);
    _cubic(p, m(27, 42), m(27, 28), m(29, 18));
    _quad(p, m(32, 13), m(35, 18));
    _cubic(p, m(37, 28), m(37, 42), m(32, 52));
  });

  static final Path _unitCircle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.5));

  static final Map<FlamePalette, _FlamePaints> _cache = {};

  static _FlamePaints _paintsFor(FlamePalette palette) =>
      _cache.putIfAbsent(palette, () => _FlamePaints(palette));
}

class _FlamePaints {
  _FlamePaints(FlamePalette c)
      : glow = Paint()
          ..shader = ui.Gradient.radial(Offset.zero, 0.5, [
            c.glow.withOpacity(0.7),
            c.glow.withOpacity(0.36),
            c.glow.withOpacity(0),
          ], const [0, 0.45, 1]),
        outer = Paint()
          ..shader = ui.Gradient.radial(const Offset(0, 0.12), 0.9, [
            c.outerHot,
            c.outer,
            c.outerMid,
            c.outerEnd.withOpacity(0),
          ], const [0, 0.3, 0.62, 1])
          // Sigma is in unit-box space (scaled by the canvas transform):
          // ~1–3 px of feathering at phone size.
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.025),
        mid = Paint()..color = c.mid.withOpacity(0.95),
        core = Paint()..color = c.core;

  final Paint glow;
  final Paint outer;
  final Paint mid;
  final Paint core;
}

/// A single flame filling its box (nozzle near the top), e.g. for a garage
/// preview. The race scene paints flames through [FlameRenderer] directly.
class FlamePainter extends CustomPainter {
  const FlamePainter({
    required this.time,
    required this.intensity,
    this.palette = FlamePalette.classic,
    this.seed = 0,
  });

  final double time;
  final double intensity;
  final FlamePalette palette;
  final double seed;

  static final Expando<double> _lastLength = Expando();
  static final Expando<double> _lastBase = Expando();

  /// Outer length drawn by the last [paint] call (for tests).
  double? get lastLength => _lastLength[this];

  /// Length without flicker at this [intensity] (for tests).
  double? get lastBaseLength => _lastBase[this];

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height * 0.62 / 1.8; // room for a 1.8 boost
    _lastBase[this] = base * intensity;
    _lastLength[this] = FlameRenderer.paint(
      canvas,
      nozzle: Offset(size.width / 2, size.height * 0.12),
      width: size.width * 0.6,
      length: base,
      time: time,
      intensity: intensity,
      palette: palette,
      seed: seed,
    );
  }

  @override
  bool shouldRepaint(FlamePainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.intensity != intensity ||
      oldDelegate.palette != palette ||
      oldDelegate.seed != seed;
}
