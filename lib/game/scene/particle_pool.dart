import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../ui/theme/tokens.dart';

/// Visual shape of a particle in [ParticlePool].
enum ParticleShape { circle, star, drop, ring }

/// Pre-allocated mutable particle slot reused across frames.
class Particle {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double ax = 0;
  double ay = 0;
  double size = 6;
  double endSize = 6;
  Color color = GameColors.star;
  double age = 0;
  double life = 0;
  double rotation = 0;
  double vRot = 0;
  ParticleShape shape = ParticleShape.circle;
  bool active = false;
}

/// Fixed-capacity particle pool that pre-allocates all [Particle] objects in
/// its constructor and reuses them with zero allocations on [spawn], [update],
/// and [paint].
class ParticlePool {
  ParticlePool(this.capacity)
      : assert(capacity >= 0),
        _slots = List<Particle>.generate(capacity, (_) => Particle(),
            growable: false),
        _allocations = capacity;

  final int capacity;
  final List<Particle> _slots;
  final int _allocations;
  final Paint _paint = Paint();
  int _alive = 0;
  int _cursor = 0;

  static final Path _unitStar = _buildUnitStar();

  static Path _buildUnitStar() {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? 1.0 : 0.45;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    return p;
  }

  /// Total [Particle] objects allocated over the lifetime of this pool.
  /// Always equals [capacity] and never grows after construction.
  @visibleForTesting
  int get allocations => _allocations;

  /// Number of currently active particles (`<= capacity`).
  int get alive => _alive;

  /// Spawns one particle if a slot is available. Returns `false` when full.
  bool spawn({
    required double x,
    required double y,
    double vx = 0,
    double vy = 0,
    double ax = 0,
    double ay = 0,
    double size = 6,
    double? endSize,
    Color color = GameColors.star,
    Duration life = const Duration(milliseconds: 600),
    double rotation = 0,
    double vRot = 0,
    ParticleShape shape = ParticleShape.circle,
  }) {
    if (capacity == 0 || _alive >= capacity || life <= Duration.zero) {
      return false;
    }
    for (var n = 0; n < capacity; n++) {
      final idx = (_cursor + n) % capacity;
      final p = _slots[idx];
      if (!p.active) {
        _cursor = (idx + 1) % capacity;
        p
          ..x = x
          ..y = y
          ..vx = vx
          ..vy = vy
          ..ax = ax
          ..ay = ay
          ..size = size
          ..endSize = endSize ?? size
          ..color = color
          ..age = 0
          ..life = life.inMicroseconds / 1e6
          ..rotation = rotation
          ..vRot = vRot
          ..shape = shape
          ..active = true;
        _alive++;
        return true;
      }
    }
    return false;
  }

  /// Advances all live particles by [dt], returning expired slots to the pool.
  void update(Duration dt) {
    final sec = dt.inMicroseconds / 1e6;
    if (sec <= 0 || _alive == 0) return;
    for (var i = 0; i < capacity; i++) {
      final p = _slots[i];
      if (!p.active) continue;
      p.age += sec;
      if (p.age >= p.life) {
        p.active = false;
        _alive--;
        continue;
      }
      p.vx += p.ax * sec;
      p.vy += p.ay * sec;
      p.x += p.vx * sec;
      p.y += p.vy * sec;
      p.rotation += p.vRot * sec;
    }
  }

  /// Paints all live particles onto [c] using alpha color paint (no `saveLayer`).
  void paint(Canvas c) {
    if (_alive == 0) return;
    for (var i = 0; i < capacity; i++) {
      final p = _slots[i];
      if (!p.active) continue;
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final fade = t < 0.12
          ? t / 0.12
          : t > 0.6
              ? (1.0 - t) / 0.4
              : 1.0;
      final alpha = (fade * p.color.opacity).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;
      final diameter = p.size + (p.endSize - p.size) * t;
      final radius = diameter * 0.5;
      if (radius <= 0.1) continue;

      switch (p.shape) {
        case ParticleShape.circle:
          _paint
            ..style = PaintingStyle.fill
            ..color = p.color.withOpacity(alpha);
          c.drawCircle(Offset(p.x, p.y), radius, _paint);
        case ParticleShape.ring:
          _paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.2, radius * 0.30)
            ..color = p.color.withOpacity(alpha);
          c.drawCircle(Offset(p.x, p.y), radius, _paint);
        case ParticleShape.drop:
          _paint
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = math.max(1.5, radius * 0.55)
            ..color = p.color.withOpacity(alpha);
          c.drawLine(
            Offset(p.x, p.y - radius),
            Offset(p.x + p.vx * 0.018, p.y + radius),
            _paint,
          );
        case ParticleShape.star:
          _paint
            ..style = PaintingStyle.fill
            ..color = p.color.withOpacity(alpha);
          c.save();
          c.translate(p.x, p.y);
          c.rotate(p.rotation);
          c.scale(radius, radius);
          c.drawPath(_unitStar, _paint);
          c.restore();
      }
    }
  }

  /// Deactivates all particles without allocating.
  void clear() {
    for (var i = 0; i < capacity; i++) {
      _slots[i].active = false;
    }
    _alive = 0;
  }
}
