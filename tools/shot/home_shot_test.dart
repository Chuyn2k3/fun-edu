// Reusable render harness: draws one screen to a PNG with flutter_tester.
// It lives in tools/shot/ (not test/) so a plain `flutter test` skips it.
// Usage: see docs/perf.md section "screenshots". To shoot another screen,
// edit the overrides and `home:` below.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:funedu/ui/theme/app_theme.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/learning/lesson_item.dart';
import 'package:funedu/learning/today_lesson_provider.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Nunito');
  for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
  }
  await loader.load();
  final m = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await m.load();
}

double _env(String k, String d) => double.parse(Platform.environment[k] ?? d);

void main() {
  testWidgets('shot', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = Size(_env('W', '390') * 2, _env('H', '844') * 2);
    tester.view.devicePixelRatio = 2;
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: ProviderScope(
        overrides: [
          homeSummaryProvider.overrideWith((ref) async => const HomeSummary(totalStars: 12, learnedDaysThisWeek: 3, masteredWriting: 2)),
          kidsProvider.overrideWith((ref) async => [KidProfile(id: 1, nickname: 'Na', avatar: kidAvatars[0], age: 5, createdAt: DateTime(2026))]),
          currentKidIdProvider.overrideWith((ref) async => 1),
          voiceEnabledProvider.overrideWith((ref) async => false),
          todayLessonProvider.overrideWith((ref) async => const [WritingItem('net-xien'), MathItem(0), WritingItem('net-cong')]),
          glyphProvider.overrideWith((ref, id) async => Glyph(id: id, label: 'Nét xiên', strokes: const [])),
        ],
        child: MaterialApp(theme: buildAppTheme(), debugShowCheckedModeBanner: false, home: const HomeScreen()),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
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
      File(Platform.environment['SHOT_OUT'] ?? '/tmp/shot.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
