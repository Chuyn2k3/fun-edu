import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import 'flame_painter.dart';
import 'rocket_sprite.dart';
import 'smoke_particles.dart';
import 'space_track.dart';
import 'speed_lines.dart';
import 'trails.dart';

/// The rocket race: a purple sky, a 2.5D track narrowing to the finish
/// planet, the kid's rocket (lane 0) and Chíp's white rocket (lane 1) with
/// flickering flames and smoke, parallax clouds and a comet fly-by.
///
/// Layers, back to front, each in its own [RepaintBoundary]:
/// 1. sky gradient (static), 2. stars + far clouds (moving),
/// 3. track + planet (static), 4. rockets, flames, smoke, comet and the
/// near clouds (moving). One [Ticker] drives a [SceneClock]; moving layers
/// repaint from it without rebuilding widgets. With reduce motion the
/// ticker never runs: flames are still, rockets jump to their steps.
class RaceScene extends StatefulWidget {
  const RaceScene({
    super.key,
    required this.kidSteps,
    required this.chipSteps,
    required this.kidRocket,
    required this.kidTrail,
    required this.boosting,
    required this.won,
    this.lanes = 2,
    this.bottomInset = 0,
  }) : assert(lanes >= 2);

  /// Steps climbed, 0..10 (10 = at the planet).
  final int kidSteps;
  final int chipSteps;

  /// Garage item ids, e.g. `rocket_orange`, `trail_flame`.
  final String kidRocket;
  final String kidTrail;

  /// Turning true (a comet question answered right) sends a comet across
  /// and boosts the kid's flame. Edge-triggered: pulse it (true for the
  /// comet answer, false afterwards) so the next comet fires again.
  final bool boosting;

  /// The kid finished first: their flame stays the leader's.
  final bool won;
  final int lanes;

  /// Inset from the bottom of the screen occupied by floating HUD controls.
  final double bottomInset;

  static const steps = 10;

  @override
  State<RaceScene> createState() => RaceSceneState();
}

class RaceSceneState extends State<RaceScene>
    with SingleTickerProviderStateMixin {
  final SceneClock _clock = SceneClock();
  final SceneImages _images = SceneImages();
  late final Ticker _ticker = createTicker(_onTick);
  late final _Racer _kid = _Racer(
      lane: 0,
      sprite: RocketSprite.forItem(widget.kidRocket),
      trail: TrailStyle.fromId(widget.kidTrail),
      seed: 1);
  late final _Racer _chip = _Racer(
      lane: 1,
      sprite: RocketSprite.chip,
      trail: TrailStyle.flame,
      seed: 2,
      isChip: true);
  TrackGeometry? _geometry;
  bool _reduceMotion = false;
  Duration _last = Duration.zero;
  double? _cometAge;
  final SpeedLines _speedLines = const SpeedLines();
  double _speedLinesAge = double.infinity;
  double _shakeAge = double.infinity;
  bool _kidWasAhead = false;

  static const _cometDuration = 1.3;

  // --- test hooks -----------------------------------------------------------
  @visibleForTesting
  double get flameTime => _clock.time;
  @visibleForTesting
  double get kidProgress => _kid.pos;
  @visibleForTesting
  double get chipProgress => _chip.pos;
  @visibleForTesting
  bool get isTicking => _ticker.isActive;
  @visibleForTesting
  double get kidBoost => _kid.boost;
  @visibleForTesting
  double get kidFlameIntensity => _kid.intensity;
  @visibleForTesting
  double get chipFlameIntensity => _chip.intensity;

  /// 0..1 while a comet crosses, otherwise null.
  @visibleForTesting
  double? get cometProgress =>
      _cometAge == null ? null : _cometAge! / _cometDuration;

  @visibleForTesting
  bool get isSpeedLinesActive =>
      !_reduceMotion && _speedLines.isActive(_speedLinesAge);

  @visibleForTesting
  Offset get shakeOffset => _shakeOffset;

  @visibleForTesting
  double get kidBaseY => _kid.baseY;

  @visibleForTesting
  double get chipBaseY => _chip.baseY;

  @visibleForTesting
  bool get isChipSpinning => !_reduceMotion && _chip.isSpinning;

  @visibleForTesting
  double get chipSpinAngle => _reduceMotion ? 0.0 : _chip.spinAngle;

  @visibleForTesting
  double get kidAnticipationDip => _kid.anticipationDip;

  @visibleForTesting
  static const luckyStarMilestones = [4, 8];

  @visibleForTesting
  List<int> get visibleLuckyStars =>
      luckyStarMilestones.where((m) => widget.kidSteps < m).toList();

  @visibleForTesting
  bool isStarVisible(int milestone) =>
      luckyStarMilestones.contains(milestone) && widget.kidSteps < milestone;

  @visibleForTesting
  Offset luckyStarPosition(int milestone) {
    final g = _geometry ??
        TrackGeometry(const Size(390, 480),
            lanes: widget.lanes, bottomInset: widget.bottomInset);
    return g.basePoint(milestone / RaceScene.steps, 0);
  }

  @visibleForTesting
  Iterable<String> get loadedAssets => _assets;

  @override
  void initState() {
    super.initState();
    _kid.setTarget(widget.kidSteps, jump: true);
    _chip.setTarget(widget.chipSteps, jump: true);
    _kidWasAhead = widget.kidSteps > widget.chipSteps;
    _chip.leadOffset = _chipWantsLead ? _Racer.chipLeadOffset : 0.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _images.resolve(createLocalImageConfiguration(context), _assets);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduceMotion || (!reduce && !_ticker.isActive)) {
      _reduceMotion = reduce;
      if (reduce) {
        _ticker.stop();
        _kid.snap();
        _chip.snap();
        _snapLead();
        _cometAge = null;
        _speedLinesAge = double.infinity;
        _shakeAge = double.infinity;
        _settleSmoke();
        _clock.touch();
      } else if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    }
  }

  Iterable<String> get _assets => {
        _kid.sprite.asset,
        if (_kid.sprite.pilotAsset != null) _kid.sprite.pilotAsset!,
        _chip.sprite.asset,
        if (_chip.sprite.pilotAsset != null) _chip.sprite.pilotAsset!,
        AppImages.planet,
        AppImages.comet,
      };

  @override
  void didUpdateWidget(RaceScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.kidRocket != widget.kidRocket) {
      _kid.sprite = RocketSprite.forItem(widget.kidRocket);
      _images.resolve(createLocalImageConfiguration(context), _assets);
    }
    if (old.kidTrail != widget.kidTrail) {
      _kid.smoke.style = TrailStyle.fromId(widget.kidTrail);
      _kid.trail = TrailStyle.fromId(widget.kidTrail);
    }
    final kidUp = widget.kidSteps > old.kidSteps;
    final chipUp = widget.chipSteps > old.chipSteps;
    _kid.setTarget(widget.kidSteps, jump: _reduceMotion);
    _chip.setTarget(widget.chipSteps, jump: _reduceMotion);
    if (_reduceMotion) {
      _snapLead();
      _settleSmoke();
      _clock.touch();
      return;
    }
    final cometNow = widget.boosting && !old.boosting;
    if (kidUp || cometNow) {
      _kid.startBoost(hold: cometNow ? 0.6 : 0.3);
      _speedLinesAge = 0;
      _shakeAge = 0;
    }
    if (chipUp) _chip.startBoost(hold: 0.3);
    if (cometNow) _cometAge = 0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _images.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    // Clamp so a dropped frame or a resume does not teleport anything.
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    if (dt <= 0) return;
    final t = _clock.time + dt;
    _kid.step(dt, leading: _kidLeads);
    _chip.step(dt, leading: _chipLeads);

    final wantOffset = _chipWantsLead ? _Racer.chipLeadOffset : 0.0;
    _chip.leadOffset += (wantOffset - _chip.leadOffset) * math.min(1.0, dt * 3);

    final kidAhead =
        (_kid.pos + _kid.leadOffset) > (_chip.pos + _chip.leadOffset);
    if (!_kidWasAhead && kidAhead) {
      if (!_reduceMotion) {
        _chip.spinOut();
      }
    }
    _kidWasAhead = kidAhead;

    final g = _geometry;
    if (g != null) {
      _kid.emitSmoke(dt, g, t);
      _chip.emitSmoke(dt, g, t);
    }
    if (_cometAge != null) {
      _cometAge = _cometAge! + dt;
      if (_cometAge! >= _cometDuration) _cometAge = null;
    }
    _speedLinesAge += dt;
    _shakeAge += dt;
    _clock.advance(dt);
  }

  Offset get _shakeOffset {
    if (_reduceMotion || _shakeAge > 0.25 || _shakeAge < 0) return Offset.zero;
    final intensity = (1.0 - _shakeAge / 0.25) * 3.0;
    final dx = math.sin(_shakeAge * 60) * intensity;
    final dy = math.cos(_shakeAge * 45) * intensity;
    return Offset(dx, dy);
  }

  bool get _kidLeads => widget.won || _kid.pos > _chip.pos + 0.02;
  bool get _chipLeads => !widget.won && _chip.pos > _kid.pos + 0.02;
  bool get _chipWantsLead =>
      !widget.won &&
      (_chipLeads || (widget.kidSteps == 0 && widget.chipSteps == 0));

  /// Reduce motion: no ticker eases the leader flame, so set it outright.
  void _snapLead() {
    _kid.lead = _kidLeads ? 1 : 0;
    _chip.lead = _chipLeads ? 1 : 0;
    _chip.leadOffset = _chipWantsLead ? _Racer.chipLeadOffset : 0.0;
  }

  /// Reduce motion: lay a still puff trail behind each rocket.
  void _settleSmoke() {
    final g = _geometry;
    if (g == null) return;
    for (final r in [_kid, _chip]) {
      r.smoke.clear();
      for (var i = 0; i < 60; i++) {
        r.emitSmoke(1 / 60, g, 0);
      }
    }
  }

  void _setGeometry(TrackGeometry g) {
    if (g == _geometry) return;
    _geometry = g;
    _kid.smoke.clear();
    _chip.smoke.clear();
    if (_reduceMotion) _settleSmoke();
  }

  @override
  Widget build(BuildContext context) {
    final kid = widget.kidSteps.clamp(0, RaceScene.steps);
    final chip = widget.chipSteps.clamp(0, RaceScene.steps);
    return Semantics(
      container: true,
      label: 'Tên lửa của bé: $kid trên ${RaceScene.steps} nấc. '
          'Chíp Chíp: $chip trên ${RaceScene.steps} nấc.',
      child: LayoutBuilder(builder: (context, c) {
        final size = c.biggest;
        final g = TrackGeometry(size,
            lanes: widget.lanes, bottomInset: widget.bottomInset);
        _setGeometry(g);
        return ClipRect(
          child: Stack(fit: StackFit.expand, children: [
            const RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GameColors.skyTop,
                      GameColors.skyUpper,
                      GameColors.skyLower,
                      Color(0xFF1B113E),
                    ],
                    stops: [0, 0.35, 0.70, 1],
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: SkyMotionPainter(clock: _clock, geometry: g),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                isComplex: true,
                painter: TrackPainter(
                  geometry: g,
                  planet: _images[AppImages.planet],
                  label: null,
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _RaceForegroundPainter(
                  state: this,
                  geometry: g,
                  repaint: Listenable.merge([
                    _clock,
                    _images[_kid.sprite.asset],
                    if (_kid.sprite.pilotAsset != null)
                      _images[_kid.sprite.pilotAsset!],
                    _images[_chip.sprite.asset],
                    if (_chip.sprite.pilotAsset != null)
                      _images[_chip.sprite.pilotAsset!],
                    _images[AppImages.comet],
                  ]),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

/// One rocket: spring position, flame boost and its smoke pool.
@visibleForTesting
class Racer {
  Racer({
    required this.lane,
    required this.sprite,
    required this.trail,
    required int seed,
    this.isChip = false,
  })  : smoke = SmokeParticles(style: trail, seed: seed),
        seed = seed * 1.7,
        leadOffset = isChip ? chipLeadOffset : 0.0;

  final int lane;
  RocketSprite sprite;
  TrailStyle trail;
  final SmokeParticles smoke;
  final double seed;
  final bool isChip;

  static const chipLeadOffset = 0.04;
  static const _spinDuration = 0.48;

  double pos = 0, vel = 0, target = 0;
  double _boostAge = double.infinity, _hold = 0.3;
  double _anticipationAge = double.infinity;
  double _spinAge = double.infinity;
  double lead = 0;
  double leadOffset = 0.0;

  bool get isSpinning => _spinAge < _spinDuration;
  double get spinAngle =>
      isSpinning ? (_spinAge / _spinDuration) * 2 * math.pi : 0.0;

  void spinOut() {
    _spinAge = 0.0;
  }

  void advance(double dt) {
    if (isSpinning) {
      _spinAge += dt;
    }
  }

  @visibleForTesting
  double get anticipationAge => _anticipationAge;

  @visibleForTesting
  double get anticipationDip =>
      (!_anticipationAge.isInfinite && _anticipationAge < 0.08)
          ? math.sin((_anticipationAge / 0.08) * math.pi) * 6.0
          : 0.0;

  // Slightly under-damped spring (ζ 0.75): settles in ~450 ms with a ~3 %
  // overshoot, so a rocket surges and settles like a real thrust.
  static const _omega = 11.85, _zeta = 0.75;

  void setTarget(int steps, {required bool jump}) {
    target = steps.clamp(0, RaceScene.steps) / RaceScene.steps;
    if (jump) snap();
  }

  void snap() {
    pos = target;
    vel = 0;
    _boostAge = double.infinity;
    _anticipationAge = double.infinity;
    _spinAge = double.infinity;
  }

  void startBoost({required double hold}) {
    _boostAge = 0;
    _anticipationAge = 0;
    _hold = hold;
  }

  /// Boost envelope 0..1: rises in 80 ms, holds, decays in 300 ms.
  double get boost {
    final a = _boostAge;
    if (a < 0.08) return a / 0.08;
    if (a < _hold) return 1;
    final f = 1 - (a - _hold) / 0.3;
    return f <= 0 ? 0 : f * f * (3 - 2 * f);
  }

  void step(double dt, {required bool leading}) {
    var left = dt;
    while (left > 0) {
      final h = math.min(left, 1 / 240);
      final acc = _omega * _omega * (target - pos) - 2 * _zeta * _omega * vel;
      vel += acc * h;
      pos += vel * h;
      left -= h;
    }
    if ((target - pos).abs() < 1e-4 && vel.abs() < 1e-3) {
      pos = target;
      vel = 0;
    }
    _boostAge += dt;
    _anticipationAge += dt;
    advance(dt);
    final want = leading ? 1.0 : 0.0;
    lead += (want - lead) * math.min(1, dt * 3);
  }

  /// Flame intensity: 1 cruising, up to ~1.8 on a boost, longer while
  /// surging, a little longer for the leader.
  double get intensity =>
      math.min(2.0, 1 + 0.8 * boost + math.min(0.5, vel.abs() * 0.8) + 0.15 * lead);

  // Per-frame pose (computed in [pose], read by the painter).
  double baseX = 0, baseY = 0, width = 0, height = 0, tilt = 0;

  Rect get rect => Rect.fromLTWH(-width / 2, -height, width, height);
  Offset get center => Offset(0, -height / 2);
  double get top => -height;

  void pose(TrackGeometry g, double t, {required bool still}) {
    final effectivePos = (pos + leadOffset).clamp(0.0, 1.0);
    final b = g.basePoint(effectivePos, lane);
    width = g.rocketWidth(effectivePos);
    height = width * sprite.aspect;
    tilt = g.laneTilt(lane);
    baseX = b.dx;
    baseY = b.dy;
    if (still) return;
    final u = g.u;
    final moving = math.min(1.0, vel.abs() * 2.5);
    // Hover bob, engine rumble, and a shake while surging.
    baseY += 1.6 * u * math.sin(t * 2 * math.pi * 0.9 + seed);
    baseX += (0.35 + 1.1 * moving) * u * math.sin(t * 47 + seed);
    tilt += 0.035 * moving * math.sin(t * 23 + seed);
    if (_anticipationAge < 0.08) {
      baseY += math.sin((_anticipationAge / 0.08) * math.pi) * 6.0;
    }
  }

  /// Nozzle in scene space for the current pose.
  Offset nozzle() {
    final d = -height * (1 - sprite.nozzle);
    return Offset(baseX - d * math.sin(tilt), baseY + d * math.cos(tilt));
  }

  double get flameWidth => width * 0.62;
  double get flameLength => width * 1.75;

  void emitSmoke(double dt, TrackGeometry g, double t) {
    pose(g, t, still: false);
    final n = nozzle();
    final reach = flameLength * intensity * 0.88;
    smoke.update(dt,
        emitX: n.dx - reach * math.sin(tilt),
        emitY: n.dy + reach * math.cos(tilt),
        unit: g.u * width / (60 * g.u),
        intensity: intensity);
  }
}

typedef _Racer = Racer;

class _RaceForegroundPainter extends CustomPainter {
  _RaceForegroundPainter({
    required this.state,
    required this.geometry,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final RaceSceneState state;
  final TrackGeometry geometry;

  static final Paint _shadow = Paint()
    ..color = GameColors.rocketShadow.withOpacity(0.45);
  static final Path _unitOval = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1));
  static final Path _streak = Path()
    ..moveTo(0, -0.5)
    ..cubicTo(0.3, -0.42, 0.7, -0.14, 1, 0)
    ..cubicTo(0.7, 0.14, 0.3, 0.42, 0, 0.5)
    ..close();
  static final Paint _streakPaint = Paint()
    ..shader = ui.Gradient.linear(Offset.zero, const Offset(1, 0), [
      GameColors.cometHead.withOpacity(0.9),
      GameColors.cometTail.withOpacity(0.5),
      GameColors.cometTail.withOpacity(0),
    ], const [0, 0.35, 1])
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.04);
  static final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    final g = geometry;
    final still = s._reduceMotion;
    final t = s._clock.time;
    final u = g.u;
    final w = size.width, h = size.height;

    final shake = s._shakeOffset;
    final hasShake = shake != Offset.zero;
    if (hasShake) {
      canvas.save();
      canvas.translate(shake.dx, shake.dy);
    }

    // Mid clouds (behind the rockets), drifting slowly (when no bottom HUD).
    if (g.bottomInset == 0) {
      final midBob = still ? 0.0 : math.sin(t * 2 * math.pi / 13);
      Clouds.paintBig(canvas, Offset(-34 * u + 7 * u * midBob, h - 62 * u),
          0.5 * u);
      Clouds.paintBig(
          canvas, Offset(w + 26 * u - 7 * u * midBob, h - 78 * u), 0.46 * u,
          mirror: true);
    }

    // Lucky stars at milestones 4 and 8 on kid lane (lane 0).
    _paintLuckyStars(canvas, g, t, still);

    // Rockets, farther one first.
    final kid = s._kid, chip = s._chip;
    kid.pose(g, t, still: still);
    chip.pose(g, t, still: still);
    final first = (kid.pos + kid.leadOffset) > (chip.pos + chip.leadOffset)
        ? kid
        : chip;
    final second = identical(first, kid) ? chip : kid;
    _paintRacer(canvas, first, t, still);
    _paintRacer(canvas, second, t, still);

    // Comet fly-by.
    final cp = s.cometProgress;
    if (cp != null) _paintComet(canvas, size, cp);

    // Front clouds at the bottom corners (when no bottom HUD).
    if (g.bottomInset == 0) {
      final frontBob = still ? 0.0 : math.sin(t * 2 * math.pi / 9 + 1);
      Clouds.paintBig(canvas, Offset(-6 * u + 12 * u * frontBob, h + 2 * u), u);
      Clouds.paintBig(
          canvas, Offset(w + 18 * u - 12 * u * frontBob, h + 4 * u), 0.92 * u,
          mirror: true);
    }

    if (hasShake) {
      canvas.restore();
    }

    if (!still && s._speedLines.isActive(s._speedLinesAge)) {
      s._speedLines.paint(canvas, size, s._speedLinesAge, seed: 42);
    }
  }

  void _paintRacer(Canvas canvas, _Racer r, double t, bool still) {
    // Soft shadow on the track under the fins.
    canvas.save();
    canvas.translate(r.baseX, r.baseY + 1.5 * geometry.u);
    canvas.scale(r.width * 0.5, r.width * 0.12);
    canvas.drawPath(_unitOval, _shadow);
    canvas.restore();

    r.smoke.paint(canvas, t);

    canvas.save();
    canvas.translate(r.baseX, r.baseY);
    canvas.rotate(r.tilt);
    if (r.spinAngle != 0 && !still) {
      final cy = -r.height / 2;
      canvas.translate(0, cy);
      canvas.rotate(r.spinAngle);
      canvas.translate(0, -cy);
    }
    FlameRenderer.paint(
      canvas,
      nozzle: Offset(0, -r.height * (1 - r.sprite.nozzle)),
      width: r.flameWidth,
      length: r.flameLength,
      time: still ? 0 : t,
      intensity: r.intensity,
      palette: r.trail.palette,
      seed: r.seed,
    );
    final img = state._images[r.sprite.asset].value;
    if (img != null) {
      canvas.save();
      canvas.translate(-r.width / 2, -r.height);
      canvas.scale(r.width / img.width, r.height / img.height);
      canvas.drawImage(img, Offset.zero, _imagePaint);
      canvas.restore();
    }
    if (r.sprite.pilotAsset != null) {
      final pilotImg = state._images[r.sprite.pilotAsset!].value;
      if (pilotImg != null) {
        final pilotSize = r.width * 0.44;
        final pilotCenter = Offset(0, r.top + r.height * 0.38);
        final pilotRect = Rect.fromCenter(
          center: pilotCenter,
          width: pilotSize,
          height: pilotSize,
        );
        paintImageFitted(canvas, pilotImg, pilotRect);
      }
    }
    canvas.restore();
  }

  void _paintLuckyStars(Canvas canvas, TrackGeometry g, double t, bool still) {
    for (final milestone in RaceSceneState.luckyStarMilestones) {
      if (state.widget.kidSteps < milestone) {
        final pt = g.basePoint(milestone / RaceScene.steps, 0);
        final bob = still ? 0.0 : math.sin(t * 3 + milestone) * 3;
        final center = Offset(pt.dx, pt.dy + bob);

        final scale = g.widthAt(pt.dy) / g.widthAt(g.startY);
        final outerR = 12.0 * g.u * scale;
        final innerR = outerR * 0.48;

        // Outer soft glow
        final glowPaint = Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, outerR * 0.7);
        canvas.drawCircle(center, outerR * 1.1, glowPaint);

        // 5-point star path
        final starPath = Path();
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? outerR : innerR;
          final x = center.dx + r * math.cos(angle);
          final y = center.dy + r * math.sin(angle);
          if (i == 0) {
            starPath.moveTo(x, y);
          } else {
            starPath.lineTo(x, y);
          }
        }
        starPath.close();

        // Golden gradient fill
        final starPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(center.dx, center.dy - outerR),
            Offset(center.dx, center.dy + outerR),
            const [
              Color(0xFFFFD700),
              Color(0xFFFFA000),
            ],
          );
        canvas.drawPath(starPath, starPaint);

        // Subtle outline highlight
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 1.2 * g.u * scale)
          ..color = const Color(0xFFFFF9C4).withOpacity(0.85);
        canvas.drawPath(starPath, borderPaint);
      }
    }
  }

  void _paintComet(Canvas canvas, Size size, double p) {
    final u = geometry.u;
    final cw = 92 * u;
    final w = size.width, h = size.height;
    // Quadratic arc from beyond the right edge, down-left across the sky.
    final x0 = w + cw * 0.6, y0 = 0.05 * h;
    final x1 = w * 0.55, y1 = 0.10 * h;
    final x2 = -cw * 1.2, y2 = 0.34 * h;
    final e = p; // linear: comets do not ease
    final a = (1 - e) * (1 - e), b = 2 * (1 - e) * e, c = e * e;
    final x = a * x0 + b * x1 + c * x2;
    final y = a * y0 + b * y1 + c * y2;
    final dx = 2 * (1 - e) * (x1 - x0) + 2 * e * (x2 - x1);
    final dy = 2 * (1 - e) * (y1 - y0) + 2 * e * (y2 - y1);
    final tail = math.atan2(-dy, -dx); // tail points back along the path

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(tail);
    canvas.save();
    canvas.scale(cw * 2.6, cw * 0.42);
    canvas.drawPath(_streak, _streakPaint);
    canvas.restore();
    final img = state._images[AppImages.comet].value;
    if (img != null) {
      // The art's tail points up-right (≈ −24°); turn it onto the path and
      // centre the star (≈ 27 %, 60 % of the image) on the head.
      canvas.rotate(_cometArtTail);
      final iw = cw, ih = cw * img.height / img.width;
      canvas.translate(-0.27 * iw, -0.60 * ih);
      canvas.scale(iw / img.width, ih / img.height);
      canvas.drawImage(img, Offset.zero, _imagePaint);
    }
    canvas.restore();
  }

  static const _cometArtTail = 24 * math.pi / 180;

  @override
  bool shouldRepaint(_RaceForegroundPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.geometry != geometry;
}
