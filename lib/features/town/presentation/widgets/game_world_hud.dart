import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

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
          // 1. Left: Player Level & Avatar Pill
          _buildPlayerProfilePill(isTablet),

          // 2. Center: 3D Wooden World Banner (Visible on Tablet or wide screens)
          if (isTablet) _buildWorldTitleBoard(),

          // 3. Right: Resource Cluster (Coins + Magic Dew + Sound + Lock)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResourcePill(
                emoji: '🪙',
                value: '${widget.coins}',
                gradient: const [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                borderColor: const Color(0xFFFFECB3),
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 10 : 6),
              _buildResourcePill(
                emoji: '💧',
                value: '${widget.magicDew}',
                gradient: const [Color(0xFF81D4FA), Color(0xFF0288D1)],
                borderColor: const Color(0xFFE1F5FE),
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 10 : 6),
              _buildSoundButton(isTablet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerProfilePill(bool isTablet) {
    return Container(
      padding: EdgeInsets.fromLTRB(isTablet ? 10 : 6, isTablet ? 6 : 4, isTablet ? 14 : 10, isTablet ? 6 : 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFB300), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Avatar Frame with Level Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isTablet ? 42 : 36,
                height: isTablet ? 42 : 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE082),
                ),
                child: Center(
                  child: Text('🐻', style: TextStyle(fontSize: isTablet ? 24 : 20)),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
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
          SizedBox(width: isTablet ? 10 : 6),
          // Player Name & Mini XP bar
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
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: isTablet ? 60 : 44,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.7,
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

  Widget _buildWorldTitleBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
    );
  }

  Widget _buildResourcePill({
    required String emoji,
    required String value,
    required List<Color> gradient,
    required Color borderColor,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8, vertical: isTablet ? 6 : 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: isTablet ? 16 : 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundButton(bool isTablet) {
    return GestureDetector(
      onTap: _toggleAudio,
      child: Container(
        width: isTablet ? 40 : 34,
        height: isTablet ? 40 : 34,
        decoration: BoxDecoration(
          color: _isMuted ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _isMuted ? '🔇' : '🔊',
            style: TextStyle(fontSize: isTablet ? 18 : 15),
          ),
        ),
      ),
    );
  }
}
