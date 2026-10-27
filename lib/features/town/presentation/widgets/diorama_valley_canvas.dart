import 'package:flutter/material.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_ground_painter.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/alphabet_castle_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/market_building_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/math_mushroom_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/pet_sanctuary_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/wonder_tree_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/interactive_pippo_character.dart';

/// The central 3D Diorama Valley Canvas (Virtual size 800 x 1350):
/// - Tablet / iPad: 100% Panoramic Diorama view (FittedBox)
/// - Mobile / Phone: Interactive Smooth Pan / Zoom Viewport (InteractiveViewer)
class DioramaValleyCanvas extends StatefulWidget {
  final VoidCallback onMarketTap;
  final VoidCallback onMathMushroomTap;
  final VoidCallback onWonderTreeTap;
  final VoidCallback onPetSanctuaryTap;
  final VoidCallback onAlphabetCastleTap;

  const DioramaValleyCanvas({
    super.key,
    required this.onMarketTap,
    required this.onMathMushroomTap,
    required this.onWonderTreeTap,
    required this.onPetSanctuaryTap,
    required this.onAlphabetCastleTap,
  });

  @override
  State<DioramaValleyCanvas> createState() => _DioramaValleyCanvasState();
}

class _DioramaValleyCanvasState extends State<DioramaValleyCanvas> {
  static const double virtualWidth = 800.0;
  static const double virtualHeight = 1350.0;

  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _centerOnPippo(Size screenSize) {
    if (screenSize.width <= 0 || screenSize.height <= 0) return;

    // Scale so the full diorama width fits comfortably on phone
    final fitScale = (screenSize.width / virtualWidth).clamp(0.48, 1.10);
    final dx = (screenSize.width - (virtualWidth * fitScale)) / 2;
    // Position Pippo in comfortable central viewport
    final pippoY = 710.0 * fitScale;
    final dy = (screenSize.height * 0.48) - pippoY;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(fitScale);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isTablet = screenWidth >= 600 || MediaQuery.of(context).size.shortestSide >= 600;

        final dioramaWorld = SizedBox(
          width: virtualWidth,
          height: virtualHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // 1. Full-Coverage Ground Landscape (Valley, River, Bridge, Cobblestone Paths, Pads)
              Positioned.fill(
                child: CustomPaint(
                  painter: DioramaGroundPainter(scale: 1.0),
                ),
              ),

              // 2. TIER 2: Alphabet Castle (Elevated Top Hill - Scale 0.88)
              Positioned(
                top: 95,
                left: (virtualWidth / 2) - (110 * 0.88),
                child: AlphabetCastleBuildingWidget(
                  scale: 0.88,
                  onTap: widget.onAlphabetCastleTap,
                ),
              ),

              // 3. TIER 3: Market Building (Middle Left - Scale 1.05)
              Positioned(
                top: 420,
                left: 65,
                child: MarketBuildingWidget(
                  scale: 1.05,
                  onTap: widget.onMarketTap,
                ),
              ),

              // 4. TIER 3: Wonder Tree (Middle Right across River - Scale 1.05)
              Positioned(
                top: 420,
                right: 65,
                child: WonderTreeBuildingWidget(
                  scale: 1.05,
                  onTap: widget.onWonderTreeTap,
                ),
              ),

              // 5. TIER 3 CENTER: Interactive Mascot Pippo at Village Plaza (Scale 1.15)
              const Positioned(
                top: 610,
                left: (virtualWidth / 2) - (65 * 1.15),
                child: InteractivePippoCharacter(scale: 1.15),
              ),

              // 6. TIER 4: Math Mushroom (Foreground Lower Left - Scale 1.18)
              Positioned(
                top: 910,
                left: 65,
                child: MathMushroomWidget(
                  scale: 1.18,
                  onTap: widget.onMathMushroomTap,
                ),
              ),

              // 7. TIER 4: Pet Sanctuary (Foreground Lower Right - Scale 1.18)
              Positioned(
                top: 910,
                right: 65,
                child: PetSanctuaryBuildingWidget(
                  scale: 1.18,
                  onTap: widget.onPetSanctuaryTap,
                ),
              ),
            ],
          ),
        );

        if (isTablet) {
          // On Tablet/iPad: Grand panoramic view scaled to fit screen perfectly
          return Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: dioramaWorld,
            ),
          );
        }

        // On Phone: Interactive smooth pan / zoom viewport
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _transformationController.value.isIdentity()) {
            _centerOnPippo(Size(screenWidth, screenHeight));
          }
        });

        return InteractiveViewer(
          constrained: false,
          transformationController: _transformationController,
          minScale: 0.40,
          maxScale: 1.60,
          boundaryMargin: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
          clipBehavior: Clip.none,
          child: dioramaWorld,
        );
      },
    );
  }
}
