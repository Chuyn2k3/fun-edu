// Render harness for the rocket race scene: three PNGs of one surge
// (t = 0, 0.5 s, 1 s after a correct comet answer). Lives in tools/shot/ so
// `flutter test` skips it. Usage (see docs/perf.md "screenshots"):
//   mkdir -p test/_shot && cp tools/shot/race_shot_test.dart test/_shot/
//   W=390 H=844 SHOT_OUT=/tmp/race FLUTTER_ROOT=$HOME/flutter324 \
//     ROCKET=rocket_orange TRAIL=trail_flame \
//     flutter test test/_shot/race_shot_test.dart
//   rm -rf test/_shot
// Writes $SHOT_OUT-0.png, -0.5.png, -1.png. Phones get the scene on top
// (480 pt) as in the mockup; landscape tablets get it on the left half.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/ui/theme/app_theme.dart';

double _env(String k, String d) => double.parse(Platform.environment[k] ?? d);
String _s(String k, String d) => Platform.environment[k] ?? d;

Widget _layout(Size size, Widget scene) {
  const panel = ColoredBox(color: Color(0xFFFFF4E4));
  if (size.shortestSide < 600) {
    return Column(children: [
      SizedBox(height: 480, child: scene),
      const Expanded(child: panel),
    ]);
  }
  if (size.width > size.height) {
    return Row(children: [
      Expanded(child: scene),
      const Expanded(child: panel),
    ]);
  }
  return Column(children: [
    Expanded(flex: 55, child: scene),
    const Expanded(flex: 45, child: panel),
  ]);
}

void main() {
  testWidgets('race shot', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('Nunito');
      for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
        loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
      }
      await loader.load();
    });
    final size = Size(_env('W', '390'), _env('H', '844'));
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    final key = GlobalKey();
    final out = _s('SHOT_OUT', '/tmp/race');

    Widget app(int kid, int chip, bool boosting) => RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: buildAppTheme(),
            debugShowCheckedModeBanner: false,
            home: Material(
              child: _layout(
                size,
                RaceScene(
                  kidSteps: kid,
                  chipSteps: chip,
                  kidRocket: _s('ROCKET', 'rocket_orange'),
                  kidTrail: _s('TRAIL', 'trail_flame'),
                  boosting: boosting,
                  won: false,
                ),
              ),
            ),
          ),
        );

    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> snap(String name) async {
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final im = await b.toImage(pixelRatio: 2);
        final data = await im.toByteData(format: ui.ImageByteFormat.png);
        File('$out-$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    final kid0 = _env('KID', '5').toInt(), chip0 = _env('CHIP', '4').toInt();
    await tester.pumpWidget(app(kid0, chip0, false));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await frames(90); // settle, fill the smoke trails
    await tester.pumpWidget(app(kid0 + 2, chip0, true)); // comet answer
    await frames(1);
    await snap('0');
    await frames(31);
    await snap('0.5');
    await frames(31);
    await snap('1');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
