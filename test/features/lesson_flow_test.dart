import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/lesson/lesson_done_screen.dart';
import 'package:funedu/features/lesson/lesson_flow_screen.dart';
import 'package:funedu/features/math/exercise/choice_answers.dart';
import 'package:funedu/features/trace/trace_pad.dart';
import 'package:funedu/learning/lesson_item.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:go_router/go_router.dart';

Stroke _line() => Stroke([
      for (var i = 0; i <= 10; i++) Point2(0.1 + 0.08 * i, 0.5),
    ]);

Glyph _glyph(String id, String label) =>
    Glyph(id: id, label: label, strokes: [_line()]);

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _draw(WidgetTester t) async {
  final o = t.getTopLeft(find.byType(TracePad));
  final side = t.getSize(find.byType(TracePad)).width;
  final s = _line();
  final a = s.points.first;
  final b = s.points.last;
  await t.runAsync(() async {
    await t.dragFrom(
      o + Offset(a.x * side, a.y * side),
      Offset((b.x - a.x) * side, (b.y - a.y) * side),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await t.pump();
}

/// Lets the 1.2 s completion timer fire and the DB writes finish.
Future<void> _finishGlyph(WidgetTester t) async {
  // The stroke was drawn inside runAsync, so the timer is a real one.
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 1300)),
  );
  // Drift work needs the real event loop; fake-zone continuations need pumps.
  for (var i = 0; i < 6; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump();
  }
  await t.pumpAndSettle();
}

/// Fails the first [failures] math saves, then behaves normally.
class _FlakyLevelRepository extends LevelRepository {
  _FlakyLevelRepository(super.db, this.failures);

  int failures;
  int attempts = 0;

  @override
  Future<int> recordMathSession({
    required int firstTryCorrect,
    required int total,
  }) {
    attempts++;
    if (failures > 0) {
      failures--;
      throw StateError('disk full');
    }
    return super.recordMathSession(
      firstTryCorrect: firstTryCorrect,
      total: total,
    );
  }
}

Future<AppDatabase> _pump(
  WidgetTester t, {
  required List<LessonItem> lesson,
  String initial = '/lesson',
  int mathSaveFailures = 0,
  List<_FlakyLevelRepository>? flaky,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home stub')),
      ),
      GoRoute(path: '/lesson', builder: (_, __) => const LessonFlowScreen()),
      GoRoute(
        path: '/lesson/done',
        builder: (_, s) => LessonDoneScreen(
          starsEarned: s.extra is int ? s.extra! as int : 0,
        ),
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (flaky != null)
          levelRepositoryProvider.overrideWith((ref) {
            final repo = _FlakyLevelRepository(db, mathSaveFailures);
            flaky.add(repo);
            return repo;
          }),
        todayLessonProvider.overrideWith((ref) async => lesson),
        glyphProvider.overrideWith((ref, id) async => _glyph(id, 'Chữ $id')),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await t.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('two glyphs: records progress, shows done screen with +4',
      (t) async {
    _setSize(t, 375, 667);
    final db = await _pump(t,
        lesson: [const WritingItem('a'), const WritingItem('b')]);
    expect(find.text('Viết Chữ a'), findsOneWidget);

    await _draw(t);
    await _finishGlyph(t);
    expect(find.text('Viết Chữ b'), findsOneWidget);

    await _draw(t);
    await _finishGlyph(t);

    expect(find.text('Xong bài hôm nay!'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);
    final progress = await t.runAsync(() => db.select(db.glyphProgress).get());
    expect(progress!.map((r) => r.glyphId).toSet(), {'a', 'b'});
    final lessons =
        await t.runAsync(() => db.select(db.lessonCompletions).get());
    expect(lessons, hasLength(1));
    expect(lessons!.single.starsEarned, 4);

    await t.tap(find.text('Về trang chính'));
    await t.pumpAndSettle();
    expect(find.text('home stub'), findsOneWidget);
  });

  testWidgets('back on the first glyph goes home and records nothing',
      (t) async {
    _setSize(t, 375, 667);
    final db = await _pump(t,
        lesson: [const WritingItem('a'), const WritingItem('b')]);
    await t.tap(find.bySemanticsLabel('Quay lại'));
    await t.pumpAndSettle();
    expect(find.text('home stub'), findsOneWidget);
    expect(
        await t.runAsync(() => db.select(db.lessonCompletions).get()), isEmpty);
    expect(await t.runAsync(() => db.select(db.glyphProgress).get()), isEmpty);
  });

  testWidgets('empty lesson shows a friendly message', (t) async {
    _setSize(t, 375, 667);
    await _pump(t, lesson: const []);
    expect(find.text('Chưa có bài nào'), findsOneWidget);
    await t.tap(find.text('Về trang chính'));
    await t.pumpAndSettle();
    expect(find.text('home stub'), findsOneWidget);
  });

  for (final size in [const Size(375, 667), const Size(1024, 1366)]) {
    testWidgets('done screen has no overflow at $size', (t) async {
      _setSize(t, size.width, size.height);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await t.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: LessonDoneScreen(starsEarned: 5)),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('Tuần này của bé'), findsOneWidget);
      for (final d in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']) {
        expect(find.text(d), findsOneWidget);
      }
    });
  }

  testWidgets('writing, math, writing: records all and shows +5', (t) async {
    _setSize(t, 375, 667);
    final db = await _pump(t, lesson: const [
      WritingItem('a'),
      MathItem(4),
      WritingItem('b'),
    ]);
    await t.runAsync(() => LevelRepository(db).setLevel('toan', 4));
    await _draw(t);
    await _finishGlyph(t);

    // Math session (cong-5): answer each question correctly first try.
    expect(find.text('Toán · Cộng trong 5'), findsOneWidget);
    final prompt = RegExp(r'^(\d+) \+ (\d+) = \?$');
    for (var i = 0; i < 5; i++) {
      final text = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere(prompt.hasMatch);
      final m = prompt.firstMatch(text)!;
      final answer = int.parse(m[1]!) + int.parse(m[2]!);
      await t.tap(find.descendant(
        of: find.byType(ChoiceAnswers),
        matching: find.text('$answer'),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 900));
    }
    await t.pump(const Duration(milliseconds: 1200));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(find.text('Viết Chữ b'), findsOneWidget);
    expect(
      await t.runAsync(() => LevelRepository(db).levelOf('toan')),
      5,
    );

    await _draw(t);
    await _finishGlyph(t);
    expect(find.text('Xong bài hôm nay!'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    final lessons =
        await t.runAsync(() => db.select(db.lessonCompletions).get());
    expect(lessons!.single.starsEarned, 5);
    final progress = await t.runAsync(() => db.select(db.glyphProgress).get());
    expect(progress!.map((r) => r.glyphId).toSet(), {'a', 'b'});
  });

  testWidgets('failed math save offers Thử lại that retries only the save',
      (t) async {
    _setSize(t, 375, 667);
    final flaky = <_FlakyLevelRepository>[];
    final db = await _pump(
      t,
      lesson: const [MathItem(4)],
      mathSaveFailures: 1,
      flaky: flaky,
    );
    await t.runAsync(() => LevelRepository(db).setLevel('toan', 4));
    final prompt = RegExp(r'^(\d+) \+ (\d+) = \?$');
    for (var i = 0; i < 5; i++) {
      final text = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere(prompt.hasMatch);
      final m = prompt.firstMatch(text)!;
      await t.tap(find.descendant(
        of: find.byType(ChoiceAnswers),
        matching: find.text('${int.parse(m[1]!) + int.parse(m[2]!)}'),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 900));
    }
    await t.pump(const Duration(milliseconds: 1200));
    await t.pumpAndSettle();
    expect(find.text('Không lưu được kết quả'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(flaky.single.attempts, 1);

    await t.tap(find.text('Thử lại'));
    await t.pump();
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(flaky.single.attempts, 2);
    expect(find.text('Xong bài hôm nay!'), findsOneWidget);
    expect(
      await t.runAsync(() => LevelRepository(db).levelOf('toan')),
      5,
    );
  });

  testWidgets('waits for the fresh lesson instead of a stale reloading one',
      (t) async {
    _setSize(t, 375, 667);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    var calls = 0;
    final second = Completer<List<LessonItem>>();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayLessonProvider.overrideWith(
          (ref) => ++calls == 1
              ? Future.value([const WritingItem('old')])
              : second.future,
        ),
        glyphProvider.overrideWith((ref, id) async => _glyph(id, 'Chữ $id')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(todayLessonProvider.future);
    container.invalidate(todayLessonProvider);
    // Now reloading with the stale ['old'] still readable.
    expect(container.read(todayLessonProvider).valueOrNull,
        [const WritingItem('old')]);

    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LessonFlowScreen()),
      ),
    );
    await t.pump();
    expect(find.text('Viết Chữ old'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    second.complete([const WritingItem('new')]);
    await t.pumpAndSettle();
    expect(find.text('Viết Chữ new'), findsOneWidget);
  });
}
