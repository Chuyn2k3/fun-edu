import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter for the 3D Diorama Valley Ground Layer:
/// - Full-coverage lush diorama landmass (Horizon ridge, Upper plateau, Valley meadow, Foreground bank)
/// - Mountain spring pool source flowing naturally under wooden bridge to foreground
/// - Tactile cobblestone road network with bezier-evaluated stepping stones
/// - Perfectly aligned wooden bridge at river crossing
/// - Central sunburst stone plaza for Pippo
/// - 5 natural foundation blending pads beneath buildings (prevent floating)
/// - Cute nature details: wild flower patches, grass tufts, river pebbles
/// - Consistent 135° directional soft ambient lighting & shadows
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

    // Key spatial anchors in virtual canvas (800 x 1350)
    final plazaCenter = Offset(w * 0.50, h * 0.526);
    final station1Center = Offset(w * 0.22, h * 0.392); // Market (left)
    final station2Center = Offset(w * 0.24, h * 0.755); // Mushroom (bottom left)
    final station3Center = Offset(w * 0.78, h * 0.392); // Tree (right)
    final station4Center = Offset(w * 0.76, h * 0.755); // Sanctuary (bottom right)
    final station5Center = Offset(w * 0.50, h * 0.133); // Castle (top hill)

    // -------------------------------------------------------------------------
    // 1. FULL-COVERAGE LUSH DIORAMA LANDMASS (THUNG LŨNG CỎ XANH ĐA TẦNG)
    // -------------------------------------------------------------------------
    _drawValleyTerrain(canvas, w, h, s, shadowOffset, station5Center);

    // -------------------------------------------------------------------------
    // 2. FLOWING BLUE RIVER & WATER HIGHLIGHTS (DÒNG SUỐI NGUỒN NÚI)
    // -------------------------------------------------------------------------
    final riverSource = Offset(w * 0.72, h * 0.163);
    final riverPath = Path()
      ..moveTo(riverSource.dx, riverSource.dy)
      ..cubicTo(w * 0.63, h * 0.31, w * 0.57, h * 0.42, w * 0.605, h * 0.485)
      ..cubicTo(w * 0.64, h * 0.56, w * 0.83, h * 0.72, w * 0.78, h * 1.05);

    // River bed shadow (sunlight from top-right casts shadow on the left riverbank)
    final riverBedShadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 62.0 * s
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(riverPath.shift(shadowOffset * 0.5), riverBedShadowPaint);

    // River sandbank / gravel shore
    final riverSandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFD54F), Color(0xFFD7CCC8)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 56.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(riverPath, riverSandPaint);

    // River water base
    final riverWaterPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF0288D1), Color(0xFF01579B)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 42.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(riverPath, riverWaterPaint);

    // Mountain spring pool at river origin
    final poolRect = Rect.fromCenter(center: riverSource, width: 64 * s, height: 42 * s);
    final poolPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE1F5FE), Color(0xFF00E5FF), Color(0xFF0288D1)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(poolRect);
    canvas.drawOval(poolRect, poolPaint);

    // River current foam highlights
    final riverFoamPaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(riverPath, riverFoamPaint);

    // Sparkling water ripples
    _drawRiverRipples(canvas, w, h, s);

    // Smooth river pebbles along the shore
    _drawRiverPebbles(canvas, w, h, s);

    // -------------------------------------------------------------------------
    // 3. FOUNDATION BLENDING PADS (MÓNG TIẾP ĐẤT TỰ NHIÊN DƯỚI CÔNG TRÌNH)
    // -------------------------------------------------------------------------
    // Castle terrace (Tầng 2 - Stone Plateau)
    _drawFoundationPad(
      canvas: canvas,
      center: station5Center.translate(0, 25 * s),
      width: 250 * s,
      height: 85 * s,
      baseColor: const Color(0xFFB0BEC5),
      grassColor: const Color(0xFFA5D6A7),
      shadowOffset: shadowOffset,
    );

    // Market wood-gravel patio (Tầng 3)
    _drawFoundationPad(
      canvas: canvas,
      center: station1Center.translate(0, 40 * s),
      width: 240 * s,
      height: 90 * s,
      baseColor: const Color(0xFFBCAAA4),
      grassColor: const Color(0xFFAED581),
      shadowOffset: shadowOffset,
    );

    // Wonder Tree forest clearing (Tầng 3)
    _drawFoundationPad(
      canvas: canvas,
      center: station3Center.translate(0, 45 * s),
      width: 230 * s,
      height: 90 * s,
      baseColor: const Color(0xFF795548),
      grassColor: const Color(0xFF7CB342),
      shadowOffset: shadowOffset,
    );

    // Math Mushroom mossy mound (Tầng 4)
    _drawFoundationPad(
      canvas: canvas,
      center: station2Center.translate(0, 40 * s),
      width: 240 * s,
      height: 95 * s,
      baseColor: const Color(0xFF5D4037),
      grassColor: const Color(0xFF558B2F),
      shadowOffset: shadowOffset,
    );

    // Pet Sanctuary sandy meadow (Tầng 4)
    _drawFoundationPad(
      canvas: canvas,
      center: station4Center.translate(0, 40 * s),
      width: 240 * s,
      height: 95 * s,
      baseColor: const Color(0xFFFFD54F),
      grassColor: const Color(0xFF689F38),
      shadowOffset: shadowOffset,
    );

    // -------------------------------------------------------------------------
    // 4. ORGANIC COBBLESTONE ROAD NETWORK (ĐƯỜNG MÒN ĐÁ SỎI TỰ NHIÊN)
    // -------------------------------------------------------------------------
    final pCastleControl = Offset(w * 0.48, h * 0.32);
    final pCastleEnd = Offset(station5Center.dx, station5Center.dy + (60 * s));

    final pMarketControl = Offset(w * 0.34, h * 0.48);
    final pMarketEnd = Offset(station1Center.dx + (45 * s), station1Center.dy + (50 * s));

    final pTreeControl = Offset(w * 0.63, h * 0.47);
    final pTreeEnd = Offset(station3Center.dx - (35 * s), station3Center.dy + (50 * s));

    final pMushroomControl = Offset(w * 0.35, h * 0.65);
    final pMushroomEnd = Offset(station2Center.dx + (40 * s), station2Center.dy + (45 * s));

    final pSanctuaryControl = Offset(w * 0.65, h * 0.65);
    final pSanctuaryEnd = Offset(station4Center.dx - (40 * s), station4Center.dy + (45 * s));

    final roadPaths = Path();

    // To Castle
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(pCastleControl.dx, pCastleControl.dy, pCastleEnd.dx, pCastleEnd.dy);

    // To Market
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(pMarketControl.dx, pMarketControl.dy, pMarketEnd.dx, pMarketEnd.dy);

    // To Wonder Tree (passes directly over bridge)
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(pTreeControl.dx, pTreeControl.dy, pTreeEnd.dx, pTreeEnd.dy);

    // To Math Mushroom
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(pMushroomControl.dx, pMushroomControl.dy, pMushroomEnd.dx, pMushroomEnd.dy);

    // To Pet Sanctuary
    roadPaths.moveTo(plazaCenter.dx, plazaCenter.dy);
    roadPaths.quadraticBezierTo(pSanctuaryControl.dx, pSanctuaryControl.dy, pSanctuaryEnd.dx, pSanctuaryEnd.dy);

    // Road shadow (135°)
    final roadShadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38.0 * s
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(roadPaths.shift(shadowOffset * 0.6), roadShadowPaint);

    // Road sand/dirt base
    final roadDirtPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFCA28), Color(0xFFD7CCC8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(roadPaths, roadDirtPaint);

    // Cobblestone core highlight
    final roadStonePaint = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(roadPaths, roadStonePaint);

    // Individual tactile cobblestones on the roads (precisely following bezier curves!)
    _drawCobblestonePaversBezier(
      canvas: canvas,
      s: s,
      start: plazaCenter,
      cCastle: pCastleControl,
      endCastle: pCastleEnd,
      cMarket: pMarketControl,
      endMarket: pMarketEnd,
      cTree: pTreeControl,
      endTree: pTreeEnd,
      cMushroom: pMushroomControl,
      endMushroom: pMushroomEnd,
      cSanctuary: pSanctuaryControl,
      endSanctuary: pSanctuaryEnd,
    );

    // -------------------------------------------------------------------------
    // 5. WOODEN BRIDGE OVER RIVER (CẦU GỖ MỘC QUA SUỐI)
    // Positioned precisely at the intersection of River and Path to Wonder Tree!
    // -------------------------------------------------------------------------
    final bridgeCenter = Offset(w * 0.605, h * 0.480);
    canvas.save();
    canvas.translate(bridgeCenter.dx, bridgeCenter.dy);
    canvas.rotate(-math.pi / 5.2);

    // Bridge shadow on river water
    final bridgeShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: shadowOffset * 0.6, width: 48 * s, height: 72 * s),
        Radius.circular(6 * s),
      ),
      bridgeShadowPaint,
    );

    // Bridge timber deck
    final bridgeWoodPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 44 * s, height: 68 * s),
        Radius.circular(6 * s),
      ),
      bridgeWoodPaint,
    );

    // Bridge planks
    final plankPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.5 * s;
    for (double y = -26 * s; y <= 26 * s; y += 12 * s) {
      canvas.drawLine(Offset(-22 * s, y), Offset(22 * s, y), plankPaint);
    }

    // Bridge golden handrails
    final railPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 4.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-21 * s, -31 * s), Offset(-21 * s, 31 * s), railPaint);
    canvas.drawLine(Offset(21 * s, -31 * s), Offset(21 * s, 31 * s), railPaint);

    canvas.restore();

    // -------------------------------------------------------------------------
    // 6. CENTRAL STONE PLAZA FOR PIPPO (QUẢNG TRƯỜNG GẠCH ĐÁ TRÒN)
    // -------------------------------------------------------------------------
    final plazaRect = Rect.fromCenter(
      center: plazaCenter.translate(0, 18 * s),
      width: 190 * s,
      height: 85 * s,
    );

    // Plaza shadow
    final plazaShadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
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
      ..strokeWidth = 4.5 * s;
    canvas.drawOval(plazaRect, plazaRimPaint);

    // Cobblestone concentric ring pattern
    final plazaRingPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s;
    canvas.drawOval(
      Rect.fromCenter(center: plazaRect.center, width: 135 * s, height: 60 * s),
      plazaRingPaint,
    );

    // Radiating stone dividers
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      final r1 = 28 * s;
      final r2 = 72 * s;
      final p1 = Offset(
        plazaRect.center.dx + math.cos(angle) * r1,
        plazaRect.center.dy + math.sin(angle) * (r1 * 0.44),
      );
      final p2 = Offset(
        plazaRect.center.dx + math.cos(angle) * r2,
        plazaRect.center.dy + math.sin(angle) * (r2 * 0.44),
      );
      canvas.drawLine(p1, p2, plazaRingPaint);
    }

    // -------------------------------------------------------------------------
    // 7. CUTE NATURE DETAILS (HOA CỎ & ĐÁ CUỘI TẠO ĐỘ SINH ĐỘNG)
    // -------------------------------------------------------------------------
    _drawNatureDetails(canvas, w, h, s);
  }

  void _drawValleyTerrain(
    Canvas canvas,
    double w,
    double h,
    double s,
    Offset shadowOffset,
    Offset castleCenter,
  ) {
    // 1. Distant Horizon Hills Ridge (Tầng 1 - Dãy đồi mờ xa chân trời)
    final distantHillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFA5D6A7).withOpacity(0.92),
          const Color(0xFF81C784),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.08, w, h * 0.25));

    final distantHillPath = Path()
      ..moveTo(0, h * 0.16)
      ..quadraticBezierTo(w * 0.22, h * 0.09, w * 0.45, h * 0.13)
      ..quadraticBezierTo(w * 0.65, h * 0.08, w * 0.85, h * 0.12)
      ..quadraticBezierTo(w * 0.95, h * 0.10, w, h * 0.14)
      ..lineTo(w, h * 1.2)
      ..lineTo(0, h * 1.2)
      ..close();
    canvas.drawPath(distantHillPath, distantHillPaint);

    // Horizon sunlit rim highlight
    final horizonRimPaint = Paint()
      ..color = const Color(0xFFE8F5E9).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s;
    canvas.drawPath(distantHillPath, horizonRimPaint);

    // 2. Castle Upper Plateau (Tầng 2 - Đồi Lâu Đài Chữ Cái nhô cao)
    final plateauPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC5E1A5), Color(0xFF9CCC65)],
      ).createShader(Rect.fromLTWH(0, h * 0.12, w, h * 0.20));

    final plateauPath = Path()
      ..moveTo(w * 0.12, h * 0.23)
      ..quadraticBezierTo(w * 0.28, h * 0.14, w * 0.50, h * 0.14)
      ..quadraticBezierTo(w * 0.72, h * 0.14, w * 0.88, h * 0.23)
      ..quadraticBezierTo(w * 0.50, h * 0.27, w * 0.12, h * 0.23)
      ..close();

    // Shadow cast by plateau onto valley
    final plateauShadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(plateauPath.shift(shadowOffset * 0.7), plateauShadowPaint);
    canvas.drawPath(plateauPath, plateauPaint);

    // 3. Main Valley Meadow (Tầng 3 - Thung lũng cỏ xanh trung tâm)
    final valleyMeadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8BC34A), // Xanh lá non rực rỡ
          Color(0xFF7CB342), // Xanh thung lũng mướt mát
          Color(0xFF689F38), // Chân thung lũng có chiều sâu
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.22, w, h * 0.50));

    final valleyMeadowPath = Path()
      ..moveTo(0, h * 0.23)
      ..quadraticBezierTo(w * 0.35, h * 0.25, w * 0.65, h * 0.22)
      ..quadraticBezierTo(w * 0.85, h * 0.24, w, h * 0.22)
      ..lineTo(w, h * 0.72)
      ..quadraticBezierTo(w * 0.60, h * 0.69, w * 0.30, h * 0.73)
      ..lineTo(0, h * 0.72)
      ..close();
    canvas.drawPath(valleyMeadowPath, valleyMeadowPaint);

    // Soft topographic contour curve in valley
    final contourPaint = Paint()
      ..color = const Color(0xFF9CCC65).withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * s;
    final contourPath = Path()
      ..moveTo(0, h * 0.44)
      ..quadraticBezierTo(w * 0.25, h * 0.42, w * 0.50, h * 0.46)
      ..quadraticBezierTo(w * 0.75, h * 0.50, w, h * 0.45);
    canvas.drawPath(contourPath, contourPaint);

    // 4. Foreground Slope (Tầng 4 - Thảm cỏ tiền cảnh kéo dài bao phủ đáy màn hình)
    final foregroundSlopePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF689F38), // Xanh cỏ đậm
          Color(0xFF558B2F), // Xanh thẫm
          Color(0xFF33691E), // Đáy tiền cảnh sâu lắng
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.68, w, h * 0.45));

    final foregroundSlopePath = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.35, h * 0.67, w * 0.68, h * 0.71)
      ..quadraticBezierTo(w * 0.88, h * 0.68, w, h * 0.71)
      ..lineTo(w, h * 1.3)
      ..lineTo(0, h * 1.3)
      ..close();

    // Foreground shadow cast
    final fgShadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(foregroundSlopePath.shift(shadowOffset * 0.5), fgShadowPaint);
    canvas.drawPath(foregroundSlopePath, foregroundSlopePaint);

    // Soft sun highlight along foreground slope ridge
    final fgHighlightPaint = Paint()
      ..color = const Color(0xFFAED581).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.70)
        ..quadraticBezierTo(w * 0.35, h * 0.67, w * 0.68, h * 0.71)
        ..quadraticBezierTo(w * 0.88, h * 0.68, w, h * 0.71),
      fgHighlightPaint,
    );
  }

  void _drawRiverRipples(Canvas canvas, double w, double h, double s) {
    final ripplePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;

    final ripples = [
      Offset(w * 0.69, h * 0.25),
      Offset(w * 0.61, h * 0.36),
      Offset(w * 0.58, h * 0.44),
      Offset(w * 0.63, h * 0.57),
      Offset(w * 0.73, h * 0.68),
      Offset(w * 0.80, h * 0.82),
    ];

    for (final pt in ripples) {
      final p = Path()
        ..moveTo(pt.dx - (10 * s), pt.dy)
        ..quadraticBezierTo(pt.dx, pt.dy - (3 * s), pt.dx + (10 * s), pt.dy);
      canvas.drawPath(p, ripplePaint);
    }
  }

  void _drawRiverPebbles(Canvas canvas, double w, double h, double s) {
    final pebblePaint = Paint()..color = const Color(0xFFB0BEC5);
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.25);

    final pebblePoints = [
      Offset(w * 0.67, h * 0.22),
      Offset(w * 0.58, h * 0.32),
      Offset(w * 0.53, h * 0.42),
      Offset(w * 0.56, h * 0.54),
      Offset(w * 0.61, h * 0.65),
      Offset(w * 0.71, h * 0.76),
      Offset(w * 0.84, h * 0.88),
    ];

    for (int i = 0; i < pebblePoints.length; i++) {
      final pt = pebblePoints[i];
      final rx = (6 + (i % 3) * 2) * s;
      final ry = (4 + (i % 2) * 2) * s;

      canvas.drawOval(
        Rect.fromCenter(center: pt.translate(-1 * s, 2 * s), width: rx * 2, height: ry * 2),
        shadowPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: pt, width: rx * 2, height: ry * 2),
        pebblePaint,
      );
    }
  }

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  void _drawCobblestonePaversBezier({
    required Canvas canvas,
    required double s,
    required Offset start,
    required Offset cCastle,
    required Offset endCastle,
    required Offset cMarket,
    required Offset endMarket,
    required Offset cTree,
    required Offset endTree,
    required Offset cMushroom,
    required Offset endMushroom,
    required Offset cSanctuary,
    required Offset endSanctuary,
  }) {
    final stonePaint = Paint()..color = const Color(0xFFFFF9C4);
    final stoneShadow = Paint()..color = const Color(0xFFBCAAA4).withOpacity(0.7);

    void drawStone(Offset pt, double r) {
      canvas.drawCircle(pt.translate(-0.8 * s, 1.2 * s), r * s, stoneShadow);
      canvas.drawCircle(pt, r * s, stonePaint);
    }

    // Path to Castle stones
    for (double t = 0.20; t <= 0.85; t += 0.14) {
      final pt = _quadBezier(start, cCastle, endCastle, t);
      drawStone(pt, 5.5);
    }

    // Path to Market stones
    for (double t = 0.25; t <= 0.85; t += 0.15) {
      final pt = _quadBezier(start, cMarket, endMarket, t);
      drawStone(pt, 5.5);
    }

    // Path to Tree stones (passes across bridge)
    for (double t = 0.22; t <= 0.85; t += 0.15) {
      final pt = _quadBezier(start, cTree, endTree, t);
      drawStone(pt, 5.5);
    }

    // Path to Mushroom stones
    for (double t = 0.22; t <= 0.85; t += 0.15) {
      final pt = _quadBezier(start, cMushroom, endMushroom, t);
      drawStone(pt, 6.0);
    }

    // Path to Sanctuary stones
    for (double t = 0.22; t <= 0.85; t += 0.15) {
      final pt = _quadBezier(start, cSanctuary, endSanctuary, t);
      drawStone(pt, 6.0);
    }
  }

  void _drawNatureDetails(Canvas canvas, double w, double h, double s) {
    // 1. Wild Daisy Flower Patches
    final petalPaint = Paint()..color = Colors.white;
    final flowerCenterPaint = Paint()..color = const Color(0xFFFFD54F);

    void drawDaisy(Offset pt) {
      const radius = 3.2;
      for (int i = 0; i < 4; i++) {
        final angle = i * (math.pi / 2);
        canvas.drawCircle(
          Offset(pt.dx + math.cos(angle) * radius * s, pt.dy + math.sin(angle) * radius * s),
          radius * s,
          petalPaint,
        );
      }
      canvas.drawCircle(pt, 2.2 * s, flowerCenterPaint);
    }

    final flowerLocations = [
      Offset(w * 0.18, h * 0.29),
      Offset(w * 0.35, h * 0.34),
      Offset(w * 0.42, h * 0.44),
      Offset(w * 0.12, h * 0.58),
      Offset(w * 0.38, h * 0.62),
      Offset(w * 0.86, h * 0.31),
      Offset(w * 0.70, h * 0.42),
      Offset(w * 0.72, h * 0.64),
      Offset(w * 0.15, h * 0.88),
      Offset(w * 0.48, h * 0.82),
      Offset(w * 0.82, h * 0.92),
    ];

    for (final loc in flowerLocations) {
      drawDaisy(loc);
    }

    // 2. Cute Tufts of Grass
    final grassTuftPaint = Paint()
      ..color = const Color(0xFF33691E).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round;

    void drawTuft(Offset pt) {
      canvas.drawLine(pt, Offset(pt.dx - (4 * s), pt.dy - (7 * s)), grassTuftPaint);
      canvas.drawLine(pt, Offset(pt.dx, pt.dy - (9 * s)), grassTuftPaint);
      canvas.drawLine(pt, Offset(pt.dx + (4 * s), pt.dy - (7 * s)), grassTuftPaint);
    }

    final tuftLocations = [
      Offset(w * 0.28, h * 0.30),
      Offset(w * 0.10, h * 0.45),
      Offset(w * 0.44, h * 0.38),
      Offset(w * 0.88, h * 0.48),
      Offset(w * 0.30, h * 0.58),
      Offset(w * 0.68, h * 0.58),
      Offset(w * 0.40, h * 0.74),
      Offset(w * 0.60, h * 0.80),
      Offset(w * 0.88, h * 0.78),
    ];

    for (final pt in tuftLocations) {
      drawTuft(pt);
    }
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
      ..color = Colors.black.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(rect.shift(shadowOffset * 0.7), shadowPaint);

    // Foundation dirt/stone base
    final basePaint = Paint()..color = baseColor;
    canvas.drawOval(rect, basePaint);

    // Organic grass tuft border
    final grassBorderPaint = Paint()
      ..color = grassColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width + 5, height: height + 5),
      grassBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DioramaGroundPainter oldDelegate) => oldDelegate.scale != scale;
}
