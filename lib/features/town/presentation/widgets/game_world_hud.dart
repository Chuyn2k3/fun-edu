import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';

class GameWorldHud extends StatefulWidget {
  final int coins;
  final int magicDew;
  final String playerName;
  final VoidCallback? onParentGateTap;

  const GameWorldHud({
    super.key,
    this.coins = 150,
    this.magicDew = 1,
    this.playerName = 'Bé Yêu',
    this.onParentGateTap,
  });

  @override
  State<GameWorldHud> createState() => _GameWorldHudState();
}

class _GameWorldHudState extends State<GameWorldHud> {
  bool _isMuted = false;

  void _toggleAudio() {
    setState(() => _isMuted = !_isMuted);
    AudioManager().toggleSound(!_isMuted);
    if (!_isMuted) {
      AudioManager().playSfx(AudioSfx.click);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 12.0,
        vertical: isTablet ? 12.0 : 6.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Left: Player Profile Pill with 3D Mascot Avatar
          _buildPlayerProfilePill(isTablet),

          // 2. Right: Tactile 3D Jelly Resource Cluster
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coins Pill
              _buildJellyResourcePill(
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFFFFD54F),
                value: '${widget.coins}',
                gradient: const [Color(0xFFFFEE58), Color(0xFFFF8F00)],
                borderColor: Colors.white,
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 10 : 6),
              // Magic Dew Pill
              _buildJellyResourcePill(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF80D8FF),
                value: '${widget.magicDew}',
                gradient: const [Color(0xFF81D4FA), Color(0xFF0288D1)],
                borderColor: Colors.white,
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 10 : 6),
              // Sound Toggle 3D Button
              _buildJellySoundButton(isTablet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerProfilePill(bool isTablet) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 6 : 4,
        isTablet ? 4 : 3,
        isTablet ? 16 : 12,
        isTablet ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Pippo Avatar Frame
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isTablet ? 44 : 36,
                height: isTablet ? 44 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFECB3), Color(0xFFFFB74D)],
                  ),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppShopAssets.bearIdlePng,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.4),
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.face_rounded, color: Color(0xFF8D6E63));
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'Lv.3',
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isTablet ? 10 : 8),
          // Player Name & XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.playerName,
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3E2723),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: isTablet ? 64 : 48,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.75,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJellyResourcePill({
    required IconData icon,
    required Color iconColor,
    required String value,
    required List<Color> gradient,
    required Color borderColor,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 9,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
          const BoxShadow(
            color: Colors.white70,
            offset: Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isTablet ? 18 : 15),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJellySoundButton(bool isTablet) {
    return GestureDetector(
      onTap: _toggleAudio,
      child: Container(
        width: isTablet ? 40 : 34,
        height: isTablet ? 40 : 34,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isMuted
                ? [const Color(0xFFEF5350), const Color(0xFFC62828)]
                : [const Color(0xFF81C784), const Color(0xFF2E7D32)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
            const BoxShadow(
              color: Colors.white70,
              offset: Offset(0, -1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: Colors.white,
            size: isTablet ? 20 : 17,
          ),
        ),
      ),
    );
  }
}
