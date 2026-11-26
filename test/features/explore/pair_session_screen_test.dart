import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/explore/explore_flags.dart';
import 'package:funedu/explore/explore_island.dart';
import 'package:funedu/explore/geography_generator.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/features/explore/geography_session_screen.dart';
import 'package:funedu/features/subject/geography_map_screen.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/voice/speaker.dart';
import 'package:go_router/go_router.dart';

class _Spy implements Speaker {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

GeoItem _p(String id, String name) =>
    GeoItem(id: id, name: name, speech: name, fact: '', clue: '', prefix: 'thu');

final _pairLevel = GeographyLevel(
  id: 'an-gi',
  title: 'Con gì ăn gì?',
  subtitle: '',
  clues: false,
  items: const [],
  pairs: [
    for (final (a, b) in [
      ('Thỏ', 'Cà rốt'),
      ('Khỉ', 'Chuối'),
      ('Mèo', 'Đĩa cá'),
      ('Bò', 'Bó cỏ'),
      ('Ong', 'Hoa'),
    ])
      PairItem(
        id: a,
        ask: _p('a-$a', a),
        answer: _p('b-$b', b),
        question: '$a thích ăn gì?',
        fact: 'Câu kể về $a.',
      ),
  ],
);

final _island = ExploreIsland(
  id: 'thu',
  prefix: 'thu',
  name: 'Thử',
  mapTitle: 'Đảo thử',
  subject: Subject.sinhHoc,
  islandImage: '',
  levels: [for (var i = 0; i < 9; i++) _pairLevel],
  ready: true,
);

void _size(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<_Spy> _pump(WidgetTester t, {void Function(int, int)? done}) async {
  final spy = _Spy();
  await t.pumpWidget(ProviderScope(
    overrides: [
      speakerProvider.overrideWithValue(spy),
      homeSummaryProvider.overrideWith((_) async => const HomeSummary(
          totalStars: 1, learnedDaysThisWeek: 1, masteredWriting: 0)),
    ],
    child: MaterialApp(
      home: ExploreSessionScreen(
        island: _island,
        level: _pairLevel,
        random: Random(4),
        onCompleted: done ?? (_, __) {},
      ),
    ),
  ));
  await t.pump();
  return spy;
}

final _qs = generateGeographyQuestions(_pairLevel, Random(4));

void main() {
  testWidgets('a pair question shows the picture asked about and reads it',
      (t) async {
    _size(t, 390, 844);
    final spy = await _pump(t);
    expect(find.byKey(const ValueKey('geo-focus')), findsOneWidget);
    expect(spy.spoken.first, _qs[0].speech);
    await t.tap(find.byKey(ValueKey('geo-choice-${_qs[0].correctIndex}')));
    await t.pump();
    expect(spy.spoken.last, _qs[0].praise);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('all right first time completes 5/5', (t) async {
    _size(t, 390, 844);
    int? first;
    await _pump(t, done: (f, _) => first = f);
    for (final q in _qs) {
      final f = find.byKey(ValueKey('geo-choice-${q.correctIndex}'));
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pump(const Duration(seconds: 3));
    }
    expect(first, 5);
  });

  for (final (size, scale, focusMin) in const [
    (Size(375, 667), 2.0, 160.0),
    (Size(390, 844), 1.0, 160.0),
    (Size(820, 1180), 1.0, 220.0),
    (Size(1180, 820), 1.0, 220.0),
  ]) {
    testWidgets('pair layout at $size x$scale', (t) async {
      _size(t, size.width, size.height);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(t);
      expect(t.takeException(), isNull);
      final focus = t.getSize(find.byKey(const ValueKey('geo-focus')));
      expect(focus.width, greaterThanOrEqualTo(focusMin));
      // The missing picture shows its name.
      expect(find.text(_qs[0].focus!.name), findsWidgets);
    });
  }

  testWidgets('routes: geography map title and a past-the-end island level',
      (t) async {
    _size(t, 390, 844);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final kid =
        await KidRepository(db).addKid(nickname: 'Na', avatar: 'a', age: 5);
    await LevelRepository(db, kidId: kid).setLevel('thu', 12);
    final router = GoRouter(initialLocation: '/subject/thu', routes: [
      GoRoute(path: '/kham-pha', builder: (_, __) => const Text('sảnh')),
      GoRoute(
          path: '/subject/thu',
          builder: (_, __) => ExploreMapScreen(_island)),
      GoRoute(
          path: '/subject/dia-ly',
          builder: (_, __) => const ExploreMapScreen(geographyIsland)),
    ]);
    addTearDown(router.dispose);
    await t.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        exploreIslandsProvider.overrideWithValue([geographyIsland, _island]),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await t.pumpAndSettle();
    expect(find.text('Đảo thử'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const ValueKey('geo-done-7')), 100);
    expect(find.byKey(const ValueKey('geo-done-8')), findsNothing);
    router.go('/subject/dia-ly');
    await t.pumpAndSettle();
    expect(find.text('Khám phá Việt Nam'), findsOneWidget);
  });
}
