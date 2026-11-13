import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/features/subject/math_map_screen.dart';
import 'package:funedu/learning/lesson_item.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/widgets/pressable.dart';
import 'package:go_router/go_router.dart';

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump();
  }
  await t.pumpAndSettle();
}

Future<(AppDatabase, List<String>)> _pump(
  WidgetTester t, {
  int level = 2,
  Size size = const Size(375, 667),
}) async {
  _setSize(t, size.width, size.height);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await t.runAsync(() => LevelRepository(db, kidId: 1).setLevel('toan', level));
  final visited = <String>[];
  final router = GoRouter(
    initialLocation: '/subject/toan',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home stub')),
      ),
      GoRoute(
        path: '/subject/toan',
        builder: (_, __) => const MathMapScreen(),
      ),
      GoRoute(
        path: '/practice-math/:levelIndex',
        builder: (ctx, s) {
          visited.add(s.pathParameters['levelIndex']!);
          return Scaffold(
            body: TextButton(
              onPressed: () => ctx.pop(),
              child: const Text('practice stub'),
            ),
          );
        },
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentKidIdProvider.overrideWith((ref) async => 1)
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(t);
  return (db, visited);
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
  testWidgets('current level 2: two ticks, Đang học at level 3, locks after',
      (t) async {
    await _pump(t);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    expect(find.text('Đang học'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    expect(find.byKey(const ValueKey('locked-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('locked-2')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('tapping done or current opens practice, locked does nothing',
      (t) async {
    final (_, visited) = await _pump(t);
    await t.tap(find.text(mathLevels[0].title));
    await t.pumpAndSettle();
    expect(visited, ['0']);
    await t.tap(find.text('practice stub'));
    await t.pumpAndSettle();

    await t.ensureVisible(find.text(mathLevels[3].title));
    await t.tap(find.text(mathLevels[3].title));
    await t.pumpAndSettle();
    expect(visited, ['0']);
  });

  testWidgets('shows a spinner, not level 1 as current, until loaded',
      (t) async {
    _setSize(t, 375, 667);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const MathMapScreen()),
    ]);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          mathLevelIndexProvider.overrideWith((ref) => Completer<int>().future),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đang học'), findsNothing);
  });

  testWidgets('no overflow on a tablet', (t) async {
    await _pump(t, size: const Size(1024, 1366));
    expect(find.text('Đang học'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('back button goes home', (t) async {
    await _pump(t);
    await t.tap(find.bySemanticsLabel('Quay lại'));
    await t.pumpAndSettle();
    expect(find.text('home stub'), findsOneWidget);
  });

  testWidgets('home Toán card is active and shows 3/9', (t) async {
    _setSize(t, 375, 667);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/subject/toan',
        builder: (_, __) => const Scaffold(body: Text('toan stub')),
      ),
    ]);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          homeSummaryProvider.overrideWith(
            (ref) async => const HomeSummary(
              totalStars: 0,
              learnedDaysThisWeek: 0,
              masteredWriting: 0,
              mathLevelIndex: 2,
            ),
          ),
          todayLessonProvider.overrideWith((ref) async => const [MathItem(2)]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('3/9'), findsOneWidget);
    // The card sits below the fold on a small phone; bring it clear of the
    // floating nav bar first.
    await t.drag(find.byType(ListView), const Offset(0, -200));
    await t.pumpAndSettle();
    await t.tap(find.text('Toán'));
    await t.pumpAndSettle();
    expect(find.text('toan stub'), findsOneWidget);
  });

  for (final (size, cols) in [
    (const Size(1366, 1024), 3),
    (const Size(1024, 1366), 3),
    (const Size(390, 844), 1),
  ]) {
    testWidgets('math map has $cols tiles in the first row at $size',
        (t) async {
      await _pump(t, size: size);
      expect(_firstRowCount(t), cols);
      expect(t.getSize(find.byType(Pressable).first).width,
          greaterThanOrEqualTo(120));
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('tablet portrait: no orphan row, nine tiles all on screen',
      (t) async {
    await _pump(t, size: const Size(1024, 1366));
    final tops = <double>[];
    for (final e in find.byType(Pressable).evaluate()) {
      final r = t.getRect(find.byWidget(e.widget));
      expect(r.bottom, lessThanOrEqualTo(1366));
      expect(r.width, greaterThanOrEqualTo(120));
      expect(r.height, greaterThanOrEqualTo(120));
      tops.add(r.top);
    }
    expect(tops.length, 9);
    for (final y in tops.toSet()) {
      expect(tops.where((x) => (x - y).abs() < 1).length, 3);
    }
  });

  testWidgets('tablet landscape: nine tiles fit without scrolling', (t) async {
    await _pump(t, size: const Size(1366, 1024));
    for (final e in find.byType(Pressable).evaluate()) {
      final r = t.getRect(find.byWidget(e.widget));
      expect(r.bottom, lessThanOrEqualTo(1024));
      expect(r.width, greaterThanOrEqualTo(120));
    }
    expect(find.byType(Pressable), findsNWidgets(9));
  });
}
