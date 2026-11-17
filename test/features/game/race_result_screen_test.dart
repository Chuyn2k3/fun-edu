import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_result_screen.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/engine/race.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/voice/speaker.dart';

import '../../voice/fake_speaker.dart';
import '../setup_helpers.dart';
import 'game_test_helpers.dart';

void main() {
  Widget buildScreen({
    required AppDatabase db,
    required FakeSpeaker speaker,
    required RaceResultArgs args,
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        speakerProvider.overrideWithValue(speaker),
      ],
      child: MaterialApp(
        home: RaceResultScreen(args: args),
      ),
    );
  }

  testWidgets(
      'displays bonus lucky stars badge (+N Sao May Mắn!) when luckyStarsCollected > 0',
      (t) async {
    setSize(t, 390, 844);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final kids = KidRepository(db);
    final kid =
        await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    await placeKid(db, kid);

    final speaker = FakeSpeaker();
    final args = RaceResultArgs(
      subject: RaceSubject.toan,
      outcome: const RaceOutcome(
        won: true,
        kidTime: Duration(seconds: 25),
        firstTryCorrect: 8,
        cometsFirstTry: 2,
        answered: 8,
        missed: [],
        luckyStarsCollected: 2,
      ),
      record: const RaceRecordResult(
        starsEarned: 9,
        beatRecord: false,
        previousBest: null,
        totalStars: 9,
        milestonesCrossed: [],
        newBadges: [],
      ),
      kidSteps: 10,
      rocket: 'rocket_orange',
      trail: 'trail_flame',
      luckyStarsCollected: 2,
    );

    await t.pumpWidget(buildScreen(db: db, speaker: speaker, args: args));

    if (find.byKey(const ValueKey('landing-cutscene')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const ValueKey('landing-cutscene')));
      await pumpReal(t, times: 6);
    }

    expect(find.text('+2 Sao May Mắn!'), findsOneWidget);
  });

  testWidgets(
      'does not display lucky stars badge when luckyStarsCollected is 0',
      (t) async {
    setSize(t, 390, 844);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final kids = KidRepository(db);
    final kid =
        await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    await placeKid(db, kid);

    final speaker = FakeSpeaker();
    final args = RaceResultArgs(
      subject: RaceSubject.toan,
      outcome: const RaceOutcome(
        won: true,
        kidTime: Duration(seconds: 25),
        firstTryCorrect: 8,
        cometsFirstTry: 2,
        answered: 8,
        missed: [],
        luckyStarsCollected: 0,
      ),
      record: const RaceRecordResult(
        starsEarned: 7,
        beatRecord: false,
        previousBest: null,
        totalStars: 7,
        milestonesCrossed: [],
        newBadges: [],
      ),
      kidSteps: 10,
      rocket: 'rocket_orange',
      trail: 'trail_flame',
      luckyStarsCollected: 0,
    );

    await t.pumpWidget(buildScreen(db: db, speaker: speaker, args: args));

    if (find.byKey(const ValueKey('landing-cutscene')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const ValueKey('landing-cutscene')));
      await pumpReal(t, times: 6);
    }

    expect(find.textContaining('Sao May Mắn'), findsNothing);
  });
}
