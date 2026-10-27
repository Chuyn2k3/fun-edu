import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

class MathMushroomWidget extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;

  const MathMushroomWidget({
    super.key,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  State<MathMushroomWidget> createState() => _MathMushroomWidgetState();
}

class _MathMushroomWidgetState extends State<MathMushroomWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _smokeController;

  @override
  void initState() {
    super.initState();
    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _smokeController.dispose();
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
              // 1. Soft 135° Directional Ground Shadow
              Positioned(
                bottom: 2 * s,
                child: Container(
                  width: 175 * s,
                  height: 28 * s,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.all(Radius.elliptical(175 * s, 28 * s)),
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

              // 2. Animated Chimney Smoke Puffs
              Positioned(
                top: 2 * s,
                right: 36 * s,
                child: AnimatedBuilder(
                  animation: _smokeController,
                  builder: (context, child) {
                    final p = _smokeController.value;
                    final puffOpacity = (1.0 - p).clamp(0.0, 0.9);
                    final puffOffset = -p * 28 * s;
                    final puffScale = 0.5 + (p * 0.8);

                    return Transform.translate(
                      offset: Offset(math.sin(p * math.pi) * 6 * s, puffOffset),
                      child: Transform.scale(
                        scale: puffScale,
                        child: Opacity(
                          opacity: puffOpacity,
                          child: Container(
                            width: 18 * s,
                            height: 18 * s,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 6 * s,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. Cobblestone Chimney Pipe
              Positioned(
                top: 26 * s,
                right: 42 * s,
                child: Container(
                  width: 18 * s,
                  height: 32 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF90A4AE), Color(0xFF546E7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(4 * s),
                    border: Border.all(color: Colors.white70, width: 2 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(2 * s, 2 * s),
                        blurRadius: 4 * s,
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Mushroom Stem / Fairy Cottage Body
              Positioned(
                bottom: 18 * s,
                child: Container(
                  width: 120 * s,
                  height: 126 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFFDE7), // Kem sữa ấm
                        Color(0xFFFFECB3), // Vàng mơ
                        Color(0xFFFFD54F), // Đế ấm
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32 * s),
                    border: Border.all(color: Colors.white, width: 3.5 * s),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8F00).withOpacity(0.4),
                        offset: Offset(0, 8 * s),
                        blurRadius: 10 * s,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Glowing Round Fairy Window
                      Positioned(
                        top: 18 * s,
                        left: 20 * s,
                        child: Container(
                          width: 26 * s,
                          height: 26 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFF176),
                            border: Border.all(color: const Color(0xFF795548), width: 2.2 * s),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.7),
                                blurRadius: 10 * s,
                                spreadRadius: 2 * s,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Window Crossbars
                              Container(width: 22 * s, height: 1.8 * s, color: const Color(0xFF795548)),
                              Container(width: 1.8 * s, height: 22 * s, color: const Color(0xFF795548)),
                            ],
                          ),
                        ),
                      ),

                      // Arched Wooden Fairy Door
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 48 * s,
                          height: 60 * s,
                          margin: EdgeInsets.only(bottom: 2 * s),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D4C41), Color(0xFF3E2723)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s)),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 2.5 * s),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: EdgeInsets.only(right: 5 * s),
                              width: 8 * s,
                              height: 8 * s,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD54F),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Giant Crimson Mushroom Dome Cap (Mũ nấm đỏ đốm trắng 3D)
              Positioned(
                top: 40 * s,
                child: Container(
                  width: 188 * s,
                  height: 102 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF5252), // Đỏ rực rỡ
                        Color(0xFFD32F2F), // Đỏ tươi
                        Color(0xFF880E4F), // Đỏ mận đổ bóng có chiều sâu
                      ],
                      stops: [0.0, 0.65, 1.0],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(95 * s),
                      bottom: Radius.circular(36 * s),
                    ),
                    border: Border.all(color: Colors.white, width: 4 * s),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB71C1C).withOpacity(0.55),
                        offset: Offset(0, 10 * s),
                        blurRadius: 14 * s,
                      ),
                      const BoxShadow(
                        color: Colors.white54,
                        offset: Offset(0, -1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // White Embossed Polka Dots
                      Positioned(
                        top: 14 * s,
                        left: 36 * s,
                        child: _buildMushroomDot(22 * s),
                      ),
                      Positioned(
                        top: 24 * s,
                        right: 38 * s,
                        child: _buildMushroomDot(18 * s),
                      ),
                      Positioned(
                        top: 48 * s,
                        left: 22 * s,
                        child: _buildMushroomDot(15 * s),
                      ),

                      // Golden Math Equation Banner "+ - = 1 2 3"
                      Positioned(
                        top: 18 * s,
                        left: 68 * s,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 3 * s),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12 * s),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5 * s),
                          ),
                          child: Text(
                            '1 + 2 = 3',
                            style: TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 14 * s,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD54F),
                              letterSpacing: 0.8,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Carved Wooden Name Signboard: "Nhà Nấm Toán Học"
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
                          color: Color(0xFFFFD54F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      Text(
                        'Nhà Nấm Toán Học',
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
                          color: Color(0xFFFFD54F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Tactile 3D Jelly Action Button: "LUYỆN TOÁN"
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFBA68C8), // Tím pastel ngọt
                        Color(0xFF8E24AA), // Tím đậm
                        Color(0xFF4A148C), // Chân đế
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: Colors.white, width: 2.2 * s),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A148C).withOpacity(0.65),
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5 * s),
                      Text(
                        'LUYỆN TOÁN',
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

  Widget _buildMushroomDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFEBEE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(1, 2),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}
