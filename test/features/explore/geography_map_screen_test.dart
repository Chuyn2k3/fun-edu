import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/explore/geography_generator.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/features/explore/geography_session_screen.dart';
import 'package:funedu/features/subject/geography_map_screen.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/voice/speaker.dart';
import 'package:go_router/go_router.dart';

class _QuietSpeaker implements MultilingualSpeaker {
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> speakWithLanguage(String text, String language) async {}
  @override
  Future<void> stop() async {}
}

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1.0;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
}

void main() {
  late AppDatabase db;
  late int kid;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    kid = await KidRepository(db).addKid(nickname: 'Na', avatar: 'a', age: 5);
  });
  tearDown(() => db.close());

  Future<void> pumpAt(WidgetTester t, String location) async {
    final router = GoRouter(initialLocation: location, routes: [
      GoRoute(path: '/kham-pha', builder: (_, __) => const Text('sảnh')),
      GoRoute(
          path: '/subject/dia-ly',
          builder: (_, __) => const GeographyMapScreen()),
      GoRoute(
        path: '/practice-dia-ly/:i',
        builder: (_, s) => PracticeGeographyScreen(
          int.tryParse(s.pathParameters['i']!) ?? -1,
          random: Random(5),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await t.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        speakerProvider.overrideWithValue(_QuietSpeaker()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();
  }

  Future<void> answerAll(WidgetTester t, int level) async {
    final qs = generateGeographyQuestions(geographyLevels[level], Random(5));
    for (final q in qs) {
      final f = find.byKey(ValueKey('geo-choice-${q.correctIndex}'));
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pump(geographyAnswerPause('${q.answer.speech}. ${q.answer.fact}') +
          const Duration(milliseconds: 300));
    }
    await t.pumpAndSettle();
  }

  testWidgets('map marks done, current and locked levels', (t) async {
    _setSize(t, 390, 844);
    await LevelRepository(db, kidId: kid).setLevel('dia-ly', 2);
    await pumpAt(t, '/subject/dia-ly');
    expect(find.text('Khám phá Việt Nam'), findsOneWidget);
    expect(find.byKey(const ValueKey('geo-done-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('geo-done-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('geo-done-2')), findsNothing);
    await t.scrollUntilVisible(find.byKey(const ValueKey('geo-locked-3')), 100);
    expect(find.byKey(const ValueKey('geo-locked-3')), findsOneWidget);
  });

  testWidgets('a stored level past the ladder shows the last level as current',
      (t) async {
    _setSize(t, 390, 844);
    await LevelRepository(db, kidId: kid).setLevel('dia-ly', 12);
    await pumpAt(t, '/subject/dia-ly');
    await t.scrollUntilVisible(find.byKey(const ValueKey('geo-done-7')), 100);
    expect(find.byKey(const ValueKey('geo-done-8')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('map fits a small phone at text x2.0', (t) async {
    _setSize(t, 375, 667);
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpAt(t, '/subject/dia-ly');
    expect(t.takeException(), isNull);
  });

  for (final size in const [Size(390, 844), Size(1180, 820)]) {
    testWidgets('map renders all 9 levels at $size', (t) async {
      _setSize(t, size.width, size.height);
      await pumpAt(t, '/subject/dia-ly');
      expect(find.text('Cảnh vật quanh em'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('finishing the current level 5/5 moves the kid up', (t) async {
    _setSize(t, 390, 844);
    await LevelRepository(db, kidId: kid).setLevel('dia-ly', 2);
    await pumpAt(t, '/practice-dia-ly/2');
    await answerAll(t, 2);
    expect(await LevelRepository(db, kidId: kid).levelOf('dia-ly'), 3);
    expect(find.text('Khám phá Việt Nam'), findsOneWidget);
  });

  testWidgets('replaying a past level does not change the level', (t) async {
    _setSize(t, 390, 844);
    await LevelRepository(db, kidId: kid).setLevel('dia-ly', 2);
    await pumpAt(t, '/practice-dia-ly/0');
    await answerAll(t, 0);
    expect(await LevelRepository(db, kidId: kid).levelOf('dia-ly'), 2);
  });

  testWidgets('an unknown level shows a message', (t) async {
    _setSize(t, 390, 844);
    await pumpAt(t, '/practice-dia-ly/99');
    expect(find.text('Chưa có cấp này'), findsOneWidget);
  });
}
