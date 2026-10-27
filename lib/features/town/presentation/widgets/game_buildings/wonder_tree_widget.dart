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
    final s = widget.scale;
    final width = 205.0 * s;
    final height = 245.0 * s;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Soft 135° Directional Canopy Ground Shadow
              Positioned(
                bottom: 2 * s,
                child: Container(
                  width: 180 * s,
                  height: 30 * s,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.all(Radius.elliptical(180 * s, 30 * s)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10 * s,
                        offset: Offset(-6 * s, 8 * s),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Thick Gnarled Oak Trunk (Thân cây đại thụ gân guốc vững chắc)
              Positioned(
                bottom: 18 * s,
                child: Container(
                  width: 68 * s,
                  height: 120 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF8D6E63), // Vỏ cây sáng
                        Color(0xFF5D4037), // Gỗ sồi ấm
                        Color(0xFF3E2723), // Gốc rễ tối vững chãi
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20 * s),
                    border: Border.all(color: const Color(0xFFD7CCC8), width: 3 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 6 * s),
                        blurRadius: 8 * s,
                      ),
                    ],
                  ),
                  child: Center(
                    // Hollow Tree Knothole with Glowing Friendly Creature Eyes
                    child: Container(
                      width: 22 * s,
                      height: 28 * s,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B0E09),
                        borderRadius: BorderRadius.all(Radius.elliptical(22 * s, 28 * s)),
                        border: Border.all(color: const Color(0xFF4E342E), width: 1.5 * s),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGlowingEye(3.5 * s),
                          SizedBox(width: 4 * s),
                          _buildGlowingEye(3.5 * s),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Animated Rope Swing (Chiếc xích đu đung đưa nhịp nhàng)
              Positioned(
                bottom: 42 * s,
                left: 32 * s,
                child: AnimatedBuilder(
                  animation: _swingController,
                  builder: (context, child) {
                    final angle = math.sin(_swingController.value * math.pi * 2) * 0.12;
                    return Transform.rotate(
                      angle: angle,
                      alignment: Alignment.topCenter,
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      // Dual Ropes
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 2 * s, height: 42 * s, color: const Color(0xFFFFD54F)),
                          SizedBox(width: 14 * s),
                          Container(width: 2 * s, height: 42 * s, color: const Color(0xFFFFD54F)),
                        ],
                      ),
                      // Wooden Swing Seat
                      Container(
                        width: 28 * s,
                        height: 7 * s,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D4C41),
                          borderRadius: BorderRadius.circular(3 * s),
                          border: Border.all(color: const Color(0xFFFFD54F), width: 1.2 * s),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              offset: Offset(0, 2 * s),
                              blurRadius: 3 * s,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Voluminous Layered Canopy (Tán lá bồng bềnh 3D với quả táo vàng lấp lánh)
              Positioned(
                top: 40 * s,
                child: SizedBox(
                  width: 196 * s,
                  height: 126 * s,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Back Foliage Cloud
                      Positioned(
                        top: 0,
                        child: _buildFoliagePuff(120 * s, const Color(0xFF1B5E20)),
                      ),
                      // Left Foliage Cloud
                      Positioned(
                        bottom: 8 * s,
                        left: 8 * s,
                        child: _buildFoliagePuff(96 * s, const Color(0xFF2E7D32)),
                      ),
                      // Right Foliage Cloud
                      Positioned(
                        bottom: 8 * s,
                        right: 8 * s,
                        child: _buildFoliagePuff(96 * s, const Color(0xFF388E3C)),
                      ),
                      // Front Sunlit Crown
                      Positioned(
                        top: 18 * s,
                        child: _buildFoliagePuff(102 * s, const Color(0xFF4CAF50)),
                      ),

                      // Golden Magic Apple 1
                      Positioned(
                        top: 42 * s,
                        left: 48 * s,
                        child: _buildGoldenApple(16 * s),
                      ),
                      // Golden Magic Apple 2
                      Positioned(
                        top: 52 * s,
                        right: 50 * s,
                        child: _buildGoldenApple(14 * s),
                      ),
                      // Sparkle Dew Orb
                      Positioned(
                        top: 28 * s,
                        right: 42 * s,
                        child: Container(
                          width: 8 * s,
                          height: 8 * s,
                          decoration: BoxDecoration(
                            color: const Color(0xFF80D8FF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00B0FF).withOpacity(0.8),
                                blurRadius: 8 * s,
                                spreadRadius: 2 * s,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Carved Wooden Name Signboard: "Cây Tri Thức"
              Positioned(
                top: 8 * s,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 6 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                    ),
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2.5 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        offset: Offset(0, 5 * s),
                        blurRadius: 8 * s,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8 * s,
                        height: 8 * s,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      Text(
                        'Cây Tri Thức',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 16 * s,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      Container(
                        width: 8 * s,
                        height: 8 * s,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Tactile 3D Jelly Action Button: "TƯỚI NƯỚC"
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF81C784), // Xanh ngọc tươi
                        Color(0xFF388E3C), // Xanh lục đậm
                        Color(0xFF1B5E20), // Chân đế
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: Colors.white, width: 2.2 * s),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withOpacity(0.65),
                        offset: Offset(0, 4 * s),
                        blurRadius: 6 * s,
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
                      Container(
                        width: 6 * s,
                        height: 6 * s,
                        decoration: const BoxDecoration(
                          color: Color(0xFF80D8FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5 * s),
                      Text(
                        'TƯỚI NƯỚC',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          fontSize: 12 * s,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
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

  Widget _buildGlowingEye(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFB300),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildFoliagePuff(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenApple(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFFF6F00)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.7),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
