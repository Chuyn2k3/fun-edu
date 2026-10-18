import 'package:flutter/material.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';

class BackgroundSceneryLayer extends StatelessWidget {
  const BackgroundSceneryLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        AppShopAssets.shopBackground,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Warm wooden interior fallback painter if asset is missing
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEEDBB2), // Warm sunlight from window
                  Color(0xFF8B5A2B), // Deep oak wood
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
