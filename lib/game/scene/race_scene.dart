import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../profile/avatars.dart' show kidAvatars;
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import 'flame_painter.dart';
import 'rocket_sprite.dart';
import 'smoke_particles.dart';
import 'space_track.dart';
import 'speed_lines.dart';
import 'trails.dart';

/// Redesigned StarPath rocket race scene:
/// Both rockets race along a visible 10-step perspective stardust highway towards
/// destination planet Saturn. The scene features warm twilight sky gradients,
/// atmospheric corona and depth wisps around Saturn, trajectory banking tilts,
/// and the child's avatar visible inside the rocket window.
///
/// 4 RepaintBoundary layers, back to front:
/// 1. Warm twilight space gradient (static),
/// 2. Multi-layer scrolling universe: nebulae, twinkling stars (moving),
/// 3. StarPath stardust highway ribbon, 10 perspective-scaled star stones,
///    approaching Saturn with corona (static: repaints ONLY on step change!),
/// 4. Foreground dynamic racers, smoke particles, flames, trailing nitro streaks,
///    Chíp reaction bubble, comet fly-by, and border speed lines (moving).
///
/// One [Ticker] drives [SceneClock]; with reduce motion the ticker never runs.
class RaceScene extends StatefulWidget {
  const RaceScene({
    super.key,
    required this.kidSteps,
    required this.chipSteps,
    required this.kidRocket,
    required this.kidTrail,
    required this.boosting,
    required this.won,
    this.kidAvatar,
    this.stallSeq = 0,
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

  /// Kid's chosen avatar asset path for the porthole window.
  final String? kidAvatar;

  /// Sequence number incremented on wrong answers to trigger sputter dip.
  final int stallSeq;
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
  StarPath? _starPath;
  bool _reduceMotion = false;
  Duration _last = Duration.zero;
  double? _cometAge;
  final SpeedLines _speedLines = const SpeedLines();
  double _speedLinesAge = double.infinity;
  double _shakeAge = double.infinity;
  bool _kidWasAhead = false;
  double _overtakeAge = double.infinity;

  static const _cometDuration = 1.3;
  static const _overtakeDuration = 0.75;

  String get kidAvatarAsset => widget.kidAvatar ?? kidAvatars[0];

  // --- test hooks -----------------------------------------------------------
  @visibleForTesting
  double get flameTime => _clock.time;
  @visibleForTesting
  double get spaceScroll => _clock.scroll;
  @visibleForTesting
  double get spaceWarp => _clock.warp;
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
  bool get isOvertakeBannerVisible =>
      !_reduceMotion && _overtakeAge < _overtakeDuration;

  @visibleForTesting
  bool get isChipWobbling => !_reduceMotion && _chip.isWobbling;

  @visibleForTesting
  double get chipWobbleAngle => _reduceMotion ? 0.0 : _chip.wobbleAngle;

  @visibleForTesting
  double get kidAnticipationDip => _kid.anticipationDip;

  @visibleForTesting
  bool get isKidStalled => !_reduceMotion && _kid.isStalled;

  @visibleForTesting
  double get kidSputterDip => !_reduceMotion ? _kid.sputterDip : 0.0;

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
    if (_starPath != null) {
      return _starPath!.point(milestone, isKid: true);
    }
    final sp = StarPath(const Size(390, 480), bottomInset: widget.bottomInset);
    return sp.point(milestone, isKid: true);
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
        _overtakeAge = double.infinity;
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
        _chip.sprite.asset,
        kidAvatarAsset,
        AppImages.planet,
        AppImages.comet,
        AppImages.chipSurprise,
        AppImages.chipJoy,
      };

  @override
  void didUpdateWidget(RaceScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.kidRocket != widget.kidRocket) {
      _kid.sprite = RocketSprite.forItem(widget.kidRocket);
      _images.resolve(createLocalImageConfiguration(context), _assets);
    }
    if (old.kidAvatar != widget.kidAvatar) {
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
    if (widget.stallSeq > old.stallSeq && !_reduceMotion) {
      _kid.stall();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _images.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
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
        _chip.wobble();
        _overtakeAge = 0.0;
      }
    }
    _kidWasAhead = kidAhead;

    final sp = _starPath;
    if (sp != null) {
      _kid.emitSmoke(dt, sp, t);
      _chip.emitSmoke(dt, sp, t);
    }
    if (_cometAge != null) {
      _cometAge = _cometAge! + dt;
      if (_cometAge! >= _cometDuration) _cometAge = null;
    }
    _speedLinesAge += dt;
    _shakeAge += dt;
    _overtakeAge += dt;

    final targetWarp =
        math.max(_kid.boost, _speedLines.isActive(_speedLinesAge) ? 0.85 : 0.0);
    _clock.advance(dt, targetWarp: targetWarp);
  }

  Offset get _shakeOffset {
    if (_reduceMotion || _shakeAge > 0.25 || _shakeAge < 0) return Offset.zero;
    final intensity = (1.0 - _shakeAge / 0.25) * 2.8;
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
    final sp = _starPath;
    if (sp == null) return;
    for (final r in [_kid, _chip]) {
      r.smoke.clear();
      r.clearStallSmoke();
      for (var i = 0; i < 60; i++) {
        r.emitSmoke(1 / 60, sp, 0);
      }
    }
  }

  void _setGeometry(TrackGeometry g, [StarPath? sp]) {
    if (g == _geometry && sp == _starPath) return;
    _geometry = g;
    _starPath = sp ?? StarPath(g.size, bottomInset: g.bottomInset);
    _kid.smoke.clear();
    _kid.clearStallSmoke();
    _chip.smoke.clear();
    _chip.clearStallSmoke();
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
        final isLandscapeTablet =
            size.width >= 600 && size.width > size.height;
        final sp = StarPath(size,
            bottomInset: widget.bottomInset,
            isLandscapeTablet: isLandscapeTablet);
        _setGeometry(g, sp);

        return ClipRect(
          child: Stack(fit: StackFit.expand, children: [
            // Layer 1: Warm Twilight Space Gradient
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
                      GameColors.skyHorizon,
                    ],
                    stops: [0.0, 0.35, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            // Layer 2: Cosmic motion (parallax nebulae, twinkling stars)
            RepaintBoundary(
              child: CustomPaint(
                painter: SkyMotionPainter(clock: _clock, geometry: g),
              ),
            ),

            // Layer 3: Static Star Track, 10 perspective step stones, and Saturn with corona
            // Repaints ONLY when steps change (not every frame!)
            RepaintBoundary(
              child: CustomPaint(
                painter: _StarTrackPainter(
                  starPath: sp,
                  kidSteps: kid,
                  chipSteps: chip,
                  planetImage: _images[AppImages.planet].value,
                ),
              ),
            ),

            // Layer 4: Foreground dynamic racers, smoke, flames, comet, speed lines
            RepaintBoundary(
              child: CustomPaint(
                painter: _RaceForegroundPainter(
                  state: this,
                  geometry: g,
                  starPath: sp,
                  repaint: Listenable.merge([
                    _clock,
                    _images[_kid.sprite.asset],
                    _images[_chip.sprite.asset],
                    _images[kidAvatarAsset],
                    _images[AppImages.planet],
                    _images[AppImages.comet],
                    _images[AppImages.chipSurprise],
                    _images[AppImages.chipJoy],
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

/// One rocket: spring position, flame boost, turbulence wobble, stall sputter,
/// and its smoke pool.
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
  late final math.Random _random = math.Random((seed * 1000).toInt());

  static const chipLeadOffset = 0.04;
  static const _wobbleDuration = 0.55;
  static const _stallDuration = 0.35;

  double pos = 0, vel = 0, target = 0;
  double _boostAge = double.infinity, _hold = 0.3;
  double _anticipationAge = double.infinity;
  double _wobbleAge = double.infinity;
  double _stallAge = double.infinity;
  double lead = 0;
  double leadOffset = 0.0;

  /// True while Chíp rocks from the child's overtake wake.
  bool get isWobbling => _wobbleAge < _wobbleDuration;

  /// Natural damped side-to-side turbulence tilt (max ±17°) when overtaken.
  double get wobbleAngle {
    if (!isWobbling) return 0.0;
    final prog = (_wobbleAge / _wobbleDuration).clamp(0.0, 1.0);
    return math.sin(_wobbleAge * 26.0) * 0.30 * (1.0 - prog);
  }

  /// Slight horizontal slip during turbulence wobble (in scene units).
  double get wobbleSlip {
    if (!isWobbling) return 0.0;
    final prog = (_wobbleAge / _wobbleDuration).clamp(0.0, 1.0);
    return math.sin(_wobbleAge * 16.0) * 7.0 * (1.0 - prog);
  }

  bool get isStalled => _stallAge < _stallDuration;

  void wobble() {
    _wobbleAge = 0.0;
  }

  void stall() {
    _stallAge = 0.0;
  }

  void advance(double dt) {
    if (isWobbling) {
      _wobbleAge += dt;
    }
    if (isStalled) {
      _stallAge += dt;
    }
    for (var i = _stallPuffs.length - 1; i >= 0; i--) {
      _stallPuffs[i].advance(dt);
      if (_stallPuffs[i].isDead) {
        _stallPuffs.removeAt(i);
      }
    }
  }

  @visibleForTesting
  double get anticipationAge => _anticipationAge;

  @visibleForTesting
  double get anticipationDip =>
      (!_anticipationAge.isInfinite && _anticipationAge < 0.08)
          ? math.sin((_anticipationAge / 0.08) * math.pi) * 6.0
          : 0.0;

  @visibleForTesting
  double get sputterDip =>
      isStalled ? math.sin((_stallAge / _stallDuration) * math.pi) * 8.0 : 0.0;

  final List<_StallPuff> _stallPuffs = [];

  void clearStallSmoke() {
    _stallPuffs.clear();
  }

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
    _wobbleAge = double.infinity;
    _stallAge = double.infinity;
    _stallPuffs.clear();
  }

  void startBoost({required double hold}) {
    _boostAge = 0;
    _anticipationAge = 0;
    _hold = hold;
  }

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

  double get intensity {
    if (isStalled) return 0.55;
    if (isWobbling) {
      final prog = (_wobbleAge / _wobbleDuration).clamp(0.0, 1.0);
      return 0.58 + 0.42 * prog;
    }
    return math.min(
      1.65,
      1.0 + 0.48 * boost + math.min(0.24, vel.abs() * 0.4) + 0.15 * lead,
    );
  }

  double baseX = 0, baseY = 0, width = 0, height = 0, tilt = 0;

  Rect get rect => Rect.fromLTWH(-width / 2, -height, width, height);
  Offset get center => Offset(0, -height / 2);
  double get top => -height;

  void pose(
    Object path,
    double t, {
    required bool still,
    double? anchorPos,
  }) {
    Offset b;
    double w;
    double lTilt;
    double u;

    if (path is TrackGeometry) {
      final effectivePos = (pos + leadOffset).clamp(0.0, 1.0);
      b = anchorPos != null
          ? path.relativeBasePoint(effectivePos, anchorPos, lane)
          : path.basePoint(effectivePos, lane);
      w = path.rocketWidth(effectivePos);
      lTilt = path.laneTilt(lane);
      u = path.u;
    } else {
      final StarPath sp = path is StarPath
          ? path
          : StarPath(const Size(390, 844));
      final effectivePos = (pos + leadOffset).clamp(0.0, 1.0);
      b = sp.pointAtT(effectivePos, isKid: !isChip);
      w = sp.rocketWidth(effectivePos);
      lTilt = sp.angleAtT(effectivePos, isKid: !isChip);
      u = sp.u;
    }

    width = w;
    height = width * sprite.aspect;
    tilt = lTilt;
    baseX = b.dx;
    baseY = b.dy;
    if (still) return;

    final moving = math.min(1.0, vel.abs() * 2.5);
    baseY += 2.6 * u * math.sin(t * 2 * math.pi * 0.85 + seed);
    if (!isChip && boost > 0 && _anticipationAge >= 0.08) {
      baseY -= 16.0 * u * boost;
    }
    baseX += (0.45 + 1.0 * moving) * u * math.sin(t * 36 + seed);
    tilt += 0.020 * math.sin(t * 2.1 + seed) +
        0.028 * moving * math.sin(t * 20 + seed);

    if (_anticipationAge < 0.08) {
      baseY += anticipationDip;
    }
    if (isWobbling) {
      tilt += wobbleAngle;
      baseX += wobbleSlip * u;
    }
    if (isStalled) {
      baseY += sputterDip;
      final wobblePhase = (_stallAge / _stallDuration);
      baseX += math.sin(_stallAge * 54) * 3.5 * (1.0 - wobblePhase);
      tilt += math.sin(_stallAge * 42) * 0.08 * (1.0 - wobblePhase);
    }
  }

  Offset nozzle() {
    final d = -height * (1 - sprite.nozzle);
    return Offset(baseX - d * math.sin(tilt), baseY + d * math.cos(tilt));
  }

  double get flameWidth => width * 0.44;
  double get flameLength => width * 0.96;

  void emitSmoke(
    double dt,
    Object path,
    double t, {
    double? anchorPos,
  }) {
    pose(path, t, still: false, anchorPos: anchorPos);
    final n = nozzle();
    final reach = flameLength * intensity * 0.78;
    final u = path is StarPath
        ? path.u
        : (path is TrackGeometry ? path.u : 1.0);
    smoke.update(
      dt,
      emitX: n.dx - reach * math.sin(tilt),
      emitY: n.dy + reach * math.cos(tilt),
      unit: u * width / (84 * u),
      intensity: intensity,
    );

    if (isStalled) {
      _emitStallPuffs(dt, n, u);
    }
  }

  void _emitStallPuffs(double dt, Offset n, double u) {
    final count = (dt * 28).clamp(1, 3).toInt();
    for (var i = 0; i < count; i++) {
      if (_stallPuffs.length > 20) break;
      final life = 0.35 + _random.nextDouble() * 0.2;
      final angle = tilt + (_random.nextDouble() - 0.5) * 0.7;
      final speed = (36.0 + _random.nextDouble() * 44.0) * u;
      _stallPuffs.add(_StallPuff(
        x: n.dx + (_random.nextDouble() - 0.5) * 6 * u,
        y: n.dy + (_random.nextDouble() - 0.5) * 6 * u,
        vx: math.sin(angle) * speed,
        vy: math.cos(angle) * speed,
        life: life,
        startSize: (7.0 + _random.nextDouble() * 4.0) * u,
        endSize: (19.0 + _random.nextDouble() * 8.0) * u,
        color: GameColors.stallSmoke,
      ));
    }
  }
}

class _StallPuff {
  _StallPuff({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.startSize,
    required this.endSize,
    required this.color,
  });

  double x, y;
  final double vx, vy;
  double age = 0;
  final double life;
  final double startSize, endSize;
  final Color color;

  bool get isDead => age >= life;

  void advance(double dt) {
    age += dt;
    x += vx * dt;
    y += vy * dt;
  }
}

typedef _Racer = Racer;

/// Layer 3: Static Star Track, stardust highway ribbon, 10 perspective-scaled
/// stepping stones, and Saturn with atmospheric corona and depth wisps.
/// Only repaints when steps change or resized.
class _StarTrackPainter extends CustomPainter {
  _StarTrackPainter({
    required this.starPath,
    required this.kidSteps,
    required this.chipSteps,
    required this.planetImage,
  });

  final StarPath starPath;
  final int kidSteps;
  final int chipSteps;
  final ui.Image? planetImage;

  static final Paint _warpRayPaint = Paint()
    ..color = GameColors.warpRay.withOpacity(0.12)
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;

  static final Paint _roadPaint = Paint()
    ..color = GameColors.roadSurface.withOpacity(0.06)
    ..style = PaintingStyle.fill;

  static final Paint _railPaint = Paint()
    ..color = GameColors.roadRail.withOpacity(0.24)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  static final Paint _stoneShadowPaint = Paint()..color = GameColors.stoneShadow;
  static final Paint _stoneHighlightPaint = Paint()
    ..color = GameColors.star.withOpacity(0.85);

  static final Path _unitCircle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1));

  @override
  void paint(Canvas canvas, Size size) {
    final sp = starPath;
    final vp = sp.planetCenter;

    // 1. Draw 3D Radial Stardust Perspective Lines radiating from Saturn
    for (var i = 0; i < 16; i++) {
      final angle = (i / 16.0) * math.pi + 0.15;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      final startDist = 65.0 + (i % 3) * 22.0;
      final rayLen = 45.0 + (i % 4) * 30.0;
      final p1 = Offset(vp.dx + dx * startDist, vp.dy + dy * startDist);
      final p2 = Offset(p1.dx + dx * rayLen, p1.dy + dy * rayLen);
      canvas.drawLine(p1, p2, _warpRayPaint);
    }

    // 2. Draw Translucent Glowing Stardust Highway Ribbon (3D Road Surface)
    for (var s = 0; s < 10; s++) {
      final kp0 = sp.point(s, isKid: true);
      final cp0 = sp.point(s, isKid: false);
      final kp1 = sp.point(s + 1, isKid: true);
      final cp1 = sp.point(s + 1, isKid: false);

      final quad = Path()
        ..moveTo(kp0.dx, kp0.dy)
        ..lineTo(cp0.dx, cp0.dy)
        ..lineTo(cp1.dx, cp1.dy)
        ..lineTo(kp1.dx, kp1.dy)
        ..close();
      canvas.drawPath(quad, _roadPaint);
    }

    // 3. Draw Lane Rails with glow
    final kidPath = Path();
    final chipPath = Path();
    for (var s = 0; s <= 10; s++) {
      final kp = sp.point(s, isKid: true);
      final cp = sp.point(s, isKid: false);
      if (s == 0) {
        kidPath.moveTo(kp.dx, kp.dy);
        chipPath.moveTo(cp.dx, cp.dy);
      } else {
        kidPath.lineTo(kp.dx, kp.dy);
        chipPath.lineTo(cp.dx, cp.dy);
      }
    }
    canvas.drawPath(kidPath, _railPaint);
    canvas.drawPath(chipPath, _railPaint);

    // 4. Draw 10 Checkpoint Stones with Perspective Scale!
    for (var s = 1; s <= 10; s++) {
      final pScale = sp.stoneScaleAt(s);
      final kp = sp.point(s, isKid: true);
      final cp = sp.point(s, isKid: false);

      _drawStone(canvas, kp, s <= kidSteps, s == 4 || s == 8, pScale);
      _drawStone(canvas, cp, s <= chipSteps, s == 4 || s == 8, pScale);
    }

    // 5. Draw Approaching Destination Planet Saturn with Atmospheric Corona & Depth Wisps
    final maxStep = math.max(kidSteps, chipSteps);
    final pr = sp.planetRectFor(maxStep / 10.0);
    _paintAtmosphericPlanet(canvas, pr);
  }

  void _drawStone(
      Canvas canvas, Offset p, bool lit, bool isLucky, double pScale) {
    final r = (isLucky ? 9.5 : 7.0) * pScale;

    // Drop shadow
    canvas.drawCircle(p + Offset(0, 1.5 * pScale), r, _stoneShadowPaint);

    if (lit) {
      // Warm glow
      final glowPaint = Paint()
        ..color = (isLucky ? GameColors.stoneLuckyGlow : GameColors.stoneLitGlow)
            .withOpacity(0.45);
      canvas.drawCircle(p, r + 4 * pScale, glowPaint);
    }

    final fill = Paint()
      ..color = lit
          ? (isLucky ? GameColors.stoneLucky : GameColors.stoneLit)
          : GameColors.stoneUnlit.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p, r, fill);

    // Top glossy highlight for 3D clay look
    if (lit) {
      canvas.drawCircle(
        p - Offset(1.2 * pScale, 1.2 * pScale),
        r * 0.42,
        _stoneHighlightPaint,
      );
    }

    if (isLucky) {
      final luckyRim = Paint()
        ..color = GameColors.stoneLuckyBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * pScale;
      canvas.drawCircle(p, r + 1.2 * pScale, luckyRim);
    }
  }

  void _paintAtmosphericPlanet(Canvas canvas, Rect pr) {
    final cx = pr.center.dx;
    final cy = pr.center.dy;
    final w = pr.width;
    final h = pr.height;

    // Outer corona
    final coronaPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        1.0,
        [
          GameColors.coronaInner.withOpacity(0.40),
          GameColors.coronaMid.withOpacity(0.20),
          GameColors.coronaOuter.withOpacity(0.06),
          GameColors.transparent,
        ],
        const [0.0, 0.42, 0.72, 1.0],
      );

    canvas.save();
    canvas.translate(cx, cy);
    final coronaR = w * 0.78;
    canvas.scale(coronaR, coronaR);
    canvas.drawPath(_unitCircle, coronaPaint);
    canvas.restore();

    // Warm ring glow
    final ringGlowPaint = Paint()
      ..color = GameColors.ringGlow.withOpacity(0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 1.15, height: h * 0.70),
      ringGlowPaint,
    );

    // Planet Image
    if (planetImage != null) {
      paintImageFitted(canvas, planetImage!, pr);
    }

    // Foreground Stardust Wisps (Bụi sao lướt qua phía trước tạo chiều sâu Z)
    final wispRect = Rect.fromCenter(
      center: Offset(cx, cy + h * 0.18),
      width: w * 1.05,
      height: 10,
    );
    final wispPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(wispRect.left, 0),
        Offset(wispRect.right, 0),
        [
          GameColors.transparent,
          GameColors.star.withOpacity(0.20),
          GameColors.ringGlow.withOpacity(0.32),
          GameColors.star.withOpacity(0.20),
          GameColors.transparent,
        ],
        const [0.0, 0.20, 0.50, 0.80, 1.0],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(wispRect, const Radius.circular(5)),
      wispPaint,
    );
  }

  @override
  bool shouldRepaint(_StarTrackPainter oldDelegate) =>
      oldDelegate.starPath != starPath ||
      oldDelegate.kidSteps != kidSteps ||
      oldDelegate.chipSteps != chipSteps ||
      oldDelegate.planetImage != planetImage;
}

class _RaceForegroundPainter extends CustomPainter {
  _RaceForegroundPainter({
    required this.state,
    required this.geometry,
    required this.starPath,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final RaceSceneState state;
  final TrackGeometry geometry;
  final StarPath starPath;

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
  static final Paint _stallPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    final sp = starPath;
    final still = s._reduceMotion;
    final t = s._clock.time;

    final shake = s._shakeOffset;
    final hasShake = shake != Offset.zero;
    if (hasShake) {
      canvas.save();
      canvas.translate(shake.dx, shake.dy);
    }

    final kid = s._kid, chip = s._chip;
    kid.pose(sp, t, still: still);
    chip.pose(sp, t, still: still);

    // Free-flight rockets (behind racer first, front racer second).
    final first = (kid.pos + kid.leadOffset) > (chip.pos + chip.leadOffset)
        ? chip
        : kid;
    final second = identical(first, kid) ? chip : kid;
    _paintRacer(canvas, first, t, still);
    _paintRacer(canvas, second, t, still);

    // Comet fly-by.
    final cp = s.cometProgress;
    if (cp != null) _paintComet(canvas, size, cp);

    if (hasShake) {
      canvas.restore();
    }

    // Edge speed lines during boost / Nitro warp.
    if (!still && s._speedLines.isActive(s._speedLinesAge)) {
      s._speedLines.paint(canvas, size, s._speedLinesAge, seed: 42);
    }
  }

  void _paintRacer(Canvas canvas, _Racer r, double t, bool still) {
    r.smoke.paint(canvas, t);
    if (!still) {
      _paintStallPuffs(canvas, r);
    }

    canvas.save();
    canvas.translate(r.baseX, r.baseY);
    canvas.rotate(r.tilt);

    // 1. Speed streaks trailing behind rocket when nitro boost
    if (!still && r.boost > 0.35) {
      _paintSpeedStreaks(canvas, r);
    }

    // 2. Multi-layer rocket flame
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

    // 3. Rocket Body & Kid Avatar in window
    final rocketImg = state._images[r.sprite.asset].value;
    final avatarImg = r.isChip
        ? null
        : state._images[state.kidAvatarAsset].value;
    RocketSprite.paintRocket(
      canvas,
      sprite: r.sprite,
      rocketImage: rocketImg,
      avatarImage: avatarImg,
      rect: Rect.fromLTWH(-r.width / 2, -r.height, r.width, r.height),
    );

    // 4. Chíp reaction bubble (pilot Chíp expressions)
    if (r.isChip && !still) {
      final isBehind = state.widget.chipSteps < state.widget.kidSteps;
      final reactionImg = state
          ._images[isBehind ? AppImages.chipSurprise : AppImages.chipJoy].value;
      if (reactionImg != null) {
        _paintChipReaction(canvas, r, isBehind, reactionImg);
      }
    }

    canvas.restore();
  }

  void _paintSpeedStreaks(Canvas canvas, _Racer r) {
    final cyanPaint = Paint()
      ..color = GameColors.nitroStreakCyan
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final whitePaint = Paint()
      ..color = GameColors.nitroStreakWhite
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final rw = r.width;
    final rh = r.height;
    // 4 fine streaks trailing behind rocket
    canvas.drawLine(
        Offset(-rw * 0.35, -rh * 0.3), Offset(-rw * 0.55, 12), cyanPaint);
    canvas.drawLine(
        Offset(rw * 0.35, -rh * 0.3), Offset(rw * 0.55, 12), cyanPaint);
    canvas.drawLine(
        Offset(-rw * 0.18, -rh * 0.18), Offset(-rw * 0.28, 20), whitePaint);
    canvas.drawLine(
        Offset(rw * 0.18, -rh * 0.18), Offset(rw * 0.28, 20), whitePaint);
  }

  void _paintChipReaction(
      Canvas canvas, _Racer r, bool isBehind, ui.Image img) {
    final bubbleCenter = Offset(r.width * 0.62, -r.height * 0.65);
    const bubbleR = 14.0;
    // Shadow
    canvas.drawCircle(bubbleCenter + const Offset(0, 1.5), bubbleR,
        Paint()..color = GameColors.cockpitShadow);
    // White backing
    canvas.drawCircle(bubbleCenter, bubbleR, Paint()..color = GameColors.star);
    // Border
    canvas.drawCircle(
      bubbleCenter,
      bubbleR,
      Paint()
        ..color = isBehind
            ? GameColors.chipReactionBehind
            : GameColors.chipReactionLead
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // Face icon
    final imgRect =
        Rect.fromCircle(center: bubbleCenter, radius: bubbleR * 0.72);
    paintImageFitted(canvas, img, imgRect);
  }

  void _paintStallPuffs(Canvas canvas, _Racer r) {
    for (final p in r._stallPuffs) {
      final prog = (p.age / p.life).clamp(0.0, 1.0);
      final alpha = ((1.0 - prog) * 0.65).clamp(0.0, 1.0);
      final size = p.startSize + (p.endSize - p.startSize) * prog;
      _stallPaint.color = p.color.withOpacity(alpha);
      canvas.drawCircle(Offset(p.x, p.y), size, _stallPaint);
    }
  }

  void _paintComet(Canvas canvas, Size size, double p) {
    final sp = starPath;
    final u = sp.u;
    final x = size.width * (1.12 - 1.24 * p);
    final y = sp.saturnY + 28 * u + 36 * u * math.sin(p * math.pi * 0.65);
    const angle = -0.26;
    final fade = p < 0.1
        ? p / 0.1
        : p > 0.85
            ? (1 - p) / 0.15
            : 1.0;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    if (fade < 1) {
      canvas.saveLayer(
        Rect.fromLTRB(-90 * u, -45 * u, 210 * u, 45 * u),
        Paint()..color = GameColors.star.withOpacity(fade),
      );
    }
    canvas.save();
    canvas.scale(155 * u, 22 * u);
    canvas.drawPath(_streak, _streakPaint);
    canvas.restore();

    final img = state._images[AppImages.comet].value;
    if (img != null) {
      final head = 82 * u;
      paintImageFitted(
          canvas, img, Rect.fromLTWH(-head * 0.28, -head * 0.55, head, head));
    }
    if (fade < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaceForegroundPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.starPath != starPath ||
      oldDelegate.state != state;
}
