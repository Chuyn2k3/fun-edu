import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

class WonderTreeBuildingWidget extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;

  const WonderTreeBuildingWidget({
    super.key,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  State<WonderTreeBuildingWidget> createState() => _WonderTreeBuildingWidgetState();
}

class _WonderTreeBuildingWidgetState extends State<WonderTreeBuildingWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _swingController;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swingController.dispose();
    super.dispose();
  }

  void _handleTap() {
    AudioManager().playSfx(AudioSfx.click);
    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() => _isPressed = false);
        widget.onTap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = 190.0 * widget.scale;
    final height = 240.0 * widget.scale;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Ground Shadow (Bóng tán cây)
              Positioned(
                bottom: 4 * widget.scale,
                child: Container(
                  width: 170 * widget.scale,
                  height: 28 * widget.scale,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.all(Radius.elliptical(170 * widget.scale, 28 * widget.scale)),
                  ),
                ),
              ),

              // 2. Tree Trunk (Thân cây cổ thụ vững chắc)
              Positioned(
                bottom: 16 * widget.scale,
                child: Container(
                  width: 58 * widget.scale,
                  height: 110 * widget.scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                    ),
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    border: Border.all(color: const Color(0xFFBCAAA4), width: 3 * widget.scale),
                  ),
                  child: Center(
                    // Hollow hole with cute eyes
                    child: Container(
                      width: 18 * widget.scale,
                      height: 22 * widget.scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1C14),
                        borderRadius: BorderRadius.all(Radius.elliptical(18 * widget.scale, 22 * widget.scale)),
                      ),
                      child: Center(
                        child: Text('👀', style: TextStyle(fontSize: 8 * widget.scale)),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Hanging Rope Swing (Chiếc xích đu đung đưa)
              Positioned(
                bottom: 40 * widget.scale,
                left: 28 * widget.scale,
                child: AnimatedBuilder(
                  animation: _swingController,
                  builder: (context, child) {
                    final angle = (math.sin(_swingController.value * math.pi * 2) * 0.08);
                    return Transform.rotate(
                      angle: angle,
                      alignment: Alignment.topCenter,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      Container(width: 2 * widget.scale, height: 38 * widget.scale, color: const Color(0xFFD7CCC8)),
                      Container(
                        width: 24 * widget.scale,
                        height: 8 * widget.scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D4C41),
                          borderRadius: BorderRadius.circular(4 * widget.scale),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Lush Foliage Puffs (Vòm lá cây hoạt hình 3 tầng xanh mướt)
              Positioned(
                top: 36 * widget.scale,
                child: SizedBox(
                  width: 180 * widget.scale,
                  height: 120 * widget.scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Back Foliage
                      Positioned(
                        top: 0,
                        child: _buildFoliagePuff(110 * widget.scale, const Color(0xFF2E7D32)),
                      ),
                      // Left Foliage
                      Positioned(
                        bottom: 10 * widget.scale,
                        left: 10 * widget.scale,
                        child: _buildFoliagePuff(90 * widget.scale, const Color(0xFF388E3C)),
                      ),
                      // Right Foliage
                      Positioned(
                        bottom: 10 * widget.scale,
                        right: 10 * widget.scale,
                        child: _buildFoliagePuff(90 * widget.scale, const Color(0xFF43A047)),
                      ),
                      // Front Crown
                      Positioned(
                        top: 20 * widget.scale,
                        child: _buildFoliagePuff(95 * widget.scale, const Color(0xFF66BB6A)),
                      ),
                      // Golden Apple 1
                      Positioned(
                        top: 38 * widget.scale,
                        left: 45 * widget.scale,
                        child: Text('🍎', style: TextStyle(fontSize: 18 * widget.scale)),
                      ),
                      // Golden Apple 2
                      Positioned(
                        top: 48 * widget.scale,
                        right: 48 * widget.scale,
                        child: Text('🍎', style: TextStyle(fontSize: 16 * widget.scale)),
                      ),
                      // Sparkle
                      Positioned(
                        top: 24 * widget.scale,
                        right: 36 * widget.scale,
                        child: Text('✨', style: TextStyle(fontSize: 14 * widget.scale)),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Title Signboard (Biển tên Cây Tri Thức)
              Positioned(
                top: 10 * widget.scale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 5 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(14 * widget.scale),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2.5 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(0, 4 * widget.scale),
                        blurRadius: 6 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌳', style: TextStyle(fontSize: 16 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'Cây Tri Thức',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 15 * widget.scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Action Button Pill (Nút tưới nước)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 4 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    ),
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    border: Border.all(color: Colors.white, width: 2 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF01579B).withOpacity(0.6),
                        offset: Offset(0, 3 * widget.scale),
                        blurRadius: 4 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💧', style: TextStyle(fontSize: 12 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'TƯỚI NƯỚC',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 11 * widget.scale,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoliagePuff(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5 * widget.scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: Offset(0, 4 * widget.scale),
            blurRadius: 6 * widget.scale,
          ),
        ],
      ),
    );
  }
}
