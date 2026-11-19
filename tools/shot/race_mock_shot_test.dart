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
    final scene = _StarPathScene(
      kidStep: kidStep,
      chipStep: chipStep,
      isNitro: isNitro,
      isComet: isComet,
    );

    final desk = _AnswerDesk(
      questionNumber: questionNumber,
      isComet: isComet,
      isLandscapeTablet: isLandscapeTablet,
    );

    if (isLandscapeTablet) {
      return Row(
        children: [
          Expanded(flex: 58, child: scene),
          Expanded(flex: 42, child: desk),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: 54, child: scene),
        Expanded(flex: 46, child: desk),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// STAR PATH SCENE (CẢNH ĐƯỜNG SAO VỀ HÀNH TINH)
// -----------------------------------------------------------------------------
class _StarPathScene extends StatelessWidget {
  const _StarPathScene({
    required this.kidStep,
    required this.chipStep,
    required this.isNitro,
    required this.isComet,
  });

  final int kidStep;
  final int chipStep;
  final bool isNitro;
  final bool isComet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;

      // Calculate path points for 10 steps
      // Step 0 is bottom, Step 10 is Saturn destination
      final saturnX = w * 0.50;
      final saturnY = h * 0.16;

      Offset pointAt(int step, {bool isKid = true}) {
        final t = step / 10.0;
        // Perspective curve: steps are further apart at bottom, closer near top
        final py = h * 0.90 - (h * 0.90 - saturnY) * math.pow(t, 0.78);
        // S-curve lateral shift
        final cx = w * 0.50 + math.sin(t * math.pi * 1.2) * (w * 0.12);
        // Dual lane lateral offset
        final laneOffset = (isKid ? -1.0 : 1.0) * (w * 0.11 * (1.0 - t * 0.45));
        return Offset(cx + laneOffset, py);
      }

      final kidPos = pointAt(kidStep, isKid: true);
      final chipPos = pointAt(chipStep, isKid: false);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Warm Twilight Sky
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

          // 2. Stars and Stepping stones
          CustomPaint(
            size: Size(w, h),
            painter: _StarPathPainter(
              kidStep: kidStep,
              chipStep: chipStep,
              pointAt: pointAt,
            ),
          ),

          // 3. Saturn destination planet
          Positioned(
            left: saturnX - 44,
            top: saturnY - 44,
            width: 88,
            height: 88,
            child: Image.asset(AppImages.planet, fit: BoxFit.contain),
          ),

          // 4. Comet passing by (if comet question)
          if (isComet)
            Positioned(
              left: w * 0.32,
              top: h * 0.28,
              width: 72,
              height: 72,
              child: Image.asset(AppImages.comet, fit: BoxFit.contain),
            ),

          // 5. Kid's Rocket with Avatar
          Positioned(
            left: kidPos.dx - 36,
            top: kidPos.dy - 46,
            width: 72,
            height: 92,
            child: _KidRocketView(isNitro: isNitro),
          ),

          // 6. Chíp's Rocket (Pilot Chíp)
          Positioned(
            left: chipPos.dx - 36,
            top: chipPos.dy - 46,
            width: 72,
            height: 92,
            child: _ChipRocketView(isBehind: chipStep < kidStep),
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

    // Draw 10 steps (stepping stones)
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
    final r = isLucky ? 8.0 : 6.0;
    final fill = Paint()
      ..color = lit
          ? (isLucky ? const Color(0xFFFFD54F) : const Color(0xFFFFEA79))
          : Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    if (lit) {
      // Glow ring
      canvas.drawCircle(p, r + 4, Paint()..color = const Color(0xFFFFD54F).withOpacity(0.35));
    }
    canvas.drawCircle(p, r, fill);

    if (isLucky) {
      canvas.drawCircle(p, r + 1.5, Paint()..color = const Color(0xFFFF8F00)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _KidRocketView extends StatelessWidget {
  const _KidRocketView({required this.isNitro});

  final bool isNitro;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Engine Flame
        Positioned(
          bottom: isNitro ? -30 : -16,
          child: Container(
            width: isNitro ? 24 : 16,
            height: isNitro ? 38 : 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isNitro
                    ? const [Colors.white, Color(0xFF00E5FF), Color(0xFF0091EA)]
                    : const [Colors.white, Color(0xFFFFD600), Color(0xFFFF3D00)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isNitro ? const Color(0xFF00E5FF).withOpacity(0.8) : const Color(0xFFFF9100).withOpacity(0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        // Rocket Body
        Image.asset(AppImages.rocketOrange, fit: BoxFit.contain),
        // Kid Avatar in cockpit window!
        Positioned(
          top: 18,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: AssetImage(kidAvatars[0]),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Nitro wind lines trailing behind
        if (isNitro)
          Positioned(
            bottom: -10,
            left: -8,
            child: Icon(Icons.air_rounded, color: Colors.white.withOpacity(0.8), size: 20),
          ),
      ],
    );
  }
}

class _ChipRocketView extends StatelessWidget {
  const _ChipRocketView({required this.isBehind});

  final bool isBehind;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Engine Flame
        Positioned(
          bottom: -14,
          child: Container(
            width: 14,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFFFD600), Color(0xFFFF3D00)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF9100).withOpacity(0.6), blurRadius: 8),
              ],
            ),
          ),
        ),
        // Rocket Body
        Image.asset(AppImages.rocketChip, fit: BoxFit.contain),
        // Chíp reaction bubble when behind
        if (isBehind)
          Positioned(
            top: -12,
            right: -10,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(Icons.sentiment_very_satisfied_rounded, size: 16, color: AppColors.accent),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ANSWER DESK ("BÀN HỌC" KEM CỦA APP)
// -----------------------------------------------------------------------------
class _AnswerDesk extends StatelessWidget {
  const _AnswerDesk({
    required this.questionNumber,
    required this.isComet,
    required this.isLandscapeTablet,
  });

  final int questionNumber;
  final bool isComet;
  final bool isLandscapeTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscapeTablet ? 32 : 20,
            vertical: 16,
          ),
          child: Column(
            children: [
              // Header: Pause button + "Câu N/10"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: raisedDecoration(radius: 22),
                    child: const Icon(Icons.pause_rounded, size: 26, color: AppColors.text),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: raisedDecoration(radius: AppRadii.pill),
                    child: Text(
                      'Câu $questionNumber/10',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Question Card (Thẻ câu hỏi nổi chất liệu đất sét)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: raisedDecoration(
                  radius: AppRadii.card,
                  accent: isComet ? const Color(0xFFFFB300) : AppColors.accent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isComet) ...[
                      Image.asset(AppImages.comet, width: 34, height: 34, fit: BoxFit.contain),
                      const SizedBox(width: 12),
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
              const Spacer(),

              // 3 Candy Answer Keys
              Row(
                children: [
                  Expanded(child: _CandyKey(text: '4', color: const Color(0xFFFF8A65))),
                  const SizedBox(width: 12),
                  Expanded(child: _CandyKey(text: '5', color: const Color(0xFF4DB6AC), isCorrect: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _CandyKey(text: '6', color: const Color(0xFF81C784))),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandyKey extends StatelessWidget {
  const _CandyKey({
    required this.text,
    required this.color,
    this.isCorrect = false,
  });

  final String text;
  final Color color;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.55),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
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
