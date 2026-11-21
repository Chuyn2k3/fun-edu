import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/voice/voice_lines.dart';

import 'game_test_helpers.dart';

void main() {
  testWidgets('RaceScreen layout is full-bleed with floating cockpit HUD on phone',
      (t) async {
    await bootGame(t, size: const Size(390, 844));
    await openRace(t, 'toan');

    // Full-bleed: RaceScene occupies full height (844)
    final sceneSize = t.getSize(find.byType(RaceScene));
    expect(sceneSize.height, 844);
    expect(sceneSize.width, 390);

    // Floating cockpit HUD is present
    expect(find.byType(FloatingCockpitHUD), findsOneWidget);

    // Answer keys have accessible height >= 64 on phone
    final key0 = t.getSize(find.byKey(const ValueKey('race-key-0')));
    expect(key0.height, greaterThanOrEqualTo(64.0));
  });

  testWidgets('RaceScreen answer keys maintain height >= 80 on tablet portrait',
      (t) async {
    await bootGame(t, size: const Size(800, 1280));
    await openRace(t, 'toan');

    // Full-bleed: RaceScene occupies full height (1280) on tablet portrait
    final sceneSize = t.getSize(find.byType(RaceScene));
    expect(sceneSize.height, 1280);
    expect(sceneSize.width, 800);

    // Answer keys have accessible height >= 80 on tablet
    final key0 = t.getSize(find.byKey(const ValueKey('race-key-0')));
    expect(key0.height, greaterThanOrEqualTo(80.0));
  });

  testWidgets('Nitro streak gauge displays when comboStreak >= 2', (t) async {
    await bootGame(t, size: const Size(390, 844));
    await openRace(t, 'toan');

    // Initially at combo 0: no nitro gauge
    expect(find.textContaining('BỨT TỐC'), findsNothing);

    // First correct answer -> combo 1: still no nitro gauge
    await answerRight(t);
    expect(find.textContaining('BỨT TỐC'), findsNothing);

    // Second consecutive correct answer -> combo 2: nitro gauge appears!
    await answerRight(t);
    expect(find.textContaining('BỨT TỐC x2'), findsOneWidget);

    // Wrong answer -> resets combo to 0: nitro gauge disappears
    await answerWrong(t);
    expect(find.textContaining('BỨT TỐC'), findsNothing);
  });

  testWidgets('a comet question still reads the letter aloud (Tiếng Việt)',
      (t) async {
    final h = await bootGame(t, size: const Size(390, 844));
    await openRace(t, 'tieng-viet');
    await answerRight(t);
    await answerRight(t);
    final q = raceState(t).current!;
    expect(q.comet, isTrue, reason: 'question 3 is a comet');
    expect(q.spoken, isNotEmpty);
    expect(h.speaker.spoken.last, '$voiceComet ${q.spoken}');

    // The listen button repeats the letter itself, not the comet line.
    await t.tap(find.byKey(const ValueKey('listen-big')).evaluate().isNotEmpty
        ? find.byKey(const ValueKey('listen-big'))
        : find.byKey(const ValueKey('listen')));
    await t.pump();
    expect(h.speaker.spoken.last, q.spoken);
  });
}
