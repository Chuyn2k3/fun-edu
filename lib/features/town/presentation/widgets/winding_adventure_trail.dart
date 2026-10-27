import 'package:flutter/material.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/alphabet_castle_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/market_building_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/math_mushroom_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/pet_sanctuary_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/wonder_tree_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/interactive_pippo_character.dart';

class WindingAdventureTrail extends StatelessWidget {
  final VoidCallback onMarketTap;
  final VoidCallback onMathMushroomTap;
  final VoidCallback onWonderTreeTap;
  final VoidCallback onPetSanctuaryTap;
  final VoidCallback onAlphabetCastleTap;

  const WindingAdventureTrail({
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
        final screenWidth = constraints.maxWidth;
        // Dynamically compute optimal scale based on device width
        final buildingScale = (screenWidth / 430).clamp(0.78, 1.05);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 80, bottom: 110),
          child: Column(
            children: [
              // 1. 3D Wooden Carved World Title Sign
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF5D4037), Color(0xFF3E2723)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        offset: const Offset(0, 6),
                        blurRadius: 10,
                      ),
                      const BoxShadow(
                        color: Color(0xFFFFECB3),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌿', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'Làng Cổ Tích FunEdu',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('✨', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),

              // 2. Interactive Mascot Pippo 3D at the Village Entrance
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InteractivePippoCharacter(scale: buildingScale * 1.05),
              ),

              // 3. Winding Adventure S-Curve Trail with Connected Road
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Continuous Curved Cobblestone Pathway Canvas
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WindingRoadPainter(
                        screenWidth: screenWidth,
                        buildingScale: buildingScale,
                      ),
                    ),
                  ),

                  // Building Stations Along the Trail
                  Column(
                    children: [
                      // Station 1: Tiệm Tạp Hóa Nhí (Left bias)
                      _buildStationRow(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 18, right: 12, top: 10, bottom: 24),
                        child: MarketBuildingWidget(
                          scale: buildingScale,
                          onTap: onMarketTap,
                        ),
                      ),

                      // Station 2: Nhà Nấm Toán Học (Right bias)
                      _buildStationRow(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(left: 12, right: 18, top: 12, bottom: 24),
                        child: MathMushroomWidget(
                          scale: buildingScale,
                          onTap: onMathMushroomTap,
                        ),
                      ),

                      // Station 3: Cây Tri Thức (Left bias)
                      _buildStationRow(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 18, right: 12, top: 12, bottom: 24),
                        child: WonderTreeBuildingWidget(
                          scale: buildingScale,
                          onTap: onWonderTreeTap,
                        ),
                      ),

                      // Station 4: Trại Ấp Thú (Right bias)
                      _buildStationRow(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(left: 12, right: 18, top: 12, bottom: 24),
                        child: PetSanctuaryBuildingWidget(
                          scale: buildingScale,
                          onTap: onPetSanctuaryTap,
                        ),
                      ),

                      // Station 5: Lâu Đài Chữ Cái (Center Top Pinnacle)
                      _buildStationRow(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
                        child: AlphabetCastleBuildingWidget(
                          scale: buildingScale * 1.08,
                          onTap: onAlphabetCastleTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStationRow({
    required Alignment alignment,
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}

// -------------------------------------------------------------
// Winding Cobblestone Road Custom Painter (Đường mòn đá sỏi uốn lượn)
// -------------------------------------------------------------
class _WindingRoadPainter extends CustomPainter {
  final double screenWidth;
  final double buildingScale;

  _WindingRoadPainter({
    required this.screenWidth,
    required this.buildingScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Road path: S-curve snaking from entrance up to Station 5
    // Key milestones:
    // P0: Entrance bottom center (w*0.5, 0)
    // P1: Station 1 bottom left (w*0.35, h*0.16)
    // P2: Station 2 mid right (w*0.65, h*0.36)
    // P3: Station 3 mid left (w*0.35, h*0.56)
    // P4: Station 4 upper right (w*0.65, h*0.76)
    // P5: Station 5 pinnacle top center (w*0.5, h*0.92)

    final roadPath = Path()
      ..moveTo(w * 0.5, 10)
      ..cubicTo(w * 0.45, h * 0.08, w * 0.30, h * 0.10, w * 0.35, h * 0.17)
      ..cubicTo(w * 0.40, h * 0.24, w * 0.70, h * 0.28, w * 0.65, h * 0.37)
      ..cubicTo(w * 0.60, h * 0.46, w * 0.30, h * 0.48, w * 0.35, h * 0.57)
      ..cubicTo(w * 0.40, h * 0.66, w * 0.70, h * 0.68, w * 0.65, h * 0.77)
      ..cubicTo(w * 0.60, h * 0.85, w * 0.45, h * 0.88, w * 0.5, h * 0.94);

    // 1. Road Drop Shadow (Bóng đổ của con đường trên nền cỏ)
    final shadowPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.4)
      ..strokeWidth = 46.0 * buildingScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(roadPath, shadowPaint);

    // 2. Road Dirt / Cobblestone Underlayer (Nền đất đá sỏi vàng)
    final dirtPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFD7CCC8), // Đá sỏi sáng
          Color(0xFFFFE082), // Cát vàng mịn
          Color(0xFFBCAAA4), // Đá ấm
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 38.0 * buildingScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(roadPath, dirtPaint);

    // 3. Cobblestone Stepping Stones (Đá lát đường nổi bật)
    final stonePaint = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.75)
      ..strokeWidth = 24.0 * buildingScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(roadPath, stonePaint);

    // 4. Trail Border Highlights (Đường gạch viền lấp lánh)
    final borderDashPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(roadPath, borderDashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
