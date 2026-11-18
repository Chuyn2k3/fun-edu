import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/subject/vietnamese_map_screen.dart';
import 'package:funedu/features/vietnamese/vietnamese_session_screen.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/vietnamese/vietnamese_generator.dart';
import 'package:funedu/vietnamese/vietnamese_level.dart';
import 'package:funedu/voice/speaker.dart';

class _SpySpeaker implements Speaker {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async => spoken.add(text);
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
  testWidgets('VietnameseSessionScreen handles wrong retry and finishes 5 questions',
      (t) async {
    _setSize(t, 390, 844);
    final speaker = _SpySpeaker();
    final level = vietnameseLevels[3]; // Ghép tiếng (equationBuild)
    final expected = generateVietnameseQuestions(level, Random(7), count: 5);
    int? gotFirstTry;
    int? gotTotal;

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          speakerProvider.overrideWithValue(speaker),
          homeSummaryProvider.overrideWith(
            (_) async => const HomeSummary(
              totalStars: 12,
              learnedDaysThisWeek: 2,
              masteredWriting: 4,
            ),
          ),
        ],
        child: MaterialApp(
          home: VietnameseSessionScreen(
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

    // First question spoken automatically.
    expect(speaker.spoken.length, 1);

    // Wrong pick on Q1 -> Chíp encourages retry, replays speech.
    final wrongIdx = (expected[0].correctIndex + 1) % 3;
    await t.ensureVisible(find.byKey(ValueKey('vn-choice-$wrongIdx')));
    await t.tap(find.byKey(ValueKey('vn-choice-$wrongIdx')));
    await t.pump();
    expect(find.textContaining('Thử lại nhé!'), findsOneWidget);

    // Now answer all 5 correctly.
    for (var i = 0; i < 5; i++) {
      final correctIdx = expected[i].correctIndex;
      await t.ensureVisible(find.byKey(ValueKey('vn-choice-$correctIdx')));
      await t.tap(find.byKey(ValueKey('vn-choice-$correctIdx')));
      await t.pump(i == 4
          ? const Duration(milliseconds: 1300)
          : const Duration(milliseconds: 1000));
    }

    expect(gotTotal, 5);
    expect(gotFirstTry, 4); // Missed Q1 once, got Q2..Q5 first try.
  });

  for (final levelIndex in [0, 3, 8]) {
    for (final size in const [Size(390, 844), Size(1024, 768)]) {
      testWidgets(
          'VietnameseSessionScreen level $levelIndex renders cleanly at $size',
          (t) async {
        _setSize(t, size.width, size.height);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              speakerProvider.overrideWithValue(_SpySpeaker()),
              homeSummaryProvider.overrideWith(
                (_) async => const HomeSummary(
                  totalStars: 5,
                  learnedDaysThisWeek: 1,
                  masteredWriting: 2,
                ),
              ),
            ],
            child: MaterialApp(
              home: VietnameseSessionScreen(
                level: vietnameseLevels[levelIndex],
                random: Random(1),
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
    testWidgets('VietnameseMapScreen renders all 9 levels at $size', (t) async {
      _setSize(t, size.width, size.height);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            vietnameseLevelIndexProvider.overrideWith((_) async => 2),
          ],
          child: const MaterialApp(home: VietnameseMapScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('Nguyên âm'), findsOneWidget);
      expect(find.text('Dấu thanh'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  test('LevelRepository.recordVietnameseSession updates tieng-viet independently',
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

    final next = await repo.recordVietnameseSession(
      firstTryCorrect: 5,
      total: 5,
    );
    expect(next, 1);
    expect(await repo.levelOf('tieng-viet'), 1);
    expect(await repo.levelOf('toan'), 2);
  });
}
