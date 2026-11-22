import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/collection/collection_model.dart';
import 'package:funedu/collection/collection_provider.dart';
import 'package:funedu/features/collection/collection_screen.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/features/house/house_screen.dart';
import 'package:funedu/house/house_model.dart';
import 'package:funedu/house/house_repository.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/voice/speaker.dart';

import '../voice/fake_speaker.dart';

void main() {
  testWidgets('HomeScreen never shows CircularProgressIndicator while loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<HomeSummary>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kidsProvider.overrideWith((ref) => const []),
          currentKidIdProvider.overrideWith((ref) => null),
          homeSummaryProvider.overrideWith((ref) => completer.future),
          todayLessonProvider.overrideWith((ref) => const []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    // Verify: No spinner!
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
      'CollectionScreen never shows CircularProgressIndicator while loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<LearningSnapshot>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionSnapshotProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: CollectionScreen()),
      ),
    );
    await tester.pump();

    // Verify: No spinner!
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CollectionScreen), findsOneWidget);
  });

  testWidgets(
      'HouseScreen never shows CircularProgressIndicator while loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<ChipHouseData>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chipHouseDataProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: HouseScreen()),
      ),
    );
    await tester.pump();

    // Verify: No spinner!
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(HouseScreen), findsOneWidget);
  });

  testWidgets('HouseScreen ignores feeding until the house data has loaded',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final speaker = FakeSpeaker();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chipHouseDataProvider
              .overrideWith((ref) => Completer<ChipHouseData>().future),
          speakerProvider.overrideWithValue(speaker),
        ],
        child: const MaterialApp(home: HouseScreen()),
      ),
    );
    await tester.pump();

    final treat = find.byKey(ValueKey('house-treat-${houseTreats.first.id}'));
    await tester.ensureVisible(treat);
    await tester.tap(treat);
    await tester.pump();

    // No "not enough stars" line and no feeding effect from placeholder data.
    expect(speaker.spoken, isEmpty);
  });

  testWidgets('HomeScreen keeps numbers hidden until they load', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<HomeSummary>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kidsProvider.overrideWith((ref) => const []),
          currentKidIdProvider.overrideWith((ref) => null),
          homeSummaryProvider.overrideWith((ref) => completer.future),
          todayLessonProvider.overrideWith((ref) => const []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    Visibility around(String text) => tester.widget<Visibility>(find
        .ancestor(of: find.textContaining(text), matching: find.byType(Visibility))
        .first);
    expect(around('ngày học tuần này').visible, isFalse);

    completer.complete(const HomeSummary(
        totalStars: 12, learnedDaysThisWeek: 3, masteredWriting: 0));
    await tester.pump();
    await tester.pump();
    expect(find.text('3 ngày học tuần này'), findsOneWidget);
    expect(around('ngày học tuần này').visible, isTrue);
    expect(around('12').visible, isTrue);
  });

  testWidgets('CollectionScreen fades its counts in once loaded', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<LearningSnapshot>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionSnapshotProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: CollectionScreen()),
      ),
    );
    await tester.pump();
    double opacity() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity;
    expect(opacity(), 0);

    final now = DateTime.now();
    completer.complete(LearningSnapshot(
      kidName: 'Na',
      totalStars: 5,
      totalLessons: 1,
      totalLearnedDays: 1,
      learnedDaysThisWeek: 1,
      masteredWriting: 0,
      mathLevelIndex: 0,
      vietnameseLevelIndex: 0,
      englishLevelIndex: 0,
      viewedYear: now.year,
      viewedMonth: now.month,
      learnedDaysInMonth: const {},
      learnedToday: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(), 1);
  });
}

