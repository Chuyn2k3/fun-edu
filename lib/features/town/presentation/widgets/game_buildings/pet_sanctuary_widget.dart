import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/audio/audio_sfx_enum.dart';

class PetSanctuaryBuildingWidget extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;

  const PetSanctuaryBuildingWidget({
    super.key,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  State<PetSanctuaryBuildingWidget> createState() => _PetSanctuaryBuildingWidgetState();
}

class _PetSanctuaryBuildingWidgetState extends State<PetSanctuaryBuildingWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wobbleController.dispose();
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
              // 1. Ground Shadow (Bóng chuồng ấp)
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

              // 2. Wooden Ranch Fence & Barn Body (Chuồng gỗ rơm vàng)
              Positioned(
                bottom: 16 * widget.scale,
                child: Container(
                  width: 154 * widget.scale,
                  height: 110 * widget.scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFCC80), Color(0xFFD7CCC8)],
                    ),
                    borderRadius: BorderRadius.circular(20 * widget.scale),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 3 * widget.scale),
                  ),
                  child: Stack(
                    children: [
                      // Straw Texture at bottom
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 38 * widget.scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE082),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16 * widget.scale)),
                          ),
                          child: Center(
                            child: Text('🌾 🌾 🌾', style: TextStyle(fontSize: 16 * widget.scale)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Giant Wobbling Mystery Dragon Egg (Quả trứng rồng khổng lồ lắc lư)
              Positioned(
                bottom: 40 * widget.scale,
                child: AnimatedBuilder(
                  animation: _wobbleController,
                  builder: (context, child) {
                    final angle = (math.sin(_wobbleController.value * math.pi * 2) * 0.08);
                    return Transform.rotate(
                      angle: angle,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 78 * widget.scale,
                    height: 104 * widget.scale,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(-0.3, -0.4),
                        colors: [
                          Color(0xFFF8BBD0),
                          Color(0xFFEC407A),
                          Color(0xFF880E4F),
                        ],
                        stops: [0.2, 0.7, 1.0],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(46 * widget.scale),
                        bottom: Radius.circular(36 * widget.scale),
                      ),
                      border: Border.all(color: Colors.white, width: 3.5 * widget.scale),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC2185B).withOpacity(0.5),
                          offset: Offset(0, 8 * widget.scale),
                          blurRadius: 10 * widget.scale,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Egg spots
                        Positioned(
                          top: 24 * widget.scale,
                          left: 18 * widget.scale,
                          child: Container(
                            width: 14 * widget.scale,
                            height: 14 * widget.scale,
                            decoration: const BoxDecoration(
                              color: Color(0xFF80DEEA),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 48 * widget.scale,
                          right: 18 * widget.scale,
                          child: Container(
                            width: 18 * widget.scale,
                            height: 18 * widget.scale,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF59D),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Golden crack line
                        Center(
                          child: Text('⚡', style: TextStyle(fontSize: 22 * widget.scale, color: Colors.amberAccent)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Title Signboard (Biển tên Trại Ấp Thú)
              Positioned(
                top: 10 * widget.scale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 5 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC407A), Color(0xFFAD1457)],
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
                      Text('🐣', style: TextStyle(fontSize: 16 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'Trại Ấp Thú',
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

              // 5. Action Button Pill (Nút gõ trứng)
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14 * widget.scale, vertical: 4 * widget.scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF80AB), Color(0xFFC2185B)],
                    ),
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    border: Border.all(color: Colors.white, width: 2 * widget.scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF880E4F).withOpacity(0.6),
                        offset: Offset(0, 3 * widget.scale),
                        blurRadius: 4 * widget.scale,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔨', style: TextStyle(fontSize: 12 * widget.scale)),
                      SizedBox(width: 4 * widget.scale),
                      Text(
                        'ẤP TRỨNG',
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
}
