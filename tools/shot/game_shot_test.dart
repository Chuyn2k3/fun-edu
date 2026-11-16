// Render harness for the rocket race screens (race, win, lose, offer,
// badge). Lives in tools/shot/ so `flutter test` skips it. Usage:
//   mkdir -p test/_shot && cp tools/shot/game_shot_test.dart test/_shot/
//   W=390 H=844 SHOT_OUT=/tmp/game FLUTTER_ROOT=$HOME/flutter324 \
//     flutter test test/_shot/game_shot_test.dart
//   rm -rf test/_shot
// Writes $SHOT_OUT-<name>.png for: toan, comet, flyby, tv, cutscene, badge,
// offer, win, lose. Env ONLY=<name,...> limits the scenarios.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/voice/speaker.dart';

double _env(String k, String d) => double.parse(Platform.environment[k] ?? d);
final _out = Platform.environment['SHOT_OUT'] ?? '/tmp/game';
final _only = Platform.environment['ONLY']?.split(',');

Future<void> _fonts() async {
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
  late WidgetTester t;
  Future<void> real([int n = 4]) async {
    for (var i = 0; i < n; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> frames(int n) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> snap(String name) async {
    for (final e in find.byType(Image).evaluate()) {
      final img = e.widget as Image;
      await t.runAsync(() => precacheImage(img.image, e));
    }
    await frames(2);
    await t.runAsync(() async {
      final view = t.binding.renderViews.first;
      final layer = view.debugLayer! as OffsetLayer;
      final im = await layer.toImage(Offset.zero & (view.size * 2), pixelRatio: 1);
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      File('$_out-$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  RaceState st() => ProviderScope.containerOf(
          t.element(find.byType(RaceScreen)))
      .read(raceControllerProvider);

  Future<void> right({int thinkMs = 900}) async {
    await t.pump(Duration(milliseconds: thinkMs));
    final i = st().current!.correctIndex;
    await t.tap(find.byKey(ValueKey('race-key-$i')));
    await frames(30);
  }

  Future<void> boot({int stars = 0}) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    appRouter.go('/');
    await t.runAsync(() async {
      final kids = KidRepository(db);
      final kid =
          await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
      final l = LevelRepository(db, kidId: kid);
      await l.setLevel('viet', 6);
      await l.setLevel('toan', 6);
      if (stars > 0) {
        await db.into(db.gameProfile).insert(GameProfileCompanion.insert(
            kidId: Value(kid), cosmicStars: Value(stars)));
      }
    });
    await t.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        speakerProvider.overrideWithValue(const SilentSpeaker()),
        voiceEnabledProvider.overrideWith((ref) async => false),
        raceRandomProvider.overrideWith((ref) => Random(3)),
      ],
      child: const App(),
    ));
    await real(8);
  }

  Future<void> open(String s) async {
    appRouter.go('/game/race/$s');
    await real(10);
    await frames(60);
  }

  bool want(String n) => _only == null || _only!.contains(n);

  testWidgets('game shots', (tester) async {
    t = tester;
    await t.runAsync(_fonts);
    t.view.physicalSize = Size(_env('W', '390') * 2, _env('H', '844') * 2);
    t.view.devicePixelRatio = 2;

    if (want('toan') || want('comet') || want('flyby')) {
      await boot();
      await open('toan');
      await right();
      if (want('toan')) await snap('toan');
      await right();
      await frames(20);
      if (want('comet')) await snap('comet');
      await right();
      await frames(4);
      if (want('flyby')) await snap('flyby');
      await t.pumpWidget(const SizedBox());
      await frames(5);
    }
    if (want('tv')) {
      await boot();
      await open('tieng-viet');
      await right();
      await snap('tv');
      await t.pumpWidget(const SizedBox());
      await frames(5);
    }
    if (want('cutscene') || want('badge') || want('offer') || want('win')) {
      await boot(stars: 24);
      await open('toan');
      while (find.byType(RaceScreen).evaluate().isNotEmpty &&
          st().phase == RacePhase.racing) {
        await right(thinkMs: 600);
      }
      await real(6);
      await t.pump(const Duration(milliseconds: 1500));
      await real(6);
      for (var i = 0; i < 140; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      if (want('cutscene')) await snap('cutscene');
      await t.pump(const Duration(seconds: 1));
      await real(6);
      await frames(60);
      if (want('badge')) await snap('badge');
      await t.tap(find.text('Tuyệt quá!'));
      await real(8);
      await frames(30);
      if (want('offer')) await snap('offer');
      for (var k = 0; k < 2; k++) {
        final f = find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('offer-'));
        if (f.evaluate().isEmpty) break;
        await t.tap(f.first);
        await real(8);
        await frames(30);
      }
      await real(6);
      if (want('win')) await snap('win');
      await t.pumpWidget(const SizedBox());
      await frames(5);
    }
    if (want('lose')) {
      await boot();
      await open('toan');
      await t.pump(const Duration(seconds: 2));
      final r = st().current!.correctIndex;
      await t.tap(find.byKey(ValueKey('race-key-${(r + 1) % 3}')));
      await frames(10);
      while (st().kidSteps < 8) {
        await right(thinkMs: 400);
      }
      for (var i = 0; i < 80 && find.byType(RaceScreen).evaluate().isNotEmpty; i++) {
        await t.pump(const Duration(milliseconds: 500));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      }
      await real(8);
      await t.pump(const Duration(seconds: 2));
      await real(6);
      await frames(30);
      await snap('lose');
      await t.pumpWidget(const SizedBox());
      await frames(5);
    }
    await t.pump(const Duration(seconds: 5));
  });
}
