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
}
