import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../game/scene/flame_painter.dart';
import '../../game/scene/rocket_sprite.dart';
import '../../game/scene/smoke_particles.dart';
import '../../game/scene/space_track.dart' show SceneClock;
import '../../game/scene/trails.dart';
import '../../ui/theme/tokens.dart';

/// The garage pedestal: the selected rocket hovering over a round 2.5D
/// pedestal, its flame and trail (Task 4's [FlameRenderer] and
/// [SmokeParticles]) running. [RocketStageState.takeOff] plays the 2 s
/// "Bay thử!" preview: the flame flares, the rocket lifts off out of the
/// top of the stage and drops back onto the pedestal.
///
/// One [Ticker] drives a [SceneClock]; the moving layer repaints from it
/// (no widget rebuild per frame) and sits in its own [RepaintBoundary]
/// above the static pedestal. With reduce motion the ticker never runs:
/// the flame is drawn still with a settled trail, and "Bay thử!" only
/// flares the flame for 2 s without moving the rocket.
class RocketStage extends StatefulWidget {
  const RocketStage({
    super.key,
    required this.rocket,
    required this.trail,
    this.onFlightChanged,
  });

  final String rocket;
  final String trail;

  /// Called with true when a take-off starts and false when it has landed.
  final ValueChanged<bool>? onFlightChanged;

  static const flight = Duration(seconds: 2);

  @override
  State<RocketStage> createState() => RocketStageState();
}

class RocketStageState extends State<RocketStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _clock = SceneClock();
  final _images = SceneImages();
  late RocketSprite _sprite = RocketSprite.forItem(widget.rocket);
  late TrailStyle _trail = TrailStyle.fromId(widget.trail);
  late final SmokeParticles _smoke = SmokeParticles(style: _trail, seed: 5);

  Duration _last = Duration.zero;
  bool _reduceMotion = false;
  double? _flightAge;
  Timer? _stillFlight;
  Size? _size;
  final _layout = _StageLayout();

  static double get _flightSeconds => RocketStage.flight.inMicroseconds / 1e6;

  /// Whether the "Bay thử!" preview is playing.
  bool get flying => _flightAge != null || _stillFlight != null;

  /// How far (logical px) the rocket is above its resting place.
  double get liftOffset {
    final size = _size;
    final a = _flightAge;
    if (size == null || a == null || _reduceMotion) return 0;
    return _lift(a, size.height);
  }

  /// Flight profile over 2 s: rumble (0–0.3 s), accelerate up and out of the
  /// stage (0.3–1.25 s), then fall back in from above and settle on the
  /// pedestal with a soft ease-out (1.25–2 s).
  static double _lift(double a, double h) {
    const rumble = 0.3, up = 1.25;
    final out = h * 1.15;
    if (a < rumble) return 0;
    if (a < up) {
      final t = (a - rumble) / (up - rumble);
      return out * t * t;
    }
    final t = ((a - up) / (_flightSeconds - up)).clamp(0.0, 1.0);
    final e = 1 - math.pow(1 - t, 3).toDouble();
    return out * (1 - e);
  }

  /// Flame intensity: idle 0.85, flares to 1.8 while lifting off, 1.3
  /// while dropping back in.
  double get _intensity {
    final a = _flightAge;
    if (_stillFlight != null) return 1.8;
    if (a == null) return 0.85;
    if (a < 0.3) return 0.85 + (1.8 - 0.85) * (a / 0.3);
    if (a < 1.25) return 1.8;
    final t = ((a - 1.25) / (_flightSeconds - 1.25)).clamp(0.0, 1.0);
    return 1.3 - 0.45 * t;
  }

  /// Plays the take-off preview (ignored while one is playing).
  void takeOff() {
    if (flying) return;
    if (_reduceMotion) {
      _stillFlight = Timer(RocketStage.flight, () {
        _stillFlight = null;
        if (!mounted) return;
        _clock.touch();
        widget.onFlightChanged?.call(false);
      });
      _clock.touch();
      widget.onFlightChanged?.call(true);
      return;
    }
    _flightAge = 0;
    widget.onFlightChanged?.call(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _images.resolve(createLocalImageConfiguration(context), [_sprite.asset]);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduceMotion || (!reduce && !_ticker.isActive)) {
      _reduceMotion = reduce;
      if (reduce) {
        _ticker.stop();
        if (_flightAge != null) {
          _flightAge = null;
          // Not during build: tell the parent after this frame.
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onFlightChanged?.call(false));
        }
        _settleSmoke();
        _clock.touch();
      } else if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    }
  }

  @override
  void didUpdateWidget(RocketStage oldWidget) {
    final old = oldWidget;
    super.didUpdateWidget(old);
    if (old.rocket != widget.rocket) {
      _sprite = RocketSprite.forItem(widget.rocket);
      _images.resolve(createLocalImageConfiguration(context), [_sprite.asset]);
    }
    if (old.trail != widget.trail) {
      _trail = TrailStyle.fromId(widget.trail);
      _smoke
        ..style = _trail
        ..clear();
      if (_reduceMotion) _settleSmoke();
    }
    _clock.touch();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stillFlight?.cancel();
    _images.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    if (dt <= 0) return;
    final a = _flightAge;
    if (a != null) {
      final next = a + dt;
      if (next >= _flightSeconds) {
        _flightAge = null;
        widget.onFlightChanged?.call(false);
      } else {
        _flightAge = next;
      }
    }
    _emit(dt, _clock.time + dt);
    _clock.advance(dt);
  }

  /// Reduce motion: lay a still trail under the rocket.
  void _settleSmoke() {
    if (_size == null) return;
    _smoke.clear();
    for (var i = 0; i < 50; i++) {
      _emit(1 / 60, 0);
    }
  }

  void _emit(double dt, double t) {
    final size = _size;
    if (size == null) return;
    final g = _layout
      ..update(size, _sprite, lift: liftOffset, time: t, still: _reduceMotion);
    final reach = g.flameLength * _intensity * 0.8;
    _smoke.update(dt,
        emitX: g.baseX,
        emitY: g.nozzleY + reach,
        unit: g.rocketW / 60,
        intensity: _intensity);
  }

  void _setSize(Size s) {
    if (s == _size) return;
    _size = s;
    _smoke.clear();
    if (_reduceMotion) _settleSmoke();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _setSize(c.biggest);
      return Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(
              child: CustomPaint(painter: _PedestalPainter())),
          RepaintBoundary(
            child: CustomPaint(
              painter: _RocketPainter(
                state: this,
                repaint: Listenable.merge([_clock, _images[_sprite.asset]]),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Where things sit in a stage of a given size. One instance is reused
/// every frame ([update]), so painting allocates nothing.
class _StageLayout {
  double pedCy = 0, pedRy = 0, rocketH = 0, rocketW = 0;
  double flameWidth = 0, flameLength = 0;

  /// Bottom centre of the rocket picture, and the nozzle.
  double baseX = 0, baseY = 0, nozzleY = 0;

  void update(Size size, RocketSprite sprite,
      {required double lift, required double time, required bool still}) {
    final w = size.width, h = size.height;
    pedCy = h * 0.84;
    final pedRx = math.min(w * 0.34, h * 0.42);
    pedRy = pedRx * 0.17;
    rocketH = math.min(h * 0.46, w * 0.42 * sprite.aspect);
    rocketW = rocketH / sprite.aspect;
    final hover = still ? 0.0 : 3 * math.sin(time * 2 * math.pi / 1.6);
    baseX = w / 2;
    baseY = pedCy - pedRy * 2.6 - hover - lift;
    nozzleY = baseY - rocketH * (1 - sprite.nozzle);
    flameWidth = rocketW * 0.6;
    flameLength = rocketW * 1.1;
  }
}

class _PedestalPainter extends CustomPainter {
  const _PedestalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * 0.84);
    final rx = math.min(w * 0.34, h * 0.42);
    final ry = rx * 0.17;
    final side = ry * 0.9;
    // Side band, then the top face, a rim and a soft spot under the rocket.
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(0, side), width: rx * 2, height: ry * 2),
        Paint()..color = GameColors.trackSide);
    canvas.drawRect(Rect.fromLTRB(c.dx - rx, c.dy, c.dx + rx, c.dy + side),
        Paint()..color = GameColors.trackSide);
    canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameColors.trackTie, GameColors.track],
          ).createShader(
              Rect.fromCenter(center: c, width: rx * 2, height: ry * 2)));
    canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, ry * 0.12)
          ..color = GameColors.laneLine);
    canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 1.1, height: ry * 1.0),
        Paint()..color = GameColors.rocketShadow.withOpacity(0.45));
  }

  @override
  bool shouldRepaint(_PedestalPainter old) => false;
}

class _RocketPainter extends CustomPainter {
  _RocketPainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  final RocketStageState state;

  static final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    final still = s._reduceMotion;
    final t = s._clock.time;
    final g = s._layout
      ..update(size, s._sprite, lift: s.liftOffset, time: t, still: still);
    // A little rumble right before lift-off.
    final a = s._flightAge;
    final shake =
        a != null && a < 0.3 ? 1.6 * math.sin(a * 2 * math.pi * 18) : 0.0;

    s._smoke.paint(canvas, t);
    canvas.save();
    canvas.translate(shake, 0);
    FlameRenderer.paint(
      canvas,
      nozzle: Offset(g.baseX, g.nozzleY),
      width: g.flameWidth,
      length: g.flameLength,
      time: still ? 0 : t,
      intensity: s._intensity,
      palette: s._trail.palette,
      seed: 1.3,
    );
    final img = s._images[s._sprite.asset].value;
    if (img != null) {
      canvas.save();
      canvas.translate(g.baseX - g.rocketW / 2, g.baseY - g.rocketH);
      canvas.scale(g.rocketW / img.width, g.rocketH / img.height);
      canvas.drawImage(img, Offset.zero, _imagePaint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RocketPainter old) => old.state != state;
}
