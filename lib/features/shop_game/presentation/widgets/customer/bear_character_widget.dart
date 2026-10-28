import 'package:flutter/material.dart';
import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';

class BearCharacterWidget extends StatefulWidget {
  final GamePhase phase;
  final double size;

  const BearCharacterWidget({
    super.key,
    required this.phase,
    this.size = 280,
  });

  @override
  State<BearCharacterWidget> createState() => _BearCharacterWidgetState();
}

class _BearCharacterWidgetState extends State<BearCharacterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapBounceController;
  late final Animation<double> _bounceAnimation;
  bool _showGreetingBubble = false;

  @override
  void initState() {
    super.initState();
    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_tapBounceController);
  }

  @override
  void dispose() {
    _tapBounceController.dispose();
    super.dispose();
  }

  void _onTapBear() {
    if (_tapBounceController.isAnimating) return;
    _tapBounceController.forward(from: 0.0);
    setState(() {
      _showGreetingBubble = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showGreetingBubble = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHappy = widget.phase == GamePhase.celebrating ||
        widget.phase == GamePhase.levelComplete;

    return GestureDetector(
      onTap: _onTapBear,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Interactive Greeting Speech Bubble
          if (_showGreetingBubble)
            Positioned(
              top: -65,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showGreetingBubble ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 2.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xin chào bé! 🐻✨',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Main Animated Bear Character
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value * (isHappy ? 1.08 : 1.0),
                alignment: Alignment.bottomCenter,
                child: child,
              );
            },
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Image.asset(
                AppShopAssets.bearWavingWebp,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to static png
                  return Image.asset(
                    AppShopAssets.bearIdlePng,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8D6E63),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 4),
                        ),
                        child: const Center(
                          child: Text('🐻', style: TextStyle(fontSize: 64)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
