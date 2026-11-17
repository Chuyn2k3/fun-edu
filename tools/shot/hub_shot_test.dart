// Render harness for the Góc Chơi screens (hub, garage, badge cabinet,
// sticker album). Lives in tools/shot/ so `flutter test` skips it. Usage:
//   mkdir -p test/_shot && cp tools/shot/hub_shot_test.dart test/_shot/
//   W=390 H=844 SHOT_OUT=/tmp/hub FLUTTER_ROOT=$HOME/flutter324 \
//     flutter test test/_shot/hub_shot_test.dart
//   rm -rf test/_shot
// Writes $SHOT_OUT-<name>.png for: hub, hub-end (scrolled to the bottom),
// garage, garage-fly (mid "Bay thử!"), garage-trails, badges, stickers.
// Env ONLY=<name,...> limits the scenarios.
import 'dart:io';
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
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/voice/speaker.dart';

double _env(String k, String d) => double.parse(Platform.environment[k] ?? d);
final _out = Platform.environment['SHOT_OUT'] ?? '/tmp/hub';
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
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
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
      final im =
          await layer.toImage(Offset.zero & (view.size * 2), pixelRatio: 1);
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      File('$_out-$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> boot() async {
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
      await db.into(db.gameProfile).insert(GameProfileCompanion.insert(
          kidId: Value(kid),
          cosmicStars: const Value(64),
          selectedRocket: const Value('rocket_blue')));
      for (final id in [
        'rocket_blue',
        'trail_rainbow',
        'sticker_clap',
        'rocket_green'
      ]) {
        await db
            .into(db.gameItems)
            .insert(GameItemsCompanion.insert(kidId: kid, itemId: id));
      }
      await db.into(db.gameCounters).insert(GameCountersCompanion.insert(
          kidId: kid, key: 'seen:rocket_blue', value: const Value(1)));
      for (final (b, d) in [
        ('scholar', 12),
        ('chip_buddy', 15),
        ('pilot', 16)
      ]) {
        await db.into(db.gameBadges).insert(GameBadgesCompanion.insert(
            kidId: kid, badgeId: b, earnedAt: DateTime(2026, 11, d)));
      }
      for (final (s, won, ms, first) in [
        ('toan', true, 75000, 9),
        ('toan', true, 68000, 10),
        ('toan', false, 90000, 6),
        ('tiengViet', true, 81000, 8),
        ('tiengViet', false, 99000, 5),
      ]) {
        await db.into(db.raceResults).insert(RaceResultsCompanion.insert(
            kidId: kid,
            subject: s,
            finishedAt: DateTime(2026, 11, 16),
            won: won,
            kidTimeMs: ms,
            firstTryCorrect: first,
            cometsFirstTry: 1,
            stars: 5));
      }
    });
    await t.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        speakerProvider.overrideWithValue(const SilentSpeaker()),
        voiceEnabledProvider.overrideWith((ref) async => false),
      ],
      child: const App(),
    ));
    await real(8);
  }

  bool want(String n) => _only == null || _only!.contains(n);

  Future<void> go(String path) async {
    appRouter.go(path);
    await real(10);
    await frames(30);
  }

  testWidgets('hub shots', (tester) async {
    t = tester;
    await t.runAsync(_fonts);
    t.view.physicalSize = Size(_env('W', '390') * 2, _env('H', '844') * 2);
    t.view.devicePixelRatio = 2;

    await boot();
    if (want('hub') || want('hub-end')) {
      await go('/game');
      if (want('hub')) await snap('hub');
      final s = find.byType(Scrollable).first;
      await t.drag(s, const Offset(0, -2000));
      await real(4);
      if (want('hub-end')) await snap('hub-end');
    }
    if (want('badges')) {
      await go('/game/badges');
      await snap('badges');
    }
    if (want('stickers')) {
      await go('/game/stickers');
      await snap('stickers');
    }
    if (want('garage') || want('garage-fly') || want('garage-trails')) {
      await go('/game/garage');
      await real(6);
      await frames(90);
      if (want('garage')) await snap('garage');
      await t.tap(find.text('Bay thử!'));
      await frames(44); // ~0.7 s: rising
      if (want('garage-fly')) await snap('garage-fly');
      await frames(120);
      await t.tap(find.byKey(const ValueKey('garage-tab-trails')));
      await real(6);
      await frames(60);
      if (want('garage-trails')) await snap('garage-trails');
    }
    await t.pumpWidget(const SizedBox());
    await frames(5);
    await t.pump(const Duration(seconds: 5));
  });
}
