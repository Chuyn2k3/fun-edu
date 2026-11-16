import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../ui/theme/tokens.dart';
import 'trails.dart';

/// A fixed pool of smoke puffs (or rainbow puffs, or sparkles) behind one
/// rocket. Puffs spawn under the flame, drift down and sideways, grow and
/// fade. Positions are in scene pixels, so a rising rocket leaves a trail.
///
/// All state lives in typed arrays sized once; [update] and [paint] allocate
/// nothing. A slot is only reused once its puff is dead (alpha 0); when every
/// slot is busy the emitter simply skips a puff.
class SmokeParticles {
  SmokeParticles({required TrailStyle style, int seed = 0, this.capacity = 24})
      : assert(capacity <= 24),
        _style = style,
        _rng = math.Random(seed),
        _x = Float32List(capacity),
        _y = Float32List(capacity),
        _vx = Float32List(capacity),
        _vy = Float32List(capacity),
        _age = Float32List(capacity),
        _life = Float32List(capacity),
        _size0 = Float32List(capacity),
        _size1 = Float32List(capacity),
        _phase = Float32List(capacity),
        _rgb = Int32List(capacity),
        _transforms = Float32List(capacity * 4),
        _rects = Float32List(capacity * 4),
        _colors = Int32List(capacity) {
    _age.fillRange(0, capacity, 1);
    _life.fillRange(0, capacity, 1); // age ≥ life: dead
    _fillRects();
  }

  final int capacity;
  TrailStyle _style;
  final math.Random _rng;
  final Float32List _x, _y, _vx, _vy, _age, _life, _size0, _size1, _phase;
  final Int32List _rgb;
  final Float32List _transforms, _rects;
  final Int32List _colors;
  double _emit = 1; // the first frame already shows a puff
  int _colorCursor = 0;

  /// Called just before a dead slot is reused, with the alpha it had (tests).
  @visibleForTesting
  void Function(int slot, double alpha)? onReuse;

  TrailStyle get style => _style;
  set style(TrailStyle s) {
    if (s == _style) return;
    _style = s;
    _fillRects();
  }

  int get liveCount {
    var n = 0;
    for (var i = 0; i < capacity; i++) {
      if (_age[i] < _life[i]) n++;
    }
    return n;
  }

  void clear() {
    for (var i = 0; i < capacity; i++) {
      _age[i] = _life[i];
    }
    _emit = 0;
  }

  /// 0 when dead; eases in over the first 12 % of life, then fades out.
  double alphaOf(int i) {
    final life = _life[i];
    final age = _age[i];
    if (age >= life) return 0;
    final t = age / life;
    final peak = _style.particles == ParticleKind.sparkle ? 1.0 : 0.62;
    if (t < 0.12) return peak * t / 0.12;
    final f = (1 - t) / 0.88;
    return peak * f * f * (3 - 2 * f); // smoothstep to 0
  }

  /// Advances by [dt] seconds and emits from ([emitX], [emitY]). [unit] scales
  /// speeds and sizes with the scene; [intensity] 0 stops emitting, 1 is
  /// normal, 1.8 is a boost.
  void update(double dt,
      {required double emitX,
      required double emitY,
      required double unit,
      required double intensity}) {
    for (var i = 0; i < capacity; i++) {
      if (_age[i] >= _life[i]) continue;
      _age[i] += dt;
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
      // Air drag: puffs slow down as they spread.
      final drag = 1 - 1.1 * dt;
      _vx[i] *= drag;
      _vy[i] *= drag;
    }
    if (intensity <= 0) return;
    final sparkle = _style.particles == ParticleKind.sparkle;
    _emit += dt * (sparkle ? 18 : 16) * intensity;
    while (_emit >= 1) {
      _emit -= 1;
      final slot = _freeSlot();
      if (slot < 0) {
        _emit = 0;
        break;
      }
      onReuse?.call(slot, alphaOf(slot));
      _spawn(slot, emitX, emitY, unit, sparkle);
    }
  }

  int _freeSlot() {
    for (var i = 0; i < capacity; i++) {
      if (_age[i] >= _life[i]) return i;
    }
    return -1;
  }

  void _spawn(int i, double x, double y, double unit, bool sparkle) {
    final r = _rng;
    _x[i] = x + (r.nextDouble() - 0.5) * 8 * unit;
    _y[i] = y + (r.nextDouble() - 0.3) * 6 * unit;
    _vx[i] = (r.nextDouble() - 0.5) * (sparkle ? 70 : 46) * unit;
    _vy[i] = (sparkle ? 50 + r.nextDouble() * 30 : 46 + r.nextDouble() * 30) * unit;
    _age[i] = 0;
    _life[i] = sparkle ? 0.7 + r.nextDouble() * 0.4 : 0.9 + r.nextDouble() * 0.4;
    if (sparkle) {
      _size0[i] = (14 + r.nextDouble() * 8) * unit;
      _size1[i] = _size0[i] * 0.6;
    } else {
      _size0[i] = (14 + r.nextDouble() * 6) * unit;
      _size1[i] = (44 + r.nextDouble() * 18) * unit;
    }
    _phase[i] = r.nextDouble() * math.pi * 2;
    _rgb[i] = _nextRgb();
  }

  int _nextRgb() {
    switch (_style.particles) {
      case ParticleKind.puff:
        return _style.palette.smoke.value & 0xFFFFFF;
      case ParticleKind.rainbowPuff:
        _colorCursor = (_colorCursor + 1) % GameColors.rainbow.length;
        return GameColors.rainbow[_colorCursor].value & 0xFFFFFF;
      case ParticleKind.sparkle:
        _colorCursor = (_colorCursor + 1) % GameColors.sparkles.length;
        return GameColors.sparkles[_colorCursor].value & 0xFFFFFF;
    }
  }

  void _fillRects() {
    final cell = _style.particles == ParticleKind.sparkle ? 1 : 0;
    for (var i = 0; i < capacity; i++) {
      _rects[i * 4] = cell * ParticleSprites.cell;
      _rects[i * 4 + 1] = 0;
      _rects[i * 4 + 2] = (cell + 1) * ParticleSprites.cell;
      _rects[i * 4 + 3] = ParticleSprites.cell;
    }
  }

  /// Draws every puff in one atlas call. [time] twinkles sparkles.
  void paint(Canvas canvas, double time) {
    final atlas = ParticleSprites.image;
    if (atlas == null) return;
    final sparkle = _style.particles == ParticleKind.sparkle;
    const half = ParticleSprites.cell / 2;
    for (var i = 0; i < capacity; i++) {
      var a = alphaOf(i);
      final o = i * 4;
      if (a == 0) {
        _transforms[o] = 0;
        _transforms[o + 1] = 0;
        _transforms[o + 2] = 0;
        _transforms[o + 3] = 0;
        _colors[i] = 0;
        continue;
      }
      final t = _age[i] / _life[i];
      final eased = 1 - (1 - t) * (1 - t);
      final size = _size0[i] + (_size1[i] - _size0[i]) * eased;
      var scale = size / ParticleSprites.cell;
      var rot = 0.0;
      if (sparkle) {
        final tw = 0.5 + 0.5 * math.sin(time * 14 + _phase[i]);
        a *= 0.55 + 0.45 * tw;
        scale *= 0.8 + 0.3 * tw;
        rot = _phase[i] + t * 1.5;
      }
      final sc = scale * math.cos(rot);
      final ss = scale * math.sin(rot);
      _transforms[o] = sc;
      _transforms[o + 1] = ss;
      _transforms[o + 2] = _x[i] - sc * half + ss * half;
      _transforms[o + 3] = _y[i] - ss * half - sc * half;
      _colors[i] = ((a * 255).round() << 24) | _rgb[i];
    }
    canvas.drawRawAtlas(
        atlas, _transforms, _rects, _colors, BlendMode.modulate, null, _paint);
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.low;
}

/// A tiny white sprite atlas drawn once in code: cell 0 a soft round puff,
/// cell 1 a four-point sparkle. Particles and stars tint it per instance.
abstract final class ParticleSprites {
  static const double cell = 64;
  static ui.Image? _image;

  static ui.Image? get image => _image ??= _build();

  static ui.Image _build() {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    const r = cell / 2;
    // Puff: dense centre, soft edge, a little brighter on top (lit from above).
    c.drawCircle(
      const Offset(r, r),
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(r, r * 0.8),
          r,
          const [
            Color(0xFFFFFFFF),
            Color(0xC0FFFFFF),
            Color(0x4DFFFFFF),
            Color(0x00FFFFFF),
          ],
          const [0, 0.35, 0.7, 1],
        ),
    );
    // Sparkle: four-point star with a soft halo.
    const cx = cell + r;
    c.drawCircle(
      const Offset(cx, r),
      r * 0.55,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(cx, r), r * 0.55,
            const [Color(0x99FFFFFF), Color(0x00FFFFFF)]),
    );
    final star = Path()..moveTo(cx, 2);
    const k = 0.16;
    star
      ..quadraticBezierTo(cx + r * k, r - r * k, cell * 2 - 2, r)
      ..quadraticBezierTo(cx + r * k, r + r * k, cx, cell - 2)
      ..quadraticBezierTo(cx - r * k, r + r * k, cell + 2, r)
      ..quadraticBezierTo(cx - r * k, r - r * k, cx, 2)
      ..close();
    c.drawPath(star, Paint()..color = const Color(0xFFFFFFFF));
    final pic = rec.endRecording();
    final img = pic.toImageSync(cell.toInt() * 2, cell.toInt());
    pic.dispose();
    return img;
  }
}
