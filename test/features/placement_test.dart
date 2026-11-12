import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/features/placement/placement_screen.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:go_router/go_router.dart';

void _setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// Drift needs the real event loop; fake-zone continuations need pumps.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump();
  }
  await t.pumpAndSettle();
}

class _FailingRepo extends LevelRepository {
  _FailingRepo(super.db);
  bool fail = true;

  @override
  Future<void> setLevel(String subject, int index) {
    if (fail) throw StateError('disk full');
    return super.setLevel(subject, index);
  }
}

Widget _stubWriting(Glyph g, int step, int total, void Function(int) done) =>
    Scaffold(
      body: Column(children: [
        Text('viet ${g.id}'),
        TextButton(onPressed: () => done(0), child: const Text('viet-ok')),
        TextButton(onPressed: () => done(3), child: const Text('viet-bad')),
      ]),
    );

Widget _stubMath(level, int step, int total, void Function(int, int) done) =>
    Scaffold(
      body: Column(children: [
        Text('toan ${level.id}'),
        TextButton(onPressed: () => done(3, 3), child: const Text('toan-ok')),
        TextButton(onPressed: () => done(1, 3), child: const Text('toan-bad')),
        Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.of(c).maybePop(),
            child: const Text('toan-back'),
          ),
        ),
      ]),
    );

Future<AppDatabase> _pumpPlacement(
  WidgetTester t, {
  LevelRepository Function(AppDatabase)? repo,
  Size size = const Size(375, 667),
}) async {
  _setSize(t, size.width, size.height);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final router = GoRouter(
    initialLocation: '/placement',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home stub')),
      ),
      GoRoute(
        path: '/placement',
        builder: (_, __) => PlacementScreen(
          writingBuilder: _stubWriting,
          mathBuilder: _stubMath,
        ),
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (repo != null) levelRepositoryProvider.overrideWithValue(repo(db)),
        glyphProvider.overrideWith(
          (ref, id) async => Glyph(
            id: id,
            label: id,
            strokes: [
              Stroke([Point2(0.1, 0.5), Point2(0.9, 0.5)])
            ],
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
  for (final size in const [Size(375, 667), Size(1024, 1366)]) {
    testWidgets('welcome screen has no overflow at $size', (t) async {
      await _pumpPlacement(t, size: size);
      expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
      expect(find.text('Mình chơi thử một chút nhé!'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('passes net-ngang, fails so-0; math 0 and 2 pass, 4 fails',
      (t) async {
    final db = await _pumpPlacement(t);
    await t.tap(find.text('Bắt đầu'));
    await t.pumpAndSettle();
    expect(find.text('viet net-ngang'), findsOneWidget);
    await t.tap(find.text('viet-ok'));
    await t.pumpAndSettle();
    expect(find.text('viet so-0'), findsOneWidget);
    await t.tap(find.text('viet-bad'));
    await t.pumpAndSettle();
    // Writing stops at the first failure; math starts at level 0.
    expect(find.text('toan dem-5'), findsOneWidget);
    await t.tap(find.text('toan-ok'));
    await t.pumpAndSettle();
    expect(find.text('toan so-sanh-10'), findsOneWidget);
    await t.tap(find.text('toan-ok'));
    await t.pumpAndSettle();
    expect(find.text('toan cong-5'), findsOneWidget);
    // Nothing is stored before the end.
    expect(await t.runAsync(() => LevelRepository(db).levelOf('viet')), isNull);
    await t.tap(find.text('toan-bad'));
    await _settle(t);

    expect(find.text('Xong rồi! Mình cùng học nhé!'), findsOneWidget);
    final repo = LevelRepository(db);
    expect(await t.runAsync(() => repo.levelOf('viet')), 0);
    expect(await t.runAsync(() => repo.levelOf('toan')), 2);
    await t.tap(find.text('Vào học'));
    await t.pumpAndSettle();
    expect(find.text('home stub'), findsOneWidget);
  });

  testWidgets('passing every step places at so-4 and math level 6', (t) async {
    final db = await _pumpPlacement(t);
    await t.tap(find.text('Bắt đầu'));
    await t.pumpAndSettle();
    for (final id in ['net-ngang', 'so-0', 'so-4']) {
      expect(find.text('viet $id'), findsOneWidget);
      await t.tap(find.text('viet-ok'));
      await t.pumpAndSettle();
    }
    for (var i = 0; i < 4; i++) {
      await t.tap(find.text('toan-ok'));
      await t.pumpAndSettle();
    }
    await _settle(t);
    final repo = LevelRepository(db);
    expect(await t.runAsync(() => repo.levelOf('viet')), 9);
    expect(await t.runAsync(() => repo.levelOf('toan')), 6);
  });

  testWidgets('failing the first of each places both at 0', (t) async {
    final db = await _pumpPlacement(t);
    await t.tap(find.text('Bắt đầu'));
    await t.pumpAndSettle();
    await t.tap(find.text('viet-bad'));
    await t.pumpAndSettle();
    await t.tap(find.text('toan-bad'));
    await _settle(t);
    final repo = LevelRepository(db);
    expect(await t.runAsync(() => repo.levelOf('viet')), 0);
    expect(await t.runAsync(() => repo.levelOf('toan')), 0);
  });

  testWidgets('leaving during the math step saves nothing', (t) async {
    final db = await _pumpPlacement(t);
    await t.tap(find.text('Bắt đầu'));
    await t.pumpAndSettle();
    await t.tap(find.text('viet-ok'));
    await t.pumpAndSettle();
    await t.tap(find.text('viet-bad'));
    await t.pumpAndSettle();
    expect(find.text('toan dem-5'), findsOneWidget);
    await t.tap(find.text('toan-ok'));
    await t.pumpAndSettle();
    await t.tap(find.text('toan-back'));
    await t.pumpAndSettle();
    expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
    expect(await t.runAsync(() => LevelRepository(db).isPlaced()), isFalse);
  });

  testWidgets('a failed save shows the snackbar and Thử lại recovers',
      (t) async {
    late _FailingRepo failing;
    final db =
        await _pumpPlacement(t, repo: (db) => failing = _FailingRepo(db));
    await t.tap(find.text('Bắt đầu'));
    await t.pumpAndSettle();
    await t.tap(find.text('viet-bad'));
    await t.pumpAndSettle();
    await t.tap(find.text('toan-bad'));
    await _settle(t);
    expect(find.text('Không lưu được kết quả'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Vào học'), findsNothing);
    expect(await t.runAsync(() => LevelRepository(db).isPlaced()), isFalse);

    failing.fail = false;
    await t.tap(find.text('Thử lại'));
    await _settle(t);
    expect(find.text('Vào học'), findsOneWidget);
    expect(await t.runAsync(() => LevelRepository(db).isPlaced()), isTrue);
  });

  group('real router', () {
    Future<AppDatabase> pumpApp(WidgetTester t, {required bool placed}) async {
      _setSize(t, 375, 667);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      appRouter.go('/');
      if (placed) {
        await t.runAsync(() async {
          final r = LevelRepository(db);
          await r.setLevel('viet', 0);
          await r.setLevel('toan', 0);
        });
      }
      await t.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const App(),
        ),
      );
      await _settle(t);
      return db;
    }

    testWidgets('not placed: opens the placement welcome', (t) async {
      await pumpApp(t, placed: false);
      expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
      expect(find.text('Bài hôm nay'), findsNothing);
    });

    testWidgets('unplaced: home is never built, frame by frame', (t) async {
      _setSize(t, 375, 667);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      appRouter.go('/');
      await t.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const App(),
        ),
      );
      for (var i = 0; i < 30; i++) {
        expect(find.byType(HomeScreen), findsNothing);
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
    });

    testWidgets('placed: opens home', (t) async {
      await pumpApp(t, placed: true);
      expect(find.text('Bài hôm nay'), findsOneWidget);
    });
  });
}
