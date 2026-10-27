import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';
import 'package:fun_edu/feature/game_feature/game_page.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_bottom_dock.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/alphabet_castle_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/market_building_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/math_mushroom_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/pet_sanctuary_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_buildings/wonder_tree_widget.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_world_background.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_world_hud.dart';
import 'package:fun_edu/features/town/presentation/widgets/interactive_pippo_character.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:go_router/go_router.dart';

class TownScreen extends StatefulWidget {
  const TownScreen({super.key});

  @override
  State<TownScreen> createState() => _TownScreenState();
}

class _TownScreenState extends State<TownScreen> {
  int _activeDockIndex = 0;

  void _showActionDialog({
    required String title,
    required String message,
    required String emoji,
  }) {
    AudioManager().playSfx(AudioSfx.levelVictory);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFFFB300), width: 3),
        ),
        backgroundColor: Colors.white,
        title: Center(
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 22,
                  color: Color(0xFF3E2723),
                ),
              ),
            ],
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4037),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tuyệt Vời!',
              style: TextStyle(fontFamily: 'LilitaOne', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackpackModal() {
    AudioManager().playSfx(AudioSfx.levelVictory);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black26, offset: Offset(0, -6), blurRadius: 16),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎒 Balo Thần Kỳ Của Bé',
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 22,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBackpackItem('🍎 Táo Đỏ', 'x12 quả'),
                _buildBackpackItem('💧 Nước Thần', '3 giọt'),
                _buildBackpackItem('🐣 Trứng Rồng', 'Đang ấp'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng Balo', style: TextStyle(fontFamily: 'LilitaOne', fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackpackItem(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB300), width: 2),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontFamily: 'LilitaOne', color: Color(0xFFE65100), fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Immersive Animated Scenery Background (Sky + Sun + Hills + Windmill + River)
          const GameWorldBackground(),

          // 2. Ambient Floating Sparkles & Particles
          const AmbientParticlesLayer(particleCount: 16),

          // 3. Responsive Game World Content Area
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600 || MediaQuery.of(context).size.shortestSide >= 600;

                return Stack(
                  children: [
                    // Main Scrollable / Viewport Content
                    Positioned.fill(
                      child: isTablet
                          ? _buildTabletPanoramaView(context, constraints)
                          : _buildMobileAdventureTrail(context, constraints),
                    ),

                    // Top Floating Game HUD Bar
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: GameWorldHud(
                        coins: 150,
                        magicDew: 1,
                        playerName: 'Bé Yêu',
                      ),
                    ),

                    // Bottom Floating Game Navigation Dock
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: GameBottomDock(
                        activeIndex: _activeDockIndex,
                        onMapTap: () {
                          setState(() => _activeDockIndex = 0);
                        },
                        onArcadeTap: () {
                          setState(() => _activeDockIndex = 1);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ListGamePage()),
                          );
                        },
                        onBackpackTap: () {
                          _showBackpackModal();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Mobile Phone View: Vertical Winding Adventure Trail
  // -------------------------------------------------------------
  Widget _buildMobileAdventureTrail(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 80, bottom: 90),
      child: Column(
        children: [
          // World Banner Header on mobile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Làng Cổ Tích FunEdu',
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Interactive Mascot Pippo Greeting
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: InteractivePippoCharacter(scale: 0.95),
          ),

          // Station 1: Siêu Thị Pippo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: MarketBuildingWidget(
              scale: 1.0,
              onTap: () {
                context.pushNamed(GoRouterName.shopGameLevelSelect.routeName);
              },
            ),
          ),

          // Wooden trail connector divider with flowers
          _buildTrailConnector('🍃 🌸 🍃'),

          // Station 2: Học Viện Toán Học (Nhà Toán Học)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: MathMushroomWidget(
              scale: 1.0,
              onTap: () {
                context.pushNamed(GoRouterName.numberStudy.routeName);
              },
            ),
          ),

          _buildTrailConnector('🍄 ⭐ 🍄'),

          // Station 3: Cây Tri Thức
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: WonderTreeBuildingWidget(
              scale: 1.0,
              onTap: () {
                _showActionDialog(
                  title: 'Cây Tri Thức',
                  message: 'Bé đã tưới 1 Giọt Nước Thần!\nCây lớn thêm 1 bậc và sắp ra quả thần kỳ rồi đó! 🍎✨',
                  emoji: '💧🌳',
                );
              },
            ),
          ),

          _buildTrailConnector('🌿 🦋 🌿'),

          // Station 4: Trại Ấp Thú
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: PetSanctuaryBuildingWidget(
              scale: 1.0,
              onTap: () {
                _showActionDialog(
                  title: 'Trại Ấp Thú',
                  message: 'Bong! Bé vừa gõ búa phép thuật!\nVỏ trứng đã nứt thêm 1 vết, 1 ngày nữa sẽ nở bạn Rồng Con! 🐉✨',
                  emoji: '🔨🐣',
                );
              },
            ),
          ),

          _buildTrailConnector('✨ 🏰 ✨'),

          // Station 5: Lâu Đài Chữ Cái
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AlphabetCastleBuildingWidget(
              scale: 1.0,
              onTap: () {
                _showActionDialog(
                  title: 'Lâu Đài Chữ Cái',
                  message: 'Pippo đang xây dựng Lâu Đài Ngôn Ngữ với các bạn thú mới. Bé cùng chờ đón nhé! 🏰🎈',
                  emoji: '🏰✨',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailConnector(String decor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(decor, style: const TextStyle(fontSize: 14)),
          ),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Tablet / iPad View: Grand Panoramic Valley Layout
  // -------------------------------------------------------------
  Widget _buildTabletPanoramaView(BuildContext context, BoxConstraints constraints) {
    final scale = (constraints.maxWidth / 980).clamp(0.85, 1.25);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 85 * scale,
        bottom: 80 * scale,
        left: 32 * scale,
        right: 32 * scale,
      ),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Interactive Mascot Pippo standing at entrance
            Padding(
              padding: EdgeInsets.only(right: 24 * scale, bottom: 20 * scale),
              child: InteractivePippoCharacter(scale: scale),
            ),

            // Station 1: Siêu Thị Pippo
            MarketBuildingWidget(
              scale: scale,
              onTap: () {
                context.pushNamed(GoRouterName.shopGameLevelSelect.routeName);
              },
            ),
            SizedBox(width: 20 * scale),

            // Station 2: Nhà Toán Học
            MathMushroomWidget(
              scale: scale,
              onTap: () {
                context.pushNamed(GoRouterName.numberStudy.routeName);
              },
            ),
            SizedBox(width: 20 * scale),

            // Station 3: Cây Tri Thức
            WonderTreeBuildingWidget(
              scale: scale,
              onTap: () {
                _showActionDialog(
                  title: 'Cây Tri Thức',
                  message: 'Bé đã tưới 1 Giọt Nước Thần!\nCây lớn thêm 1 bậc và sắp ra quả thần kỳ rồi đó! 🍎✨',
                  emoji: '💧🌳',
                );
              },
            ),
            SizedBox(width: 20 * scale),

            // Station 4: Trại Ấp Thú
            PetSanctuaryBuildingWidget(
              scale: scale,
              onTap: () {
                _showActionDialog(
                  title: 'Trại Ấp Thú',
                  message: 'Bong! Bé vừa gõ búa phép thuật!\nVỏ trứng đã nứt thêm 1 vết, 1 ngày nữa sẽ nở bạn Rồng Con! 🐉✨',
                  emoji: '🔨🐣',
                );
              },
            ),
            SizedBox(width: 20 * scale),

            // Station 5: Lâu Đài Chữ Cái
            AlphabetCastleBuildingWidget(
              scale: scale,
              onTap: () {
                _showActionDialog(
                  title: 'Lâu Đài Chữ Cái',
                  message: 'Pippo đang xây dựng Lâu Đài Ngôn Ngữ với các bạn thú mới. Bé cùng chờ đón nhé! 🏰🎈',
                  emoji: '🏰✨',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
