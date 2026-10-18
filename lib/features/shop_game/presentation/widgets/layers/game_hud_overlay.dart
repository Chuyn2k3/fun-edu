import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/floating_counting_text.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/hand_tutor_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/hud/top_hud_bar.dart';

class GameHudOverlay extends StatelessWidget {
  final GamePhase phase;
  final int levelNumber;
  final int totalCoins;
  final bool isMuted;
  final VoidCallback onExitPressed;
  final VoidCallback onSoundToggled;
  final String? countingText;
  final bool showTutor;

  const GameHudOverlay({
    super.key,
    required this.phase,
    required this.levelNumber,
    required this.totalCoins,
    required this.isMuted,
    required this.onExitPressed,
    required this.onSoundToggled,
    this.countingText,
    this.showTutor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Pinned Top HUD Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopHudBar(
              levelNumber: levelNumber,
              totalCoins: totalCoins,
              isMuted: isMuted,
              onExitPressed: onExitPressed,
              onSoundToggled: onSoundToggled,
            ),
          ),
          // Floating Counting Text if present
          if (countingText != null)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingCountingText(
                  key: ValueKey(countingText),
                  text: countingText!,
                ),
              ),
            ),
          // Hand Tutor Guide
          if (showTutor && phase == GamePhase.collectingItems)
            const Positioned(
              left: 140,
              bottom: 120,
              child: HandTutorWidget(),
            ),
          // Celebrating Overlay Banner
          if (phase == GamePhase.celebrating)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black12,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            offset: Offset(0, 8),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🎉 🌟 🎊',
                            style: TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'XUẤT SẮC!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5D4037),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+5 🪙 Thưởng!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.elasticOut),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
