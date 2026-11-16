import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../ui/theme/tokens.dart';
import 'smoke_particles.dart';

/// The scene's single time source. One ticker advances it; every moving
/// layer repaints from it, so no widget rebuilds per frame.
class SceneClock extends ChangeNotifier {
  double _time = 0;
  double get time => _time;

  void advance(double dt) {
    _time += dt;
    notifyListeners();
  }

  /// Repaint without moving time (reduce motion, new targets).
  void touch() => notifyListeners();
}

/// Layout of the 2.5D track for a scene of [size]. Everything scales with
/// [u], the track's bottom width over the mockup's 254 pt, so phones and
/// iPads (portrait or landscape) keep the same composition.
@immutable
class TrackGeometry {
  factory TrackGeometry(Size size, {int lanes = 2}) {
    final w = size.width, h = size.height;
    final bottomW = math.min(0.65 * w, 0.53 * h);
    return TrackGeometry._(size, lanes, bottomW);
  }

  TrackGeometry._(this.size, this.lanes, this.bottomW)
      : assert(lanes >= 2),
        u = bottomW / 254,
        topW = bottomW * 0.323,
        topY = size.height * 0.40,
        cx = size.width / 2;

  final Size size;
  final int lanes;

  /// Width of the track surface at the bottom edge and at the far (top) end.
  final double bottomW, topW;

  /// Scale unit: 1.0 on the phone mockup (390 × 480 scene).
  final double u;
  final double topY, cx;

  double get bottomY => size.height;

  /// Base (fins) of a rocket at progress 0 and 1.
  double get startY => size.height * 0.86;
  double get finishY => topY + 6 * u;

  double get _dwdy => (bottomW - topW) / (bottomY - topY);

  /// Track surface width at screen height [y].
  double widthAt(double y) => topW + (y - topY) * _dwdy;

  double get _vanishY => topY - topW / _dwdy;

  /// Screen y of a rocket base at progress [p] (0 start, 1 finish): a blend
  /// of linear and true perspective, so far steps look shorter but still
  /// move enough to see.
  double yAt(double p) {
    final y0 = startY, y1 = finishY, yv = _vanishY;
    final lin = y0 + (y1 - y0) * p;
    final k = (y0 - yv) / (y1 - yv);
    final persp = yv + (y0 - yv) / (1 + p * (k - 1));
    return lin + (persp - lin) * 0.2;
  }

  double _laneFrac(int lane) => (lane + 0.5) / lanes - 0.5;

  /// Point on the track under a rocket in [lane] at progress [p].
  Offset basePoint(double p, int lane) {
    final y = yAt(p);
    return Offset(cx + _laneFrac(lane) * widthAt(y) * 0.94, y);
  }

  /// Rocket width at progress [p]: shrinks with distance (softened).
  double rocketWidth(double p) =>
      60 * u * math.sqrt(widthAt(yAt(p)) / widthAt(startY));

  /// Rocket image rect ([aspect] = height / width) standing on its base point.
  Rect rocketRect(double p, int lane, double aspect) {
    final b = basePoint(p, lane);
    final w = rocketWidth(p);
    return Rect.fromLTWH(b.dx - w / 2, b.dy - w * aspect, w, w * aspect);
  }

  /// Lean of a rocket so its axis follows its lane toward the vanishing point.
  double laneTilt(int lane) => -math.atan(_laneFrac(lane) * 0.94 * _dwdy);

  /// The finish planet, sitting on the far end of the track.
  Rect get planetRect {
    final pw = 160 * u, ph = 120 * u;
    final bottom = topY - 10 * u;
    return Rect.fromLTWH(cx - pw / 2, bottom - ph, pw, ph);
  }

  @override
  bool operator ==(Object other) =>
      other is TrackGeometry && other.size == size && other.lanes == lanes;

  @override
  int get hashCode => Object.hash(size, lanes);
}

/// Static layer: the raised track slab, lane lines, step ties, finish strip
/// and the planet. Repaints only on resize or when the planet image arrives.
class TrackPainter extends CustomPainter {
  TrackPainter({required this.geometry, required this.planet, this.label})
      : super(repaint: planet);

  final TrackGeometry geometry;
  final ValueListenable<ui.Image?> planet;

  /// Text in a pill under the planet ("ĐÍCH").
  final String? label;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final u = g.u;
    final cx = g.cx, top = g.topY, bot = g.bottomY;
    final ht = g.topW / 2, hb = g.bottomW / 2;
    final side = 10 * u, sideTop = 4 * u;

    // Slab: rim (far edge + sides) behind the surface.
    final rim = Path()
      ..moveTo(cx - ht - sideTop, top - sideTop)
      ..lineTo(cx + ht + sideTop, top - sideTop)
      ..lineTo(cx + hb + side, bot)
      ..lineTo(cx - hb - side, bot)
      ..close();
    canvas.drawPath(rim, Paint()..color = GameColors.trackRim);
    // Darker side faces give the slab its thickness.
    final leftSide = Path()
      ..moveTo(cx - ht - sideTop, top)
      ..lineTo(cx - ht, top)
      ..lineTo(cx - hb, bot)
      ..lineTo(cx - hb - side, bot)
      ..close();
    final rightSide = Path()
      ..moveTo(cx + ht + sideTop, top)
      ..lineTo(cx + ht, top)
      ..lineTo(cx + hb, bot)
      ..lineTo(cx + hb + side, bot)
      ..close();
    final sidePaint = Paint()..color = GameColors.trackSide;
    canvas.drawPath(leftSide, sidePaint);
    canvas.drawPath(rightSide, sidePaint);

    final surface = Path()
      ..moveTo(cx - ht, top)
      ..lineTo(cx + ht, top)
      ..lineTo(cx + hb, bot)
      ..lineTo(cx - hb, bot)
      ..close();
    canvas.drawPath(
      surface,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, bot), const [
          GameColors.trackFar,
          GameColors.track,
        ]),
    );

    // Step ties every two steps (perspective-thin toward the planet).
    final tie = Paint()..color = GameColors.trackTie;
    for (var s = 2; s <= 8; s += 2) {
      final y = g.yAt(s / 10);
      final w = g.widthAt(y);
      final t = 2.2 * u * w / g.bottomW + 0.6;
      canvas.drawRect(
          Rect.fromLTRB(cx - w / 2 + 2 * u, y - t / 2, cx + w / 2 - 2 * u, y + t / 2),
          tie);
    }

    // Finish strip: two rows of checks across the far end.
    final fy = g.finishY;
    final fw = g.widthAt(fy);
    final rows = 2, cols = 8;
    final ch = 3.2 * u;
    final light = Paint()..color = GameColors.laneLine;
    final dark = Paint()..color = GameColors.trackSide;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final y0 = fy - ch * (r + 1) + ch * 0.6;
        final wRow = g.widthAt(y0);
        final x0 = cx - wRow / 2 + wRow * c / cols;
        canvas.drawRect(Rect.fromLTWH(x0, y0, wRow / cols + 0.5, ch),
            (r + c).isEven ? light : dark);
      }
    }
    assert(fw > 0);

    // Lane dividers: dashes shrink and thin toward the top.
    final dash = Paint()..color = GameColors.laneLine;
    for (var i = 1; i < g.lanes; i++) {
      final f = i / g.lanes - 0.5;
      var y = bot;
      while (y > fy + 2 * u) {
        final k = g.widthAt(y) / g.bottomW;
        final len = 11 * u * k;
        final gap = 12 * u * k;
        final y2 = math.max(y - len, fy + 2 * u);
        final w1 = 1.6 * u * k + 0.4, w2 = 1.6 * u * (g.widthAt(y2) / g.bottomW) + 0.4;
        final x1 = cx + f * g.widthAt(y) * 0.94;
        final x2 = cx + f * g.widthAt(y2) * 0.94;
        canvas.drawPath(
          Path()
            ..moveTo(x1 - w1, y)
            ..lineTo(x1 + w1, y)
            ..lineTo(x2 + w2, y2)
            ..lineTo(x2 - w2, y2)
            ..close(),
          dash,
        );
        y = y2 - gap;
      }
    }

    // Planet: warm halo, image, label pill.
    final pr = g.planetRect;
    final hc = pr.center.translate(0, 6 * u);
    canvas.drawCircle(
      hc,
      pr.width * 0.75,
      Paint()
        ..shader = ui.Gradient.radial(hc, pr.width * 0.75, [
          GameColors.planetHalo.withOpacity(0.38),
          GameColors.planetHalo.withOpacity(0.12),
          GameColors.planetHalo.withOpacity(0),
        ], const [0, 0.5, 1]),
    );
    final img = planet.value;
    if (img != null) {
      paintImageFitted(canvas, img, pr);
    }
    final text = label;
    if (text != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: (12 * u).clamp(12.0, 22.0),
            color: GameColors.star,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pill = Rect.fromCenter(
        center: Offset(cx, pr.top - 4 * u),
        width: tp.width + 18 * u,
        height: tp.height + 4 * u,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pill, Radius.circular(pill.height / 2)),
        Paint()..color = GameColors.skyTop.withOpacity(0.92),
      );
      tp.paint(canvas, pill.center - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(TrackPainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.planet != planet || oldDelegate.label != label;
}

/// Draws [img] contained (aspect kept) and centred in [rect].
void paintImageFitted(Canvas canvas, ui.Image img, Rect rect, [Paint? paint]) {
  final s = math.min(rect.width / img.width, rect.height / img.height);
  final w = img.width * s, h = img.height * s;
  canvas.save();
  canvas.translate(rect.center.dx - w / 2, rect.center.dy - h / 2);
  canvas.scale(s);
  canvas.drawImage(img, Offset.zero, paint ?? _imagePaint);
  canvas.restore();
}

final Paint _imagePaint = Paint()..filterQuality = FilterQuality.medium;

/// Clouds drawn in code, 2.5D: a light top fading to a lilac-pink belly.
/// Paths are in mockup points around an anchor and built once; drawing is a
/// translate + scale, so the same paths serve every size.
abstract final class Clouds {
  /// Big corner cloud, anchor at its bottom-left corner. Mirror for right.
  static final Path _bigBody = Path()
    ..moveTo(-24, 24)
    ..lineTo(-24, 0)
    ..cubicTo(-26, -34, 14, -50, 48, -40)
    ..cubicTo(60, -70, 104, -72, 120, -42)
    ..cubicTo(146, -54, 178, -36, 174, 0)
    ..lineTo(174, 24)
    ..close();
  static final Path _bigBelly = Path()
    ..moveTo(-24, 24)
    ..lineTo(-24, 2)
    ..cubicTo(8, -16, 58, -16, 84, -6)
    ..cubicTo(112, -18, 154, -16, 174, 2)
    ..lineTo(174, 24)
    ..close();
  static final Path _bigShine = Path()
    ..addOval(const Rect.fromLTWH(62, -62, 40, 14))
    ..addOval(const Rect.fromLTWH(10, -38, 30, 10))
    ..addOval(const Rect.fromLTWH(128, -42, 26, 9));

  static final Paint _bodyPaint = Paint()
    ..shader = ui.Gradient.linear(const Offset(0, -70), const Offset(0, 4), [
      GameColors.cloudTop,
      GameColors.cloudLight,
      Color.lerp(GameColors.cloudLight, GameColors.cloudShade, 0.45)!,
    ], const [0, 0.55, 1]);
  static final Paint _bellyPaint = Paint()..color = GameColors.cloudShade;
  static final Paint _shinePaint = Paint()
    ..color = GameColors.star.withOpacity(0.75)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  /// Big cloud with its bottom-left at [anchor]; [scale] in scene units
  /// (pass u × size); [mirror] flips it for the right corner.
  static void paintBig(Canvas canvas, Offset anchor, double scale,
      {bool mirror = false}) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(mirror ? -scale : scale, scale);
    canvas.drawPath(_bigBody, _bodyPaint);
    canvas.drawPath(_bigBelly, _bellyPaint);
    canvas.drawPath(_bigShine, _shinePaint);
    canvas.restore();
  }

  /// Small flat-bottomed far cloud, faint lilac, anchor at its base centre.
  static final Path _farBody = Path()
    ..moveTo(-34, 8)
    ..cubicTo(-42, -6, -26, -16, -14, -10)
    ..cubicTo(-10, -28, 18, -30, 22, -10)
    ..cubicTo(34, -16, 46, -4, 38, 8)
    ..close();
  static final Path _farBelly = Path()
    ..moveTo(-34, 8)
    ..cubicTo(-20, 1, 20, 0, 38, 8)
    ..close();
  static final Paint _farPaint = Paint()
    ..color = GameColors.cloudFar.withOpacity(0.55);
  static final Paint _farBellyPaint = Paint()
    ..color = GameColors.cloudFarShade.withOpacity(0.55);

  static const farWidth = 84.0;

  static void paintFar(Canvas canvas, Offset anchor, double scale) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(scale);
    canvas.drawPath(_farBody, _farPaint);
    canvas.drawPath(_farBelly, _farBellyPaint);
    canvas.restore();
  }
}

/// Moving sky behind the track: twinkling stars and far clouds drifting.
/// Stars are one atlas draw from arrays filled once per size.
class SkyMotionPainter extends CustomPainter {
  SkyMotionPainter({required this.clock, required this.geometry})
      : super(repaint: clock) {
    _layoutStars();
  }

  final SceneClock clock;
  final TrackGeometry geometry;

  late final int _count;
  late final Float32List _sx, _sy, _ss, _sp, _transforms, _rects;
  late final Int32List _rgb, _colors;

  void _layoutStars() {
    final s = geometry.size;
    final rng = math.Random(42);
    _count = (s.width * s.height / 12000).round().clamp(10, 40);
    _sx = Float32List(_count);
    _sy = Float32List(_count);
    _ss = Float32List(_count);
    _sp = Float32List(_count);
    _rgb = Int32List(_count);
    _transforms = Float32List(_count * 4);
    _rects = Float32List(_count * 4);
    _colors = Int32List(_count);
    final skyBottom = geometry.topY + s.height * 0.12;
    for (var i = 0; i < _count; i++) {
      final big = i % 6 == 0;
      _sx[i] = rng.nextDouble() * s.width;
      _sy[i] = rng.nextDouble() * skyBottom;
      _ss[i] = (big ? 12 + rng.nextDouble() * 5 : 3 + rng.nextDouble() * 2.5) *
          geometry.u.clamp(1.0, 1.8);
      _sp[i] = rng.nextDouble() * math.pi * 2;
      _rgb[i] = (i.isEven ? GameColors.starWarm : GameColors.star).value &
          0xFFFFFF;
      final cell = big ? 1 : 0;
      _rects[i * 4] = cell * ParticleSprites.cell;
      _rects[i * 4 + 1] = 0;
      _rects[i * 4 + 2] = (cell + 1) * ParticleSprites.cell;
      _rects[i * 4 + 3] = ParticleSprites.cell;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.time;
    final g = geometry;
    // Far clouds: three lanes at different speeds (parallax), wrapping.
    final span = size.width + Clouds.farWidth * 2 * g.u;
    for (var i = 0; i < 3; i++) {
      final speed = _farSpeed[i] * g.u;
      final scale = _farScale[i] * g.u;
      final y = _farY[i] * size.height;
      final x0 = _farX[i] * span;
      final x = (x0 + speed * t) % span - Clouds.farWidth * g.u;
      Clouds.paintFar(canvas, Offset(x, y), scale);
    }

    final atlas = ParticleSprites.image;
    if (atlas == null) return;
    const half = ParticleSprites.cell / 2;
    for (var i = 0; i < _count; i++) {
      final tw = 0.5 + 0.5 * math.sin(t * (1.3 + (i % 5) * 0.35) + _sp[i]);
      final a = 0.45 + 0.55 * tw;
      final sc = _ss[i] / ParticleSprites.cell * (0.85 + 0.15 * tw);
      final o = i * 4;
      _transforms[o] = sc;
      _transforms[o + 1] = 0;
      _transforms[o + 2] = _sx[i] - sc * half;
      _transforms[o + 3] = _sy[i] - sc * half;
      _colors[i] = ((a * 255).round() << 24) | _rgb[i];
    }
    canvas.drawRawAtlas(
        atlas, _transforms, _rects, _colors, BlendMode.modulate, null, _paint);
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.low;
  static const _farSpeed = [5.0, 3.2, 7.0];
  static const _farScale = [1.1, 0.8, 1.4];
  static const _farY = [0.30, 0.20, 0.47];
  static const _farX = [0.15, 0.62, 0.85];

  @override
  bool shouldRepaint(SkyMotionPainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.clock != clock;
}
