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
        margin: EdgeInsets.only(bottom: isTablet ? 16 : 6),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 8,
          vertical: isTablet ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF263238).withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDockItem(
              emoji: '🗺️',
              label: isTablet ? 'Thung Lũng' : 'Bản Đồ',
              isActive: activeIndex == 0,
              isTablet: isTablet,
              onTap: () {
                AudioManager().playSfx(AudioSfx.click);
                onMapTap();
              },
            ),
            SizedBox(width: isTablet ? 12 : 6),
            _buildDockItem(
              emoji: '🎮',
              label: isTablet ? 'Phòng Chơi' : 'Trò Chơi',
              isActive: activeIndex == 1,
              isTablet: isTablet,
              onTap: () {
                AudioManager().playSfx(AudioSfx.click);
                onArcadeTap();
              },
            ),
            SizedBox(width: isTablet ? 12 : 6),
            _buildDockItem(
              emoji: '🎒',
              label: 'Balo',
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

  Widget _buildDockItem({
    required String emoji,
    required String label,
    required bool isActive,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 8,
          vertical: isTablet ? 8 : 4,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFE65100)],
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: isTablet ? 18 : 15)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: isTablet ? 13 : 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
