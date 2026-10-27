import 'dart:math' as math;
import 'package:flutter/material.dart';

class GameWorldBackground extends StatefulWidget {
  const GameWorldBackground({super.key});

  @override
  State<GameWorldBackground> createState() => _GameWorldBackgroundState();
}

class _GameWorldBackgroundState extends State<GameWorldBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _windmillController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _windmillController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _windmillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // 1. Sky Gradient (Bầu trời hoạt hình ban mai tươi sáng)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4FC3F7), // Xanh trời trong trẻo
                    Color(0xFF81D4FA), // Xanh pastel êm dịu
                    Color(0xFFFFF9C4), // Ánh bình minh vàng dịu chân trời
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Animated Sun & Glowing Sunbeams (Mặt trời hoạt hình tỏa sáng)
          Positioned(
            top: 24,
            right: 28,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final scale = 0.95 + (_ambientController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFF59D),
                      Color(0xFFFFCA28),
                      Color(0xFFFF8F00),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.55),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌞', style: TextStyle(fontSize: 48)),
                ),
              ),
            ),
          ),

          // 3. Floating Hot Air Balloon (Khinh khí cầu hoạt hình lơ lửng)
          Positioned(
            top: 60,
            left: 36,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final floatY = math.sin(_ambientController.value * math.pi * 2) * 8.0;
                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Text('🎈', style: TextStyle(fontSize: 28)),
              ),
            ),
          ),

          // 4. Floating Clouds (Mây trôi bồng bềnh)
          Positioned(
            top: 40,
            left: 110,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_ambientController.value * 20, 0),
                  child: child,
                );
              },
              child: const _CloudPuff(width: 90, height: 36),
            ),
          ),
          Positioned(
            top: 100,
            right: 80,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-_ambientController.value * 18, 0),
                  child: child,
                );
              },
              child: const _CloudPuff(width: 120, height: 42),
            ),
          ),

          // 5. Multi-tiered Rolling Green Hills & River (Dãy đồi cỏ xanh và dòng suối uốn lượn)
          Positioned.fill(
            child: CustomPaint(
              painter: _DetailedLandscapePainter(),
            ),
          ),

          // 6. Animated Windmill on the distant hill (Cối xay gió quay cánh trên đỉnh đồi)
          Positioned(
            bottom: 240,
            left: 20,
            child: SizedBox(
              width: 50,
              height: 70,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Windmill Tower
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7CCC8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
                      ),
                    ),
                  ),
                  // Rotating Blades
                  Positioned(
                    top: 14,
                    child: AnimatedBuilder(
                      animation: _windmillController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _windmillController.value * math.pi * 2,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const Text('✦', style: TextStyle(fontSize: 32, color: Color(0xFF5D4037))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudPuff extends StatelessWidget {
  final double width;
  final double height;

  const _CloudPuff({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

class _DetailedLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Tầng đồi xa (Distant Mountains / Hills - Xanh ngọc lục bảo)
    final distantPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF81C784).withOpacity(0.9),
          const Color(0xFF43A047),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65));

    final distantPath = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.35, size.width * 0.55, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.48, size.width, size.height * 0.38)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(distantPath, distantPaint);

    // 2. Tầng đồi trung (Mid Hill - Xanh tươi sáng)
    final midPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8BC34A), Color(0xFF388E3C)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.48, size.width, size.height * 0.52));

    final midPath = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.48, size.width * 0.65, size.height * 0.56)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.62, size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(midPath, midPaint);

    // 3. Dòng suối trong xanh (Sparkling River Stream)
    final riverPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4FC3F7), Color(0xFF0288D1), Color(0xFF81D4FA)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5))
      ..strokeWidth = 24.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.56)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.62, size.width * 0.7, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.78, size.width * 0.95, size.height * 0.88);
    canvas.drawPath(riverPath, riverPaint);

    // 4. Tầng đồi tiền cảnh (Near Foreground Meadow - Thảm cỏ gần mơn mởn)
    final nearPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9CCC65), Color(0xFF2E7D32)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35));

    final nearPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.64, size.width, size.height * 0.76)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(nearPath, nearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
