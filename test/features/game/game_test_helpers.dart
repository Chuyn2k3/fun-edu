import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/race_controller.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/voice/speaker.dart';

import '../../voice/fake_speaker.dart';
import '../setup_helpers.dart';

/// One booted app with a placed kid, a fake speaker and a seeded race.
class GameHarness {
  GameHarness(this.db, this.kid, this.speaker);

  final AppDatabase db;
  final int kid;
  final FakeSpeaker speaker;
}

/// Pumps without pumpAndSettle-forever loops: lets drift answer and the
/// fake clock move by [step] a few times.
Future<void> pumpReal(WidgetTester t,
    {int times = 4, Duration step = const Duration(milliseconds: 50)}) async {
  for (var i = 0; i < times; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(step);
  }
}

Future<GameHarness> bootGame(
  WidgetTester t, {
  Size size = const Size(390, 844),
  Future<void> Function(AppDatabase db, int kid)? seed,
  int randomSeed = 7,
  bool reduceMotion = true,
  List<Override> extra = const [],
}) async {
  setSize(t, size.width, size.height);
  t.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  appRouter.go('/');
  late int kid;
  await t.runAsync(() async {
    final kids = KidRepository(db);
    kid = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    await placeKid(db, kid);
    if (seed != null) await seed(db, kid);
  });
  final speaker = FakeSpeaker();
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        speakerProvider.overrideWithValue(speaker),
        raceRandomProvider.overrideWith((ref) => Random(randomSeed)),
        ...extra,
      ],
      child: const App(),
    ),
  );
  await settle(t);
  return GameHarness(db, kid, speaker);
}

ProviderContainer containerOf(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(Navigator).first));

RaceState raceState(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(RaceScreen)))
        .read(raceControllerProvider);

Future<void> openRace(WidgetTester t, String subject) async {
  appRouter.go('/game/race/$subject');
  await pumpReal(t, times: 8);
  expect(raceState(t).phase, RacePhase.racing);
}

/// Thinks for [think] (race time runs, Chíp may step), taps the right key
/// of the current question and waits for the next one.
Future<void> answerRight(WidgetTester t,
    {Duration think = const Duration(seconds: 1)}) async {
  await t.pump(think);
  final i = raceState(t).current!.correctIndex;
  await t.tap(find.byKey(ValueKey('race-key-$i')));
  await t.pump();
  await t.pump(const Duration(milliseconds: 450));
}

Future<void> answerWrong(WidgetTester t) async {
  final right = raceState(t).current!.correctIndex;
  final i = (right + 1) % 3;
  await t.tap(find.byKey(ValueKey('race-key-$i')));
  await t.pump();
  await t.pump(const Duration(milliseconds: 100));
}

/// Answers right until the race is over, then lets the result route open.
Future<void> winRace(WidgetTester t) async {
  while (find.byType(RaceScreen).evaluate().isNotEmpty &&
      raceState(t).phase == RacePhase.racing) {
    await answerRight(t);
  }
  await pumpReal(t, times: 10, step: const Duration(milliseconds: 300));
}
