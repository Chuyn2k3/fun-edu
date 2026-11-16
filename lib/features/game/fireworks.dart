import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../ui/theme/tokens.dart';

/// Code-drawn fireworks: a few bursts of sparks that fly out, fall a little
/// and fade. Sparks are fixed at construction (typed arrays) and placed
/// analytically from the time, so painting allocates nothing. Under reduce
/// motion a single still frame (bursts open) is drawn.
class Fireworks extends StatefulWidget {
  const Fireworks({
    super.key,
    this.bursts = 5,
    this.duration = const Duration(milliseconds: 2400),
    this.delay = Duration.zero,
    this.repeat = false,
  });

  final int bursts;
  final Duration duration;
  final Duration delay;
  final bool repeat;

  @override
  State<Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final _Sparks _sparks = _Sparks(widget.bursts, seed: 11);
  bool _reduce = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduce) {
      _c.stop();
      _c.value = 0.32;
    } else if (!_started) {
      _started = true;
      Future<void>.delayed(widget.delay, () {
        if (!mounted || _reduce) return;
        widget.repeat ? _c.repeat() : _c.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FireworksPainter(_c, _sparks),
        ),
      ),
    );
  }
}

class _Sparks {
  _Sparks(this.bursts, {required int seed}) {
    final r = math.Random(seed);
    cx = Float32List(bursts);
    cy = Float32List(bursts);
    start = Float32List(bursts);
    palette = Int32List(bursts);
    dirX = Float32List(bursts * perBurst);
    dirY = Float32List(bursts * perBurst);
    speed = Float32List(bursts * perBurst);
    for (var b = 0; b < bursts; b++) {
      cx[b] = 0.15 + 0.7 * r.nextDouble();
      cy[b] = 0.12 + 0.4 * r.nextDouble();
      start[b] = b / bursts * 0.45;
      palette[b] = r.nextInt(GameColors.fireworks.length);
      for (var i = 0; i < perBurst; i++) {
        final a = i / perBurst * math.pi * 2 + r.nextDouble() * 0.2;
        final k = b * perBurst + i;
        dirX[k] = math.cos(a);
        dirY[k] = math.sin(a);
        speed[k] = 0.75 + 0.25 * r.nextDouble();
      }
    }
  }

  static const perBurst = 22;
  static const alphaSteps = 16;

  /// Every palette colour at [alphaSteps] opacities, made once.
  static final List<List<Color>> faded = [
    for (final c in GameColors.fireworks)
      [for (var a = 0; a <= alphaSteps; a++) c.withOpacity(a / alphaSteps)],
  ];

  final int bursts;
  late final Float32List cx, cy, start, dirX, dirY, speed;
  late final Int32List palette;

  /// Scratch buffer for one colour half of a burst (x, y pairs).
  final Float32List points = Float32List(perBurst);
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.anim, this.s) : super(repaint: anim);

  final Animation<double> anim;
  final _Sparks s;
  final Paint _p = Paint()
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round;

  static const _life = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final radius = size.shortestSide * 0.26;
    final n = GameColors.fireworks.length;
    for (var b = 0; b < s.bursts; b++) {
      final local = (t - s.start[b]) / _life;
      if (local <= 0 || local >= 1) continue;
      // Fast out, slow end; a little gravity; fade in the last 40 %.
      final out = 1 - math.pow(1 - local, 3).toDouble();
      final fade = (local < 0.6 ? 1.0 : (1 - local) / 0.4).clamp(0.0, 1.0);
      final ox = s.cx[b] * size.width;
      final oy = s.cy[b] * size.height;
      final fall = local * local * radius * 0.35;
      _p.strokeWidth =
          2 * math.max(2.0, size.shortestSide * 0.012) * (1.2 - local * 0.5);
      for (var half = 0; half < 2; half++) {
        var j = 0;
        for (var i = half; i < _Sparks.perBurst; i += 2) {
          final k = b * _Sparks.perBurst + i;
          final d = out * radius * s.speed[k];
          s.points[j++] = ox + s.dirX[k] * d;
          s.points[j++] = oy + s.dirY[k] * d + fall;
        }
        _p.color = _Sparks.faded[(s.palette[b] + half) % n]
            [(fade * _Sparks.alphaSteps).round()];
        canvas.drawRawPoints(ui.PointMode.points, s.points, _p);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.s != s;
}
