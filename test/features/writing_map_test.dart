import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/subject/writing_map_screen.dart';
import 'package:funedu/features/trace/trace_pad.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:go_router/go_router.dart';

import 'package:funedu/learning/writing_ladder.dart';

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

final _stroke = Stroke([Point2(0.1, 0.5), Point2(0.9, 0.5)]);

const _labels = {'net-ngang': 'Nét ngang', 'net-xien': 'Nét xiên'};

Future<AppDatabase> _pump(WidgetTester t, {bool master = false}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (master) {
    await t.runAsync(
      () => ProgressRepository(db)
          .recordGlyphCompleted('net-ngang', failedStrokes: 0),
    );
  }
  final router = GoRouter(
    initialLocation: '/subject/viet',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home stub')),
      ),
      GoRoute(
        path: '/subject/viet',
        builder: (_, __) => const WritingMapScreen(),
      ),
      GoRoute(
        path: '/practice/:glyphId',
        builder: (_, s) => PracticeScreen(s.pathParameters['glyphId']!),
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        glyphListProvider.overrideWith(
          (ref) async => [
            for (final id in writingLadder)
              Glyph(id: id, label: _labels[id] ?? id, strokes: [_stroke]),
          ],
        ),
        glyphProvider.overrideWith(
          (ref, id) async => Glyph(
            id: id,
            label: _labels[id] ?? id,
            strokes: [_stroke],
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await t.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('mastered glyph shows a tick, others do not', (t) async {
    _setSize(t, 375, 667);
    await _pump(t, master: true);
    final ngang = find.ancestor(
      of: find.text('Nét ngang'),
      matching: find.byType(InkWell),
    );
    final xien = find.ancestor(
      of: find.text('Nét xiên'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(
          of: ngang, matching: find.byKey(const ValueKey('mastered'))),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: xien, matching: find.byKey(const ValueKey('mastered'))),
      findsNothing,
    );
  });

  testWidgets('tapping a glyph opens its practice screen', (t) async {
    _setSize(t, 375, 667);
    await _pump(t);
    await t.tap(find.text('Nét xiên'));
    await t.pumpAndSettle();
    expect(find.text('Viết Nét xiên'), findsOneWidget);
  });

  testWidgets('finishing a practice records the glyph, returns, shows tick',
      (t) async {
    _setSize(t, 375, 667);
    final db = await _pump(t);
    await t.tap(find.text('Nét xiên'));
    await t.pumpAndSettle();

    final o = t.getTopLeft(find.byType(TracePad));
    final side = t.getSize(find.byType(TracePad)).width;
    await t.runAsync(() async {
      await t.dragFrom(
          o + Offset(0.1 * side, 0.5 * side), Offset(0.8 * side, 0));
      await Future<void>.delayed(const Duration(milliseconds: 1400));
    });
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump();
    }
    await t.pumpAndSettle();

    expect(find.text('Viết Nét xiên'), findsNothing);
    final xien = find.ancestor(
      of: find.text('Nét xiên'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(
          of: xien, matching: find.byKey(const ValueKey('mastered'))),
      findsOneWidget,
    );
    final lessons =
        await t.runAsync(() => db.select(db.lessonCompletions).get());
    expect(lessons, isEmpty);
  });

  for (final size in [const Size(375, 667), const Size(1024, 1366)]) {
    testWidgets('writing map has no overflow at $size', (t) async {
      _setSize(t, size.width, size.height);
      await _pump(t, master: true);
      expect(t.takeException(), isNull);
    });
  }
}
