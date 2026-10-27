import 'dart:math' as math;
import 'package:flutter/material.dart';

class GameWorldBackground extends StatefulWidget {
  final bool showTerrain;

  const GameWorldBackground({
    super.key,
    this.showTerrain = true,
  });

  @override
  State<GameWorldBackground> createState() => _GameWorldBackgroundState();
}

class _GameWorldBackgroundState extends State<GameWorldBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _sunbeamController;
  late final AnimationController _windmillController;

  @override
  void initState() {
    super.initState();
    // 1. Ambient breath (clouds, floating particles)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // 2. Slow rotating sunbeams
    _sunbeamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // 3. Rotating windmill
    _windmillController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _sunbeamController.dispose();
    _windmillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Morning Sky Gradient (Bầu trời ban mai trong trẻo)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF38B6FF), // Xanh dương rực rỡ
                  Color(0xFF8CE0FF), // Xanh pastel êm dịu
                  Color(0xFFFFF9C4), // Nắng sớm vàng dịu
                  Color(0xFFC8E6C9), // Chân thung lũng xanh mướt đồng điệu
                ],
                stops: [0.0, 0.40, 0.75, 1.0],
              ),
            ),
          ),

          // 2. Animated Radiant Sun & Rotating God Rays (Mặt trời tỏa nắng thần tiên)
          Positioned(
            top: -40,
            right: -30,
            child: AnimatedBuilder(
              animation: _sunbeamController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _sunbeamController.value * math.pi * 2,
                  child: CustomPaint(
                    size: const Size(360, 360),
                    painter: _SunbeamsPainter(),
                  ),
                );
              },
            ),
          ),

          // Sun Core Glow (Vầng mặt trời rực rỡ)
          Positioned(
            top: 24,
            right: 28,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final pulse = 1.0 + (_ambientController.value * 0.06);
                return Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFF176),
                          Color(0xFFFFB300),
                          Color(0xFFFF8F00),
                        ],
                        stops: [0.0, 0.35, 0.75, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withOpacity(0.8),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF8F00).withOpacity(0.4),
                          blurRadius: 80,
                          spreadRadius: 25,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Layered Fluffy Clouds (Mây bồng bềnh có bóng đổ và độ sâu)
          Positioned(
            top: 50,
            left: 20,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_ambientController.value * 16, 0),
                  child: child,
                );
              },
              child: const _StylizedCloud(width: 140, height: 48, scale: 1.0),
            ),
          ),
          Positioned(
            top: 110,
            right: 70,
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-_ambientController.value * 14, 0),
                  child: child,
                );
              },
              child: const _StylizedCloud(width: 180, height: 56, scale: 0.9),
            ),
          ),

          // 4. Multi-tiered Rolling Hills & Sparkling River (Thung lũng đồi xanh đa tầng & suối mát)
          if (widget.showTerrain) ...[
            Positioned.fill(
              child: CustomPaint(
                painter: _FairyValleyPainter(),
              ),
            ),

            // 5. Stylized Vector Windmill (Cối xay gió vẽ sắc nét, không dùng emoji)
            Positioned(
              bottom: 240,
              left: 24,
              child: _FairyWindmillWidget(controller: _windmillController),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Sunbeams Custom Painter (Tia nắng rọi ban mai)
// -------------------------------------------------------------
class _SunbeamsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const beamCount = 12;
    const sweep = (math.pi * 2) / beamCount;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF9C4).withOpacity(0.45),
          const Color(0xFFFFE082).withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < beamCount; i++) {
      if (i % 2 == 0) {
        final startAngle = i * sweep;
        final path = Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            Rect.fromCircle(center: center, radius: radius),
            startAngle,
            sweep * 0.55,
            false,
          )
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// Stylized 3D Fluffy Cloud Widget (Đám mây hoạt hình bóng bẩy)
// -------------------------------------------------------------
class _StylizedCloud extends StatelessWidget {
  final double width;
  final double height;
  final double scale;

  const _StylizedCloud({
    required this.width,
    required this.height,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final w = width * scale;
    final h = height * scale;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(h / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 18,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xFF0288D1).withOpacity(0.12),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fluffy cloud dome 1
          Positioned(
            top: -h * 0.4,
            left: w * 0.2,
            child: Container(
              width: h * 0.85,
              height: h * 0.85,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Fluffy cloud dome 2 (larger central puff)
          Positioned(
            top: -h * 0.55,
            left: w * 0.45,
            child: Container(
              width: h * 1.05,
              height: h * 1.05,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Fairy Valley Landscape Painter (Dãy đồi cỏ xanh & suối nước có chiều sâu)
// -------------------------------------------------------------
class _FairyValleyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Distant Blue-Green Mountain Peaks (Dãy núi xa màu ngọc lam)
    final distantMountainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF64B5F6).withOpacity(0.7),
          const Color(0xFF81C784).withOpacity(0.85),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.28, w, h * 0.45));

    final distantMountainPath = Path()
      ..moveTo(0, h * 0.44)
      ..quadraticBezierTo(w * 0.2, h * 0.32, w * 0.38, h * 0.38)
      ..quadraticBezierTo(w * 0.6, h * 0.29, w * 0.82, h * 0.42)
      ..quadraticBezierTo(w * 0.92, h * 0.36, w, h * 0.40)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(distantMountainPath, distantMountainPaint);

    // 2. Midground Lush Forest Hills (Tầng đồi xanh lá đậm)
    final midHillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF81C784), // Xanh lá tươi
          Color(0xFF388E3C), // Xanh thẫm có chiều sâu
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.42, w, h * 0.58));

    final midHillPath = Path()
      ..moveTo(0, h * 0.54)
      ..quadraticBezierTo(w * 0.25, h * 0.45, w * 0.55, h * 0.52)
      ..quadraticBezierTo(w * 0.8, h * 0.58, w, h * 0.48)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midHillPath, midHillPaint);

    // 3. Sparkling Blue River (Dòng suối uốn lượn có viền cát vàng)
    // River Sandbank (Bờ cát vàng)
    final sandPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 32.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(-20, h * 0.52)
      ..cubicTo(w * 0.25, h * 0.54, w * 0.55, h * 0.66, w * 0.72, h * 0.74)
      ..quadraticBezierTo(w * 0.85, h * 0.80, w + 20, h * 0.88);

    canvas.drawPath(riverPath, sandPaint);

    // Water Surface (Mặt nước trong biếc)
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF29B6F6),
          Color(0xFF0288D1),
          Color(0xFF4FC3F7),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5))
      ..strokeWidth = 24.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(riverPath, waterPaint);

    // Water Sparkle highlights (Gợn sóng lấp lánh)
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final wavePath = Path()
      ..moveTo(w * 0.32, h * 0.58)
      ..quadraticBezierTo(w * 0.36, h * 0.59, w * 0.42, h * 0.60)
      ..moveTo(w * 0.65, h * 0.72)
      ..quadraticBezierTo(w * 0.70, h * 0.74, w * 0.76, h * 0.76);
    canvas.drawPath(wavePath, wavePaint);

    // 4. Foreground Vibrant Meadow (Thảm cỏ đồi xanh nõn tiền cảnh)
    final foregroundMeadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFAED581), // Xanh non mơn mởn
          Color(0xFF689F38), // Xanh cỏ đậm đà
          Color(0xFF33691E), // Chân cỏ tối sâu
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.65, w, h * 0.35));

    final foregroundPath = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.35, h * 0.62, w * 0.70, h * 0.73)
      ..quadraticBezierTo(w * 0.88, h * 0.78, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(foregroundPath, foregroundMeadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// Stylized Fairy Windmill Widget (Cối xay gió vẽ vector sắc sảo)
// -------------------------------------------------------------
class _FairyWindmillWidget extends StatelessWidget {
  final AnimationController controller;

  const _FairyWindmillWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 90,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. Windmill Stone Base & Cone Roof
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red conical roof
                CustomPaint(
                  size: const Size(28, 16),
                  painter: _RoofPainter(),
                ),
                // White/Grey stone tower
                Container(
                  width: 32,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(2, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Little arched window
                      Container(
                        width: 8,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5D4037),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      // Little wooden door
                      Container(
                        width: 12,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF795548),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Rotating Windmill 4 Blades
          Positioned(
            top: 6,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: controller.value * math.pi * 2,
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(64, 64),
                painter: _WindmillBladesPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoofPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WindmillBladesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bladePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final clothPaint = Paint()
      ..color = const Color(0xFFFFF8E1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      // Blade spar
      canvas.drawLine(Offset.zero, const Offset(0, -28), bladePaint);

      // Cloth sail
      final sailPath = Path()
        ..moveTo(2, -8)
        ..lineTo(10, -10)
        ..lineTo(8, -26)
        ..lineTo(2, -26)
        ..close();
      canvas.drawPath(sailPath, clothPaint);

      canvas.restore();
    }

    // Center pin
    final pinPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawCircle(center, 4, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
