import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/widgets/pressable.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
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

Future<AppDatabase> _pump(
  WidgetTester t, {
  bool master = false,
  ProgressRepository Function(AppDatabase)? repo,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (master) {
    await t.runAsync(
      () => ProgressRepository(db, kidId: 1)
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
        currentKidIdProvider.overrideWith((ref) async => 1),
        if (repo != null)
          progressRepositoryProvider.overrideWith((ref) async => repo(db)),
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

class _FailingRepo extends ProgressRepository {
  _FailingRepo(super.db) : super(kidId: 1);

  @override
  Future<void> recordGlyphCompleted(
    String glyphId, {
    required int failedStrokes,
  }) async =>
      throw StateError('disk full');
}

/// Tiles sharing the topmost tile's y.
int _firstRowCount(WidgetTester t) {
  final tops = [
    for (final e in find.byType(Pressable).evaluate())
      t.getTopLeft(find.byWidget(e.widget)).dy,
  ];
  final first = tops.reduce((a, b) => a < b ? a : b);
  return tops.where((y) => (y - first).abs() < 1).length;
}

void main() {
  testWidgets('mastered glyph shows a tick, others do not', (t) async {
    _setSize(t, 375, 667);
    await _pump(t, master: true);
    final ngang = find.ancestor(
      of: find.text('Nét ngang'),
      matching: find.byType(Pressable),
    );
    final xien = find.ancestor(
      of: find.text('Nét xiên'),
      matching: find.byType(Pressable),
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
      matching: find.byType(Pressable),
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

  for (final size in [const Size(390, 844), const Size(1366, 1024)]) {
    testWidgets('map shows four section headings and 49 tiles at $size',
        (t) async {
      _setSize(t, size.width, size.height);
      await _pump(t);
      final titles = ['Nét cơ bản', 'Chữ số', 'Chữ cái', 'Dấu thanh'];
      final ys = <double>[];
      for (final title in titles) {
        final f = find.text(title, skipOffstage: false);
        expect(f, findsOneWidget, reason: title);
        ys.add(t.getTopLeft(f).dy);
      }
      expect(ys, orderedEquals([...ys]..sort()));
      int tiles(String prefix) => find
          .byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').startsWith(prefix),
              skipOffstage: false)
          .evaluate()
          .length;
      expect(tiles('chu-'), 29);
      expect(tiles('dau-'), 5);
      expect(find.byType(Pressable, skipOffstage: false), findsNWidgets(49));
    });
  }

  testWidgets('tapping a letter tile opens its practice screen', (t) async {
    _setSize(t, 390, 844);
    await _pump(t);
    await t.ensureVisible(find.text('chu-aw'));
    await t.pumpAndSettle();
    await t.tap(find.text('chu-aw'));
    await t.pumpAndSettle();
    expect(find.text('Viết chu-aw'), findsOneWidget);
  });

  testWidgets('no overflow at text scale 1.3 on tablet with headings',
      (t) async {
    _setSize(t, 1366, 1024);
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(t, master: true);
    expect(t.takeException(), isNull);
    expect(find.text('Dấu thanh', skipOffstage: false), findsOneWidget);
  });

  testWidgets('double tap on a tile opens only one practice screen', (t) async {
    _setSize(t, 375, 667);
    await _pump(t);
    await t.tap(find.text('Nét xiên'));
    await t.tap(find.text('Nét xiên'));
    await t.pumpAndSettle();
    expect(find.byType(PracticeScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('map back button is at least 64 pt', (t) async {
    _setSize(t, 375, 667);
    await _pump(t);
    final size = t.getSize(find.ancestor(
      of: find.byIcon(Icons.chevron_left_rounded),
      matching: find.byType(InkResponse),
    ));
    expect(size.width, greaterThanOrEqualTo(64));
    expect(size.height, greaterThanOrEqualTo(64));
  });

  testWidgets('a failed save shows a snackbar and still returns', (t) async {
    _setSize(t, 375, 667);
    await _pump(t, repo: _FailingRepo.new);
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
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Viết Nét xiên'), findsNothing);
    expect(find.text('Không lưu được kết quả'), findsOneWidget);
  });

  for (final (size, cols) in [
    (const Size(1366, 1024), 5),
    (const Size(1024, 1366), 4),
    (const Size(390, 844), 3),
  ]) {
    testWidgets('grid has $cols columns at $size', (t) async {
      _setSize(t, size.width, size.height);
      await _pump(t);
      expect(_firstRowCount(t), cols);
      if (size.shortestSide >= 600) {
        expect(t.getSize(find.byType(Pressable).first).width,
            greaterThanOrEqualTo(120));
      }
      expect(t.takeException(), isNull);
    });
  }
}
