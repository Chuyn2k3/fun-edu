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

/// Free-flight space chase race scene:
/// Both rockets fly side-by-side in deep scrolling space at a large foreground
/// scale. The camera follows the child's rocket while Chíp and upcoming lucky
/// stars move relative to the child's progress, the destination planet grows as
/// the finish approaches, and a compact vertical progress bar sits on the right.
///
/// Layers, back to front, each in its own [RepaintBoundary]:
/// 1. Deep space gradient (static),
/// 2. Multi-layer scrolling universe: nebulae, stars, warp streaks (moving),
/// 3. Approaching planet, lucky stars, rockets, flames, smoke, comet, speed
///    lines, mini progress bar and upper overtake banner (moving).
/// One [Ticker] drives a [SceneClock]; moving layers repaint without rebuilding
/// widgets. With reduce motion the ticker never runs.
class RaceScene extends StatefulWidget {
  const RaceScene({
    super.key,
    required this.kidSteps,
    required this.chipSteps,
    required this.kidRocket,
    required this.kidTrail,
    required this.boosting,
    required this.won,
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
    final g = _geometry ??
        TrackGeometry(const Size(390, 480),
            lanes: widget.lanes, bottomInset: widget.bottomInset);
    return g.relativeBasePoint(
      milestone / RaceScene.steps,
      _kid.pos,
      0,
      clampToFlight: false,
    );
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
        _chip.wobble();
        _overtakeAge = 0.0;
      }
    }
    _kidWasAhead = kidAhead;

    final g = _geometry;
    if (g != null) {
      _kid.emitSmoke(dt, g, t, anchorPos: _kid.pos);
      _chip.emitSmoke(dt, g, t, anchorPos: _kid.pos);
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
    final g = _geometry;
    if (g == null) return;
    for (final r in [_kid, _chip]) {
      r.smoke.clear();
      r.clearStallSmoke();
      for (var i = 0; i < 60; i++) {
        r.emitSmoke(1 / 60, g, 0, anchorPos: _kid.pos);
      }
    }
  }

  void _setGeometry(TrackGeometry g) {
    if (g == _geometry) return;
    _geometry = g;
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
                      GameColors.spaceTop,
                      GameColors.spaceMid,
                      GameColors.spaceBottom,
                    ],
                    stops: [0.0, 0.52, 1.0],
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
                painter: _RaceForegroundPainter(
                  state: this,
                  geometry: g,
                  repaint: Listenable.merge([
                    _clock,
                    _images[_kid.sprite.asset],
                    _images[_chip.sprite.asset],
                    _images[AppImages.planet],
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

  // Slightly under-damped spring (ζ 0.75): settles in ~450 ms with a ~3 %
  // overshoot, so a rocket surges and settles like real thrust.
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

  /// Balanced flame intensity: 1.0 cruising, up to ~1.55 on boost, briefly
  /// dipped to ~0.55 while stalled or rocked by overtake turbulence.
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

  // Per-frame pose (computed in [pose], read by the painter).
  double baseX = 0, baseY = 0, width = 0, height = 0, tilt = 0;

  Rect get rect => Rect.fromLTWH(-width / 2, -height, width, height);
  Offset get center => Offset(0, -height / 2);
  double get top => -height;

  void pose(
    TrackGeometry g,
    double t, {
    required bool still,
    double? anchorPos,
  }) {
    final effectivePos = (pos + leadOffset).clamp(0.0, 1.0);
    final b = anchorPos != null
        ? g.relativeBasePoint(effectivePos, anchorPos, lane)
        : g.basePoint(effectivePos, lane);
    width = g.rocketWidth(effectivePos);
    height = width * sprite.aspect;
    tilt = g.laneTilt(lane);
    baseX = b.dx;
    baseY = b.dy;
    if (still) return;

    final u = g.u;
    final moving = math.min(1.0, vel.abs() * 2.5);
    // Gentle space hover bob, subtle boost punch forward (after 80ms
    // anticipation dip), and engine rumble.
    baseY += 2.6 * u * math.sin(t * 2 * math.pi * 0.85 + seed);
    if (!isChip && boost > 0 && _anticipationAge >= 0.08) {
      baseY -= 20.0 * u * boost;
    }
    baseX += (0.45 + 1.0 * moving) * u * math.sin(t * 36 + seed);
    tilt += 0.025 * math.sin(t * 2.1 + seed) +
        0.032 * moving * math.sin(t * 20 + seed);

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

  /// Nozzle in scene space for the current pose.
  Offset nozzle() {
    final d = -height * (1 - sprite.nozzle);
    return Offset(baseX - d * math.sin(tilt), baseY + d * math.cos(tilt));
  }

  /// Compact, natural flame proportions balanced against the rocket body.
  double get flameWidth => width * 0.44;
  double get flameLength => width * 0.96;

  void emitSmoke(
    double dt,
    TrackGeometry g,
    double t, {
    double? anchorPos,
  }) {
    pose(g, t, still: false, anchorPos: anchorPos);
    final n = nozzle();
    final reach = flameLength * intensity * 0.78;
    smoke.update(
      dt,
      emitX: n.dx - reach * math.sin(tilt),
      emitY: n.dy + reach * math.cos(tilt),
      unit: g.u * width / (84 * g.u),
      intensity: intensity,
    );

    if (isStalled) {
      _emitStallPuffs(dt, n, g.u);
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

class _RaceForegroundPainter extends CustomPainter {
  _RaceForegroundPainter({
    required this.state,
    required this.geometry,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final RaceSceneState state;
  final TrackGeometry geometry;

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
  static final Paint _stallPaint = Paint();

  // Cached unit halo for the approaching planet (0 per-frame allocation).
  static final Path _unitCircle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1));
  static final Paint _planetHaloPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset.zero,
      1,
      [
        GameColors.planetHalo.withOpacity(0.34),
        GameColors.planetHalo.withOpacity(0.11),
        GameColors.planetHalo.withOpacity(0),
      ],
      const [0.0, 0.55, 1.0],
    );

  // Cached paints for mini vertical progress bar.
  static final Paint _barFillPaint = Paint()
    ..color = GameColors.progressTrack.withOpacity(0.68);
  static final Paint _barBorderPaint = Paint()
    ..color = GameColors.progressBorder.withOpacity(0.45)
    ..style = PaintingStyle.stroke;
  static final Paint _barProgressFill = Paint()
    ..color = GameColors.progressKid.withOpacity(0.45);
  static final Paint _kidDotFill = Paint()..color = GameColors.progressKid;
  static final Paint _kidDotRing = Paint()
    ..color = GameColors.star
    ..style = PaintingStyle.stroke;
  static final Paint _chipDotFill = Paint()..color = GameColors.progressChip;
  static final Paint _chipDotRing = Paint()
    ..color = GameColors.progressChipRing
    ..style = PaintingStyle.stroke;
  static final Paint _miniPlanetBody = Paint()..color = GameColors.planetHalo;
  static final Paint _miniPlanetRing = Paint()
    ..color = GameColors.laneLine
    ..style = PaintingStyle.stroke;

  // Cached paints for lucky stars.
  static final Paint _starGlowPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset.zero,
      1,
      [
        GameColors.planetHalo.withOpacity(0.55),
        GameColors.planetHalo.withOpacity(0.15),
        GameColors.planetHalo.withOpacity(0),
      ],
      const [0.0, 0.55, 1.0],
    );
  static final Paint _starFillPaint = Paint()..color = GameColors.flameOuter;
  static final Paint _starCorePaint = Paint()..color = GameColors.starWarm;

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    final g = geometry;
    final still = s._reduceMotion;
    final t = s._clock.time;

    final shake = s._shakeOffset;
    final hasShake = shake != Offset.zero;
    if (hasShake) {
      canvas.save();
      canvas.translate(shake.dx, shake.dy);
    }

    final kid = s._kid, chip = s._chip;
    kid.pose(g, t, still: still, anchorPos: kid.pos);
    chip.pose(g, t, still: still, anchorPos: kid.pos);

    // 1. Approaching destination planet (Saturn) growing as the race progresses.
    _paintApproachingPlanet(canvas, g, math.max(kid.pos, chip.pos));

    // 2. Approaching lucky stars at milestones 4 and 8 on kid's flight line.
    _paintLuckyStars(canvas, g, kid.pos, t, still);

    // 3. Free-flight rockets (behind racer first, front racer second).
    final first = (kid.pos + kid.leadOffset) > (chip.pos + chip.leadOffset)
        ? chip
        : kid;
    final second = identical(first, kid) ? chip : kid;
    _paintRacer(canvas, first, t, still);
    _paintRacer(canvas, second, t, still);

    // 4. Comet fly-by.
    final cp = s.cometProgress;
    if (cp != null) _paintComet(canvas, size, cp);

    if (hasShake) {
      canvas.restore();
    }

    // 5. Edge speed lines during boost / Nitro warp.
    if (!still && s._speedLines.isActive(s._speedLinesAge)) {
      s._speedLines.paint(canvas, size, s._speedLinesAge, seed: 42);
    }

    // 6. Compact right-edge mini space progress bar.
    _paintMiniProgressBar(canvas, g, kid.pos, chip.pos);

    // 7. Upper clear-space "VƯỢT LÊN!" banner (never overlaps rockets).
    if (!still && s._overtakeAge < RaceSceneState._overtakeDuration) {
      _paintOvertakeBanner(canvas, s._overtakeAge, g);
    }
  }

  void _paintApproachingPlanet(
      Canvas canvas, TrackGeometry g, double progress) {
    final pr = g.planetRectFor(progress);
    final haloR = pr.width * 0.72;
    canvas.save();
    canvas.translate(pr.center.dx, pr.center.dy);
    canvas.scale(haloR, haloR);
    canvas.drawPath(_unitCircle, _planetHaloPaint);
    canvas.restore();

    final img = state._images[AppImages.planet].value;
    if (img != null) {
      paintImageFitted(canvas, img, pr);
    }
  }

  void _paintOvertakeBanner(Canvas canvas, double age, TrackGeometry g) {
    final progress = (age / RaceSceneState._overtakeDuration).clamp(0.0, 1.0);
    final alpha = (1.0 - math.pow(progress, 3)).clamp(0.0, 1.0).toDouble();
    if (alpha <= 0.0) return;
    final scale =
        (0.88 + 0.18 * math.sin(progress * math.pi)).clamp(0.88, 1.06);

    final pos = g.bannerCenter;
    final tp = TextPainter(
      text: TextSpan(
        text: 'VƯỢT LÊN!',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: (17 * g.u).clamp(15.0, 26.0),
          color: GameColors.star.withOpacity(alpha),
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = tp.width + 24 * g.u;
    final pillHeight = tp.height + 10 * g.u;
    final pillRect = Rect.fromCenter(
      center: Offset.zero,
      width: pillWidth,
      height: pillHeight,
    );
    final rrect =
        RRect.fromRectAndRadius(pillRect, Radius.circular(pillHeight / 2));

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, pillRect.top),
        Offset(0, pillRect.bottom),
        [
          GameColors.overtakeBannerTop.withOpacity(alpha),
          GameColors.overtakeBannerBottom.withOpacity(alpha),
        ],
      );
    canvas.drawRRect(rrect, fillPaint);

    final borderPaint = Paint()
      ..color = GameColors.star.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * g.u;
    canvas.drawRRect(rrect, borderPaint);

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
    tp.dispose();
  }

  void _paintRacer(Canvas canvas, _Racer r, double t, bool still) {
    r.smoke.paint(canvas, t);
    if (!still) {
      _paintStallPuffs(canvas, r);
    }

    canvas.save();
    canvas.translate(r.baseX, r.baseY);
    canvas.rotate(r.tilt);
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
    canvas.restore();
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

  void _paintLuckyStars(
    Canvas canvas,
    TrackGeometry g,
    double kidPos,
    double t,
    bool still,
  ) {
    final u = g.u;
    for (final milestone in RaceSceneState.luckyStarMilestones) {
      if (state.widget.kidSteps >= milestone) continue;
      final pt = g.relativeBasePoint(
        milestone / RaceScene.steps,
        kidPos,
        0,
        clampToFlight: false,
      );
      final bob = still ? 0.0 : math.sin(t * 3.2 + milestone) * 3.5 * u;
      final pulse = still ? 1.0 : (0.94 + 0.08 * math.sin(t * 5.0 + milestone));
      final center = Offset(pt.dx, pt.dy - g.rocketW * 0.55 + bob);
      if (center.dy < g.topSafeY + 14 * u || center.dy > g.bottomSafeY) {
        continue;
      }
      final outerR = 13.5 * u * pulse;
      final innerR = outerR * 0.46;

      // Radial golden glow (zero blur allocation).
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(outerR * 1.9, outerR * 1.9);
      canvas.drawPath(_unitCircle, _starGlowPaint);
      canvas.restore();

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
      canvas.drawPath(starPath, _starFillPaint);
      canvas.drawCircle(center, innerR * 0.55, _starCorePaint);
    }
  }

  void _paintMiniProgressBar(
    Canvas canvas,
    TrackGeometry g,
    double kidPos,
    double chipPos,
  ) {
    final bar = g.progressBarRect;
    final u = g.u;
    final radius = Radius.circular(bar.width / 2);
    final rrect = RRect.fromRectAndRadius(bar, radius);

    // Track capsule background & subtle border.
    canvas.drawRRect(rrect, _barFillPaint);
    _barBorderPaint.strokeWidth = (1.2 * u).clamp(1.0, 2.0);
    canvas.drawRRect(rrect, _barBorderPaint);

    // Filled progress trail up to kid's position.
    final kFrac = kidPos.clamp(0.0, 1.0);
    final cFrac = chipPos.clamp(0.0, 1.0);
    final kidY = bar.bottom - bar.height * kFrac;
    final chipY = bar.bottom - bar.height * cFrac;
    if (kFrac > 0.01) {
      final fillRect = Rect.fromLTRB(bar.left, kidY, bar.right, bar.bottom);
      canvas.drawRRect(
          RRect.fromRectAndRadius(fillRect, radius), _barProgressFill);
    }

    // Mini Saturn goal emblem at top of bar.
    final capCenter = Offset(bar.center.dx, bar.top - 9 * u);
    final capR = (5.2 * u).clamp(4.0, 7.5);
    canvas.drawCircle(capCenter, capR, _miniPlanetBody);
    _miniPlanetRing.strokeWidth = (1.6 * u).clamp(1.2, 2.2);
    canvas.save();
    canvas.translate(capCenter.dx, capCenter.dy);
    canvas.rotate(-0.28);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: capR * 3.0, height: capR * 0.9),
      _miniPlanetRing,
    );
    canvas.restore();

    // Chíp marker (white dot with coral ring).
    final dotR = (5.2 * u).clamp(4.2, 7.5);
    _chipDotRing.strokeWidth = (2.0 * u).clamp(1.5, 2.8);
    canvas.drawCircle(Offset(bar.center.dx, chipY), dotR, _chipDotFill);
    canvas.drawCircle(Offset(bar.center.dx, chipY), dotR, _chipDotRing);

    // Kid marker (bright orange dot with crisp white ring, drawn on top).
    final kidDotR = dotR * 1.12;
    _kidDotRing.strokeWidth = (2.2 * u).clamp(1.6, 3.0);
    canvas.drawCircle(Offset(bar.center.dx, kidY), kidDotR, _kidDotFill);
    canvas.drawCircle(Offset(bar.center.dx, kidY), kidDotR, _kidDotRing);
  }

  void _paintComet(Canvas canvas, Size size, double p) {
    final g = geometry;
    final u = g.u;
    final x = size.width * (1.12 - 1.24 * p);
    final y = g.topSafeY + 28 * u + 36 * u * math.sin(p * math.pi * 0.65);
    final angle = -0.26;
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
      oldDelegate.geometry != geometry || oldDelegate.state != state;
}
