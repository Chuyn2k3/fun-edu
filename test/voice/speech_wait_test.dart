import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/english/english_level.dart';
import 'package:funedu/english/english_generator.dart';
import 'package:funedu/explore/geography_generator.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/features/english/english_session_screen.dart';
import 'package:funedu/features/explore/geography_session_screen.dart';
import 'package:funedu/features/vietnamese/vietnamese_session_screen.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/vietnamese/vietnamese_generator.dart';
import 'package:funedu/vietnamese/vietnamese_level.dart';
import 'package:funedu/voice/speaker.dart';
import 'package:funedu/voice/speech_wait.dart';
import 'dart:math';

/// A device voice that is still talking until the test lets it finish.
class _HeldSpeaker implements MultilingualSpeaker {
  final spoken = <String>[];
  Completer<void>? talking;

  Future<void> _say(String text) {
    spoken.add(text);
    talking = Completer<void>();
    return talking!.future;
  }

  void finish() {
    final t = talking;
    if (t != null && !t.isCompleted) t.complete();
  }

  @override
  Future<void> speak(String text) => _say(text);
  @override
  Future<void> speakWithLanguage(String text, String language) => _say(text);
  @override
  Future<void> stop() async => finish();
}

Future<void> _pump(WidgetTester t, _HeldSpeaker speaker, Widget screen) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [
      speakerProvider.overrideWithValue(speaker),
      homeSummaryProvider.overrideWith((_) async => const HomeSummary(
          totalStars: 1, learnedDaysThisWeek: 1, masteredWriting: 0)),
    ],
    child: MaterialApp(home: screen),
  ));
  await t.pump();
}

Future<void> _tap(WidgetTester t, String key) async {
  await t.ensureVisible(find.byKey(ValueKey(key)));
  await t.tap(find.byKey(ValueKey(key)));
  await t.pump();
}

void main() {
  group('afterSpeech', () {
    testWidgets('waits for the speech and the minimum, capped', (t) async {
      final speech = Completer<void>();
      var done = false;
      afterSpeech(speech.future,
              atLeast: const Duration(seconds: 1),
              atMost: const Duration(seconds: 8))
          .then((_) => done = true);
      await t.pump(const Duration(seconds: 3));
      expect(done, isFalse);
      speech.complete();
      await t.pump();
      expect(done, isTrue);

      var capped = false;
      afterSpeech(Completer<void>().future,
              atLeast: const Duration(seconds: 1),
              atMost: const Duration(seconds: 8))
          .then((_) => capped = true);
      await t.pump(const Duration(seconds: 7));
      expect(capped, isFalse);
      await t.pump(const Duration(seconds: 2));
      expect(capped, isTrue);
    });

    testWidgets('a failing voice still moves on after the minimum', (t) async {
      var done = false;
      afterSpeech(Future<void>.error(StateError('tts')),
              atLeast: const Duration(seconds: 1))
          .then((_) => done = true);
      await t.pump(const Duration(milliseconds: 1100));
      expect(done, isTrue);
    });
  });

  testWidgets('Vietnamese: the next question waits for the praise to end',
      (t) async {
    final speaker = _HeldSpeaker();
    final level = vietnameseLevels[0];
    final qs = generateVietnameseQuestions(level, Random(7), count: 5);
    await _pump(t, speaker,
        VietnameseSessionScreen(level: level, random: Random(7), onCompleted: (_, __) {}));
    speaker.finish();
    await _tap(t, 'vn-choice-${qs[0].correctIndex}');
    expect(speaker.spoken.last, qs[0].celebrationSpeech);
    await t.pump(const Duration(seconds: 3));
    expect(speaker.spoken.last, qs[0].celebrationSpeech);
    speaker.finish();
    await t.pump(const Duration(milliseconds: 50));
    expect(speaker.spoken.last, qs[1].speech);
  });

  testWidgets('English: the next question waits for the word to end',
      (t) async {
    final speaker = _HeldSpeaker();
    final level = englishLevels[4];
    final qs = generateEnglishQuestions(level, Random(7), count: 5);
    await _pump(t, speaker,
        EnglishSessionScreen(level: level, random: Random(7), onCompleted: (_, __) {}));
    speaker.finish();
    await _tap(t, 'en-choice-${qs[0].correctIndex}');
    final said = speaker.spoken.length;
    await t.pump(const Duration(seconds: 3));
    expect(speaker.spoken.length, said);
    speaker.finish();
    await t.pump(const Duration(milliseconds: 50));
    expect(speaker.spoken.length, said + 1);
  });

  testWidgets('Geography: the next question waits for the fact to end',
      (t) async {
    final speaker = _HeldSpeaker();
    final level = geographyLevels[4];
    final qs = generateGeographyQuestions(level, Random(7));
    await _pump(t, speaker,
        GeographySessionScreen(level: level, random: Random(7), onCompleted: (_, __) {}));
    speaker.finish();
    await _tap(t, 'geo-choice-${qs[0].correctIndex}');
    await t.pump(const Duration(seconds: 7));
    expect(speaker.spoken.last, isNot(qs[1].speech));
    speaker.finish();
    await t.pump(const Duration(milliseconds: 50));
    expect(speaker.spoken.last, qs[1].speech);
  });
}
