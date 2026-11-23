import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import 'online_race_painter.dart' show OnlineLabelCache;
import 'particle_pool.dart';
import 'space_track.dart' show paintImageFitted;

/// Primitive animation behaviors composed for each online sticker.
enum FxKind { popIn, wobble, arcFly, burst, rain, floatUp }

/// Maps any server-whitelisted sticker id (plus quick phrases `q_*`) to a
/// non-empty list of [FxKind] animations.
List<FxKind> fxKindsForSticker(String id) {
  if (id.startsWith('q_')) return const [FxKind.popIn];
  return switch (id) {
    'bubble' => const [FxKind.arcFly, FxKind.popIn, FxKind.burst],
    'tongue' => const [FxKind.arcFly, FxKind.wobble],
    'byebye' => const [FxKind.wobble],
    'rain' => const [FxKind.popIn, FxKind.rain],
    'sleepy' => const [FxKind.floatUp],
    'turtle' => const [FxKind.arcFly, FxKind.wobble],
    'smoke' => const [FxKind.burst],
    'cheer' => const [FxKind.popIn, FxKind.burst],
    'love' => const [FxKind.popIn, FxKind.floatUp, FxKind.burst],
    'party' => const [FxKind.popIn, FxKind.wobble, FxKind.burst],
    'wow' => const [FxKind.popIn, FxKind.wobble],
    'fast' => const [FxKind.popIn, FxKind.burst],
    'hi' => const [FxKind.popIn, FxKind.wobble],
    'gg' => const [FxKind.popIn, FxKind.burst],
    _ => const [FxKind.popIn],
  };
}

/// Asset path for image-based room stickers, or null for text-only bubbles.
String? stickerAssetForId(String id) => switch (id) {
      'cheer' => AppImages.stickerFist,
      'love' => AppImages.stickerHugHeart,
      'party' => AppImages.stickerParty,
      'bubble' => AppImages.stickerTeaseBubble,
      'tongue' => AppImages.stickerTeaseTongue,
      'byebye' => AppImages.stickerTeaseByebye,
      'rain' => AppImages.stickerTeaseRain,
      'sleepy' => AppImages.stickerTeaseSleepy,
      'turtle' => AppImages.stickerTeaseTurtle,
      'smoke' => AppImages.stickerTeaseSmoke,
      'wow' => AppImages.stickerLaugh,
      'fast' => AppImages.stickerPilotGoggles,
      'hi' => AppImages.stickerWaveRocket,
      'gg' => AppImages.stickerClap,
      _ => null,
    };

const String chipCheerUpStickerId = 'chip_cheerup';
const String chipCheerUpText = 'Kệ bạn, mình bay tiếp nào!';

/// Incoming sticker payload forwarded from [RaceScreen] to [RaceScene].
@immutable
class IncomingStickerEvent {
  const IncomingStickerEvent({
    required this.seq,
    required this.fromId,
    required this.stickerId,
    this.toId,
    this.bubbleText,
  });

  final int seq;
  final String fromId;
  final String stickerId;
  final String? toId;
  final String? bubbleText;
}

class _StickerSlot {
  bool active = false;
  String id = '';
  Offset from = Offset.zero;
  Offset to = Offset.zero;
  Offset currentPos = Offset.zero;
  Duration startAt = Duration.zero;
  Duration duration = Duration.zero;
  List<FxKind> kinds = const [FxKind.popIn];
  bool hasArcFly = false;
  bool hasPopIn = false;
  bool hasWobble = false;
  bool hasBurst = false;
  bool hasRain = false;
  bool hasFloatUp = false;
  bool burstDone = false;
  int particlesSpawned = 0;
  double emitAccum = 0;
  int seed = 0;
}

class _BubbleSlot {
  bool active = false;
  String text = '';
  Offset anchor = Offset.zero;
  Duration startAt = Duration.zero;
  Duration duration = Duration.zero;
  bool isChipCheerUp = false;
}

/// Manages sticker animations, speech bubbles, and a shared 120-particle pool
/// painted directly onto the online race canvas without allocating per frame.
class StickerFx {
  StickerFx({
    this.imageLookup,
    OnlineLabelCache? labelCache,
    int poolCapacity = defaultPoolCapacity,
  })  : pool = ParticlePool(poolCapacity),
        _externalLabels = labelCache,
        _ownedLabels = labelCache == null ? OnlineLabelCache() : null,
        _stickerSlots = List<_StickerSlot>.generate(
            maxActiveStickers, (_) => _StickerSlot(),
            growable: false),
        _bubbleSlots = List<_BubbleSlot>.generate(
            maxActiveBubbles, (_) => _BubbleSlot(),
            growable: false);

  static const int defaultPoolCapacity = 120;
  static const int maxParticlesPerSticker = 24;
  static const int maxActiveStickers = 16;
  static const int maxActiveBubbles = 8;
  static const Duration defaultStickerDuration = Duration(milliseconds: 2000);
  static const Duration maxStickerDuration = Duration(milliseconds: 2200);
  static const Duration defaultBubbleDuration = Duration(milliseconds: 2000);
  static const Duration cheerUpBubbleDuration = Duration(milliseconds: 2200);
  static const Duration _arcDuration = Duration(milliseconds: 450);

  final ui.Image? Function(String assetPath)? imageLookup;
  final OnlineLabelCache? _externalLabels;
  final OnlineLabelCache? _ownedLabels;
  final ParticlePool pool;
  final List<_StickerSlot> _stickerSlots;
  final List<_BubbleSlot> _bubbleSlots;

  final Paint _imagePaint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  Duration? _lastNow;
  int _seedCounter = 1;
  int _stickerCursor = 0;
  int _bubbleCursor = 0;

  @visibleForTesting
  int get activeStickers {
    var count = 0;
    for (final s in _stickerSlots) {
      if (s.active) count++;
    }
    return count;
  }

  @visibleForTesting
  int get activeBubbles {
    var count = 0;
    for (final b in _bubbleSlots) {
      if (b.active) count++;
    }
    return count;
  }

  @visibleForTesting
  List<String> get activeStickerIds => [
        for (final s in _stickerSlots)
          if (s.active) s.id,
      ];

  @visibleForTesting
  List<String> get activeBubbleTexts => [
        for (final b in _bubbleSlots)
          if (b.active) b.text,
      ];

  /// Starts a sticker or speech bubble animation at [now].
  void play(
    String id, {
    required Offset from,
    Offset? to,
    required Duration now,
    String? bubbleText,
    bool reduceMotion = false,
  }) {
    _lastNow ??= now;
    if (bubbleText != null && bubbleText.isNotEmpty) {
      _activateBubble(
        text: bubbleText,
        anchor: to ?? from,
        now: now,
        duration: id == chipCheerUpStickerId
            ? cheerUpBubbleDuration
            : defaultBubbleDuration,
        isChipCheerUp: id == chipCheerUpStickerId,
      );
      return;
    }
    final kinds = fxKindsForSticker(id);
    final slot = _claimStickerSlot();
    final target = to ?? from;
    final hasArc = !reduceMotion && kinds.contains(FxKind.arcFly) && to != null;
    slot
      ..active = true
      ..id = id
      ..from = from
      ..to = target
      ..currentPos = hasArc ? from : target
      ..startAt = now
      ..duration = defaultStickerDuration
      ..kinds = kinds
      ..hasArcFly = hasArc
      ..hasPopIn = kinds.contains(FxKind.popIn)
      ..hasWobble = !reduceMotion && kinds.contains(FxKind.wobble)
      ..hasBurst = !reduceMotion && kinds.contains(FxKind.burst)
      ..hasRain = !reduceMotion && kinds.contains(FxKind.rain)
      ..hasFloatUp = !reduceMotion && kinds.contains(FxKind.floatUp)
      ..burstDone = false
      ..particlesSpawned = 0
      ..emitAccum = 0.0
      ..seed = _seedCounter++;

    if (slot.hasBurst && !slot.hasArcFly) {
      _spawnBurst(slot);
      slot.burstDone = true;
    }
  }

  /// Shows Chíp's encouraging safety bubble above [anchor].
  void playCheerUp({
    required Offset anchor,
    required Duration now,
    bool reduceMotion = false,
  }) {
    play(
      chipCheerUpStickerId,
      from: anchor,
      now: now,
      bubbleText: chipCheerUpText,
      reduceMotion: reduceMotion,
    );
  }

  _StickerSlot _claimStickerSlot() {
    for (var i = 0; i < maxActiveStickers; i++) {
      final idx = (_stickerCursor + i) % maxActiveStickers;
      if (!_stickerSlots[idx].active) {
        _stickerCursor = (idx + 1) % maxActiveStickers;
        return _stickerSlots[idx];
      }
    }
    final slot = _stickerSlots[_stickerCursor];
    _stickerCursor = (_stickerCursor + 1) % maxActiveStickers;
    return slot;
  }

  void _activateBubble({
    required String text,
    required Offset anchor,
    required Duration now,
    required Duration duration,
    required bool isChipCheerUp,
  }) {
    late final _BubbleSlot chosen;
    var found = false;
    for (var i = 0; i < maxActiveBubbles; i++) {
      final idx = (_bubbleCursor + i) % maxActiveBubbles;
      if (!_bubbleSlots[idx].active) {
        _bubbleCursor = (idx + 1) % maxActiveBubbles;
        chosen = _bubbleSlots[idx];
        found = true;
        break;
      }
    }
    if (!found) {
      chosen = _bubbleSlots[_bubbleCursor];
      _bubbleCursor = (_bubbleCursor + 1) % maxActiveBubbles;
    }
    chosen
      ..active = true
      ..text = text
      ..anchor = anchor
      ..startAt = now
      ..duration = duration
      ..isChipCheerUp = isChipCheerUp;
  }

  /// Advances active stickers, bubbles, and [pool] to [now].
  void update(Duration now) {
    final prev = _lastNow ?? now;
    _lastNow = now;
    var dt = now - prev;
    if (dt < Duration.zero) dt = Duration.zero;
    final dtSec = math.min(dt.inMicroseconds / 1e6, 0.05);

    for (var i = 0; i < maxActiveStickers; i++) {
      final s = _stickerSlots[i];
      if (!s.active) continue;
      final age = now - s.startAt;
      if (age >= s.duration) {
        s.active = false;
        continue;
      }
      final progress =
          (age.inMicroseconds / s.duration.inMicroseconds).clamp(0.0, 1.0);
      if (s.hasArcFly && age < _arcDuration) {
        final arcT =
            (age.inMicroseconds / _arcDuration.inMicroseconds).clamp(0.0, 1.0);
        final ctrl = Offset(
          (s.from.dx + s.to.dx) * 0.5,
          math.min(s.from.dy, s.to.dy) - 64.0,
        );
        final inv = 1.0 - arcT;
        s.currentPos = Offset(
          inv * inv * s.from.dx +
              2.0 * inv * arcT * ctrl.dx +
              arcT * arcT * s.to.dx,
          inv * inv * s.from.dy +
              2.0 * inv * arcT * ctrl.dy +
              arcT * arcT * s.to.dy,
        );
      } else if (s.hasFloatUp && !s.hasArcFly) {
        s.currentPos = Offset(
          s.to.dx + math.sin(progress * math.pi * 2.0) * 6.0,
          s.to.dy - 36.0 * progress,
        );
      } else {
        s.currentPos = s.to;
      }

      if (s.hasBurst && !s.burstDone && (!s.hasArcFly || age >= _arcDuration)) {
        _spawnBurst(s);
        s.burstDone = true;
      }
      if (s.hasRain && dtSec > 0 && s.particlesSpawned < maxParticlesPerSticker) {
        _emitRain(s, dtSec);
      }
      if (s.hasFloatUp &&
          !s.hasBurst &&
          dtSec > 0 &&
          s.particlesSpawned < maxParticlesPerSticker) {
        _emitFloat(s, dtSec);
      }
    }

    for (var i = 0; i < maxActiveBubbles; i++) {
      final b = _bubbleSlots[i];
      if (!b.active) continue;
      if (now - b.startAt >= b.duration) {
        b.active = false;
      }
    }

    pool.update(dt);
  }

  void _spawnBurst(_StickerSlot s) {
    final cap = math.min(18, maxParticlesPerSticker - s.particlesSpawned);
    if (cap <= 0) return;
    final colors = switch (s.id) {
      'bubble' => const [GameColors.blueMid, GameColors.blueCore, GameColors.star],
      'smoke' => const [GameColors.smoke, GameColors.stallSmoke, GameColors.hudEdge],
      'love' => const [GameColors.skyHorizon, GameColors.ringGlow, GameColors.starWarm],
      'party' => GameColors.fireworks,
      _ => GameColors.sparkles,
    };
    final shape = switch (s.id) {
      'bubble' => ParticleShape.ring,
      'smoke' => ParticleShape.circle,
      _ => ParticleShape.star,
    };
    for (var i = 0; i < cap; i++) {
      final angle = (i / cap) * math.pi * 2 + (s.seed % 7) * 0.13;
      final speed = 42.0 + (i % 4) * 24.0;
      final spawned = pool.spawn(
        x: s.currentPos.dx,
        y: s.currentPos.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        ay: s.id == 'party' ? 60.0 : 0.0,
        size: s.id == 'smoke' ? 14.0 : 10.0,
        endSize: s.id == 'smoke' ? 24.0 : 3.0,
        color: colors[i % colors.length],
        life: const Duration(milliseconds: 700),
        rotation: angle,
        vRot: 3.0,
        shape: shape,
      );
      if (!spawned) break;
      s.particlesSpawned++;
    }
  }

  void _emitRain(_StickerSlot s, double dtSec) {
    s.emitAccum += dtSec * 14.0;
    while (s.emitAccum >= 1.0 && s.particlesSpawned < maxParticlesPerSticker) {
      s.emitAccum -= 1.0;
      final k = s.particlesSpawned + s.seed;
      final offsetX = ((k * 37 % 48) - 24).toDouble();
      final spawned = pool.spawn(
        x: s.currentPos.dx + offsetX,
        y: s.currentPos.dy + 12.0,
        vx: -8.0,
        vy: 115.0 + (k % 3) * 18.0,
        size: 8.0,
        endSize: 6.0,
        color: GameColors.blueOuter,
        life: const Duration(milliseconds: 520),
        shape: ParticleShape.drop,
      );
      if (!spawned) {
        s.emitAccum = 0.0;
        break;
      }
      s.particlesSpawned++;
    }
  }

  void _emitFloat(_StickerSlot s, double dtSec) {
    s.emitAccum += dtSec * 8.0;
    while (s.emitAccum >= 1.0 && s.particlesSpawned < maxParticlesPerSticker) {
      s.emitAccum -= 1.0;
      final k = s.particlesSpawned + s.seed;
      final offsetX = ((k * 29 % 34) - 17).toDouble();
      final spawned = pool.spawn(
        x: s.currentPos.dx + offsetX,
        y: s.currentPos.dy - 10.0,
        vx: ((k % 2 == 0) ? 1 : -1) * 10.0,
        vy: -42.0,
        size: 9.0,
        endSize: 4.0,
        color: s.id == 'sleepy' ? GameColors.blueMid : GameColors.starWarm,
        life: const Duration(milliseconds: 750),
        shape: s.id == 'sleepy' ? ParticleShape.circle : ParticleShape.star,
      );
      if (!spawned) {
        s.emitAccum = 0.0;
        break;
      }
      s.particlesSpawned++;
    }
  }

  /// Paints particles, active stickers, and speech bubbles within [s].
  void paint(
    Canvas c,
    Size s, {
    ui.Image? Function(String assetPath)? imageLookup,
    OnlineLabelCache? labelCache,
    bool reduceMotion = false,
  }) {
    if (s.isEmpty) return;
    final now = _lastNow ?? Duration.zero;
    final lookup = imageLookup ?? this.imageLookup;
    final labels = labelCache ?? _externalLabels ?? _ownedLabels!;
    final u = math.min(s.width / 390.0, s.height / 520.0).clamp(0.72, 1.5);

    pool.paint(c);

    // Paint stickers.
    for (var i = 0; i < maxActiveStickers; i++) {
      final slot = _stickerSlots[i];
      if (!slot.active) continue;
      final ageMs =
          math.max(0, (now - slot.startAt).inMilliseconds).toDouble();
      final durMs = math.max(1, slot.duration.inMilliseconds).toDouble();
      final progress = (ageMs / durMs).clamp(0.0, 1.0);

      var scale = 1.0;
      if (!reduceMotion && slot.hasPopIn && ageMs < 250.0) {
        final t = ageMs / 250.0;
        scale = t < 0.65 ? (t / 0.65) * 1.15 : 1.15 - 0.15 * ((t - 0.65) / 0.35);
      }

      var angle = 0.0;
      if (!reduceMotion && slot.hasWobble) {
        angle = math.sin(ageMs / 1000.0 * 18.0) * 0.24 * (1.0 - progress);
      }

      final fade = progress > 0.82 ? (1.0 - progress) / 0.18 : 1.0;
      final alpha = fade.clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      final sizePx = 56.0 * u * scale;
      final half = sizePx * 0.5;
      final cx = slot.currentPos.dx
          .clamp(half + 6.0, math.max(half + 6.0, s.width - half - 6.0))
          .toDouble();
      final cy = (slot.currentPos.dy - 36.0 * u)
          .clamp(half + 6.0, math.max(half + 6.0, s.height - half - 6.0))
          .toDouble();

      c.save();
      c.translate(cx, cy);
      if (angle != 0.0) c.rotate(angle);

      final asset = stickerAssetForId(slot.id);
      final img = asset == null ? null : lookup?.call(asset);
      final rect = Rect.fromCenter(center: Offset.zero, width: sizePx, height: sizePx);
      if (img != null) {
        _imagePaint.color = GameColors.star.withOpacity(alpha);
        paintImageFitted(c, img, rect, _imagePaint);
      } else {
        _fillPaint.color = GameColors.cockpitBg.withOpacity(0.92 * alpha);
        c.drawCircle(Offset.zero, half * 0.85, _fillPaint);
        _strokePaint
          ..color = GameColors.cometRim.withOpacity(alpha)
          ..strokeWidth = 2.0;
        c.drawCircle(Offset.zero, half * 0.85, _strokePaint);
        if (alpha >= 0.25) {
          final tp = labels.get(
            slot.id,
            GameColors.ink,
            (12.0 * u).clamp(10.0, 15.0),
          );
          tp.paint(c, Offset(-tp.width * 0.5, -tp.height * 0.5));
        }
      }
      c.restore();
    }

    // Paint quick-phrase and Chíp cheer-up speech bubbles.
    for (var i = 0; i < maxActiveBubbles; i++) {
      final b = _bubbleSlots[i];
      if (!b.active) continue;
      final ageMs = math.max(0, (now - b.startAt).inMilliseconds).toDouble();
      final durMs = math.max(1, b.duration.inMilliseconds).toDouble();
      final progress = (ageMs / durMs).clamp(0.0, 1.0);
      final fade = progress > 0.85 ? (1.0 - progress) / 0.15 : 1.0;
      final alpha = fade.clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      final fontSize = (b.isChipCheerUp ? 13.5 * u : 12.5 * u).clamp(11.0, 16.0);
      final tp = labels.get(
        b.text,
        GameColors.ink,
        fontSize,
      );
      final chipImg =
          b.isChipCheerUp ? lookup?.call(AppImages.chipEncourage) : null;
      final iconPad = chipImg != null ? 24.0 * u : 0.0;
      final maxW = math.max(80.0, s.width - 16.0);
      final pillW = math.min(maxW, tp.width + 20.0 * u + iconPad);
      final pillH = math.max(tp.height + 12.0 * u, chipImg != null ? 30.0 * u : 0.0);
      final cx = b.anchor.dx
          .clamp(
            pillW * 0.5 + 8.0,
            math.max(pillW * 0.5 + 8.0, s.width - pillW * 0.5 - 8.0),
          )
          .toDouble();
      final cy = (b.anchor.dy - 58.0 * u)
          .clamp(
            pillH * 0.5 + 8.0,
            math.max(pillH * 0.5 + 8.0, s.height - pillH * 0.5 - 8.0),
          )
          .toDouble();
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: pillW, height: pillH),
        Radius.circular(pillH * 0.45),
      );

      _fillPaint.color = (b.isChipCheerUp
              ? GameColors.rareGoldTint
              : AppColors.card)
          .withOpacity(0.95 * alpha);
      c.drawRRect(rrect, _fillPaint);
      _strokePaint
        ..color = (b.isChipCheerUp ? GameColors.cometRim : AppColors.accent)
            .withOpacity(alpha)
        ..strokeWidth = b.isChipCheerUp ? 2.2 : 1.8;
      c.drawRRect(rrect, _strokePaint);

      if (chipImg != null) {
        final iconSize = 22.0 * u;
        _imagePaint.color = GameColors.star.withOpacity(alpha);
        paintImageFitted(
          c,
          chipImg,
          Rect.fromCenter(
            center: Offset(rrect.left + 8.0 * u + iconSize * 0.5, cy),
            width: iconSize,
            height: iconSize,
          ),
          _imagePaint,
        );
      }

      if (alpha >= 0.25) {
        final textLeft = rrect.left + 10.0 * u + iconPad;
        final maxTextW = pillW - 18.0 * u - iconPad;
        if (tp.width <= maxTextW) {
          tp.paint(
            c,
            Offset(
              textLeft + (maxTextW - tp.width) * 0.5,
              cy - tp.height * 0.5,
            ),
          );
        } else {
          c.save();
          c.clipRRect(rrect);
          tp.paint(c, Offset(textLeft, cy - tp.height * 0.5));
          c.restore();
        }
      }
    }
  }

  /// Clears active stickers, bubbles, and particles without disposing caches.
  void clear() {
    for (final s in _stickerSlots) {
      s.active = false;
    }
    for (final b in _bubbleSlots) {
      b.active = false;
    }
    pool.clear();
  }

  /// Releases owned label cache resources if created internally.
  void dispose() {
    clear();
    _ownedLabels?.dispose();
  }
}
