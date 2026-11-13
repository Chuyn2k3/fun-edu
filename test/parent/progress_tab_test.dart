import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/parent/parent_unlock.dart';
import 'package:funedu/parent/screens/parent_home.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/screen_time/screen_time_service.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:go_router/go_router.dart';

import '../features/setup_helpers.dart';

const _labels = {
  'net-ngang': 'Nét ngang',
  'net-thang-dung': 'Nét thẳng đứng',
  'so-1': 'Số 1',
};

late AppDatabase db;
late int na;
late int bo;

Future<void> _seed() async {
  final kids = KidRepository(db);
  na = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
  bo = await kids.addKid(nickname: 'Bo', avatar: kidAvatars[1], age: 6);
  final p = ProgressRepository(db, kidId: na);
  await p.recordGlyphCompleted('net-ngang', failedStrokes: 0);
  for (var i = 0; i < 3; i++) {
    await p.recordGlyphCompleted('so-1', failedStrokes: 3);
  }
  await LevelRepository(db, kidId: na).setLevel('toan', 2);
  await ScreenTimeService(db, kids)
      .addUsage(na, const Duration(minutes: 20, seconds: 30));
}

List<Override> _overrides() => [
      databaseProvider.overrideWithValue(db),
      glyphListProvider.overrideWith(
        (ref) async => [
          for (final e in _labels.entries)
            Glyph(id: e.key, label: e.value, strokes: const []),
        ],
      ),
    ];

Future<void> _pumpParent(WidgetTester t,
    {Size? size, bool unlocked = false}) async {
  setSize(t, size?.width ?? 375, size?.height ?? 667);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const Text('trang chủ')),
    GoRoute(path: '/parent', builder: (_, __) => const ParentHome()),
  ], initialLocation: '/parent');
  await t.pumpWidget(ProviderScope(
    overrides: [
      ..._overrides(),
      if (unlocked)
        parentUnlockedUntilProvider
            .overrideWith((ref) => DateTime.now().add(parentUnlockDuration)),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await settle(t);
}

void main() {
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await _seed();
  });
  tearDown(() => db.close());

  Future<void> unlockedParent(WidgetTester t, {Size? size}) async {
    // Pass the gate first, as a deep link would have to.
    await _pumpParent(t, size: size);
    expect(find.text('Dành cho ba mẹ'), findsOneWidget);
    await passGate(t);
  }

  testWidgets('deep link shows the gate, then the progress tab',
      (tester) async {
    await unlockedParent(tester);
    expect(find.text('Góc ba mẹ'), findsOneWidget);
    for (final l in [
      'Tiến bộ',
      'Hồ sơ',
      'Thời gian',
      'Phần thưởng',
      'Cài đặt'
    ]) {
      expect(find.text(l), findsWidgets);
    }
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('20 / 45 phút'), findsOneWidget);
    expect(find.text('Tuần này'), findsOneWidget);
    expect(find.text('Tập viết'), findsOneWidget);
    expect(find.text('Viết đúng nét'), findsWidgets);
    expect(find.text('Đang tập'), findsWidgets);
    expect(find.text('Chưa học'), findsWidgets);
    expect(find.text('Nét ngang'), findsOneWidget);
    expect(find.text('Chữ Số 1 bé còn hay sai, cho bé tập thêm nhé.'),
        findsOneWidget);
    expect(find.text('Đang học: So sánh'), findsOneWidget);
    expect(find.text('3/9'), findsOneWidget);
  });

  testWidgets('glyph tiles use the three state styles', (tester) async {
    await unlockedParent(tester);
    BoxDecoration deco(String label) => tester
        .widget<DecoratedBox>(find
            .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
            .first)
        .decoration as BoxDecoration;
    expect(deco('Nét ngang').color, AppColors.text);
    expect(deco('Số 1').color, Subject.viet.tint);
    expect(deco('Nét thẳng đứng').color, isNull);
    expect(deco('Nét thẳng đứng').border, isNotNull);
  });

  testWidgets('switching kid chip shows that kid without changing current',
      (tester) async {
    await unlockedParent(tester);
    await tester.tap(find.text('Bo'));
    await settle(tester);
    expect(find.text('Chưa xếp cấp'), findsOneWidget);
    expect(find.textContaining('bé còn hay sai'), findsNothing);
    expect(find.text('0 / 45 phút'), findsOneWidget);
    expect(await KidRepository(db).currentKidId(), na);
    expect(bo, isNot(na));
  });

  testWidgets('other tabs show Sắp có and Về màn bé goes home', (tester) async {
    await unlockedParent(tester);
    await tester.tap(find.text('Hồ sơ'));
    await settle(tester);
    expect(find.text('Sắp có'), findsOneWidget);
    await tester.tap(find.text('Về màn bé'));
    await settle(tester);
    expect(find.text('trang chủ'), findsOneWidget);
  });

  testWidgets('home lock opens the gate then Góc ba mẹ', (tester) async {
    setSize(tester, 375, 667);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/parent', builder: (_, __) => const ParentHome()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(),
      child: MaterialApp.router(routerConfig: router),
    ));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Góc ba mẹ'));
    await settle(tester);
    expect(find.text('Dành cho ba mẹ'), findsOneWidget);
    await passGate(tester);
    // Gate passed once: the corner opens without a second gate.
    expect(find.text('Dành cho ba mẹ'), findsNothing);
    expect(find.text('Góc ba mẹ'), findsOneWidget);
    expect(find.text('Tiến bộ'), findsWidgets);
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets('no overflow at $size', (tester) async {
      await _pumpParent(tester, size: size, unlocked: true);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Bo'));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
