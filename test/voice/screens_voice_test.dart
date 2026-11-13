import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/features/math/exercise/choice_answers.dart';
import 'package:funedu/features/math/math_session_screen.dart';
import 'package:funedu/features/writing/writing_screen.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/math/question_generator.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/voice/speaker.dart';
import 'package:funedu/voice/voice_lines.dart';

import 'fake_speaker.dart';

Future<void> _pump(WidgetTester t, FakeSpeaker fake, Widget home) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentKidIdProvider.overrideWith((ref) async => 1),
        speakerProvider.overrideWithValue(fake),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await t.pump();
}

void main() {
  testWidgets('writing: opening speaks Chíp line, Nghe re-speaks it',
      (t) async {
    final fake = FakeSpeaker();
    final glyph = Glyph(id: 'm', label: 'Một', strokes: [
      Stroke([Point2(0.5, 0.1), Point2(0.5, 0.9)])
    ]);
    await _pump(
      t,
      fake,
      WritingScreen(glyph: glyph, onCompleted: (_) {}),
    );
    expect(fake.spoken, ['Bé tô nét số 1 nhé!']);
    await t.tap(find.text('Nghe'));
    await t.pump();
    expect(fake.spoken, ['Bé tô nét số 1 nhé!', 'Bé tô nét số 1 nhé!']);
    expect(find.byType(SnackBar), findsNothing);
    // Unrelated rebuild does not repeat the line.
    await t.pump(const Duration(milliseconds: 100));
    expect(fake.spoken.length, 2);
  });

  testWidgets(
      'math: speaks only the question on opening; speaker button '
      're-speaks; next question speaks after Chíp praise', (t) async {
    t.view.physicalSize = const Size(800, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final fake = FakeSpeaker();
    final level = mathLevels.firstWhere((l) => l.id == 'cong-10');
    final qs = generateQuestions(level, Random(3), count: 2);
    await _pump(
      t,
      fake,
      MathSessionScreen(
        level: level,
        random: Random(3),
        questionCount: 2,
        onCompleted: (_, __) {},
      ),
    );
    expect(fake.spoken, [spokenQuestion(qs[0])]);
    final btn = find.bySemanticsLabel('Nghe câu hỏi');
    expect(btn, findsOneWidget);
    expect(t.getSize(find.byType(IconButton)).shortestSide,
        greaterThanOrEqualTo(64));
    await t.tap(find.byIcon(Icons.volume_up_rounded));
    expect(fake.spoken.length, 2);
    final q = qs[0] as ArithmeticQuestion;
    await t.tap(find.descendant(
        of: find.byType(ChoiceAnswers), matching: find.text('${q.answer}')));
    await t.pump();
    expect(fake.spoken.last, 'Đúng rồi!');
    await t.pump(const Duration(milliseconds: 950));
    expect(fake.spoken.last, spokenQuestion(qs[1]));
  });
}
