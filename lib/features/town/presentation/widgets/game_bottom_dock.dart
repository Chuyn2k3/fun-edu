import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

class GameBottomDock extends StatelessWidget {
  final VoidCallback onMapTap;
  final VoidCallback onArcadeTap;
  final VoidCallback onBackpackTap;
  final int activeIndex;

  const GameBottomDock({
    super.key,
    required this.onMapTap,
    required this.onArcadeTap,
    required this.onBackpackTap,
    this.activeIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 16 : 8),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 8,
          vertical: isTablet ? 8 : 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFFFD54F), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(0, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDockJellyItem(
              icon: Icons.explore_rounded,
              label: isTablet ? 'Thung Lũng' : 'Bản Đồ',
              isActive: activeIndex == 0,
              isTablet: isTablet,
              onTap: () {
                AudioManager().playSfx(AudioSfx.click);
                onMapTap();
              },
            ),
            SizedBox(width: isTablet ? 12 : 6),
            _buildDockJellyItem(
              icon: Icons.sports_esports_rounded,
              label: isTablet ? 'Phòng Chơi' : 'Trò Chơi',
              isActive: activeIndex == 1,
              isTablet: isTablet,
              onTap: () {
                AudioManager().playSfx(AudioSfx.click);
                onArcadeTap();
              },
            ),
            SizedBox(width: isTablet ? 12 : 6),
            _buildDockJellyItem(
              icon: Icons.backpack_rounded,
              label: isTablet ? 'Balo Thần Kỳ' : 'Balo',
              isActive: activeIndex == 2,
              isTablet: isTablet,
              onTap: () {
                AudioManager().playSfx(AudioSfx.click);
                onBackpackTap();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockJellyItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 10 : 7,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFEE58), // Vàng nắng
                    Color(0xFFFFA000), // Cam ngọt
                    Color(0xFFFF6F00), // Đế 3D
                  ],
                  stops: [0.0, 0.6, 1.0],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isActive
              ? Border.all(color: Colors.white, width: 2.2)
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withOpacity(0.55),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                  const BoxShadow(
                    color: Colors.white70,
                    offset: Offset(0, -1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF3E2723) : const Color(0xFF8D6E63),
              size: isTablet ? 22 : 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: isTablet ? 15 : 13,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF3E2723) : const Color(0xFF8D6E63),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
