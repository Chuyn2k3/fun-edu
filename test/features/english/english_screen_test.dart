import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/english/english_generator.dart';
import 'package:funedu/english/english_level.dart';
import 'package:funedu/features/english/english_session_screen.dart';
import 'package:funedu/features/subject/english_map_screen.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/voice/speaker.dart';

class _SpyMultilingualSpeaker implements MultilingualSpeaker {
  final spoken = <(String text, String lang)>[];
  @override
  Future<void> speak(String text) async => spoken.add((text, 'vi-VN'));
  @override
  Future<void> speakWithLanguage(String text, String language) async =>
      spoken.add((text, language));
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
  testWidgets(
      'EnglishSessionScreen speaks en-US, retries wrong pick, completes 5 questions',
      (t) async {
    _setSize(t, 390, 844);
    final speaker = _SpyMultilingualSpeaker();
    final level = englishLevels[3]; // Colors
    final expected = generateEnglishQuestions(level, Random(7), count: 5);
    int? gotFirstTry;
    int? gotTotal;

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          speakerProvider.overrideWithValue(speaker),
          homeSummaryProvider.overrideWith(
            (_) async => const HomeSummary(
              totalStars: 15,
              learnedDaysThisWeek: 3,
              masteredWriting: 6,
            ),
          ),
        ],
        child: MaterialApp(
          home: EnglishSessionScreen(
            level: level,
            random: Random(7),
            onCompleted: (first, total) {
              gotFirstTry = first;
              gotTotal = total;
            },
          ),
        ),
      ),
    );
    await t.pump();

    expect(speaker.spoken.length, 1);
    expect(speaker.spoken.first.$2, 'en-US');

    // Wrong pick on Q1 -> retry message.
    final wrongIdx = (expected[0].correctIndex + 1) % 3;
    await t.ensureVisible(find.byKey(ValueKey('en-choice-$wrongIdx')));
    await t.tap(find.byKey(ValueKey('en-choice-$wrongIdx')));
    await t.pump();
    expect(find.textContaining('Thử lại nhé!'), findsOneWidget);

    // Complete all 5 correctly.
    for (var i = 0; i < 5; i++) {
      final correctIdx = expected[i].correctIndex;
      await t.ensureVisible(find.byKey(ValueKey('en-choice-$correctIdx')));
      await t.tap(find.byKey(ValueKey('en-choice-$correctIdx')));
      await t.pump(i == 4
          ? const Duration(milliseconds: 1300)
          : const Duration(milliseconds: 1000));
    }

    expect(gotTotal, 5);
    expect(gotFirstTry, 4);
  });

  for (final levelIndex in [0, 2, 3, 6, 8]) {
    for (final size in const [Size(390, 844), Size(1024, 768)]) {
      testWidgets(
          'EnglishSessionScreen level $levelIndex renders cleanly at $size',
          (t) async {
        _setSize(t, size.width, size.height);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              speakerProvider.overrideWithValue(_SpyMultilingualSpeaker()),
              homeSummaryProvider.overrideWith(
                (_) async => const HomeSummary(
                  totalStars: 8,
                  learnedDaysThisWeek: 2,
                  masteredWriting: 3,
                ),
              ),
            ],
            child: MaterialApp(
              home: EnglishSessionScreen(
                level: englishLevels[levelIndex],
                random: Random(3),
                onCompleted: (_, __) {},
              ),
            ),
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull);
      });
    }
  }

  for (final size in const [Size(390, 844), Size(1024, 768)]) {
    testWidgets('EnglishMapScreen renders all 9 levels at $size', (t) async {
      _setSize(t, size.width, size.height);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            englishLevelIndexProvider.overrideWith((_) async => 3),
          ],
          child: const MaterialApp(home: EnglishMapScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Tiếng Anh'), findsOneWidget);
      expect(find.text('Chữ cái A – M'), findsOneWidget);
      expect(find.text('Màu sắc'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  test('LevelRepository.recordEnglishSession updates tieng-anh independently',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final kid = await KidRepository(db).addKid(
      nickname: 'Na',
      avatar: 'chip',
      age: 5,
    );
    final repo = LevelRepository(db, kidId: kid);
    await repo.setLevel('toan', 2);
    await repo.setLevel('tieng-viet', 3);

    final next = await repo.recordEnglishSession(
      firstTryCorrect: 5,
      total: 5,
    );
    expect(next, 1);
    expect(await repo.levelOf('tieng-anh'), 1);
    expect(await repo.levelOf('toan'), 2);
    expect(await repo.levelOf('tieng-viet'), 3);
  });
}
