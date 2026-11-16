// Frame-cost bench for the rocket race scene under flutter_tester. Not a
// device measurement: it runs the debug JIT on the CPU, so absolute numbers
// are pessimistic and raster (GPU) time is only approximated by a CPU
// rasterisation of the whole scene. Use `flutter run --profile` on a real
// phone/iPad for the verdict (docs/perf.md). Usage:
//   mkdir -p test/_shot && cp tools/shot/race_bench_test.dart test/_shot/
//   W=390 H=480 flutter test test/_shot/race_bench_test.dart
//   rm -rf test/_shot
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/race_scene.dart';

double _env(String k, String d) => double.parse(Platform.environment[k] ?? d);

String _stats(List<int> us) {
  us.sort();
  double p(double q) => us[((us.length - 1) * q).round()] / 1000;
  final avg = us.reduce((a, b) => a + b) / us.length / 1000;
  return 'n=${us.length} avg=${avg.toStringAsFixed(2)}ms '
      'p50=${p(0.5).toStringAsFixed(2)} p90=${p(0.9).toStringAsFixed(2)} '
      'p99=${p(0.99).toStringAsFixed(2)} max=${p(1).toStringAsFixed(2)}';
}

void main() {
  testWidgets('race scene frame cost', (tester) async {
    final size = Size(_env('W', '390'), _env('H', '480'));
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    final key = GlobalKey();
    Widget app(int kid, int chip, bool boost) => RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RaceScene(
              kidSteps: kid,
              chipSteps: chip,
              kidRocket: 'rocket_orange',
              kidTrail: 'trail_sparkle',
              boosting: boost,
              won: false,
            ),
          ),
        );
    await tester.pumpWidget(app(0, 0, false));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Warm up the JIT.
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    // 10 s of play: a step every second, a comet every third.
    final frame = <int>[];
    final sw = Stopwatch();
    var kid = 0, chip = 0;
    for (var i = 0; i < 600; i++) {
      if (i % 60 == 0) {
        kid = (kid + 1).clamp(0, 10);
        if (i % 120 == 0) chip = (chip + 1).clamp(0, 10);
        await tester.pumpWidget(app(kid, chip, i % 180 == 0));
      }
      sw
        ..reset()
        ..start();
      await tester.pump(const Duration(microseconds: 16667));
      sw.stop();
      frame.add(sw.elapsedMicroseconds);
    }
    // ignore: avoid_print
    print('UI frame (tick+build+layout+paint record, debug JIT): '
        '${_stats(frame)}');

    // CPU rasterisation of the full scene at 3x (Skia software).
    final raster = <int>[];
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(microseconds: 16667));
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final s = Stopwatch()..start();
        final im = await b.toImage(pixelRatio: 3);
        await im.toByteData(format: ui.ImageByteFormat.rawRgba);
        s.stop();
        raster.add(s.elapsedMicroseconds);
        im.dispose();
      });
    }
    // ignore: avoid_print
    print('CPU raster of whole scene at 3x (software, incl. readback): '
        '${_stats(raster)}');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
