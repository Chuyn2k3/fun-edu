import 'package:flutter/material.dart';

import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';

/// Shown while the app's data loads. Matches the native launch screen
/// (cream background, centred logo) so there is no jump between them.
class SplashView extends StatefulWidget {
  const SplashView({super.key = const ValueKey('splash')});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(begin: 0.96, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              key: const ValueKey('splash-logo'),
              scale: _scale,
              child: Image.asset(
                AppImages.logo,
                width: 160,
                height: 160,
                // The logo is decorative; the word below names the app.
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ChipChip',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
