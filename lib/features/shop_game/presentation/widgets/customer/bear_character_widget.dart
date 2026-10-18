import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';

class BearCharacterWidget extends StatelessWidget {
  final GamePhase phase;

  const BearCharacterWidget({
    super.key,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final isHappy = phase == GamePhase.celebrating || phase == GamePhase.levelComplete;
    final lottieAsset = isHappy ? AppShopAssets.bearHappyLottie : AppShopAssets.bearIdleLottie;

    return Lottie.asset(
      lottieAsset,
      width: 220,
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback vector friendly bear face
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF795548),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5D4037), width: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isHappy ? '🐻 🎉' : '🐻',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bác Gấu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
