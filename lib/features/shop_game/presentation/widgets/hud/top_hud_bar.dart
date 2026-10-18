import 'package:flutter/material.dart';

class TopHudBar extends StatelessWidget {
  final int levelNumber;
  final int totalCoins;
  final bool isMuted;
  final VoidCallback onExitPressed;
  final VoidCallback onSoundToggled;

  const TopHudBar({
    super.key,
    required this.levelNumber,
    required this.totalCoins,
    required this.isMuted,
    required this.onExitPressed,
    required this.onSoundToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Group: Back Button & Level Badge
            Row(
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back_rounded,
                  color: const Color(0xFFFF7043),
                  onTap: onExitPressed,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    'Màn $levelNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
            // Right Group: Coins & Sound Toggle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFB300), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🪙',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$totalCoins',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildCircleButton(
                  icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: const Color(0xFF42A5F5),
                  onTap: onSoundToggled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 3),
              blurRadius: 5,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
