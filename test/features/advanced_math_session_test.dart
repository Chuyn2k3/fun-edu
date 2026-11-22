import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/math/exercise/advanced_pictures.dart';
import 'package:funedu/features/math/exercise/choice_answers.dart';
import 'package:funedu/features/math/math_session_screen.dart';
import 'package:funedu/game/engine/question_source.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/math/question_generator.dart';
import 'package:funedu/profile/kid_repository.dart';

MathLevel _level(String id) => mathLevels.firstWhere((l) => l.id == id);

Future<List<(int, int)>> _pump(WidgetTester t, String id, {Size size = const Size(390, 844), int seed = 1}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final calls = <(int, int)>[];
  await t.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      currentKidIdProvider.overrideWith((ref) async => 1),
    ],
    child: MaterialApp(
      home: MathSessionScreen(
        level: _level(id),
        step: 1,
        totalSteps: 4,
        random: Random(seed),
        onCompleted: (a, b) => calls.add((a, b)),
      ),
    ),
  ));
  await t.pump();
  return calls;
}

void main() {
  const sizes = [Size(320, 568), Size(390, 844), Size(820, 1180), Size(1180, 820)];

  for (final size in sizes) {
    testWidgets('số đến 100 at $size: bundles, sticks, number answers', (t) async {
      await _pump(t, 'so-100', size: size);
      expect(t.takeException(), isNull);
      final q = generateQuestions(_level('so-100'), Random(1)).first as TensOnesQuestion;
      expect(find.byType(StickBundles), findsOneWidget);
      expect(find.byKey(const ValueKey('bundle-0')), findsOneWidget);
      expect(find.text('Có bao nhiêu que tính?'), findsOneWidget);
      expect(find.descendant(of: find.byType(ChoiceAnswers), matching: find.text('${q.answer}')),
          findsOneWidget);
    });

    testWidgets('xem đồng hồ at $size: a clock and time answers', (t) async {
      await _pump(t, 'dong-ho', size: size);
      expect(t.takeException(), isNull);
      final q = generateQuestions(_level('dong-ho'), Random(1)).first as ClockQuestion;
      expect(find.byType(ClockFace), findsOneWidget);
      expect(find.text(clockLabel(q.answer)), findsOneWidget);
    });

    testWidgets('tiền at $size: banknotes and nghìn answers', (t) async {
      await _pump(t, 'tien', size: size);
      expect(t.takeException(), isNull);
      final q = generateQuestions(_level('tien'), Random(1)).first as MoneyQuestion;
      expect(find.byType(BanknoteRow), findsOneWidget);
      expect(find.text('${q.notes.first}.000'), findsWidgets);
      expect(find.text('${q.answer} nghìn'), findsOneWidget);
    });
  }

  testWidgets('a right answer on the clock moves on; buttons are kid-sized', (t) async {
    final calls = await _pump(t, 'dong-ho', seed: 3);
    final qs = generateQuestions(_level('dong-ho'), Random(3));
    for (final q in qs.cast<ClockQuestion>()) {
      final btn = find.text(clockLabel(q.answer));
      expect(t.getSize(find.ancestor(of: btn, matching: find.byType(Container)).first).height,
          greaterThanOrEqualTo(64));
      await t.tap(btn);
      await t.pump(const Duration(seconds: 2));
    }
    await t.pump(const Duration(seconds: 2));
    expect(calls, [(5, 5)]);
  });

  test('the clock hands point the right way', () {
    final (h3, m3) = ClockPainter.angles(3, false);
    expect(h3, closeTo(pi / 2, 1e-9));
    expect(m3, 0);
    final (h12half, m12half) = ClockPainter.angles(12, true);
    expect(h12half, closeTo(pi / 12, 1e-9)); // half way from 12 to 1
    expect(m12half, closeTo(pi, 1e-9));
  });

  test('a kid on an advanced level races with arithmetic', () {
    for (final id in ['so-100', 'dong-ho', 'tien']) {
      final qs = buildRaceQuestions(
        subject: RaceSubject.toan,
        mathLevelIndex: mathLevels.indexWhere((l) => l.id == id),
        glyphStats: const {},
        writingStartIndex: 0,
        speechByGlyph: const {},
        rng: Random(1),
      );
      expect(qs, hasLength(10));
      expect(qs.every((q) => q is MathRaceQuestion && q.question is ArithmeticQuestion), isTrue);
    }
  });
}
