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
      duration: const Duration(milliseconds: 2000),
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
              // 1. Ground Shadow (Bóng nấm trên mặt cỏ)
              Positioned(
                bottom: 4 * widget.scale,
                child: Container(
                  width: 160 * widget.scale,
                  height: 26 * widget.scale,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.all(Radius.elliptical(160 * widget.scale, 26 * widget.scale)),
                  ),
                ),
              ),

              // 2. Animated Chimney Smoke Puffs (Khói bay từ ống khói nấm)
              Positioned(
                top: 0,
                right: 36 * widget.scale,
                child: AnimatedBuilder(
                  animation: _smokeController,
                  builder: (context, child) {
                    final progress = _smokeController.value;
                    final puffOpacity = (1.0 - progress).clamp(0.0, 1.0);
                    final puffOffset = -progress * 26 * widget.scale;
                    final puffScale = 0.6 + (progress * 0.7);

                    return Transform.translate(
                      offset: Offset(math.sin(progress * math.pi) * 6 * widget.scale, puffOffset),
                      child: Transform.scale(
                        scale: puffScale,
                        child: Opacity(
                          opacity: puffOpacity,
                          child: Container(
                            width: 18 * widget.scale,
                            height: 18 * widget.scale,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. Stone Chimney
              Positioned(
                top: 24 * widget.scale,
                right: 44 * widget.scale,
                child: Container(
                  width: 18 * widget.scale,
                  height: 32 * widget.scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF78909C),
                    borderRadius: BorderRadius.circular(4 * widget.scale),
                    border: Border.all(color: Colors.white70, width: 2 * widget.scale),
                  ),
                ),
              ),

              // 4. Mushroom Stem / Cottage Body (Thân nấm thành nhà)
              Positioned(
                bottom: 16 * widget.scale,
                child: Container(
                  width: 110 * widget.scale,
                  height: 120 * widget.scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF9C4), Color(0xFFFFE082)],
                    ),
                    borderRadius: BorderRadius.circular(28 * widget.scale),
                    border: Border.all(color: Colors.white, width: 3.5 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withOpacity(0.4),
                        offset: Offset(0, 6 * widget.scale),
                        blurRadius: 8 * widget.scale,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Circular Glowing Window
                      Positioned(
                        top: 20 * widget.scale,
                        left: 20 * widget.scale,
                        child: Container(
                          width: 24 * widget.scale,
                          height: 24 * widget.scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFF176),
                            border: Border.all(color: const Color(0xFF8D6E63), width: 2 * widget.scale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 6 * widget.scale,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('✨', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                      // Arched Door
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 44 * widget.scale,
                          height: 54 * widget.scale,
                          margin: EdgeInsets.only(bottom: 2 * widget.scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6D4C41),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(22 * widget.scale)),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 2 * widget.scale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Giant Mushroom Cap (Mũ nấm đỏ đốm trắng 3D)
              Positioned(
                top: 36 * widget.scale,
                child: Container(
                  width: 180 * widget.scale,
                  height: 96 * widget.scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFBA68C8), Color(0xFF6A1B9A)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(90 * widget.scale),
                      bottom: Radius.circular(30 * widget.scale),
                    ),
                    border: Border.all(color: Colors.white, width: 4 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A148C).withOpacity(0.5),
                        offset: Offset(0, 10 * widget.scale),
                        blurRadius: 12 * widget.scale,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Polka Dot 1
                      Positioned(
                        top: 14 * widget.scale,
                        left: 36 * widget.scale,
                        child: _buildMushroomDot(22 * widget.scale),
                      ),
                      // Polka Dot 2 (Center)
                      Positioned(
                        top: 24 * widget.scale,
                        right: 40 * widget.scale,
                        child: _buildMushroomDot(18 * widget.scale),
                      ),
                      // Polka Dot 3
                      Positioned(
                        top: 48 * widget.scale,
                        left: 20 * widget.scale,
                        child: _buildMushroomDot(14 * widget.scale),
                      ),
                      // Floating Math Rune "+", "−"
                      Positioned(
                        top: 18 * widget.scale,
                        left: 76 * widget.scale,
                        child: Text(
                          '1 2 3',
                          style: TextStyle(
                            fontFamily: 'LilitaOne',
                            fontSize: 16 * widget.scale,
                            color: const Color(0xFFFFD54F),
                            shadows: const [
                              Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Title Signboard (Biển tên Nhà Toán Học)
              Positioned(
                top: 10 * widget.scale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 5 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
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
                      Text('🍄', style: TextStyle(fontSize: 16 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'Nhà Toán Học',
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

              // 7. Action Button Pill (Nút bấm vào học toán)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 4 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCE93D8), Color(0xFF8E24AA)],
                    ),
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    border: Border.all(color: Colors.white, width: 2 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A148C).withOpacity(0.6),
                        offset: Offset(0, 3 * widget.scale),
                        blurRadius: 4 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✏️', style: TextStyle(fontSize: 12 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'LÀM TOÁN',
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

  Widget _buildMushroomDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}
