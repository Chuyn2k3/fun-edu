import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/explore/geography_generator.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/features/explore/geography_session_screen.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/voice/speaker.dart';

class _SpySpeaker implements MultilingualSpeaker {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> speakWithLanguage(String text, String language) async =>
      spoken.add(text);
  @override
  Future<void> stop() async {}
}

/// Serves every asset except geography pictures, which fail to load.
class _BrokenGeoBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('/explore/geo-')) {
      throw FlutterError('broken $key');
    }
    return rootBundle.load(key);
  }
}

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1.0;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
}

const _seed = 1;
const _levelIndex = 4; // mien-trung: mixes clue questions

Future<_SpySpeaker> _pump(
  WidgetTester t, {
  void Function(int, int)? onCompleted,
  double textScale = 1.0,
  AssetBundle? bundle,
  int level = _levelIndex,
}) async {
  final speaker = _SpySpeaker();
  Widget screen = GeographySessionScreen(
    level: geographyLevels[level],
    random: Random(_seed),
    onCompleted: onCompleted ?? (_, __) {},
  );
  if (bundle != null) {
    screen = DefaultAssetBundle(bundle: bundle, child: screen);
  }
  await t.pumpWidget(ProviderScope(
    overrides: [
      speakerProvider.overrideWithValue(speaker),
      homeSummaryProvider.overrideWith((_) async => const HomeSummary(
          totalStars: 3, learnedDaysThisWeek: 1, masteredWriting: 0)),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: screen,
    ),
  ));
  await t.pump();
  return speaker;
}

final _expected = generateGeographyQuestions(
    geographyLevels[_levelIndex], Random(_seed));

Future<void> _tapChoice(WidgetTester t, int i) async {
  final f = find.byKey(ValueKey('geo-choice-$i'));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pump();
}

Future<void> _answerAll(WidgetTester t, {int from = 0}) async {
  for (var i = from; i < 5; i++) {
    await _tapChoice(t, _expected[i].correctIndex);
    await t.pump(const Duration(milliseconds: 2000));
  }
}

void main() {
  testWidgets('wrong then right counts no first-try', (t) async {
    _setSize(t, 390, 844);
    int? first, total;
    await _pump(t, onCompleted: (f, n) {
      first = f;
      total = n;
    });
    await _tapChoice(t, (_expected[0].correctIndex + 1) % 3);
    expect(find.textContaining('Thử lại nhé!'), findsOneWidget);
    await _answerAll(t);
    expect((first, total), (4, 5));
  });

  testWidgets('all right first time, first line asks "Đâu là" or a clue',
      (t) async {
    _setSize(t, 390, 844);
    int? first;
    final speaker = await _pump(t, onCompleted: (f, _) => first = f);
    expect(speaker.spoken.first, _expected[0].speech);
    await _answerAll(t);
    expect(first, 5);
  });

  testWidgets('pick-image levels open with "Đâu là"', (t) async {
    _setSize(t, 390, 844);
    final speaker = await _pump(t, level: 0);
    expect(speaker.spoken.first, startsWith('Đâu là '));
  });

  testWidgets('right answer reads the name and the fact', (t) async {
    _setSize(t, 390, 844);
    final speaker = await _pump(t);
    await _tapChoice(t, _expected[0].correctIndex);
    final a = _expected[0].answer;
    expect(speaker.spoken.last, '${a.speech}. ${a.fact}');
    expect(find.text('${a.name}! ${a.fact}'), findsOneWidget);
  });

  testWidgets('double tap on the right answer advances once', (t) async {
    _setSize(t, 390, 844);
    var calls = 0;
    final speaker = await _pump(t, onCompleted: (_, __) => calls++);
    await _tapChoice(t, _expected[0].correctIndex);
    await _tapChoice(t, _expected[0].correctIndex);
    await t.pump(geographyNextDelay);
    expect(speaker.spoken.last, _expected[1].speech);
    expect(find.text(_expected[1].prompt), findsOneWidget);
    await _answerAll(t, from: 1);
    await t.pump(const Duration(seconds: 3));
    expect(calls, 1);
  });

  testWidgets('tap during transition is ignored', (t) async {
    _setSize(t, 390, 844);
    await _pump(t);
    await _tapChoice(t, _expected[0].correctIndex);
    await _tapChoice(t, (_expected[0].correctIndex + 1) % 3);
    expect(find.textContaining('Thử lại nhé!'), findsNothing);
    await t.pump(geographyNextDelay);
  });

  testWidgets('broken image shows the name tile', (t) async {
    _setSize(t, 390, 844);
    await _pump(t, bundle: _BrokenGeoBundle());
    await t.pumpAndSettle();
    for (final c in _expected[0].choices) {
      expect(find.text(c.name), findsWidgets);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('speaker button repeats the question', (t) async {
    _setSize(t, 390, 844);
    final speaker = await _pump(t);
    await t.tap(find.byKey(const ValueKey('geo-speaker')));
    await t.pump();
    expect(speaker.spoken, [_expected[0].speech, _expected[0].speech]);
  });

  for (final (size, scale) in const [
    // x1.3: the shared SessionHeader itself overflows at x2.0 (pre-existing).
    (Size(375, 667), 1.3),
    (Size(390, 844), 1.0),
    (Size(820, 1180), 1.0),
    (Size(1180, 820), 1.0),
  ]) {
    testWidgets('lays out cleanly at $size, text x$scale', (t) async {
      _setSize(t, size.width, size.height);
      await _pump(t, textScale: scale);
      expect(t.takeException(), isNull);
      final tile = t.getSize(find.byKey(const ValueKey('geo-choice-0')));
      expect(tile.width, greaterThanOrEqualTo(size.shortestSide >= 600 ? 140 : 96));
    });
  }
}
