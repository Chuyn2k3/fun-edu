import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../house/house_model.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';

/// Live cozy room stage for Nhà Chíp: paints the equipped wall theme, window,
/// wooden floor, rug and corner prop, and places Chíp + accessory interactively
/// in the center. Tapping Chíp triggers [onPetChip].
class RoomStage extends StatelessWidget {
  const RoomStage({
    super.key,
    required this.state,
    required this.happyBounce,
    required this.floatingBadge,
    required this.onPetChip,
    required this.tablet,
  });

  final ChipHouseState state;
  final bool happyBounce;
  final String? floatingBadge;
  final VoidCallback onPetChip;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final wallId = state.equippedId(HouseSlot.wall);
    final rugId = state.equippedId(HouseSlot.rug);
    final decorId = state.equippedId(HouseSlot.decor);
    final buddyId = state.equippedId(HouseSlot.buddy);

    final chipImage = switch (buddyId) {
      'buddy_crayon' => happyBounce ? AppImages.chipJoy : AppImages.chipWrite,
      _ => happyBounce ? AppImages.chipJoy : AppImages.chipMain,
    };

    final stageHeight = tablet ? 300.0 : 236.0;
    final chipSize = tablet ? 148.0 : 120.0;

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
            RepaintBoundary(
              child: CustomPaint(
                painter: _RoomPainter(
                  wallId: wallId,
                  rugId: rugId,
                  decorId: decorId,
                ),
              ),
            ),

            // Star pillow buddy resting next to Chíp on the rug
            if (buddyId == 'buddy_pillow')
              Positioned(
                bottom: tablet ? 28 : 20,
                left: 0,
                right: tablet ? 136 : 112,
                child: Center(
                  child: Image.asset(
                    AppImages.icStar,
                    width: tablet ? 56 : 44,
                    height: tablet ? 56 : 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            // Interactive Chíp mascot in the center of the rug
            Align(
              alignment: const Alignment(0, 0.72),
              child: Semantics(
                button: true,
                label: 'Vuốt ve Chíp Chíp',
                child: GestureDetector(
                  key: const ValueKey('house-pet-chip'),
                  onTap: onPetChip,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedScale(
                    scale: happyBounce ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.elasticOut,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Image.asset(
                          chipImage,
                          width: chipSize,
                          height: chipSize,
                          fit: BoxFit.contain,
                        ),
                        if (buddyId == 'buddy_crown')
                          Positioned(
                            top: tablet ? -18 : -14,
                            child: Image.asset(
                              AppImages.icCrown,
                              width: tablet ? 46 : 38,
                              height: tablet ? 46 : 38,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Gentle hint chip at top-left
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
                  'Cấp ${state.stage.level} · ${state.stage.title}',
                  style: TextStyle(
                    fontSize: tablet ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),

            // Floating +XP / heart toast after feeding or petting
            if (floatingBadge != null)
              Positioned(
                top: 12,
                right: 12,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(floatingBadge),
                  tween: Tween(begin: 0.85, end: 1.0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
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
                      floatingBadge!,
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

    // 2. Cozy window centered slightly left-of-center
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
        canvas.drawCircle(Offset(x + offsetX, y), isStarry ? 2.2 : 3.0, dotPaint);
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

    // Window sky backdrop by theme
    final skyColor = switch (wallId) {
      'wall_forest' => HouseColors.forestSky,
      'wall_ocean' => HouseColors.oceanSky,
      'wall_starry' => HouseColors.starrySky,
      _ => HouseColors.sunnySky,
    };
    canvas.drawRect(winRect, Paint()..color = skyColor);

    switch (wallId) {
      case 'wall_forest':
        // Rolling green canopy hills
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
        // Ocean water band + sun
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
        // Crescent moon & tiny stars
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
        // Warm sun + soft cloud
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

    // Wooden window frame & mullions
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
    // Window sill
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
    final center = Offset(size.width * 0.5, floorY + (size.height - floorY) * 0.56);
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
        // Fluffy cloud bumps around edge
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
        // Cute clay pot + leafy green plant
        final pot = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(baseX, baseY - 14), width: 34, height: 28),
          const Radius.circular(6),
        );
        canvas.drawRRect(pot, Paint()..color = HouseColors.potClay);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(baseX - 12, baseY - 38), width: 20, height: 30),
          Paint()..color = HouseColors.plantDark,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(baseX + 12, baseY - 38), width: 20, height: 30),
          Paint()..color = HouseColors.plantDark,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(baseX, baseY - 46), width: 22, height: 36),
          Paint()..color = HouseColors.plantLight,
        );
      case 'decor_lamp':
        // Cozy floor lamp with glowing warm halo
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
        // Little desk globe on wooden stand
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(baseX, baseY - 4), width: 28, height: 8),
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
          Rect.fromCenter(center: globeC.translate(-5, -4), width: 14, height: 11),
          Paint()..color = HouseColors.globeLand,
        );
        canvas.drawOval(
          Rect.fromCenter(center: globeC.translate(6, 5), width: 12, height: 9),
          Paint()..color = HouseColors.globeLand,
        );
      default:
        // Small wooden bookshelf with colorful books
        final shelfRect = Rect.fromLTWH(baseX - 30, baseY - 54, 60, 54);
        canvas.drawRRect(
          RRect.fromRectAndRadius(shelfRect, const Radius.circular(8)),
          Paint()..color = HouseColors.shelfWood,
        );
        // Inner shelves
        final inner1 = Rect.fromLTWH(baseX - 24, baseY - 48, 48, 19);
        final inner2 = Rect.fromLTWH(baseX - 24, baseY - 24, 48, 19);
        final backP = Paint()..color = HouseColors.woodFloorTop.withOpacity(0.55);
        canvas.drawRect(inner1, backP);
        canvas.drawRect(inner2, backP);
        // Books row 1
        canvas.drawRect(
            Rect.fromLTWH(baseX - 21, baseY - 44, 9, 15), Paint()..color = HouseColors.bookRed);
        canvas.drawRect(
            Rect.fromLTWH(baseX - 10, baseY - 46, 9, 17), Paint()..color = HouseColors.bookBlue);
        canvas.drawRect(
            Rect.fromLTWH(baseX + 1, baseY - 43, 9, 14), Paint()..color = HouseColors.bookYellow);
        // Books row 2
        canvas.drawRect(
            Rect.fromLTWH(baseX - 19, baseY - 21, 9, 16), Paint()..color = HouseColors.bookGreen);
        canvas.drawRect(
            Rect.fromLTWH(baseX - 8, baseY - 19, 10, 14), Paint()..color = HouseColors.bookRed);
        canvas.drawRect(
            Rect.fromLTWH(baseX + 5, baseY - 22, 9, 17), Paint()..color = HouseColors.bookBlue);
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
