import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../profile/avatars.dart' show kidAvatars;
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import 'flame_painter.dart';
import 'rocket_sprite.dart';
import 'smoke_particles.dart';
import 'space_track.dart';
import 'speed_lines.dart';
import 'sticker_fx.dart';
import 'trails.dart';

/// One racer in the online "whole pack flies together" race scene.
@immutable
class OnlineRacer {
  const OnlineRacer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rocket,
    required this.steps,
    this.rank,
    this.me = false,
    this.away = false,
  });

  final String id;
  final String name;
  final String avatar;
  final String rocket;
  final int steps;
  final int? rank;
  final bool me;
  final bool away;
}

/// Room join-order rocket items (orange, blue, green, purple).
const List<String> roomRocketIds = [
  'rocket_orange',
  'rocket_blue',
  'rocket_green',
  'rocket_purple',
];

String roomRocketForIndex(int index) =>
    roomRocketIds[index % roomRocketIds.length];

String safeOnlineAvatar(String avatar, int index) =>
    kidAvatars.contains(avatar)
        ? avatar
        : kidAvatars[index % kidAvatars.length];

/// Horizontal lane spreading and relative vertical positioning for 1..4 online
/// racers flying together in open space.
abstract final class OnlineRaceLayout {
  static double _xFraction(int index, int count) {
    if (count <= 1) return 0.50;
    final i = index.clamp(0, count - 1);
    return switch (count) {
      2 => i == 0 ? 0.33 : 0.67,
      3 => switch (i) { 0 => 0.20, 1 => 0.50, _ => 0.80 },
      4 => switch (i) { 0 => 0.15, 1 => 0.38, 2 => 0.62, _ => 0.85 },
      _ => (i + 0.5) / count,
    };
  }

  static Offset rocketCenter({
    required Size area,
    required int index,
    required int count,
    required double steps,
    required double leaderSteps,
  }) {
    final x = area.width * _xFraction(index, count);
    final behind = math.max(0.0, leaderSteps - steps);
    final y = math.min(
      area.height * 0.82,
      area.height * 0.28 + behind * area.height * 0.045,
    );
    return Offset(x, y);
  }
}

/// Caches one [ui.ImageShader] per decoded [ui.Image] so circular cockpit
/// portholes never allocate shaders on animation frames.
class AvatarShaderCache {
  final Map<ui.Image, ui.ImageShader> _shaders = {};

  @visibleForTesting
  int get cachedCount => _shaders.length;

  ui.ImageShader shaderFor(ui.Image image) {
    final existing = _shaders[image];
    if (existing != null) return existing;
    final s = 2.0 / math.min(image.width, image.height);
    final tx = -image.width * s * 0.5;
    final ty = -image.height * s * 0.5;
    final shader = ui.ImageShader(
      image,
      ui.TileMode.clamp,
      ui.TileMode.clamp,
      Float64List.fromList([
        s, 0, 0, 0,
        0, s, 0, 0,
        0, 0, 1, 0,
        tx, ty, 0, 1,
      ]),
    );
    _shaders[image] = shader;
    return shader;
  }

  void dispose() {
    for (final s in _shaders.values) {
      s.dispose();
    }
    _shaders.clear();
  }
}

/// Caches laid-out [TextPainter] instances so name/rank labels never allocate
/// paragraphs during animation frames.
class OnlineLabelCache {
  final Map<(String, int, double), TextPainter> _cache = {};

  Iterable<String> get cachedTexts => _cache.keys.map((k) => k.$1);

  TextPainter get(String text, Color color, double fontSize) {
    final key = (text, color.value, fontSize);
    return _cache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      return tp;
    });
  }

  void dispose() {
    for (final tp in _cache.values) {
      tp.dispose();
    }
    _cache.clear();
  }
}

/// Mutable per-frame effect values updated in `RaceSceneState._onTick` so
/// [OnlineRacePainter] reads live motion without rebuilding widgets.
class OnlineRaceEffects extends ChangeNotifier {
  final Map<String, double> displayedSteps = {};
  double? cometProgress;
  double speedLinesAge = double.infinity;
  Offset shakeOffset = Offset.zero;
  String? overtakeBanner;
  bool isPositiveOvertake = true;
  bool superSpeed = false;
  int comboStreak = 0;
  int? starGateStage;
  String? starGateLeader;
  double starGateAge = 0.0;

  void notify() => notifyListeners();
}

/// Paints all online racers flying together on one shared canvas without
/// `Opacity`, `saveLayer`, `BackdropFilter`, or per-frame allocations.
class OnlineRacePainter extends CustomPainter {
  OnlineRacePainter({
    required this.racers,
    this.displayedSteps,
    this.effects,
    this.images,
    required AvatarShaderCache shaderCache,
    required OnlineLabelCache labelCache,
    this.smokes,
    this.stickerFx,
    this.clock,
    this.reduceMotion = false,
    this.bottomInset = 0,
    this.cometProgress,
    this.speedLines,
    this.speedLinesAge = double.infinity,
    this.shakeOffset = Offset.zero,
    this.superSpeed = false,
    this.comboStreak = 0,
    this.starGateStage,
    this.starGateLeader,
    this.overtakeBanner,
    this.isPositiveOvertake = true,
    Listenable? repaint,
  })  : _shaders = shaderCache,
        _labels = labelCache,
        super(repaint: repaint ?? clock);

  final List<OnlineRacer> racers;
  final Map<String, double>? displayedSteps;
  final OnlineRaceEffects? effects;
  final SceneImages? images;
  final AvatarShaderCache _shaders;
  final OnlineLabelCache _labels;
  final Map<String, SmokeParticles>? smokes;
  final StickerFx? stickerFx;
  final SceneClock? clock;
  final bool reduceMotion;
  final double bottomInset;
  final double? cometProgress;
  final SpeedLines? speedLines;
  final double speedLinesAge;
  final Offset shakeOffset;
  final bool superSpeed;
  final int comboStreak;
  final int? starGateStage;
  final String? starGateLeader;
  final String? overtakeBanner;
  final bool isPositiveOvertake;

  static final Path _unitCircle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1.0));
  static final Paint _gateGlowPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset.zero,
      1.0,
      [
        GameColors.ringGlow.withOpacity(0.55),
        GameColors.coronaInner.withOpacity(0.28),
        GameColors.coronaMid.withOpacity(0.08),
        GameColors.transparent,
      ],
      const [0.0, 0.40, 0.72, 1.0],
    );

  final Paint _normalImagePaint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _dimmedImagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..color = GameColors.star.withOpacity(0.4);
  final Paint _avatarPaint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _streakPaint = Paint()..strokeCap = StrokeCap.round;

  // Scratch buffers reused across frames so paint() allocates zero lists/closures.
  final List<int> _orderScratch = [];
  final List<int> _sortedScratch = [];
  final List<int> _ranksScratch = [];

  double _stepsOf(OnlineRacer r) =>
      effects?.displayedSteps[r.id] ??
      displayedSteps?[r.id] ??
      r.steps.toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    if (racers.isEmpty || size.isEmpty) return;

    final t = clock?.time ?? 0.0;
    final availH = math.max(120.0, size.height - bottomInset);
    final area = Size(size.width, availH);
    final u = math.min(size.width / 390.0, availH / 520.0).clamp(0.72, 1.5);
    final count = racers.length;

    final liveShake = effects?.shakeOffset ?? shakeOffset;
    final hasShake = !reduceMotion && liveShake != Offset.zero;
    if (hasShake) {
      canvas.save();
      canvas.translate(liveShake.dx, liveShake.dy);
    }

    // Leader steps across interpolated positions so vertical transitions stay smooth.
    var leaderSteps = 0.0;
    for (final r in racers) {
      final s = _stepsOf(r);
      if (s > leaderSteps) leaderSteps = s;
    }

    // Compute live rank (finished rank takes precedence over step rank).
    final liveRanks = _computeRanks(racers);

    // Draw back-to-front (trailing racers first, leader on top) via insertion sort.
    _prepareIndices(_orderScratch, count);
    for (var i = 1; i < count; i++) {
      final key = _orderScratch[i];
      final keySteps = _stepsOf(racers[key]);
      var j = i - 1;
      while (j >= 0 && _stepsOf(racers[_orderScratch[j]]) > keySteps) {
        _orderScratch[j + 1] = _orderScratch[j];
        j--;
      }
      _orderScratch[j + 1] = key;
    }

    final rocketW = math
        .min(72.0 * u, size.width / math.max(2, count) * 0.62)
        .clamp(42.0, 88.0);

    final liveSuperSpeed = effects?.superSpeed ?? superSpeed;
    final liveComboStreak = effects?.comboStreak ?? comboStreak;
    final liveStarGateStage = effects?.starGateStage ?? starGateStage;
    final liveStarGateLeader = effects?.starGateLeader ?? starGateLeader;
    final liveStarGateAge = effects?.starGateAge ?? 0.0;
    final liveOvertake = effects?.overtakeBanner ?? overtakeBanner;
    final livePositiveOvertake =
        effects?.isPositiveOvertake ?? isPositiveOvertake;

    for (var pos = 0; pos < count; pos++) {
      final idx = _orderScratch[pos];
      final r = racers[idx];
      final s = _stepsOf(r);
      final center = OnlineRaceLayout.rocketCenter(
        area: area,
        index: idx,
        count: count,
        steps: s,
        leaderSteps: leaderSteps,
      );
      _paintRacer(
        canvas,
        racer: r,
        index: idx,
        center: center,
        rocketW: rocketW,
        u: u,
        time: t,
        rank: liveRanks[idx],
        isLeader: (s - leaderSteps).abs() < 0.05 && leaderSteps > 0,
        superBoost: r.me && liveSuperSpeed,
      );
    }

    // Comet fly-by (no saveLayer: fade image directly via paint color alpha).
    final cp = effects?.cometProgress ?? cometProgress;
    if (cp != null) {
      _paintComet(canvas, area, u, cp);
    }

    if (hasShake) {
      canvas.restore();
    }

    // Edge speed lines during boost / Super Speed.
    final sl = speedLines;
    final slAge = effects?.speedLinesAge ?? speedLinesAge;
    if (!reduceMotion && sl != null && sl.isActive(slAge)) {
      sl.paint(canvas, size, slAge, seed: 42);
    }

    // Moment banners (Star Gate, Super Speed, Overtakes) painted directly on canvas.
    if (liveStarGateStage != null) {
      var leaderName = liveStarGateLeader ?? '';
      if (leaderName.isEmpty) {
        for (var i = 0; i < count; i++) {
          if (liveRanks[i] == 1) {
            leaderName = racers[i].name.isEmpty ? 'Bạn ${i + 1}' : racers[i].name;
            break;
          }
        }
      }
      _paintStarGate(
        canvas,
        area,
        u,
        liveStarGateStage,
        leaderName,
        reduceMotion ? 0.0 : liveStarGateAge,
      );
    }
    final showSuperBanner = liveSuperSpeed && liveComboStreak >= 3;
    if (showSuperBanner) {
      _paintSuperSpeedBanner(canvas, area, u, liveComboStreak);
    }
    if (liveOvertake != null) {
      _paintOvertakeBanner(
        canvas,
        area,
        u,
        liveOvertake,
        positive: livePositiveOvertake,
        belowSuper: showSuperBanner,
      );
    }

    // Stickers, particles, and speech bubbles are strictly clipped above the
    // question panel so they never paint over HUD controls.
    final fx = stickerFx;
    final clipH = math.max(0.0, size.height - bottomInset);
    if (fx != null && clipH > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipH));
      fx.paint(
        canvas,
        Size(size.width, clipH),
        imageLookup: fx.imageLookup == null && images != null
            ? (path) => images![path].value
            : null,
        labelCache: _labels,
        reduceMotion: reduceMotion,
      );
      canvas.restore();
    }
  }

  /// Computes live 1-based ranks matching [OnlineRacePainter] ordering.
  static Map<String, int> computeRanksMap(List<OnlineRacer> list) {
    final count = list.length;
    final sorted = List<int>.generate(count, (i) => i)
      ..sort((a, b) => _compareRacerOrder(list, a, b));
    final out = <String, int>{};
    for (var pos = 0; pos < count; pos++) {
      final r = list[sorted[pos]];
      out[r.id] = r.rank ?? (pos + 1);
    }
    return out;
  }

  static void _prepareIndices(List<int> buf, int count) {
    if (buf.length != count) {
      buf.clear();
      for (var i = 0; i < count; i++) {
        buf.add(i);
      }
    } else {
      for (var i = 0; i < count; i++) {
        buf[i] = i;
      }
    }
  }

  static int _compareRacerOrder(List<OnlineRacer> list, int a, int b) {
    final ra = list[a].rank;
    final rb = list[b].rank;
    if (ra != null && rb != null) return ra.compareTo(rb);
    if (ra != null) return -1;
    if (rb != null) return 1;
    final stepCmp = list[b].steps.compareTo(list[a].steps);
    // Ties fall back to join order so each racer displays a unique badge.
    return stepCmp != 0 ? stepCmp : a.compareTo(b);
  }

  List<int> _computeRanks(List<OnlineRacer> list) {
    final count = list.length;
    _prepareIndices(_sortedScratch, count);
    for (var i = 1; i < count; i++) {
      final key = _sortedScratch[i];
      var j = i - 1;
      while (j >= 0 && _compareRacerOrder(list, _sortedScratch[j], key) > 0) {
        _sortedScratch[j + 1] = _sortedScratch[j];
        j--;
      }
      _sortedScratch[j + 1] = key;
    }
    if (_ranksScratch.length != count) {
      _ranksScratch
        ..clear()
        ..addAll(List<int>.filled(count, 1));
    }
    for (var pos = 0; pos < count; pos++) {
      final i = _sortedScratch[pos];
      _ranksScratch[i] = list[i].rank ?? (pos + 1);
    }
    return _ranksScratch;
  }

  void _paintRacer(
    Canvas canvas, {
    required OnlineRacer racer,
    required int index,
    required Offset center,
    required double rocketW,
    required double u,
    required double time,
    required int rank,
    required bool isLeader,
    bool superBoost = false,
  }) {
    final rocketId = racer.rocket.isNotEmpty
        ? racer.rocket
        : roomRocketForIndex(index);
    final sprite = RocketSprite.forItem(rocketId);
    final rocketH = rocketW * sprite.aspect;
    final alpha = racer.away ? 0.4 : 1.0;

    final bobY = (reduceMotion || racer.away)
        ? 0.0
        : 2.2 * u * math.sin(time * 2 * math.pi * 0.85 + index * 1.7);
    final tilt = (reduceMotion || racer.away)
        ? 0.0
        : 0.018 * math.sin(time * 2.1 + index * 1.7);

    // Smoke trail behind active racers.
    if (!racer.away) {
      smokes?[racer.id]?.paint(canvas, time);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy + bobY);
    canvas.rotate(tilt);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: rocketW,
      height: rocketH,
    );

    // 1. Exhaust flame (blue super boost when comboStreak >= 3; away racers idle).
    if (!racer.away) {
      if (superBoost) {
        _paintSuperSpeedStreaks(canvas, rocketW, rocketH, u);
      }
      FlameRenderer.paint(
        canvas,
        nozzle: Offset(0, rocketH * (sprite.nozzle - 0.5)),
        width: rocketW * (superBoost ? 0.52 : 0.44),
        length: rocketW * (superBoost ? 1.15 : 0.88),
        time: reduceMotion ? 0 : time,
        intensity: superBoost ? 1.45 : (isLeader ? 1.18 : 1.0),
        palette: superBoost ? FlamePalette.blue : FlamePalette.classic,
        seed: index * 1.7,
      );
    }

    // 2. Rocket body (with 0.4 alpha when away, no saveLayer).
    final rocketImg = images?[sprite.asset].value;
    if (rocketImg != null) {
      paintImageFitted(
        canvas,
        rocketImg,
        rect,
        racer.away ? _dimmedImagePaint : _normalImagePaint,
      );
    }

    // 3. Cockpit porthole with circular-clipped avatar via cached ImageShader.
    final winX = rect.left + rect.width * sprite.windowCenter.dx;
    final winY = rect.top + rect.height * sprite.windowCenter.dy;
    final winR = rect.width * 0.165;

    _fillPaint.color = GameColors.windowBezelDark.withOpacity(alpha);
    canvas.drawCircle(Offset(winX, winY), winR, _fillPaint);

    final avatarAsset = safeOnlineAvatar(racer.avatar, index);
    final avatarImg = images?[avatarAsset].value;
    if (avatarImg != null) {
      final shader = _shaders.shaderFor(avatarImg);
      _avatarPaint
        ..shader = shader
        ..color = GameColors.star.withOpacity(alpha);
      canvas.save();
      canvas.translate(winX, winY);
      canvas.scale(winR, winR);
      canvas.drawCircle(Offset.zero, 1.0, _avatarPaint);
      canvas.restore();
    }

    // 4. Porthole bezel + gold ring for `me`.
    if (racer.me) {
      _strokePaint
        ..color = GameColors.ringGlow.withOpacity(0.85 * alpha)
        ..strokeWidth = math.max(2.6, rocketW * 0.052);
      canvas.drawCircle(
        Offset(winX, winY),
        winR + _strokePaint.strokeWidth * 0.6,
        _strokePaint,
      );
      _strokePaint
        ..color = GameColors.cometRim.withOpacity(alpha)
        ..strokeWidth = math.max(1.8, rocketW * 0.032);
      canvas.drawCircle(Offset(winX, winY), winR, _strokePaint);
    } else {
      _strokePaint
        ..color = GameColors.windowBezel.withOpacity(alpha)
        ..strokeWidth = math.max(1.3, rocketW * 0.025);
      canvas.drawCircle(Offset(winX, winY), winR, _strokePaint);
    }

    canvas.restore();

    // 5. Rank badge (top-right of rocket, upright).
    final badgeCenter = Offset(
      center.dx + rocketW * 0.40,
      center.dy - rocketH * 0.36 + bobY,
    );
    final badgeR = (11.5 * u).clamp(10.0, 15.0);
    _fillPaint.color =
        (rank == 1 ? GameColors.ringGlow : GameColors.starWarm)
            .withOpacity(alpha);
    canvas.drawCircle(badgeCenter, badgeR, _fillPaint);
    _strokePaint
      ..color = GameColors.cometRim.withOpacity(alpha)
      ..strokeWidth = 1.6;
    canvas.drawCircle(badgeCenter, badgeR, _strokePaint);

    final rankTp = _labels.get(
      '#$rank',
      GameColors.ink.withOpacity(alpha),
      (10.5 * u).clamp(9.5, 13.5),
    );
    rankTp.paint(
      canvas,
      Offset(
        badgeCenter.dx - rankTp.width / 2,
        badgeCenter.dy - rankTp.height / 2,
      ),
    );

    // 6. Name label pill below rocket (gold for `me`).
    final displayName = racer.name.isEmpty ? 'Bạn ${index + 1}' : racer.name;
    final nameColor = racer.me
        ? GameColors.ringGlow.withOpacity(alpha)
        : GameColors.star.withOpacity(alpha);
    final nameTp = _labels.get(
      displayName,
      nameColor,
      (12.0 * u).clamp(10.5, 15.0),
    );
    final pillW = math.min(rocketW * 1.45, nameTp.width + 14 * u);
    final pillH = nameTp.height + 6 * u;
    final nameCenterY = center.dy + rocketH * 0.5 + pillH * 0.5 + 4 * u + bobY;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, nameCenterY),
        width: pillW,
        height: pillH,
      ),
      Radius.circular(pillH / 2),
    );
    _fillPaint.color = GameColors.spaceTop.withOpacity(
      (racer.me ? 0.88 : 0.74) * alpha,
    );
    canvas.drawRRect(pillRect, _fillPaint);
    if (racer.me) {
      _strokePaint
        ..color = GameColors.cometRim.withOpacity(alpha)
        ..strokeWidth = 1.6;
      canvas.drawRRect(pillRect, _strokePaint);
    }
    final maxTextW = pillW - 10 * u;
    if (nameTp.width <= maxTextW) {
      nameTp.paint(
        canvas,
        Offset(center.dx - nameTp.width / 2, nameCenterY - nameTp.height / 2),
      );
    } else {
      canvas.save();
      canvas.clipRRect(pillRect);
      nameTp.paint(
        canvas,
        Offset(
          pillRect.left + 6 * u,
          nameCenterY - nameTp.height / 2,
        ),
      );
      canvas.restore();
    }

    // 7. "Đang chờ" badge when away.
    if (racer.away) {
      final waitTp = _labels.get(
        'Đang chờ',
        AppColors.textMuted,
        (10.5 * u).clamp(9.5, 13.0),
      );
      final waitW = waitTp.width + 12 * u;
      final waitH = waitTp.height + 5 * u;
      final waitCenterY = nameCenterY + pillH * 0.5 + waitH * 0.5 + 3 * u;
      final waitRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, waitCenterY),
          width: waitW,
          height: waitH,
        ),
        Radius.circular(waitH / 2),
      );
      _fillPaint.color = AppColors.card.withOpacity(0.92);
      canvas.drawRRect(waitRect, _fillPaint);
      waitTp.paint(
        canvas,
        Offset(center.dx - waitTp.width / 2, waitCenterY - waitTp.height / 2),
      );
    }
  }

  void _paintSuperSpeedStreaks(
    Canvas canvas,
    double rw,
    double rh,
    double u,
  ) {
    _streakPaint
      ..color = GameColors.nitroStreakCyan
      ..strokeWidth = 2.4 * u;
    canvas.drawLine(
        Offset(-rw * 0.36, -rh * 0.15), Offset(-rw * 0.52, rh * 0.52), _streakPaint);
    canvas.drawLine(
        Offset(rw * 0.36, -rh * 0.15), Offset(rw * 0.52, rh * 0.52), _streakPaint);
    _streakPaint
      ..color = GameColors.blueOuter.withOpacity(0.85)
      ..strokeWidth = 1.8 * u;
    canvas.drawLine(
        Offset(-rw * 0.20, 0), Offset(-rw * 0.26, rh * 0.65), _streakPaint);
    canvas.drawLine(
        Offset(rw * 0.20, 0), Offset(rw * 0.26, rh * 0.65), _streakPaint);
  }

  void _paintSuperSpeedBanner(
    Canvas canvas,
    Size area,
    double u,
    int combo,
  ) {
    final text = '⚡ $combo câu đúng · SIÊU TỐC!';
    final y = math.max(92.0, area.height * 0.14);
    _paintBannerPill(
      canvas,
      area: area,
      centerY: y,
      u: u,
      text: text,
      fill: GameColors.blueOuterEnd.withOpacity(0.92),
      border: GameColors.blueOuter,
      textColor: GameColors.blueCore,
      fontSize: (14.5 * u).clamp(12.0, 19.0),
    );
  }

  void _paintOvertakeBanner(
    Canvas canvas,
    Size area,
    double u,
    String text, {
    required bool positive,
    required bool belowSuper,
  }) {
    final baseY = math.max(96.0, area.height * 0.15);
    final y = belowSuper ? baseY + 34.0 * u : baseY;
    _paintBannerPill(
      canvas,
      area: area,
      centerY: y,
      u: u,
      text: text,
      fill: positive
          ? GameColors.ringGlow
          : GameColors.spaceTop.withOpacity(0.90),
      border: positive ? GameColors.rareGold : GameColors.hudEdge,
      textColor: positive ? GameColors.ink : GameColors.star,
      fontSize: (positive ? 15.0 * u : 13.5 * u).clamp(11.5, 19.0),
    );
  }

  void _paintStarGate(
    Canvas canvas,
    Size area,
    double u,
    int stage,
    String leaderName,
    double age,
  ) {
    final cx = area.width * 0.5;
    final cy = math.max(150.0, area.height * 0.46);
    final pulse = 1.0 + 0.06 * math.sin(age * 4.5);
    final glowR = math.min(area.width, area.height) * 0.42 * pulse;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(glowR, glowR);
    canvas.drawPath(_unitCircle, _gateGlowPaint);
    canvas.restore();

    final starImg = images?[AppImages.icStar].value;
    final flameImg = images?[AppImages.icFlame].value;
    final cardW = math.min(area.width - 28.0, 310.0 * u);
    final cardH = 84.0 * u;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: cardW, height: cardH),
      Radius.circular(22.0 * u),
    );
    _fillPaint.color = GameColors.spaceTop.withOpacity(0.92);
    canvas.drawRRect(cardRect, _fillPaint);
    _strokePaint
      ..color = GameColors.ringGlow
      ..strokeWidth = 3.0;
    canvas.drawRRect(cardRect, _strokePaint);

    final decoSize = 26.0 * u;
    if (flameImg != null) {
      paintImageFitted(
        canvas,
        flameImg,
        Rect.fromCenter(
          center: Offset(cardRect.left + 20 * u, cy),
          width: decoSize,
          height: decoSize,
        ),
        _normalImagePaint,
      );
    }
    if (starImg != null) {
      paintImageFitted(
        canvas,
        starImg,
        Rect.fromCenter(
          center: Offset(cardRect.right - 20 * u, cy),
          width: decoSize,
          height: decoSize,
        ),
        _normalImagePaint,
      );
    }

    final titleTp = _labels.get(
      '✨ Cổng Sao chặng $stage ✨',
      GameColors.ringGlow,
      (16.5 * u).clamp(13.0, 21.0),
    );
    final leaderDisplay = leaderName.isEmpty ? 'Bạn 1' : leaderName;
    final leaderTp = _labels.get(
      'Đang dẫn: $leaderDisplay! 🏆',
      GameColors.star,
      (14.0 * u).clamp(11.5, 18.0),
    );

    canvas.save();
    canvas.clipRRect(cardRect);
    titleTp.paint(
      canvas,
      Offset(
        cx - math.min(titleTp.width, cardW - 20 * u) / 2,
        cy - titleTp.height - 2 * u,
      ),
    );
    leaderTp.paint(
      canvas,
      Offset(
        cx - math.min(leaderTp.width, cardW - 20 * u) / 2,
        cy + 4 * u,
      ),
    );
    canvas.restore();
  }

  void _paintBannerPill(
    Canvas canvas, {
    required Size area,
    required double centerY,
    required double u,
    required String text,
    required Color fill,
    required Color border,
    required Color textColor,
    required double fontSize,
  }) {
    final tp = _labels.get(text, textColor, fontSize);
    final maxW = math.max(120.0, area.width - 24.0);
    final pillW = math.min(maxW, tp.width + 26.0 * u);
    final pillH = tp.height + 10.0 * u;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(area.width * 0.5, centerY),
        width: pillW,
        height: pillH,
      ),
      Radius.circular(pillH * 0.5),
    );
    _fillPaint.color = fill;
    canvas.drawRRect(rrect, _fillPaint);
    _strokePaint
      ..color = border
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, _strokePaint);

    if (tp.width <= pillW - 14.0 * u) {
      tp.paint(
        canvas,
        Offset(area.width * 0.5 - tp.width / 2, centerY - tp.height / 2),
      );
    } else {
      canvas.save();
      canvas.clipRRect(rrect);
      tp.paint(
        canvas,
        Offset(rrect.left + 10.0 * u, centerY - tp.height / 2),
      );
      canvas.restore();
    }
  }

  void _paintComet(Canvas canvas, Size area, double u, double p) {
    final img = images?[AppImages.comet].value;
    if (img == null) return;
    final x = area.width * (1.12 - 1.24 * p);
    final y = area.height * 0.16 + 32 * u * math.sin(p * math.pi * 0.65);
    final fade = p < 0.1
        ? p / 0.1
        : p > 0.85
            ? (1 - p) / 0.15
            : 1.0;
    final head = 74 * u;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.26);
    _fillPaint.color = GameColors.star.withOpacity(fade.clamp(0.0, 1.0));
    paintImageFitted(
      canvas,
      img,
      Rect.fromLTWH(-head * 0.28, -head * 0.55, head, head),
      _fillPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(OnlineRacePainter oldDelegate) =>
      oldDelegate.racers != racers ||
      oldDelegate.displayedSteps != displayedSteps ||
      oldDelegate.effects != effects ||
      oldDelegate.reduceMotion != reduceMotion ||
      oldDelegate.bottomInset != bottomInset ||
      oldDelegate.cometProgress != cometProgress ||
      oldDelegate.speedLinesAge != speedLinesAge ||
      oldDelegate.shakeOffset != shakeOffset ||
      oldDelegate.superSpeed != superSpeed ||
      oldDelegate.comboStreak != comboStreak ||
      oldDelegate.starGateStage != starGateStage ||
      oldDelegate.starGateLeader != starGateLeader ||
      oldDelegate.overtakeBanner != overtakeBanner ||
      oldDelegate.isPositiveOvertake != isPositiveOvertake ||
      oldDelegate.clock != clock ||
      oldDelegate.images != images ||
      oldDelegate.speedLines != speedLines ||
      oldDelegate.smokes != smokes ||
      oldDelegate.stickerFx != stickerFx;
}
