import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter for the 3D Diorama Valley Ground Layer:
/// - River with flowing water and wooden arched bridge
/// - Central stone plaza for Pippo
/// - Organic honey-gold cobblestone paths connecting all 5 stations
/// - Natural ground foundation blending pads beneath buildings (prevent floating)
/// - Consistent 135° directional soft ambient shadows
class DioramaGroundPainter extends CustomPainter {
  final double scale;

  DioramaGroundPainter({this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = scale;

    // 135° Directional Sunlight shadow offset (from top-right to bottom-left)
    final shadowOffset = Offset(-6.0 * s, 10.0 * s);

    // Key spatial anchors in virtual canvas (800 x 1100)
    final plazaCenter = Offset(w * 0.50, h * 0.55);
    final station1Center = Offset(w * 0.22, h * 0.43); // Market (left)
    final station2Center = Offset(w * 0.24, h * 0.79); // Mushroom (bottom left)
    final station3Center = Offset(w * 0.78, h * 0.43); // Tree (right)
    final station4Center = Offset(w * 0.76, h * 0.79); // Sanctuary (bottom right)
    final station5Center = Offset(w * 0.50, h * 0.18); // Castle (top hill)

    // -------------------------------------------------------------------------
    // 1. FLOWING BLUE RIVER & WATER HIGHLIGHTS
    // -------------------------------------------------------------------------
    final riverPath = Path()
      ..moveTo(w * 0.78, 0)
      ..cubicTo(w * 0.65, h * 0.20, w * 0.58, h * 0.38, w * 0.62, h * 0.52)
      ..cubicTo(w * 0.66, h * 0.65, w * 0.88, h * 0.75, w * 0.82, h * 1.05);

    // River bed shadow (sunlight from top-right casts shadow on the left riverbank)
    final riverBedPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 56.0 * s
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(riverPath.shift(shadowOffset * 0.5), riverBedPaint);

    // River water base
    final riverBasePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFF01579B)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(riverPath, riverBasePaint);

    // River sparkling foam highlights
    final riverFoamPaint = Paint()
      ..color = const Color(0xFFE1F5FE).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(riverPath, riverFoamPaint);

    // -------------------------------------------------------------------------
    // 2. FOUNDATION BLENDING PADS (MÓNG TIẾP ĐẤT TỰ NHIÊN DƯỚI CÔNG TRÌNH)
    // -------------------------------------------------------------------------
    // Castle terrace (Tầng 2)
    _drawFoundationPad(
      canvas: canvas,
      center: station5Center.translate(0, 15 * s),
      width: 220 * s,
      height: 70 * s,
      baseColor: const Color(0xFF8D6E63),
      grassColor: const Color(0xFF66BB6A),
      shadowOffset: shadowOffset,
    );

    // Market wood-gravel patio (Tầng 3)
    _drawFoundationPad(
      canvas: canvas,
      center: station1Center.translate(0, 30 * s),
      width: 210 * s,
      height: 75 * s,
      baseColor: const Color(0xFFBCAAA4),
      grassColor: const Color(0xFF81C784),
      shadowOffset: shadowOffset,
    );

    // Wonder Tree forest clearing (Tầng 3)
    _drawFoundationPad(
      canvas: canvas,
      center: station3Center.translate(0, 35 * s),
      width: 200 * s,
      height: 75 * s,
      baseColor: const Color(0xFF795548),
      grassColor: const Color(0xFF4CAF50),
      shadowOffset: shadowOffset,
    );

    // Math Mushroom mossy mound (Tầng 4)
    _drawFoundationPad(
      canvas: canvas,
      center: station2Center.translate(0, 30 * s),
      width: 220 * s,
      height: 80 * s,
      baseColor: const Color(0xFF5D4037),
      grassColor: const Color(0xFF388E3C),
      shadowOffset: shadowOffset,
    );

    // Pet Sanctuary sandy meadow (Tầng 4)
    _drawFoundationPad(
      canvas: canvas,
      center: station4Center.translate(0, 30 * s),
      width: 220 * s,
      height: 80 * s,
      baseColor: const Color(0xFFFFD54F),
      grassColor: const Color(0xFF689F38),
      shadowOffset: shadowOffset,
    );

    // -------------------------------------------------------------------------
    // 3. ORGANIC COBBLESTONE ROAD NETWORK (ĐƯỜNG MÒN ĐÁ SỎI)
    // -------------------------------------------------------------------------
    final roadPaths = Path();

    // To Castle (Station 5)
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(w * 0.48, h * 0.38, station5Center.dx, station5Center.dy + (45 * s));

    // To Market (Station 1)
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(w * 0.34, h * 0.52, station1Center.dx + (40 * s), station1Center.dy + (40 * s));

    // To Wonder Tree (Station 3) - crosses the river
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(w * 0.65, h * 0.50, station3Center.dx - (30 * s), station3Center.dy + (40 * s));

    // To Math Mushroom (Station 2)
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(w * 0.36, h * 0.68, station2Center.dx + (35 * s), station2Center.dy + (35 * s));

    // To Pet Sanctuary (Station 4)
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(w * 0.64, h * 0.68, station4Center.dx - (35 * s), station4Center.dy + (35 * s));

    // Road shadow (135°)
    final roadShadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36.0 * s
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(roadPaths.shift(shadowOffset * 0.6), roadShadowPaint);

    // Road sand/dirt base
    final roadDirtPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFCA28), Color(0xFFD7CCC8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(roadPaths, roadDirtPaint);

    // Cobblestone core highlight
    final roadStonePaint = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(roadPaths, roadStonePaint);

    // -------------------------------------------------------------------------
    // 4. WOODEN BRIDGE OVER RIVER (CẦU GỖ MỘC)
    // -------------------------------------------------------------------------
    final bridgeCenter = Offset(w * 0.625, h * 0.505);
    canvas.save();
    canvas.translate(bridgeCenter.dx, bridgeCenter.dy);
    canvas.rotate(-math.pi / 7);

    // Bridge shadow
    final bridgeShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: shadowOffset * 0.5, width: 44 * s, height: 65 * s),
        Radius.circular(6 * s),
      ),
      bridgeShadowPaint,
    );

    // Bridge timber deck
    final bridgeWoodPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 40 * s, height: 60 * s),
        Radius.circular(6 * s),
      ),
      bridgeWoodPaint,
    );

    // Bridge planks
    final plankPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2 * s;
    for (double y = -24 * s; y <= 24 * s; y += 12 * s) {
      canvas.drawLine(Offset(-20 * s, y), Offset(20 * s, y), plankPaint);
    }

    // Bridge golden handrails
    final railPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-19 * s, -28 * s), Offset(-19 * s, 28 * s), railPaint);
    canvas.drawLine(Offset(19 * s, -28 * s), Offset(19 * s, 28 * s), railPaint);

    canvas.restore();

    // -------------------------------------------------------------------------
    // 5. CENTRAL STONE PLAZA FOR PIPPO (QUẢNG TRƯỜNG GẠCH ĐÁ TRÒN)
    // -------------------------------------------------------------------------
    final plazaRect = Rect.fromCenter(
      center: plazaCenter.translate(0, 15 * s),
      width: 170 * s,
      height: 75 * s,
    );

    // Plaza shadow
    final plazaShadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(plazaRect.shift(shadowOffset), plazaShadowPaint);

    // Plaza stone base
    final plazaStonePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFE082), Color(0xFFD7CCC8)],
      ).createShader(plazaRect);
    canvas.drawOval(plazaRect, plazaStonePaint);

    // Plaza golden outer rim
    final plazaRimPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * s;
    canvas.drawOval(plazaRect, plazaRimPaint);

    // Cobblestone concentric ring pattern
    final plazaRingPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;
    canvas.drawOval(
      Rect.fromCenter(center: plazaRect.center, width: 120 * s, height: 50 * s),
      plazaRingPaint,
    );
  }

  void _drawFoundationPad({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required Color baseColor,
    required Color grassColor,
    required Offset shadowOffset,
  }) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(rect.shift(shadowOffset * 0.7), shadowPaint);

    // Foundation dirt/stone base
    final basePaint = Paint()..color = baseColor;
    canvas.drawOval(rect, basePaint);

    // Organic grass tuft border
    final grassBorderPaint = Paint()
      ..color = grassColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width + 4, height: height + 4),
      grassBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DioramaGroundPainter oldDelegate) => oldDelegate.scale != scale;
}
