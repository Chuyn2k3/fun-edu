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

              // 2. Wooden Ranch Fence & Straw Nest Bed
              Positioned(
                bottom: 18 * s,
                child: Container(
                  width: 164 * s,
                  height: 114 * s,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFD54F), // Vàng nắng
                        Color(0xFFFFA000), // Gỗ rơm vàng ấm
                        Color(0xFF8D6E63), // Hàng rào gỗ
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24 * s),
                    border: Border.all(color: const Color(0xFFFFF9C4), width: 3.2 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: Offset(0, 6 * s),
                        blurRadius: 8 * s,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // White Picket Fence slats
                      Positioned(
                        top: 14 * s,
                        left: 12 * s,
                        right: 12 * s,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (_) => _buildFencePost(s)),
                        ),
                      ),
                      // Golden Straw Bed
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 38 * s,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF176), Color(0xFFFFB300)],
                            ),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20 * s)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              6,
                              (i) => Container(
                                width: 14 * s,
                                height: 4 * s,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE082),
                                  borderRadius: BorderRadius.circular(2 * s),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Giant Wobbling Mystery Dragon Egg (Quả trứng rồng ma thuật lắc lư)
              Positioned(
                bottom: 42 * s,
                child: AnimatedBuilder(
                  animation: _wobbleController,
                  builder: (context, child) {
                    final angle = math.sin(_wobbleController.value * math.pi * 2) * 0.12;
                    return Transform.rotate(
                      angle: angle,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 82 * s,
                    height: 108 * s,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(-0.35, -0.4),
                        colors: [
                          Color(0xFFF8BBD0),
                          Color(0xFFEC407A),
                          Color(0xFF880E4F),
                        ],
                        stops: [0.15, 0.65, 1.0],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(50 * s),
                        bottom: Radius.circular(38 * s),
                      ),
                      border: Border.all(color: Colors.white, width: 3.8 * s),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC2185B).withOpacity(0.55),
                          offset: Offset(0, 10 * s),
                          blurRadius: 14 * s,
                        ),
                        const BoxShadow(
                          color: Colors.white70,
                          offset: Offset(0, -1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Cyan Dragon Magic Spot
                        Positioned(
                          top: 24 * s,
                          left: 18 * s,
                          child: Container(
                            width: 15 * s,
                            height: 15 * s,
                            decoration: const BoxDecoration(
                              color: Color(0xFF80DEEA),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Golden Dragon Magic Spot
                        Positioned(
                          top: 50 * s,
                          right: 18 * s,
                          child: Container(
                            width: 20 * s,
                            height: 20 * s,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF59D),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Golden Glowing Crack Vector Lines
                        Center(
                          child: CustomPaint(
                            size: Size(32 * s, 42 * s),
                            painter: _CrackPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Carved Wooden Name Signboard: "Trại Ấp Thú"
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
                          color: Color(0xFFEC407A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      Text(
                        'Trại Ấp Thú',
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
                          color: Color(0xFFEC407A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Tactile 3D Jelly Action Button: "GÕ BÚA"
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF80AB), // Hồng tươi
                        Color(0xFFE91E63), // Hồng đậm
                        Color(0xFF880E4F), // Chân đế
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18 * s),
                    border: Border.all(color: Colors.white, width: 2.2 * s),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF880E4F).withOpacity(0.65),
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
                        'GÕ BÚA',
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

  Widget _buildFencePost(double s) {
    return Container(
      width: 12 * s,
      height: 38 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6 * s)),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(1 * s, 2 * s),
            blurRadius: 2 * s,
          ),
        ],
      ),
    );
  }
}

class _CrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glow = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.6, size.height * 0.35)
      ..lineTo(size.width * 0.3, size.height * 0.65)
      ..lineTo(size.width * 0.75, size.height);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
