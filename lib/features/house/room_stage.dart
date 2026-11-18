import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../house/house_model.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';

/// Kind of custom room animation played in [RoomStage].
enum HouseFxKind { feed, levelUp, decor, pet }

/// Immutable trigger payload for one discrete 120fps room animation.
class HouseFxEvent {
  const HouseFxEvent({
    required this.seq,
    required this.kind,
    this.treatColor,
    this.treatIcon,
    this.decorSlot,
    this.decorColor,
    this.badge,
  });

  final int seq;
  final HouseFxKind kind;
  final Color? treatColor;
  final IconData? treatIcon;
  final HouseSlot? decorSlot;
  final Color? decorColor;
  final String? badge;
}

/// Live cozy room stage for Nhà Chíp: paints the equipped wall theme, window,
/// wooden floor, rug and corner prop inside a cached [RepaintBoundary], and
/// runs custom 120fps GPU-friendly choreography for feeding, decorating and
/// petting Chíp.
class RoomStage extends StatefulWidget {
  const RoomStage({
    super.key,
    required this.state,
    required this.fxEvent,
    required this.onPetChip,
    required this.tablet,
  });

  final ChipHouseState state;
  final HouseFxEvent? fxEvent;
  final VoidCallback onPetChip;
  final bool tablet;

  @override
  State<RoomStage> createState() => _RoomStageState();
}

class _RoomStageState extends State<RoomStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fxController;
  HouseFxEvent? _activeFx;

  @override
  void initState() {
    super.initState();
    _fxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _fxController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {});
      }
    });
    if (widget.fxEvent != null) {
      _playEvent(widget.fxEvent!);
    }
  }

  @override
  void didUpdateWidget(covariant RoomStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.fxEvent;
    if (next != null && next.seq != oldWidget.fxEvent?.seq) {
      _playEvent(next);
    }
  }

  void _playEvent(HouseFxEvent event) {
    _activeFx = event;
    _fxController.duration = switch (event.kind) {
      HouseFxKind.feed => const Duration(milliseconds: 1050),
      HouseFxKind.levelUp => const Duration(milliseconds: 1300),
      HouseFxKind.decor => const Duration(milliseconds: 900),
      HouseFxKind.pet => const Duration(milliseconds: 850),
    };
    _fxController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _fxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallId = widget.state.equippedId(HouseSlot.wall);
    final rugId = widget.state.equippedId(HouseSlot.rug);
    final decorId = widget.state.equippedId(HouseSlot.decor);
    final buddyId = widget.state.equippedId(HouseSlot.buddy);

    final fx = _activeFx;
    final animating = fx != null && _fxController.isAnimating;

    final stageHeight = widget.tablet ? 300.0 : 236.0;
    final chipSize = widget.tablet ? 148.0 : 120.0;
    final badgeText = fx?.badge;

    // Pre-built static Chíp images so 120Hz AnimatedBuilder swaps expression
    // right when the treat lands without rebuilding Image widgets.
    final normalAsset =
        buddyId == 'buddy_crayon' ? AppImages.chipWrite : AppImages.chipMain;
    final normalChip = Image.asset(
      normalAsset,
      width: chipSize,
      height: chipSize,
      fit: BoxFit.contain,
    );
    final joyChip = Image.asset(
      AppImages.chipJoy,
      width: chipSize,
      height: chipSize,
      fit: BoxFit.contain,
    );
    final crownWidget = buddyId == 'buddy_crown'
        ? Image.asset(
            AppImages.icCrown,
            width: widget.tablet ? 46 : 38,
            height: widget.tablet ? 46 : 38,
            fit: BoxFit.contain,
          )
        : null;

    return Container(
      height: stageHeight,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: AppColors.card,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card - 4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Static room architecture (cached in GPU texture; only
            // repaints when wall, rug, or decor changes).
            RepaintBoundary(
              child: CustomPaint(
                painter: _RoomPainter(
                  wallId: wallId,
                  rugId: rugId,
                  decorId: decorId,
                ),
              ),
            ),

            // Star pillow buddy resting next to Chíp on the rug (with pop-in)
            if (buddyId == 'buddy_pillow')
              Positioned(
                bottom: widget.tablet ? 28 : 20,
                left: 0,
                right: widget.tablet ? 136 : 112,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _fxController,
                    builder: (_, child) {
                      final popBuddy = animating &&
                          fx.kind == HouseFxKind.decor &&
                          fx.decorSlot == HouseSlot.buddy;
                      final s = popBuddy
                          ? Curves.elasticOut
                              .transform(_fxController.value.clamp(0.0, 1.0))
                          : 1.0;
                      return Transform.scale(scale: s, child: child);
                    },
                    child: Image.asset(
                      AppImages.icStar,
                      width: widget.tablet ? 56 : 44,
                      height: widget.tablet ? 56 : 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

            // Layer 2: Choreographed Chíp mascot + crown (pure GPU Matrix4
            // transform per 120Hz frame, isolated in its own RepaintBoundary).
            Align(
              alignment: const Alignment(0, 0.72),
              child: RepaintBoundary(
                child: Semantics(
                  button: true,
                  label: 'Vuốt ve Chíp Chíp',
                  child: GestureDetector(
                    key: const ValueKey('house-pet-chip'),
                    onTap: widget.onPetChip,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _fxController,
                      builder: (_, __) {
                        final t = animating ? _fxController.value : 1.0;
                        final pose = _chipPoseFor(fx?.kind, t);
                        final isJoy = animating &&
                            (fx.kind == HouseFxKind.pet ||
                                fx.kind == HouseFxKind.decor ||
                                t >= 0.36);
                        final dropCrown = animating &&
                            fx.kind == HouseFxKind.decor &&
                            fx.decorSlot == HouseSlot.buddy;
                        final crownDropY = dropCrown
                            ? -34.0 *
                                (1.0 -
                                    Curves.bounceOut
                                        .transform((t * 1.4).clamp(0.0, 1.0)))
                            : 0.0;

                        return Transform.translate(
                          offset: Offset(0, pose.dy),
                          child: Transform.rotate(
                            angle: pose.angle,
                            child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.diagonal3Values(
                                pose.scaleX,
                                pose.scaleY,
                                1.0,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: [
                                  isJoy ? joyChip : normalChip,
                                  if (crownWidget != null)
                                    Positioned(
                                      top: (widget.tablet ? -18.0 : -14.0) +
                                          crownDropY,
                                      child: crownWidget,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Layer 3A: Flying treat parabolic arc during feeding (0.0 -> 0.42)
            if (animating &&
                (fx.kind == HouseFxKind.feed ||
                    fx.kind == HouseFxKind.levelUp) &&
                fx.treatIcon != null)
              IgnorePointer(
                child: RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final color = fx.treatColor ?? AppColors.accent;
                      return AnimatedBuilder(
                        animation: _fxController,
                        builder: (_, child) {
                          final raw = _fxController.value / 0.42;
                          if (raw < 0 || raw > 1.0) {
                            return const SizedBox.shrink();
                          }
                          final p = Curves.easeInOutCubic.transform(raw);
                          // Quadratic bezier from bottom-center -> high arc -> Chíp's hands
                          final startX = w * 0.50;
                          final startY = h * 0.96;
                          final ctrlX = w * 0.34;
                          final ctrlY = h * 0.16;
                          final endX = w * 0.50;
                          final endY = h * 0.64;
                          final inv = 1.0 - p;
                          final x = inv * inv * startX +
                              2 * inv * p * ctrlX +
                              p * p * endX;
                          final y = inv * inv * startY +
                              2 * inv * p * ctrlY +
                              p * p * endY;
                          final scale =
                              (1.15 - 0.55 * p).clamp(0.45, 1.2);
                          return Stack(
                            children: [
                              Positioned(
                                left: x - 24,
                                top: y - 24,
                                child: Transform.rotate(
                                  angle: p * math.pi * 2.2,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.32),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(fx.treatIcon, color: color, size: 28),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Layer 3B: 120fps vector sparkle/heart/confetti/shimmer painter
            if (animating)
              IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RoomFxPainter(
                      animation: _fxController,
                      event: fx,
                    ),
                  ),
                ),
              ),

            // Stage level badge at top-left
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  'Cấp ${widget.state.stage.level} · ${widget.state.stage.title}',
                  style: TextStyle(
                    fontSize: widget.tablet ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),

            // Floating +XP / Level Up / Decor toast at top-right
            if (badgeText != null)
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedBuilder(
                  animation: _fxController,
                  builder: (_, child) {
                    final t = animating ? _fxController.value : 1.0;
                    final pop = Curves.easeOutBack
                        .transform((t * 2.4).clamp(0.0, 1.0));
                    final lift = animating ? -8.0 * math.sin(t * math.pi) : 0.0;
                    return Transform.translate(
                      offset: Offset(0, lift),
                      child: Transform.scale(scale: pop, child: child),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: CollectionColors.goldFill,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(
                        color: CollectionColors.goldBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: CollectionColors.goldInk,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipPose {
  const _ChipPose({
    this.dy = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.angle = 0,
  });

  final double dy;
  final double scaleX;
  final double scaleY;
  final double angle;
}

_ChipPose _chipPoseFor(HouseFxKind? kind, double t) {
  if (kind == null || t >= 1.0) return const _ChipPose();
  switch (kind) {
    case HouseFxKind.feed:
    case HouseFxKind.levelUp:
      if (t < 0.36) {
        // Anticipation crouch waiting for the incoming treat
        final p = math.sin((t / 0.36) * math.pi);
        return _ChipPose(
          dy: 3.0 * p,
          scaleX: 1.0 + 0.05 * p,
          scaleY: 1.0 - 0.05 * p,
        );
      }
      // Joyful munch squash-stretch + celebratory hop
      final p = ((t - 0.36) / 0.64).clamp(0.0, 1.0);
      final damp = 1.0 - p;
      final munch = math.sin(p * math.pi * 3.0) * damp;
      final hopHeight = kind == HouseFxKind.levelUp ? 28.0 : 18.0;
      final hop = math.sin(p * math.pi) * hopHeight * (1.0 - 0.3 * p);
      return _ChipPose(
        dy: -hop,
        scaleX: 1.0 + 0.12 * munch,
        scaleY: 1.0 - 0.10 * munch,
        angle: 0.06 * math.sin(p * math.pi * 4.0) * damp,
      );
    case HouseFxKind.decor:
      final damp = 1.0 - t;
      final hop = math.sin(t * math.pi) * 14.0;
      return _ChipPose(
        dy: -hop,
        scaleX: 1.0 + 0.06 * math.sin(t * math.pi * 2.0) * damp,
        scaleY: 1.0 - 0.05 * math.sin(t * math.pi * 2.0) * damp,
        angle: 0.08 * math.sin(t * math.pi * 4.0) * damp,
      );
    case HouseFxKind.pet:
      final damp = 1.0 - t;
      return _ChipPose(
        dy: -10.0 * math.sin(t * math.pi),
        scaleX: 1.0 + 0.08 * math.sin(t * math.pi * 3.0) * damp,
        scaleY: 1.0 - 0.07 * math.sin(t * math.pi * 3.0) * damp,
        angle: 0.10 * math.sin(t * math.pi * 5.0) * damp,
      );
  }
}

/// Pure 120fps vector FX overlay (no saveLayer, no MaskFilter.blur).
class _RoomFxPainter extends CustomPainter {
  const _RoomFxPainter({
    required this.animation,
    required this.event,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final HouseFxEvent event;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0.0 || t >= 1.0) return;

    final floorY = size.height * 0.64;
    final chipCenter = Offset(size.width * 0.50, floorY - 12);

    switch (event.kind) {
      case HouseFxKind.feed:
        if (t < 0.36) return;
        final p = ((t - 0.36) / 0.64).clamp(0.0, 1.0);
        _paintRadialBurst(
          canvas,
          chipCenter,
          p,
          count: 10,
          maxRadius: size.width * 0.24,
          colors: [
            CollectionColors.goldBorder,
            event.treatColor ?? AppColors.accent,
            HouseColors.rugRainbow1,
            HouseColors.sunnySun,
          ],
          includeHearts: true,
        );
      case HouseFxKind.levelUp:
        if (t < 0.34) return;
        final p = ((t - 0.34) / 0.66).clamp(0.0, 1.0);
        _paintExpandingRing(
          canvas,
          chipCenter,
          p,
          maxRadius: size.width * 0.34,
          color: CollectionColors.goldBorder,
        );
        _paintRadialBurst(
          canvas,
          chipCenter,
          p,
          count: 18,
          maxRadius: size.width * 0.36,
          colors: const [
            HouseColors.rugRainbow1,
            HouseColors.rugRainbow2,
            HouseColors.rugRainbow3,
            HouseColors.rugRainbow4,
            CollectionColors.goldBorder,
            AppColors.accent,
          ],
          includeHearts: true,
        );
      case HouseFxKind.decor:
        _paintDecorMagic(canvas, size, floorY, t);
      case HouseFxKind.pet:
        _paintFloatingHearts(canvas, chipCenter, t);
    }
  }

  void _paintDecorMagic(Canvas canvas, Size size, double floorY, double t) {
    final slot = event.decorSlot ?? HouseSlot.wall;
    final accent = event.decorColor ?? CollectionColors.goldBorder;
    switch (slot) {
      case HouseSlot.wall:
        // Diagonal golden shimmer sweep across the room wall
        final sweepX = -size.width * 0.25 + size.width * 1.5 * t;
        final band = Path()
          ..moveTo(sweepX, 0)
          ..lineTo(sweepX + 54, 0)
          ..lineTo(sweepX + 18, floorY)
          ..lineTo(sweepX - 36, floorY)
          ..close();
        final alpha = math.sin(t * math.pi) * 0.34;
        canvas.drawPath(
          band,
          Paint()..color = Colors.white.withOpacity(alpha),
        );
        // Twinkling four-point sparkles across the wall
        const anchors = [
          Offset(0.18, 0.22),
          Offset(0.36, 0.16),
          Offset(0.62, 0.20),
          Offset(0.78, 0.32),
          Offset(0.28, 0.48),
          Offset(0.68, 0.46),
        ];
        for (var i = 0; i < anchors.length; i++) {
          final local = ((t - i * 0.08) / 0.55).clamp(0.0, 1.0);
          if (local <= 0 || local >= 1) continue;
          final s = math.sin(local * math.pi);
          _drawFourPointStar(
            canvas,
            Offset(size.width * anchors[i].dx, floorY * anchors[i].dy),
            12.0 * s,
            Paint()..color = CollectionColors.goldHalo.withOpacity(0.95 * s),
          );
        }
      case HouseSlot.rug:
        final rugCenter = Offset(
          size.width * 0.5,
          floorY + (size.height - floorY) * 0.56,
        );
        _paintExpandingRing(
          canvas,
          rugCenter,
          t,
          maxRadius: size.width * 0.30,
          color: accent,
          aspectY: 0.38,
        );
        _paintRadialBurst(
          canvas,
          rugCenter,
          t,
          count: 10,
          maxRadius: size.width * 0.24,
          colors: [CollectionColors.goldBorder, accent, Colors.white],
          includeHearts: false,
        );
      case HouseSlot.decor:
        final propCenter = Offset(size.width * 0.82, floorY - 26);
        _paintExpandingRing(
          canvas,
          propCenter,
          t,
          maxRadius: 56,
          color: CollectionColors.goldBorder,
        );
        _paintRadialBurst(
          canvas,
          propCenter,
          t,
          count: 10,
          maxRadius: 58,
          colors: [CollectionColors.goldBorder, accent, HouseColors.sunnySun],
          includeHearts: false,
        );
      case HouseSlot.buddy:
        final chipCenter = Offset(size.width * 0.50, floorY - 18);
        _paintExpandingRing(
          canvas,
          chipCenter,
          t,
          maxRadius: 72,
          color: CollectionColors.goldBorder,
        );
        _paintRadialBurst(
          canvas,
          chipCenter,
          t,
          count: 12,
          maxRadius: 78,
          colors: [CollectionColors.goldBorder, HouseColors.sunnySun, accent],
          includeHearts: true,
        );
    }
  }

  void _paintFloatingHearts(Canvas canvas, Offset origin, double t) {
    const count = 7;
    for (var i = 0; i < count; i++) {
      final delay = i * 0.06;
      final p = ((t - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final spread = (i - (count - 1) / 2) * 18.0;
      final sway = math.sin(p * math.pi * 2.5 + i) * 8.0;
      final pos = Offset(
        origin.dx + spread + sway,
        origin.dy - 14 - p * 82.0,
      );
      final alpha = (1.0 - p).clamp(0.0, 1.0);
      final scale = 0.7 + 0.45 * math.sin(p * math.pi);
      if (i.isEven) {
        _drawHeart(
          canvas,
          pos,
          9.5 * scale,
          Paint()..color = HouseColors.rugRainbow1.withOpacity(alpha),
        );
      } else {
        _drawFourPointStar(
          canvas,
          pos,
          9.0 * scale,
          Paint()..color = CollectionColors.goldBorder.withOpacity(alpha),
        );
      }
    }
  }

  void _paintExpandingRing(
    Canvas canvas,
    Offset center,
    double p, {
    required double maxRadius,
    required Color color,
    double aspectY = 1.0,
  }) {
    final eased = Curves.easeOutCubic.transform(p);
    final alpha = (1.0 - p).clamp(0.0, 1.0) * 0.75;
    final rx = maxRadius * eased;
    final ry = rx * aspectY;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()
        ..color = color.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (4.5 * (1.0 - p)).clamp(1.0, 4.5),
    );
  }

  void _paintRadialBurst(
    Canvas canvas,
    Offset center,
    double p, {
    required int count,
    required double maxRadius,
    required List<Color> colors,
    required bool includeHearts,
  }) {
    final eased = Curves.easeOutCubic.transform(p);
    final alpha = (1.0 - p).clamp(0.0, 1.0);
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i / count) * math.pi * 2 + 0.18;
      final radius = maxRadius * eased * (0.72 + 0.34 * ((i % 3) / 2.0));
      final gravityY = 18.0 * p * p;
      final pt = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius + gravityY,
      );
      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(alpha);
      final size = (8.5 + (i % 3) * 2.0) * (1.0 - 0.35 * p);
      if (includeHearts && i % 3 == 0) {
        _drawHeart(canvas, pt, size * 0.9, paint);
      } else if (i.isEven) {
        _drawFourPointStar(canvas, pt, size, paint);
      } else {
        canvas.drawCircle(pt, size * 0.42, paint);
      }
    }
  }

  void _drawFourPointStar(Canvas canvas, Offset c, double r, Paint paint) {
    final inner = r * 0.34;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + inner, c.dy - inner)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + inner, c.dy + inner)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - inner, c.dy + inner)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - inner, c.dy - inner)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.72)
      ..cubicTo(
        c.dx - r * 1.15,
        c.dy + r * 0.05,
        c.dx - r * 0.95,
        c.dy - r * 0.95,
        c.dx,
        c.dy - r * 0.32,
      )
      ..cubicTo(
        c.dx + r * 0.95,
        c.dy - r * 0.95,
        c.dx + r * 1.15,
        c.dy + r * 0.05,
        c.dx,
        c.dy + r * 0.72,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoomFxPainter oldDelegate) =>
      oldDelegate.event.seq != event.seq;
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter({
    required this.wallId,
    required this.rugId,
    required this.decorId,
  });

  final String wallId;
  final String rugId;
  final String decorId;

  @override
  void paint(Canvas canvas, Size size) {
    final floorY = size.height * 0.64;

    // 1. Wall gradient by theme
    final (wallTop, wallBottom) = switch (wallId) {
      'wall_forest' => (
          HouseColors.forestWallTop,
          HouseColors.forestWallBottom,
        ),
      'wall_ocean' => (
          HouseColors.oceanWallTop,
          HouseColors.oceanWallBottom,
        ),
      'wall_starry' => (
          HouseColors.starryWallTop,
          HouseColors.starryWallBottom,
        ),
      _ => (HouseColors.sunnyWallTop, HouseColors.sunnyWallBottom),
    };

    final wallRect = Rect.fromLTWH(0, 0, size.width, floorY);
    canvas.drawRect(
      wallRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wallTop, wallBottom],
        ).createShader(wallRect),
    );

    // Subtle decorative wall dots or stars
    _paintWallPattern(canvas, size, floorY);

    // 2. Cozy window positioned cleanly below stage pill
    _paintWindow(canvas, size, floorY);

    // 3. Baseboard + warm wooden plank floor
    canvas.drawRect(
      Rect.fromLTWH(0, floorY - 8, size.width, 10),
      Paint()..color = HouseColors.baseboard,
    );
    final floorRect = Rect.fromLTWH(0, floorY, size.width, size.height - floorY);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HouseColors.woodFloorTop, HouseColors.woodFloorBottom],
        ).createShader(floorRect),
    );
    final plankPaint = Paint()
      ..color = HouseColors.woodPlankLine.withOpacity(0.45)
      ..strokeWidth = 1.2;
    for (var i = 1; i <= 3; i++) {
      final y = floorY + (size.height - floorY) * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plankPaint);
    }

    // 4. Rug centered under Chíp
    _paintRug(canvas, size, floorY);

    // 5. Corner decor prop on the right side
    _paintDecor(canvas, size, floorY);
  }

  void _paintWallPattern(Canvas canvas, Size size, double floorY) {
    final isStarry = wallId == 'wall_starry';
    final dotPaint = Paint()
      ..color = isStarry
          ? HouseColors.starryMoon.withOpacity(0.45)
          : Colors.white.withOpacity(0.32);
    const step = 36.0;
    for (var y = 20.0; y < floorY - 14; y += step) {
      for (var x = 22.0; x < size.width - 14; x += step) {
        final offsetX = ((y ~/ step).isOdd) ? step * 0.5 : 0.0;
        canvas.drawCircle(
          Offset(x + offsetX, y),
          isStarry ? 2.2 : 3.0,
          dotPaint,
        );
      }
    }
  }

  void _paintWindow(Canvas canvas, Size size, double floorY) {
    final winW = (size.width * 0.28).clamp(84.0, 146.0);
    final winH = (floorY * 0.50).clamp(62.0, 108.0);
    final winRect = Rect.fromLTWH(
      size.width * 0.12,
      floorY * 0.30,
      winW,
      winH,
    );
    final rrect = RRect.fromRectAndRadius(winRect, const Radius.circular(14));

    canvas.save();
    canvas.clipRRect(rrect);

    final skyColor = switch (wallId) {
      'wall_forest' => HouseColors.forestSky,
      'wall_ocean' => HouseColors.oceanSky,
      'wall_starry' => HouseColors.starrySky,
      _ => HouseColors.sunnySky,
    };
    canvas.drawRect(winRect, Paint()..color = skyColor);

    switch (wallId) {
      case 'wall_forest':
        canvas.drawCircle(
          Offset(winRect.left + winW * 0.28, winRect.bottom),
          winW * 0.34,
          Paint()..color = HouseColors.forestLeaf,
        );
        canvas.drawCircle(
          Offset(winRect.left + winW * 0.76, winRect.bottom + 4),
          winW * 0.38,
          Paint()..color = HouseColors.plantLight,
        );
      case 'wall_ocean':
        canvas.drawCircle(
          Offset(winRect.right - 22, winRect.top + 20),
          12,
          Paint()..color = HouseColors.sunnySun,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            winRect.left,
            winRect.top + winH * 0.58,
            winW,
            winH * 0.42,
          ),
          Paint()..color = HouseColors.oceanWave.withOpacity(0.75),
        );
      case 'wall_starry':
        final moonCenter = Offset(winRect.right - 24, winRect.top + 22);
        canvas.drawCircle(
          moonCenter,
          12,
          Paint()..color = HouseColors.starryMoon,
        );
        canvas.drawCircle(
          moonCenter.translate(5, -3),
          10,
          Paint()..color = HouseColors.starrySky,
        );
        final starP = Paint()..color = HouseColors.starryMoon;
        canvas.drawCircle(
            Offset(winRect.left + 20, winRect.top + 24), 2.5, starP);
        canvas.drawCircle(
            Offset(winRect.left + 44, winRect.top + 42), 2.0, starP);
        canvas.drawCircle(
            Offset(winRect.left + 28, winRect.bottom - 20), 2.2, starP);
      default:
        canvas.drawCircle(
          Offset(winRect.right - 22, winRect.top + 20),
          13,
          Paint()..color = HouseColors.sunnySun,
        );
        final cloudP = Paint()..color = Colors.white.withOpacity(0.92);
        canvas.drawCircle(
            Offset(winRect.left + 24, winRect.bottom - 18), 11, cloudP);
        canvas.drawCircle(
            Offset(winRect.left + 38, winRect.bottom - 20), 14, cloudP);
        canvas.drawCircle(
            Offset(winRect.left + 52, winRect.bottom - 17), 10, cloudP);
    }

    canvas.restore();

    final framePaint = Paint()
      ..color = HouseColors.windowFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRRect(rrect, framePaint);
    canvas.drawLine(
      Offset(winRect.center.dx, winRect.top),
      Offset(winRect.center.dx, winRect.bottom),
      Paint()
        ..color = HouseColors.windowFrame
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(winRect.left, winRect.center.dy),
      Offset(winRect.right, winRect.center.dy),
      Paint()
        ..color = HouseColors.windowFrame
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(winRect.left - 6, winRect.bottom - 2, winW + 12, 9),
        const Radius.circular(4),
      ),
      Paint()..color = HouseColors.windowSill,
    );
  }

  void _paintRug(Canvas canvas, Size size, double floorY) {
    final rugW = (size.width * 0.56).clamp(160.0, 320.0);
    final rugH = (size.height - floorY) * 0.62;
    final center =
        Offset(size.width * 0.5, floorY + (size.height - floorY) * 0.56);
    final oval = Rect.fromCenter(center: center, width: rugW, height: rugH);

    switch (rugId) {
      case 'rug_rainbow':
        const colors = [
          HouseColors.rugRainbow1,
          HouseColors.rugRainbow2,
          HouseColors.rugRainbow3,
          HouseColors.rugRainbow4,
        ];
        for (var i = 0; i < colors.length; i++) {
          final scale = 1.0 - i * 0.2;
          canvas.drawOval(
            Rect.fromCenter(
              center: center,
              width: rugW * scale,
              height: rugH * scale,
            ),
            Paint()..color = colors[i],
          );
        }
      case 'rug_cloud':
        canvas.drawOval(oval, Paint()..color = HouseColors.rugCloud);
        canvas.drawOval(
          oval,
          Paint()
            ..color = HouseColors.rugCloudEdge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        final bumpP = Paint()..color = HouseColors.rugCloud;
        for (var i = 0; i < 6; i++) {
          final a = (i / 6) * math.pi * 2;
          canvas.drawCircle(
            Offset(
              center.dx + math.cos(a) * rugW * 0.42,
              center.dy + math.sin(a) * rugH * 0.36,
            ),
            rugH * 0.22,
            bumpP,
          );
        }
      case 'rug_star':
        canvas.drawOval(oval, Paint()..color = HouseColors.rugStar);
        canvas.drawOval(
          oval,
          Paint()
            ..color = HouseColors.rugStarEdge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        _drawStar(
          canvas,
          center,
          rugH * 0.34,
          Paint()..color = HouseColors.rugStarEdge.withOpacity(0.45),
        );
      default:
        canvas.drawOval(oval, Paint()..color = HouseColors.rugCream);
        canvas.drawOval(
          oval,
          Paint()
            ..color = HouseColors.rugCreamEdge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
    }
  }

  void _paintDecor(Canvas canvas, Size size, double floorY) {
    final baseX = size.width * 0.82;
    final baseY = floorY + 8;

    switch (decorId) {
      case 'decor_plant':
        final pot = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(baseX, baseY - 14), width: 34, height: 28),
          const Radius.circular(6),
        );
        canvas.drawRRect(pot, Paint()..color = HouseColors.potClay);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(baseX - 12, baseY - 38), width: 20, height: 30),
          Paint()..color = HouseColors.plantDark,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(baseX + 12, baseY - 38), width: 20, height: 30),
          Paint()..color = HouseColors.plantDark,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(baseX, baseY - 46), width: 22, height: 36),
          Paint()..color = HouseColors.plantLight,
        );
      case 'decor_lamp':
        canvas.drawCircle(
          Offset(baseX, baseY - 58),
          34,
          Paint()..color = HouseColors.lampGlow.withOpacity(0.42),
        );
        canvas.drawLine(
          Offset(baseX, baseY),
          Offset(baseX, baseY - 48),
          Paint()
            ..color = HouseColors.lampStand
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(baseX, baseY), width: 28, height: 7),
            const Radius.circular(4),
          ),
          Paint()..color = HouseColors.lampStand,
        );
        canvas.drawCircle(
          Offset(baseX, baseY - 58),
          16,
          Paint()..color = HouseColors.lampGlow,
        );
      case 'decor_globe':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(baseX, baseY - 4), width: 28, height: 8),
            const Radius.circular(4),
          ),
          Paint()..color = HouseColors.shelfWood,
        );
        canvas.drawLine(
          Offset(baseX, baseY - 8),
          Offset(baseX, baseY - 22),
          Paint()
            ..color = HouseColors.shelfWood
            ..strokeWidth = 3.5,
        );
        final globeC = Offset(baseX, baseY - 38);
        canvas.drawCircle(globeC, 19, Paint()..color = HouseColors.globeWater);
        canvas.drawOval(
          Rect.fromCenter(
              center: globeC.translate(-5, -4), width: 14, height: 11),
          Paint()..color = HouseColors.globeLand,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: globeC.translate(6, 5), width: 12, height: 9),
          Paint()..color = HouseColors.globeLand,
        );
      default:
        final shelfRect = Rect.fromLTWH(baseX - 30, baseY - 54, 60, 54);
        canvas.drawRRect(
          RRect.fromRectAndRadius(shelfRect, const Radius.circular(8)),
          Paint()..color = HouseColors.shelfWood,
        );
        final inner1 = Rect.fromLTWH(baseX - 24, baseY - 48, 48, 19);
        final inner2 = Rect.fromLTWH(baseX - 24, baseY - 24, 48, 19);
        final backP = Paint()..color = HouseColors.woodFloorTop.withOpacity(0.55);
        canvas.drawRect(inner1, backP);
        canvas.drawRect(inner2, backP);
        canvas.drawRect(Rect.fromLTWH(baseX - 21, baseY - 44, 9, 15),
            Paint()..color = HouseColors.bookRed);
        canvas.drawRect(Rect.fromLTWH(baseX - 10, baseY - 46, 9, 17),
            Paint()..color = HouseColors.bookBlue);
        canvas.drawRect(Rect.fromLTWH(baseX + 1, baseY - 43, 9, 14),
            Paint()..color = HouseColors.bookYellow);
        canvas.drawRect(Rect.fromLTWH(baseX - 19, baseY - 21, 9, 16),
            Paint()..color = HouseColors.bookGreen);
        canvas.drawRect(Rect.fromLTWH(baseX - 8, baseY - 19, 10, 14),
            Paint()..color = HouseColors.bookRed);
        canvas.drawRect(Rect.fromLTWH(baseX + 5, baseY - 22, 9, 17),
            Paint()..color = HouseColors.bookBlue);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.wallId != wallId ||
      oldDelegate.rugId != rugId ||
      oldDelegate.decorId != decorId;
}
