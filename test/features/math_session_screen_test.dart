import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/math/exercise/choice_answers.dart';
import 'package:funedu/features/math/exercise/object_grid.dart';
import 'package:funedu/features/math/math_session_screen.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/math/question_generator.dart';
import 'package:funedu/ui/assets.dart';

MathLevel _level(String id) => mathLevels.firstWhere((l) => l.id == id);

class _Result {
  final calls = <(int, int)>[];
}

Future<_Result> _pump(
  WidgetTester t,
  String levelId, {
  int seed = 1,
  Size? size,
}) async {
  if (size != null) {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final result = _Result();
  await t.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: MathSessionScreen(
          level: _level(levelId),
          step: 1,
          totalSteps: 4,
          random: Random(seed),
          onCompleted: (a, b) => result.calls.add((a, b)),
        ),
      ),
    ),
  );
  await t.pump();
  return result;
}

Finder _choice(int v) =>
    find.descendant(of: find.byType(ChoiceAnswers), matching: find.text('$v'));

String _chipAsset(WidgetTester t) {
  final images = t
      .widgetList<Image>(find.byType(Image))
      .map((i) => (i.image as AssetImage).assetName)
      .where((n) => n.contains('chip-'));
  return images.single;
}

void main() {
  const level = 'cong-5';

  testWidgets('all correct first try -> onCompleted(5, 5) once', (t) async {
    final qs = generateQuestions(_level(level), Random(1), count: 5)
        .cast<ArithmeticQuestion>();
    final r = await _pump(t, level);
    expect(find.text('Mình cùng làm Toán nhé!'), findsOneWidget);
    expect(_chipAsset(t), AppImages.chipMain);
    for (var i = 0; i < 5; i++) {
      expect(find.text('Câu ${i + 1}/5'), findsOneWidget);
      expect(find.text(qs[i].prompt), findsOneWidget);
      await t.tap(_choice(qs[i].answer));
      await t.pump();
      expect(find.text('Đúng rồi!'), findsOneWidget);
      expect(_chipAsset(t), AppImages.chipJoy);
      await t.pump(const Duration(milliseconds: 900));
    }
    expect(find.text('Bé giỏi quá!'), findsOneWidget);
    expect(_chipAsset(t), AppImages.chipThumb);
    expect(r.calls, isEmpty);
    await t.pump(const Duration(milliseconds: 1200));
    expect(r.calls, [(5, 5)]);
    await t.pump(const Duration(seconds: 3));
    expect(r.calls.length, 1);
  });

  testWidgets('wrong on question 1 then correct -> onCompleted(4, 5)',
      (t) async {
    final qs = generateQuestions(_level(level), Random(1), count: 5)
        .cast<ArithmeticQuestion>();
    final r = await _pump(t, level);
    final wrong = qs[0].choices.firstWhere((c) => c != qs[0].answer);
    await t.tap(_choice(wrong));
    await t.pump();
    expect(find.text('Thử lại nhé!'), findsOneWidget);
    expect(_chipAsset(t), AppImages.chipEncourage);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Câu 1/5'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await t.tap(_choice(qs[i].answer));
      await t.pump();
      await t.pump(const Duration(milliseconds: 900));
    }
    await t.pump(const Duration(milliseconds: 1200));
    expect(r.calls, [(4, 5)]);
  });

  testWidgets('disposing mid-delay cancels timers', (t) async {
    final qs = generateQuestions(_level(level), Random(1), count: 5)
        .cast<ArithmeticQuestion>();
    final r = await _pump(t, level);
    await t.tap(_choice(qs[0].answer));
    await t.pump();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 3));
    expect(r.calls, isEmpty);
  });

  /// First seed whose first question matches [a] op [b].
  int seedFor(String levelId, int a, int b, bool plus) {
    for (var seed = 0; seed < 5000; seed++) {
      final q = generateQuestions(_level(levelId), Random(seed), count: 5)
          .first as ArithmeticQuestion;
      if (q.a == a && q.b == b && q.plus == plus) return seed;
    }
    fail('no seed for $a $b');
  }

  Finder stars() => find.descendant(
        of: find.byType(ObjectGrid),
        matching: find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == AppImages.icStar),
      );

  testWidgets('2 + 3 shows both groups: 5 stars and a plus sign', (t) async {
    await _pump(t, 'cong-5', seed: seedFor('cong-5', 2, 3, true));
    expect(find.text('2 + 3 = ?'), findsOneWidget);
    expect(stars(), findsNWidgets(5));
    expect(find.byType(ObjectGrid), findsNWidgets(2));
    expect(find.text('+'), findsOneWidget);
  });

  testWidgets('5 - 2 shows 5 stars, the last 2 faded', (t) async {
    await _pump(t, 'tru-5', seed: seedFor('tru-5', 5, 2, false));
    expect(find.text('5 − 2 = ?'), findsOneWidget);
    expect(stars(), findsNWidgets(5));
    final faded = t
        .widgetList<Opacity>(find.descendant(
            of: find.byType(ObjectGrid), matching: find.byType(Opacity)))
        .where((o) => o.opacity == 0.3);
    expect(faded.length, 2);
  });

  testWidgets('no grid when the objects would exceed 10', (t) async {
    await _pump(t, 'cong-tru-20', seed: seedFor('cong-tru-20', 12, 3, false));
    expect(find.byType(ObjectGrid), findsNothing);
  });

  group('no overflow', () {
    for (final size in const [Size(375, 667), Size(1024, 1366)]) {
      for (final id in const [
        'dem-10',
        'so-sanh-10',
        'ghep-so-10',
        'cong-tru-20'
      ]) {
        testWidgets('$id at $size', (t) async {
          await _pump(t, id, size: size);
          expect(t.takeException(), isNull);
          expect(find.text('Câu 1/5'), findsOneWidget);
        });
      }
    }
  });
}
