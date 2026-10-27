import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';
import 'package:fun_edu/feature/game_feature/game_page.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/ambient_particles_layer.dart';
import 'package:fun_edu/features/town/presentation/widgets/diorama_valley_canvas.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_bottom_dock.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_world_background.dart';
import 'package:fun_edu/features/town/presentation/widgets/game_world_hud.dart';
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
          // 1. Immersive Animated Scenery Background (Sky + Sun + Clouds)
          const GameWorldBackground(showTerrain: false),

          // 2. Ambient Floating Sparkles & Particles
          const AmbientParticlesLayer(particleCount: 16),

          // 3. Main 3D Diorama Valley World Canvas
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: DioramaValleyCanvas(
                onMarketTap: () {
                  context.pushNamed(GoRouterName.shopGameLevelSelect.routeName);
                },
                onMathMushroomTap: () {
                  context.pushNamed(GoRouterName.numberStudy.routeName);
                },
                onWonderTreeTap: () {
                  _showActionDialog(
                    title: 'Cây Tri Thức',
                    message: 'Bé đã tưới 1 Giọt Nước Thần!\nCây lớn thêm 1 bậc và sắp ra quả thần kỳ rồi đó! 🍎✨',
                    emoji: '💧🌳',
                  );
                },
                onPetSanctuaryTap: () {
                  _showActionDialog(
                    title: 'Trại Ấp Thú',
                    message: 'Bong! Bé vừa gõ búa phép thuật!\nVỏ trứng đã nứt thêm 1 vết, 1 ngày nữa sẽ nở bạn Rồng Con! 🐉✨',
                    emoji: '🔨🐣',
                  );
                },
                onAlphabetCastleTap: () {
                  _showActionDialog(
                    title: 'Lâu Đài Chữ Cái',
                    message: 'Pippo đang xây dựng Lâu Đài Ngôn Ngữ với các bạn thú mới. Bé cùng chờ đón nhé! 🏰🎈',
                    emoji: '🏰✨',
                  );
                },
              ),
            ),
          ),

          // 4. Top Floating Edge-Pinned Game HUD Bar
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: GameWorldHud(
                coins: 150,
                magicDew: 1,
                playerName: 'Bé Yêu',
              ),
            ),
          ),

          // 5. Bottom Floating Game Navigation Dock
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
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
          ),
        ],
      ),
    );
  }
}
