import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../ui/theme/tokens.dart';
import 'smoke_particles.dart';

/// The scene's single time & scroll source. One ticker advances it; every
/// moving layer repaints from it, so no widget rebuilds per frame.
class SceneClock extends ChangeNotifier {
  double _time = 0;
  double _scroll = 0;
  double _warp = 0;

  double get time => _time;

  /// Accumulated vertical downward scroll distance (in logical units).
  double get scroll => _scroll;

  /// Current smoothed warp factor 0..1 (spikes during kid boost / Nitro).
  double get warp => _warp;

  void advance(double dt, {double targetWarp = 0}) {
    _warp += (targetWarp.clamp(0.0, 1.0) - _warp) * math.min(1.0, dt * 7.5);
    final speed = 78.0 * (1.0 + 2.4 * _warp);
    _scroll += dt * speed;
    _time += dt;
    notifyListeners();
  }

  /// Repaint without moving time (reduce motion, new targets).
  void touch() => notifyListeners();
}

/// Free-flight space chase layout for a scene of [size].
///
/// Both rockets fly at a large, consistent foreground scale in open space:
/// the child's rocket anchors in the lower-middle flight zone while Chíp and
/// upcoming lucky stars are positioned relative to the child's progress.
/// The destination planet approaches and grows as the race nears completion,
/// and a compact vertical progress bar sits along the right edge.
@immutable
class TrackGeometry {
  factory TrackGeometry(
    Size size, {
    int lanes = 2,
    double bottomInset = 0,
  }) {
    return TrackGeometry._(size, lanes, bottomInset);
  }

  TrackGeometry._(this.size, this.lanes, this.bottomInset)
      : assert(lanes >= 2),
        u = math
            .min(
              size.width / 390.0,
              math.max(180.0, size.height - bottomInset) / 520.0,
            )
            .clamp(0.72, 1.85),
        cx = size.width / 2;

  final Size size;
  final int lanes;

  /// Inset from the bottom of the screen occupied by floating HUD controls.
  final double bottomInset;

  /// Scale unit: ~1.0 on phone (390 pt wide), scaling cleanly up on iPads.
  final double u;
  final double cx;

  double get _availableH => math.max(180.0, size.height - bottomInset);

  /// Horizontal center of the flight corridor (nudged slightly left to leave
  /// clean breathing room for the right-edge mini progress bar).
  double get flightCx => cx - 8 * u;

  /// Top safe edge of the flight zone (below top pause & counter pills).
  double get topSafeY => bottomInset > 0
      ? math.max(96.0, _availableH * 0.17)
      : math.max(48.0, size.height * 0.11);

  /// Bottom safe edge of the flight zone (above floating cockpit HUD, leaving
  /// full clearance for rocket exhaust flames even when a racer trails behind).
  double get bottomSafeY => bottomInset > 0
      ? (size.height - bottomInset - 78 * u)
      : (size.height - 62 * u);

  double get flightHeight => math.max(120.0, bottomSafeY - topSafeY);

  /// Foreground rocket width — large and consistent so both rockets and Chíp's
  /// sculpted face inside the cockpit stay crisp and readable.
  double get rocketW =>
      (84 * u).clamp(62.0, math.min(size.width * 0.25, flightHeight * 0.34));

  /// Consistent rocket width across progress (no trapezoid shrinking).
  double rocketWidth(double p) => rocketW;

  /// Horizontal offset between the flight center and each rocket lane.
  double get laneSpread =>
      math.min(rocketW * 1.15, (size.width - 44 * u) * 0.26);

  double laneX(int lane) {
    if (lanes == 2) {
      return lane == 0 ? flightCx - laneSpread : flightCx + laneSpread;
    }
    final frac = (lane + 0.5) / lanes - 0.5;
    return flightCx + frac * laneSpread * 2.2;
  }

  /// Rockets fly straight upward in free space (tilt comes only from dynamic
  /// surge, hover, sputter, or overtake turbulence).
  double laneTilt(int lane) => 0.0;

  /// Vertical anchor for the kid's rocket base (fins) in chase-camera mode.
  double get kidAnchorY => topSafeY + flightHeight * 0.72;

  /// Vertical distance in pixels per race step (0.1 progress) in relative view.
  double get stepPixels =>
      (flightHeight * 0.24).clamp(64.0 * u, 128.0 * u);

  /// Screen Y for an object at progress [pos] relative to [anchorPos] (the
  /// kid's rocket). Higher progress appears higher on screen.
  double relativeY(
    double pos,
    double anchorPos, {
    bool clampToFlight = true,
  }) {
    final deltaSteps = (pos - anchorPos) * 10.0;
    final raw = kidAnchorY - deltaSteps * stepPixels;
    if (!clampToFlight) return raw;
    final minY = topSafeY + rocketW * 1.35;
    final maxY = bottomSafeY;
    if (minY >= maxY) return kidAnchorY;
    return raw.clamp(minY, maxY);
  }

  /// Relative base point for a racer in [lane] at [pos] relative to [anchorPos].
  Offset relativeBasePoint(
    double pos,
    double anchorPos,
    int lane, {
    bool clampToFlight = true,
  }) =>
      Offset(
        laneX(lane),
        relativeY(pos, anchorPos, clampToFlight: clampToFlight),
      );

  /// Monotonic Y mapping 0..1 across the flight zone (used for reference/tests).
  double yAt(double p) {
    final top = topSafeY + rocketW * 1.2;
    return bottomSafeY + (top - bottomSafeY) * p;
  }

  /// Base point along the monotonic 0..1 corridor.
  Offset basePoint(double p, int lane) => Offset(laneX(lane), yAt(p));

  /// Rocket rect standing on [basePoint].
  Rect rocketRect(double p, int lane, double aspect) {
    final b = basePoint(p, lane);
    final w = rocketWidth(p);
    return Rect.fromLTWH(b.dx - w / 2, b.dy - w * aspect, w, w * aspect);
  }

  /// Destination planet rect that starts small & distant and smoothly grows and
  /// approaches as [progress] (0..1) climbs toward the finish.
  Rect planetRectFor(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final ease = p * 0.35 + p * p * 0.65;
    final pw = (66.0 + 88.0 * ease) * u;
    final ph = pw * 0.75;
    final centerY = topSafeY + 26 * u + 28 * u * ease;
    return Rect.fromCenter(
      center: Offset(flightCx, centerY),
      width: pw,
      height: ph,
    );
  }

  /// Default destination planet rect at finish (`progress = 1.0`).
  Rect get planetRect => planetRectFor(1.0);

  /// Clear upper center position for the "VƯỢT LÊN!" overtake banner, safely
  /// below the distant destination planet and well above both rockets.
  Offset get bannerCenter => Offset(flightCx, topSafeY + 92 * u);

  /// Compact vertical mini space progress bar anchored along the right edge.
  Rect get progressBarRect {
    final barW = (8 * u).clamp(6.0, 12.0);
    final rightEdge = size.width - (14 * u).clamp(10.0, 24.0);
    final availH = math.max(80.0, bottomSafeY - topSafeY - 36 * u);
    final barH = math.min(availH, 240 * u);
    final centerY = topSafeY + 18 * u + availH * 0.5;
    return Rect.fromCenter(
      center: Offset(rightEdge - barW / 2, centerY),
      width: barW,
      height: barH,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TrackGeometry &&
      other.size == size &&
      other.lanes == lanes &&
      other.bottomInset == bottomInset;

  @override
  int get hashCode => Object.hash(size, lanes, bottomInset);
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

/// Multi-layer scrolling deep space background:
/// 1. Slow soft parallax nebulae (0.15× scroll)
/// 2. Twinkling stars & 4-point sparkles in a single drawRawAtlas (0.42× scroll)
/// 3. Near fast star streaks elongating smoothly with [SceneClock.warp] (1.0× scroll)
///
/// Zero per-frame Paint/Path/Shader allocations.
class SkyMotionPainter extends CustomPainter {
  SkyMotionPainter({required this.clock, required this.geometry})
      : super(repaint: clock) {
    _layoutField();
  }

  final SceneClock clock;
  final TrackGeometry geometry;

  late final int _starCount;
  late final Float32List _sx, _sy, _ss, _sp, _transforms, _rects;
  late final Int32List _rgb, _colors;

  late final int _streakCount;
  late final Float32List _stX, _stY, _stSpeed, _stBaseLen, _stAlpha;

  static final Path _unitCircle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1));

  static final List<Paint> _nebulaPaints = [
    _makeNebulaPaint(GameColors.nebulaViolet, 0.20),
    _makeNebulaPaint(GameColors.nebulaMagenta, 0.16),
    _makeNebulaPaint(GameColors.nebulaCyan, 0.15),
  ];

  static Paint _makeNebulaPaint(Color c, double peak) => Paint()
    ..shader = ui.Gradient.radial(
      Offset.zero,
      1,
      [c.withOpacity(peak), c.withOpacity(peak * 0.45), c.withOpacity(0)],
      const [0.0, 0.55, 1.0],
    );

  static final Paint _atlasPaint = Paint()..filterQuality = FilterQuality.low;
  static final Paint _streakPaint = Paint()..strokeCap = StrokeCap.round;

  static const _nebulaX = [0.20, 0.82, 0.48];
  static const _nebulaY = [0.22, 0.56, 0.88];
  static const _nebulaRx = [0.46, 0.40, 0.52];
  static const _nebulaRy = [0.24, 0.22, 0.20];

  void _layoutField() {
    final s = geometry.size;
    final u = geometry.u;
    final rng = math.Random(42);

    _starCount = (s.width * s.height / 7500).round().clamp(28, 64);
    _sx = Float32List(_starCount);
    _sy = Float32List(_starCount);
    _ss = Float32List(_starCount);
    _sp = Float32List(_starCount);
    _rgb = Int32List(_starCount);
    _transforms = Float32List(_starCount * 4);
    _rects = Float32List(_starCount * 4);
    _colors = Int32List(_starCount);

    for (var i = 0; i < _starCount; i++) {
      final big = i % 7 == 0;
      _sx[i] = rng.nextDouble() * s.width;
      _sy[i] = rng.nextDouble() * s.height;
      _ss[i] = (big ? 11 + rng.nextDouble() * 5 : 2.8 + rng.nextDouble() * 2.4) *
          u.clamp(0.9, 1.6);
      _sp[i] = rng.nextDouble() * math.pi * 2;
      _rgb[i] =
          (i.isEven ? GameColors.starWarm : GameColors.star).value & 0xFFFFFF;
      final cell = big ? 1 : 0;
      _rects[i * 4] = cell * ParticleSprites.cell;
      _rects[i * 4 + 1] = 0;
      _rects[i * 4 + 2] = (cell + 1) * ParticleSprites.cell;
      _rects[i * 4 + 3] = ParticleSprites.cell;
    }

    _streakCount = (s.width / 18).round().clamp(16, 28);
    _stX = Float32List(_streakCount);
    _stY = Float32List(_streakCount);
    _stSpeed = Float32List(_streakCount);
    _stBaseLen = Float32List(_streakCount);
    _stAlpha = Float32List(_streakCount);
    for (var i = 0; i < _streakCount; i++) {
      _stX[i] = rng.nextDouble() * s.width;
      _stY[i] = rng.nextDouble() * s.height;
      _stSpeed[i] = 0.85 + rng.nextDouble() * 0.55;
      _stBaseLen[i] = (6.0 + rng.nextDouble() * 7.0) * u;
      _stAlpha[i] = 0.16 + rng.nextDouble() * 0.24;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.time;
    final scroll = clock.scroll * geometry.u;
    final warp = clock.warp;
    final h = math.max(1.0, size.height);

    // 1. Slow parallax nebula clouds (0.15x scroll).
    final nebulaSpan = h * 1.4;
    for (var i = 0; i < 3; i++) {
      final rx = size.width * _nebulaRx[i];
      final ry = h * _nebulaRy[i];
      final nx = size.width * _nebulaX[i];
      final ny = ((_nebulaY[i] * nebulaSpan + scroll * 0.15) % nebulaSpan) -
          h * 0.2;
      canvas.save();
      canvas.translate(nx, ny);
      canvas.scale(rx, ry);
      canvas.drawPath(_unitCircle, _nebulaPaints[i]);
      canvas.restore();
    }

    // 2. Twinkling scrolling stars via single drawRawAtlas (0.42x scroll).
    final atlas = ParticleSprites.image;
    if (atlas != null) {
      const half = ParticleSprites.cell / 2;
      final starScroll = scroll * 0.42;
      for (var i = 0; i < _starCount; i++) {
        final tw = 0.5 + 0.5 * math.sin(t * (1.4 + (i % 5) * 0.35) + _sp[i]);
        final a = 0.40 + 0.60 * tw;
        final sc = _ss[i] / ParticleSprites.cell * (0.85 + 0.15 * tw);
        final y = (_sy[i] + starScroll) % h;
        final o = i * 4;
        _transforms[o] = sc;
        _transforms[o + 1] = 0;
        _transforms[o + 2] = _sx[i] - sc * half;
        _transforms[o + 3] = y - sc * half;
        _colors[i] = ((a * 255).round() << 24) | _rgb[i];
      }
      canvas.drawRawAtlas(atlas, _transforms, _rects, _colors,
          BlendMode.modulate, null, _atlasPaint);
    }

    // 3. Fast near star streaks (1.0x scroll, elongating with warp).
    final streakWrap = h + 60 * geometry.u;
    final hudTop = geometry.bottomInset > 0 ? h - geometry.bottomInset : h;
    _streakPaint.strokeWidth = (1.4 * geometry.u).clamp(1.0, 2.4);
    for (var i = 0; i < _streakCount; i++) {
      final len = _stBaseLen[i] * (1.0 + 2.8 * warp);
      final y = ((_stY[i] + scroll * _stSpeed[i]) % streakWrap) - 30 * geometry.u;
      if (y - len > hudTop) continue;
      final edgeFade = geometry.bottomInset > 0 && y > hudTop - 40 * geometry.u
          ? ((hudTop - (y - len)) / (40 * geometry.u + len)).clamp(0.0, 1.0)
          : 1.0;
      final alpha =
          ((_stAlpha[i] + 0.22 * warp) * edgeFade).clamp(0.0, 0.72);
      if (alpha <= 0.01) continue;
      _streakPaint.color = GameColors.streakLight.withOpacity(alpha);
      canvas.drawLine(
        Offset(_stX[i], y - len),
        Offset(_stX[i], math.min(y, hudTop)),
        _streakPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SkyMotionPainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.clock != clock;
}
