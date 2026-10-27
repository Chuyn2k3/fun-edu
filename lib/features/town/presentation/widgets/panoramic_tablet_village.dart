import 'package:flutter/material.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/alphabet_castle_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/market_building_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/math_mushroom_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/pet_sanctuary_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/wonder_tree_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/interactive_pippo_character.dart';

class PanoramicTabletVillage extends StatelessWidget {
  final VoidCallback onMarketTap;
  final VoidCallback onMathMushroomTap;
  final VoidCallback onWonderTreeTap;
  final VoidCallback onPetSanctuaryTap;
  final VoidCallback onAlphabetCastleTap;

  const PanoramicTabletVillage({
    super.key,
    required this.onMarketTap,
    required this.onMathMushroomTap,
    required this.onWonderTreeTap,
    required this.onPetSanctuaryTap,
    required this.onAlphabetCastleTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final scale = (w / 1024).clamp(0.85, 1.25);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Tablet Cobblestone Road Network Painter
            CustomPaint(
              size: Size(w, h),
              painter: _TabletVillageRoadPainter(scale: scale),
            ),

            // 2. Village Entrance Banner (Top Center)
            Positioned(
              top: 75 * scale,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28 * scale,
                    vertical: 8 * scale,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                    ),
                    borderRadius: BorderRadius.circular(24 * scale),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 3 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 4 * scale),
                        blurRadius: 8 * scale,
                      ),
                    ],
                  ),
                  child: Text(
                    '🏰 Thung Lũng Cổ Tích FunEdu 🌿',
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Station 5: Alphabet Castle (Elevated Hilltop - Top Center)
            Positioned(
              top: 130 * scale,
              left: (w / 2) - (95 * scale),
              child: AlphabetCastleBuildingWidget(
                scale: scale * 1.15,
                onTap: onAlphabetCastleTap,
              ),
            ),

            // 4. Station 3: Wonder Tree (Enchanted Grove - Upper Left)
            Positioned(
              top: 170 * scale,
              left: w * 0.12,
              child: WonderTreeBuildingWidget(
                scale: scale * 1.05,
                onTap: onWonderTreeTap,
              ),
            ),

            // 5. Station 4: Pet Sanctuary (Meadow - Upper Right)
            Positioned(
              top: 170 * scale,
              right: w * 0.12,
              child: PetSanctuaryBuildingWidget(
                scale: scale * 1.05,
                onTap: onPetSanctuaryTap,
              ),
            ),

            // 6. Station 1: Tiệm Tạp Hóa Nhí (Riverside Dock - Lower Left)
            Positioned(
              bottom: 95 * scale,
              left: w * 0.20,
              child: MarketBuildingWidget(
                scale: scale * 1.08,
                onTap: onMarketTap,
              ),
            ),

            // 7. Station 2: Math Mushroom (Enchanted Clearing - Lower Right)
            Positioned(
              bottom: 95 * scale,
              right: w * 0.20,
              child: MathMushroomWidget(
                scale: scale * 1.08,
                onTap: onMathMushroomTap,
              ),
            ),

            // 8. Interactive Pippo 3D Mascot at Central Welcome Plaza
            Positioned(
              bottom: 85 * scale,
              left: (w / 2) - (45 * scale),
              child: InteractivePippoCharacter(scale: scale * 1.15),
            ),
          ],
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Tablet Village Road Network Painter (Mạng lưới đường sỏi cho iPad)
// -------------------------------------------------------------
class _TabletVillageRoadPainter extends CustomPainter {
  final double scale;

  _TabletVillageRoadPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final roadPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFD7CCC8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 36.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.35)
      ..strokeWidth = 44.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Plaza circle in center
    final centerPlaza = Offset(w / 2, h * 0.65);
    final plazaRadius = 55.0 * scale;

    // Branches from center plaza to all buildings:
    // To Market (lower left)
    final toMarketPath = Path()
      ..moveTo(centerPlaza.dx, centerPlaza.dy)
      ..quadraticBezierTo(w * 0.38, h * 0.70, w * 0.26, h * 0.76);

    // To Math Mushroom (lower right)
    final toMathPath = Path()
      ..moveTo(centerPlaza.dx, centerPlaza.dy)
      ..quadraticBezierTo(w * 0.62, h * 0.70, w * 0.74, h * 0.76);

    // To Wonder Tree (upper left)
    final toTreePath = Path()
      ..moveTo(centerPlaza.dx, centerPlaza.dy)
      ..quadraticBezierTo(w * 0.32, h * 0.50, w * 0.20, h * 0.38);

    // To Pet Sanctuary (upper right)
    final toPetPath = Path()
      ..moveTo(centerPlaza.dx, centerPlaza.dy)
      ..quadraticBezierTo(w * 0.68, h * 0.50, w * 0.80, h * 0.38);

    // To Castle (top center)
    final toCastlePath = Path()
      ..moveTo(centerPlaza.dx, centerPlaza.dy)
      ..lineTo(w / 2, h * 0.32);

    final fullNetwork = Path()
      ..addPath(toMarketPath, Offset.zero)
      ..addPath(toMathPath, Offset.zero)
      ..addPath(toTreePath, Offset.zero)
      ..addPath(toPetPath, Offset.zero)
      ..addPath(toCastlePath, Offset.zero);

    canvas.drawPath(fullNetwork, shadowPaint);
    canvas.drawCircle(centerPlaza, plazaRadius + 4, shadowPaint);

    canvas.drawPath(fullNetwork, roadPaint);
    canvas.drawCircle(centerPlaza, plazaRadius, roadPaint);

    // Stepping stones highlight
    final stonePaint = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.7)
      ..strokeWidth = 20.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fullNetwork, stonePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
