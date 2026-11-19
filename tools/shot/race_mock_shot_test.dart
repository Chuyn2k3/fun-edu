// Render harness for the rocket race redesign mockups (Phase 0).
// Generates 5 static mockup PNGs for owner review before animation work.
// Usage:
//   mkdir -p test/_shot && cp tools/shot/race_mock_shot_test.dart test/_shot/
//   FLUTTER_ROOT=$(dirname $(dirname $(which flutter))) flutter test test/_shot/race_mock_shot_test.dart
//   rm -rf test/_shot
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/flame_painter.dart';
import 'package:funedu/game/scene/trails.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/app_theme.dart';
import 'package:funedu/ui/theme/depth.dart';
import 'package:funedu/ui/theme/tokens.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Nunito');
  for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
  }
  await loader.load();
  final m = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File(
            '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
        .readAsBytesSync())));
  await m.load();
}

void main() {
  testWidgets('generate race redesign mockups', (tester) async {
    await tester.runAsync(_loadFonts);
    const outDir = 'docs/superpowers/specs/assets/race-redesign';
    Directory(outDir).createSync(recursive: true);

    Future<void> snap(Widget widget, Size size, String filename) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      final key = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: buildAppTheme(),
            debugShowCheckedModeBanner: false,
            home: Material(child: widget),
          ),
        ),
      );

      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
        await tester.pump();
      }

      for (final e in find.byType(Image).evaluate()) {
        final img = e.widget as Image;
        await tester.runAsync(() => precacheImage(img.image, e));
      }
      await tester.pump();

      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final im = await b.toImage(pixelRatio: 2);
        final data = await im.toByteData(format: ui.ImageByteFormat.png);
        File('$outDir/$filename').writeAsBytesSync(data!.buffer.asUint8List());
      });

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 1. Phone Câu 2 (Chíp dẫn)
    await snap(
      const _MockRaceScreen(
        questionNumber: 2,
        kidStep: 2,
        chipStep: 3,
        isNitro: false,
        isComet: false,
        isLandscapeTablet: false,
      ),
      const Size(390, 844),
      'sau-cau-2-chip-dan.png',
    );

    // 2. Phone Câu 6 (Bé dẫn, Nitro bứt tốc)
    await snap(
      const _MockRaceScreen(
        questionNumber: 6,
        kidStep: 7,
        chipStep: 5,
        isNitro: true,
        isComet: false,
        isLandscapeTablet: false,
      ),
      const Size(390, 844),
      'sau-cau-6-nitro-dan.png',
    );

    // 3. Phone Câu sao chổi (Comet vàng)
    await snap(
      const _MockRaceScreen(
        questionNumber: 8,
        kidStep: 8,
        chipStep: 7,
        isNitro: false,
        isComet: true,
        isLandscapeTablet: false,
      ),
      const Size(390, 844),
      'sau-cau-sao-choi.png',
    );

    // 4. iPad ngang Câu 6 (1366x1024)
    await snap(
      const _MockRaceScreen(
        questionNumber: 6,
        kidStep: 7,
        chipStep: 5,
        isNitro: true,
        isComet: false,
        isLandscapeTablet: true,
      ),
      const Size(1366, 1024),
      'sau-ipad-ngang-cau-6.png',
    );

    // 5. Màn kết quả thắng (Result Screen đồng bộ chất liệu)
    await snap(
      const _MockResultScreen(),
      const Size(390, 844),
      'sau-ket-qua-thang.png',
    );
  });
}

// -----------------------------------------------------------------------------
// MOCK RACE SCREEN COMPONENT
// -----------------------------------------------------------------------------
class _MockRaceScreen extends StatelessWidget {
  const _MockRaceScreen({
    required this.questionNumber,
    required this.kidStep,
    required this.chipStep,
    required this.isNitro,
    required this.isComet,
    required this.isLandscapeTablet,
  });

  final int questionNumber;
  final int kidStep;
  final int chipStep;
  final bool isNitro;
  final bool isComet;
  final bool isLandscapeTablet;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Full-screen Space Scene (Vũ trụ đồ chơi tràn toàn màn hình)
        Positioned.fill(
          child: _StarPathScene(
            kidStep: kidStep,
            chipStep: chipStep,
            isNitro: isNitro,
            isComet: isComet,
            isLandscapeTablet: isLandscapeTablet,
          ),
        ),

        // 2. Cockpit Top HUD (Pause + Chặng N/10)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscapeTablet ? 36 : 20,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: raisedDecoration(radius: 24),
                    child: const Icon(Icons.pause_rounded, size: 28, color: AppColors.text),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: raisedDecoration(radius: AppRadii.pill),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(AppImages.icStar, width: 22, height: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Chặng $questionNumber/10',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Toy Cockpit Dashboard Console at Bottom
        Positioned(
          left: isLandscapeTablet ? 140 : 0,
          right: isLandscapeTablet ? 140 : 0,
          bottom: 0,
          child: _ToyCockpitDashboard(
            questionNumber: questionNumber,
            isComet: isComet,
            isNitro: isNitro,
            isLandscapeTablet: isLandscapeTablet,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// STAR PATH SCENE (CẢNH VŨ TRỤ TRÀN VIỀN — HƯỚNG 1 COCKPIT)
// -----------------------------------------------------------------------------
class _StarPathScene extends StatelessWidget {
  const _StarPathScene({
    required this.kidStep,
    required this.chipStep,
    required this.isNitro,
    required this.isComet,
    required this.isLandscapeTablet,
  });

  final int kidStep;
  final int chipStep;
  final bool isNitro;
  final bool isComet;
  final bool isLandscapeTablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;

      // Flight zone runs from above dashboard up to Saturn near top.
      final saturnX = w * 0.50;
      final saturnY = isLandscapeTablet ? h * 0.14 : h * 0.12;
      final startY = isLandscapeTablet ? h * 0.64 : h * 0.54;
      final startX = w * 0.50;

      Offset pointAt(int step, {bool isKid = true}) {
        final t = step / 10.0;
        final py = startY - (startY - saturnY) * math.pow(t, 0.82);
        final wave = math.sin(t * math.pi * 1.2) * (w * 0.18);
        final cx = startX + wave + (saturnX - startX) * t;
        final laneOffset = (isKid ? -1.0 : 1.0) * (w * 0.12 * (1.0 - t * 0.40));
        return Offset(cx + laneOffset, py);
      }

      double angleAt(int step, {required bool isKid}) {
        final t0 = math.max(0.0, (step - 0.4) / 10.0);
        final t1 = math.min(1.0, (step + 0.4) / 10.0);
        final p0 = pointAt((t0 * 10).round(), isKid: isKid);
        final p1 = pointAt((t1 * 10).round(), isKid: isKid);
        final dx = p1.dx - p0.dx;
        final dy = p1.dy - p0.dy;
        return math.atan2(dx, -dy);
      }

      final kidPos = pointAt(kidStep, isKid: true);
      final chipPos = pointAt(chipStep, isKid: false);
      final kidAngle = angleAt(kidStep, isKid: true);
      final chipAngle = angleAt(chipStep, isKid: false);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Warm Twilight Space Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameColors.skyTop,
                  GameColors.skyUpper,
                  GameColors.skyLower,
                  GameColors.skyHorizon,
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),

          // 2. Soft Glowing Cosmic Nebula Clouds (Mây vũ trụ đất sét)
          Positioned(
            top: h * 0.08,
            left: w * 0.05,
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF69B4).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.24,
            right: w * 0.05,
            child: Container(
              width: 220,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Stars and 10 Star Checkpoints
          CustomPaint(
            size: Size(w, h),
            painter: _StarPathPainter(
              kidStep: kidStep,
              chipStep: chipStep,
              pointAt: pointAt,
            ),
          ),

          // 4. Saturn Destination Planet with Ring
          Positioned(
            left: saturnX - 48,
            top: saturnY - 48,
            width: 96,
            height: 96,
            child: Image.asset(AppImages.planet, fit: BoxFit.contain),
          ),

          // 5. Comet passing by (if comet question)
          if (isComet)
            Positioned(
              left: w * 0.30,
              top: h * 0.20,
              width: 76,
              height: 76,
              child: Image.asset(AppImages.comet, fit: BoxFit.contain),
            ),

          // 6. Kid's Rocket with Avatar & Trajectory Banking Angle
          Positioned(
            left: kidPos.dx - 32,
            top: kidPos.dy - 57,
            width: 64,
            height: 160,
            child: Transform.rotate(
              angle: kidAngle,
              alignment: const Alignment(0, -0.28),
              child: _KidRocketView(isNitro: isNitro),
            ),
          ),

          // 7. Chíp's Rocket (Pilot Chíp) & Trajectory Banking Angle
          Positioned(
            left: chipPos.dx - 32,
            top: chipPos.dy - 50,
            width: 64,
            height: 140,
            child: Transform.rotate(
              angle: chipAngle,
              alignment: const Alignment(0, -0.28),
              child: _ChipRocketView(
                isBehind: chipStep < kidStep,
                reactionText: chipStep < kidStep
                    ? 'Nhanh quá!'
                    : (chipStep > kidStep ? 'Theo tớ nào!' : null),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _StarPathPainter extends CustomPainter {
  _StarPathPainter({
    required this.kidStep,
    required this.chipStep,
    required this.pointAt,
  });

  final int kidStep;
  final int chipStep;
  final Offset Function(int step, {bool isKid}) pointAt;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw star path lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final kidPath = Path();
    final chipPath = Path();

    for (var s = 0; s <= 10; s++) {
      final kp = pointAt(s, isKid: true);
      final cp = pointAt(s, isKid: false);
      if (s == 0) {
        kidPath.moveTo(kp.dx, kp.dy);
        chipPath.moveTo(cp.dx, cp.dy);
      } else {
        kidPath.lineTo(kp.dx, kp.dy);
        chipPath.lineTo(cp.dx, cp.dy);
      }
    }
    canvas.drawPath(kidPath, linePaint);
    canvas.drawPath(chipPath, linePaint);

    // Draw 10 steps (stepping stones with 3D clay depth)
    for (var s = 1; s <= 10; s++) {
      final kp = pointAt(s, isKid: true);
      final cp = pointAt(s, isKid: false);

      // Kid lane stepping stone
      _drawStone(canvas, kp, s <= kidStep, s == 4 || s == 8);
      // Chip lane stepping stone
      _drawStone(canvas, cp, s <= chipStep, s == 4 || s == 8);
    }
  }

  void _drawStone(Canvas canvas, Offset p, bool lit, bool isLucky) {
    final r = isLucky ? 8.5 : 6.5;

    // Drop shadow
    canvas.drawCircle(p + const Offset(0, 1.5), r, Paint()..color = const Color(0x33000000));

    if (lit) {
      // Warm glow
      canvas.drawCircle(
        p,
        r + 4,
        Paint()..color = (isLucky ? const Color(0xFFFF9100) : const Color(0xFFFFD54F)).withOpacity(0.4),
      );
    }

    final fill = Paint()
      ..color = lit
          ? (isLucky ? const Color(0xFFFFB300) : const Color(0xFFFFEE58))
          : Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p, r, fill);

    // Top glossy highlight for 3D clay look
    if (lit) {
      canvas.drawCircle(
        p - const Offset(1.5, 1.5),
        r * 0.4,
        Paint()..color = Colors.white.withOpacity(0.85),
      );
    }

    if (isLucky) {
      canvas.drawCircle(
        p,
        r + 1.2,
        Paint()
          ..color = const Color(0xFFFF6F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.isNitro});

  final bool isNitro;

  @override
  void paint(Canvas canvas, Size size) {
    FlameRenderer.paint(
      canvas,
      nozzle: Offset(size.width / 2, 0),
      width: isNitro ? 22 : 15,
      length: isNitro ? 46 : 24,
      time: 0.5,
      intensity: isNitro ? 1.7 : 1.0,
      palette: isNitro ? FlamePalette.blue : FlamePalette.classic,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpeedStreaksPainter extends CustomPainter {
  const _SpeedStreaksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cyanPaint = Paint()
      ..color = const Color(0xAA00E5FF)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final whitePaint = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // 4 fine streaks trailing behind
    canvas.drawLine(const Offset(6, 45), const Offset(-8, 95), cyanPaint);
    canvas.drawLine(const Offset(58, 45), const Offset(72, 95), cyanPaint);
    canvas.drawLine(const Offset(18, 55), const Offset(10, 100), whitePaint);
    canvas.drawLine(const Offset(46, 55), const Offset(54, 100), whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KidRocketView extends StatelessWidget {
  const _KidRocketView({required this.isNitro});

  final bool isNitro;

  @override
  Widget build(BuildContext context) {
    const rocketW = 64.0;
    const rocketH = 114.0;
    const nozzleY = 91.0;

    return SizedBox(
      width: rocketW,
      height: rocketH + (isNitro ? 60 : 30),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Speed streaks trailing behind when Nitro
          if (isNitro)
            const Positioned(
              top: 50,
              child: CustomPaint(
                size: Size(rocketW, 100),
                painter: _SpeedStreaksPainter(),
              ),
            ),

          // 2. Multi-layer rocket flame
          Positioned(
            top: nozzleY,
            child: CustomPaint(
              size: Size(isNitro ? 44 : 28, isNitro ? 65 : 35),
              painter: _FlamePainter(isNitro: isNitro),
            ),
          ),

          // 3. Rocket Body
          SizedBox(
            width: rocketW,
            height: rocketH,
            child: Image.asset(AppImages.rocketOrange, fit: BoxFit.contain),
          ),

          // 4. Kid Avatar in the circular porthole window
          Positioned(
            top: 51.5,
            left: 24.5,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4E6F1), width: 1.2),
                image: DecorationImage(
                  image: AssetImage(kidAvatars[0]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipRocketView extends StatelessWidget {
  const _ChipRocketView({
    required this.isBehind,
    this.reactionText,
  });

  final bool isBehind;
  final String? reactionText;

  @override
  Widget build(BuildContext context) {
    const rocketW = 64.0;
    const rocketH = 99.0;
    const nozzleY = 81.0;

    return SizedBox(
      width: rocketW,
      height: rocketH + 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Engine Flame (Classic)
          Positioned(
            top: nozzleY,
            child: CustomPaint(
              size: const Size(26, 32),
              painter: _FlamePainter(isNitro: false),
            ),
          ),

          // 2. Rocket Body (Chíp is already sculpted inside)
          SizedBox(
            width: rocketW,
            height: rocketH,
            child: Image.asset(AppImages.rocketChip, fit: BoxFit.contain),
          ),

          // 3. Chíp Speech / Reaction Bubble
          if (reactionText != null)
            Positioned(
              top: -16,
              left: rocketW - 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      isBehind ? AppImages.chipSurprise : AppImages.chipJoy,
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reactionText!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
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

// -----------------------------------------------------------------------------
// TOY COCKPIT DASHBOARD (BẢNG ĐIỀU KHIỂN PHI THUYỀN ĐỒ CHƠI)
// -----------------------------------------------------------------------------
class _ToyCockpitDashboard extends StatelessWidget {
  const _ToyCockpitDashboard({
    required this.questionNumber,
    required this.isComet,
    required this.isNitro,
    required this.isLandscapeTablet,
  });

  final int questionNumber;
  final bool isComet;
  final bool isNitro;
  final bool isLandscapeTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9EE), // Warm ivory toy plastic
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          // Specular top highlight (clay rim)
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.95), width: 3.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscapeTablet ? 48 : 20,
              vertical: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top dashboard row: Cockpit Instrument Gauges & Co-pilot Chíp!
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Toy Energy/Speed Gauge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNitro ? Icons.bolt_rounded : Icons.speed_rounded,
                            size: 18,
                            color: const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isNitro ? 'BỨT TỐC x2!' : 'NĂNG LƯỢNG',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Co-pilot Chíp peering from the cockpit!
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.accent, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            isNitro
                                ? 'Vùuu! Nhanh quá!'
                                : (isComet ? 'Sao chổi kìa bé!' : 'Nhấn nút nào bé ơi!'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFEDD5),
                            border: Border.all(color: AppColors.accent, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              isNitro ? AppImages.chipSurprise : AppImages.chipJoy,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Center: Molded Inset Monitor with Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isComet ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                      width: isComet ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isComet ? const Color(0x33F59E0B) : const Color(0x14000000),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isComet) ...[
                        Image.asset(AppImages.comet, width: 34, height: 34, fit: BoxFit.contain),
                        const SizedBox(width: 10),
                      ],
                      const Text(
                        '3 + 2 = ?',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom: 3 Chunky 3D Arcade Candy Buttons
                Row(
                  children: const [
                    Expanded(
                      child: _ToyArcadeButton(
                        label: '4',
                        topColor: Color(0xFFFF8A65),
                        lipColor: Color(0xFFE64A19),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ToyArcadeButton(
                        label: '5',
                        topColor: Color(0xFFFFB703),
                        lipColor: Color(0xFFE08700),
                        isHighlighted: true,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ToyArcadeButton(
                        label: '6',
                        topColor: Color(0xFF38BDF8),
                        lipColor: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToyArcadeButton extends StatelessWidget {
  const _ToyArcadeButton({
    required this.label,
    required this.topColor,
    required this.lipColor,
    this.isHighlighted = false,
  });

  final String label;
  final Color topColor;
  final Color lipColor;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: topColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFFFFFF) : Colors.white.withOpacity(0.4),
          width: isHighlighted ? 2.5 : 1.5,
        ),
        boxShadow: [
          // 3D tactile bottom lip
          BoxShadow(
            color: lipColor,
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
          // Soft ambient drop shadow
          BoxShadow(
            color: lipColor.withOpacity(0.35),
            offset: const Offset(0, 7),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top specular highlight pill
          Positioned(
            top: 4,
            child: Container(
              width: 44,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MOCK RESULT SCREEN (MÀN KẾT QUẢ THẮNG ĐỒNG BỘ CHẤT LIỆU)
// -----------------------------------------------------------------------------
class _MockResultScreen extends StatelessWidget {
  const _MockResultScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.skyTop,
            GameColors.skyUpper,
            GameColors.skyLower,
            AppColors.background,
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Cheering Chíp Mascot
              Image.asset(AppImages.chipJoy, width: 140, height: 140, fit: BoxFit.contain),
              const SizedBox(height: 8),
              const Text(
                'Bé về đích trước!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kỷ lục mới! Nhanh hơn 3 giây',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 24),

              // Unified Reward Card (Thẻ phần thưởng gộp chung một hàng, không emoji tofu)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: raisedDecoration(radius: AppRadii.card),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppImages.icStar, width: 34, height: 34, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    const Text(
                      '+9',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(width: 1.5, height: 28, color: AppColors.textMuted.withOpacity(0.25)),
                    const SizedBox(width: 20),
                    Image.asset(AppImages.icStar, width: 26, height: 26, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    const Text(
                      '+2 Sao May Mắn!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Next Gift Silhouette (Bóng đen bí mật, thay vì ảnh mờ)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: raisedDecoration(radius: AppRadii.card),
                child: Row(
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(Color(0xFF2A164D), BlendMode.srcIn),
                      child: Image.asset(AppImages.rocketBlue, width: 56, height: 56, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quà bí mật tiếp theo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.text),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Còn 3 sao vũ trụ để mở khóa',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Text('?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.accent)),
                  ],
                ),
              ),
              const Spacer(),

              // Primary Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 64,
                      decoration: raisedDecoration(radius: AppRadii.pill),
                      child: const Center(
                        child: Text(
                          'Về Góc Chơi',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.text),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 64,
                      decoration: raisedDecoration(radius: AppRadii.pill, accent: AppColors.accent, tint: AppColors.accent),
                      child: const Center(
                        child: Text(
                          'Đua tiếp!',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
