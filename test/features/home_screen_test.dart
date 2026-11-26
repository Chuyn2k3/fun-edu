import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/explore/explore_flags.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/features/home/home_tablet.dart';
import 'package:funedu/features/home/week_panel.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/learning/lesson_item.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:funedu/ui/widgets/floating_nav_bar.dart';
import 'package:funedu/ui/widgets/nav_rail.dart';
import 'package:funedu/ui/widgets/subject_card.dart';
import 'package:funedu/stroke/glyph_repository.dart';
import 'package:go_router/go_router.dart';

Widget _app(
  List<Override> overrides,
  List<String> visited,
) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/lesson',
        builder: (_, __) {
          visited.add('/lesson');
          return const Scaffold(body: Text('lesson stub'));
        },
      ),
      GoRoute(
        path: '/game',
        builder: (_, __) {
          visited.add('/game');
          return const Scaffold(body: Text('game stub'));
        },
      ),
      GoRoute(
        path: '/collection',
        builder: (_, __) {
          visited.add('/collection');
          return const Scaffold(body: Text('collection stub'));
        },
      ),
      GoRoute(
        path: '/house',
        builder: (_, __) {
          visited.add('/house');
          return const Scaffold(body: Text('house stub'));
        },
      ),
      GoRoute(
        path: '/kham-pha',
        builder: (_, __) {
          visited.add('/kham-pha');
          return const Scaffold(body: Text('explore stub'));
        },
      ),
      GoRoute(
        path: '/subject/viet',
        builder: (_, __) {
          visited.add('/subject/viet');
          return const Scaffold(body: Text('viet stub'));
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

List<Override> _fakes() => [
      kidsProvider.overrideWith(
        (ref) async => [
          KidProfile(
            id: 1,
            nickname: 'Na',
            avatar: kidAvatars[0],
            age: 5,
            createdAt: DateTime(2026),
          ),
        ],
      ),
      currentKidIdProvider.overrideWith((ref) async => 1),
      homeSummaryProvider.overrideWith(
        (ref) async => const HomeSummary(
          totalStars: 12,
          learnedDaysThisWeek: 3,
          masteredWriting: 2,
        ),
      ),
      todayLessonProvider.overrideWith(
        (ref) async => const [
          WritingItem('net-xien'),
          MathItem(0),
          WritingItem('net-cong'),
        ],
      ),
      glyphProvider.overrideWith(
        (ref, id) async => Glyph(id: id, label: 'Nét xiên', strokes: const []),
      ),
    ];

Finder _labeled(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == label,
    );

void _setSize(WidgetTester tester, double w, double h) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<Override> _exploreOn({int done = 4, int total = 9}) => [
      ..._fakes(),
      exploreIslandEnabledProvider.overrideWithValue(true),
      homeSummaryProvider.overrideWith(
        (ref) async => HomeSummary(
          totalStars: 12,
          learnedDaysThisWeek: 3,
          masteredWriting: 2,
          exploreDone: done,
          exploreTotal: total,
        ),
      ),
    ];

final _exploreCard = find.ancestor(
  of: find.text('Đảo Khám phá'),
  matching: find.byType(SubjectCard),
);

void exploreCardTests() {
  testWidgets('explore card is hidden while the switch is off', (t) async {
    _setSize(t, 390, 844);
    await t.pumpWidget(_app(_fakes(), []));
    await t.pumpAndSettle();
    expect(find.text('Đảo Khám phá'), findsNothing);
  });

  testWidgets('phone 390x844: explore card spans the grid and opens the hall',
      (t) async {
    _setSize(t, 390, 844);
    final visited = <String>[];
    await t.pumpWidget(_app(_exploreOn(), visited));
    await t.pumpAndSettle();
    expect(_exploreCard, findsOneWidget);
    final viet = t.getRect(find.ancestor(
        of: find.text('Viết'), matching: find.byType(SubjectCard)));
    final english = t.getRect(find.ancestor(
        of: find.text('Tiếng Anh'), matching: find.byType(SubjectCard)));
    final explore = t.getRect(_exploreCard);
    expect(explore.left, closeTo(viet.left, 0.5));
    expect(explore.right, closeTo(english.right, 0.5));
    expect(find.descendant(of: _exploreCard, matching: find.text('4/9')),
        findsOneWidget);
    await t.ensureVisible(_exploreCard);
    await t.pumpAndSettle();
    await t.tap(_exploreCard);
    await t.pumpAndSettle();
    expect(visited, ['/kham-pha']);
  });

  testWidgets('phone 375x667: subjects still above the nav bar, explore below',
      (t) async {
    _setSize(t, 375, 667);
    await t.pumpWidget(_app(_exploreOn(), []));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final nav = t.getRect(find.byType(FloatingNavBar));
    final english = t.getRect(find.ancestor(
        of: find.text('Tiếng Anh'), matching: find.byType(SubjectCard)));
    expect(english.bottom, lessThan(nav.top));
    await t.ensureVisible(_exploreCard);
    await t.pumpAndSettle();
    expect(_exploreCard.hitTestable(), findsOneWidget);
  });

  testWidgets('two ready islands show their total', (t) async {
    _setSize(t, 390, 844);
    await t.pumpWidget(_app(_exploreOn(done: 6, total: 18), []));
    await t.pumpAndSettle();
    expect(find.descendant(of: _exploreCard, matching: find.text('6/18')),
        findsOneWidget);
  });

  testWidgets('a full island shows 9/9', (t) async {
    _setSize(t, 390, 844);
    await t.pumpWidget(_app(_exploreOn(done: 9), []));
    await t.pumpAndSettle();
    expect(find.descendant(of: _exploreCard, matching: find.text('9/9')),
        findsOneWidget);
  });

  testWidgets('iPad landscape 1180x820: five cards in one row, still no scroll',
      (t) async {
    _setSize(t, 1180, 820);
    await t.pumpWidget(_app(_fakes(), []));
    await t.pumpAndSettle();
    final scrollsOff = find
        .descendant(
            of: find.byType(HomeTabletBody),
            matching: find.byType(SingleChildScrollView))
        .evaluate()
        .length;
    // A fresh scope: overrides cannot change on a live ProviderScope.
    await t.pumpWidget(KeyedSubtree(key: UniqueKey(), child: _app(_exploreOn(), [])));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final english = t.getRect(find.ancestor(
        of: find.text('Tiếng Anh'), matching: find.byType(SubjectCard)));
    final explore = t.getRect(_exploreCard);
    expect(explore.top, closeTo(english.top, 0.5));
    expect(
        find
            .descendant(
                of: find.byType(HomeTabletBody),
                matching: find.byType(SingleChildScrollView))
            .evaluate()
            .length,
        scrollsOff);
  });

  for (final (size, scale) in const [
    (Size(820, 1180), 1.0),
    (Size(1133, 744), 1.3),
    (Size(390, 844), 2.0),
  ]) {
    testWidgets('explore on: no overflow at $size, text $scale', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      _setSize(t, size.width, size.height);
      await t.pumpWidget(_app(_exploreOn(), []));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}

void main() {
  tabletLayoutTests();
  exploreCardTests();

  for (final size in const [Size(1024, 1366), Size(1366, 1024)]) {
    testWidgets(
        'tablet ${size.width.toInt()}x${size.height.toInt()} dùng NavRail',
        (tester) async {
      _setSize(tester, size.width, size.height);
      await tester.pumpWidget(_app(_fakes(), []));
      await tester.pumpAndSettle();
      expect(find.byType(NavRail), findsOneWidget);
      expect(find.byType(FloatingNavBar), findsNothing);
    });
  }

  testWidgets('điện thoại dùng FloatingNavBar, không có NavRail',
      (tester) async {
    _setSize(tester, 390, 844);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(find.byType(NavRail), findsNothing);
  });

  testWidgets(
      'iPhone nhỏ 375x667: cả 4 thẻ môn học nằm hoàn toàn phía trên FloatingNavBar',
      (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();

    final navBarRect = tester.getRect(find.byType(FloatingNavBar));
    final englishCardFinder = find.ancestor(
      of: find.text('Tiếng Anh'),
      matching: find.byType(SubjectCard),
    );
    expect(englishCardFinder, findsOneWidget);
    final englishRect = tester.getRect(englishCardFinder);

    // Thẻ Tiếng Anh (thẻ dưới cùng bên phải) nằm hoàn toàn phía trên FloatingNavBar
    expect(englishRect.bottom, lessThan(navBarRect.top));
  });

  testWidgets(
      'điện thoại 390x844: chế độ gọn không bật, thẻ môn giữ kích thước tiêu chuẩn',
      (tester) async {
    _setSize(tester, 390, 844);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.text('Viết'),
      matching: find.byType(SubjectCard),
    );
    final subjectCard = tester.widget<SubjectCard>(card);
    expect(subjectCard.compact, isFalse);
  });

  for (final scale in const [1.3, 1.6, 2.0]) {
    testWidgets(
        'điện thoại 390x844 textScale $scale: không tràn, nút Play >= 64 và bấm được',
        (tester) async {
      _setSize(tester, 390, 844);
      final visited = <String>[];
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(scale),
        ),
        child: _app(_fakes(), visited),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final playFinder = _labeled('Bắt đầu bài hôm nay');
      expect(playFinder, findsOneWidget);
      final playSize = tester.getSize(playFinder);
      expect(playSize.width, greaterThanOrEqualTo(64));
      expect(playSize.height, greaterThanOrEqualTo(64));

      await tester.tap(playFinder);
      await tester.pumpAndSettle();
      expect(visited, ['/lesson']);
    });
  }

  testWidgets('lời chào theo tên bé, mở bảng đổi bé khi chạm', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    expect(find.text('Chào Na!'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('greeting-pill'))).height,
      greaterThanOrEqualTo(64),
    );
    await tester.tap(find.byKey(const ValueKey('greeting-pill')));
    await tester.pumpAndSettle();
    expect(find.text('Thêm bé'), findsOneWidget);
  });

  testWidgets('chưa biết bé thì chào chung', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app([
      ..._fakes(),
      kidsProvider.overrideWith((ref) async => const []),
    ], []));
    await tester.pumpAndSettle();
    expect(find.text('Chào bé!'), findsOneWidget);
  });

  testWidgets('thẻ môn học có nền trắng', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    final card = find.ancestor(
        of: find.text('Viết'), matching: find.byType(SubjectCard));
    final decorated = tester
        .widgetList<Container>(
            find.descendant(of: card, matching: find.byType(Container)))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.boxShadow != null && d.boxShadow!.isNotEmpty);
    expect((decorated.first.gradient! as LinearGradient).colors.first,
        AppColors.card);
  });

  testWidgets('thẻ Viết ghi "Nét, số, chữ cái" và tổng 49', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    final card = find.ancestor(
        of: find.text('Viết'), matching: find.byType(SubjectCard));
    expect(find.descendant(of: card, matching: find.text('Nét, số, chữ cái')),
        findsOneWidget);
    expect(tester.widget<SubjectCard>(card.first).total, 78);
  });

  testWidgets('hiện đủ nội dung trang chủ', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();

    expect(find.text('Bài hôm nay'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3 ngày học tuần này'), findsOneWidget);
    expect(find.text('Cấp 1'), findsOneWidget);
    expect(find.text('2/78'), findsOneWidget);
    expect(find.text('0/3 bài'), findsOneWidget);
    expect(
      find.text('Hôm nay mình viết Nét xiên và làm Toán nhé!'),
      findsOneWidget,
    );
    expect(find.text('Sắp có'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chỉ có Toán thì lời Chíp không nhắc viết', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app([
      ..._fakes(),
      todayLessonProvider.overrideWith((ref) async => const [MathItem(0)]),
    ], []));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay mình làm Toán nhé!'), findsOneWidget);
    expect(find.text('0/1 bài'), findsOneWidget);
  });

  testWidgets('bấm nút ▶ đi tới /lesson', (tester) async {
    _setSize(tester, 375, 667);
    final visited = <String>[];
    await tester.pumpWidget(_app(_fakes(), visited));
    await tester.pumpAndSettle();
    await tester.tap(_labeled('Bắt đầu bài hôm nay'));
    await tester.pumpAndSettle();
    expect(visited, ['/lesson']);
  });

  testWidgets('bấm thẻ Viết đi tới /subject/viet', (tester) async {
    _setSize(tester, 375, 667);
    final visited = <String>[];
    await tester.pumpWidget(_app(_fakes(), visited));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viết'));
    await tester.pumpAndSettle();
    expect(visited, ['/subject/viet']);
  });

  testWidgets('bấm ổ khóa mở cổng người lớn', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    await tester.tap(_labeled('Góc ba mẹ'));
    await tester.pumpAndSettle();
    expect(find.text('Dành cho ba mẹ'), findsOneWidget);
    expect(find.text('Góc ba mẹ sắp có'), findsNothing);
  });

  for (final size in const [Size(375, 667), Size(1024, 1366), Size(1366, 1024)]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('$name: mục "Chơi" mở Góc Chơi /game', (tester) async {
      _setSize(tester, size.width, size.height);
      final visited = <String>[];
      await tester.pumpWidget(_app(_fakes(), visited));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chơi'));
      await tester.pumpAndSettle();
      expect(visited, ['/game']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('$name: mục "Sưu tập" mở /collection', (tester) async {
      _setSize(tester, size.width, size.height);
      final visited = <String>[];
      await tester.pumpWidget(_app(_fakes(), visited));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sưu tập'));
      await tester.pumpAndSettle();
      expect(visited, ['/collection']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('$name: mục "Nhà Chíp" mở /house', (tester) async {
      _setSize(tester, size.width, size.height);
      final visited = <String>[];
      await tester.pumpWidget(_app(_fakes(), visited));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà Chíp'));
      await tester.pumpAndSettle();
      expect(visited, ['/house']);
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets('lỗi tải thì hiện số không, không văng', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app([
      ..._fakes().take(2),
      homeSummaryProvider.overrideWith((ref) async => throw StateError('x')),
      todayLessonProvider.overrideWith((ref) async => throw StateError('x')),
    ], []));
    await tester.pumpAndSettle();
    expect(find.text('Bài hôm nay'), findsOneWidget);
    expect(find.text('0/0 bài'), findsOneWidget);
    expect(find.text('0 ngày học tuần này'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('đang tải thì render ngay cấu trúc, không hiện vòng quay', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpAndSettle();
  });

  for (final size in const [Size(375, 667), Size(1024, 1366)]) {
    testWidgets('không tràn ở ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      _setSize(tester, size.width, size.height);
      await tester.pumpWidget(_app(_fakes(), []));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a reload keeps the old content instead of a spinner',
      (tester) async {
    _setSize(tester, 375, 667);
    final gate = Completer<HomeSummary>();
    var calls = 0;
    final overrides = [
      ..._fakes().take(2),
      ..._fakes().skip(3),
      homeSummaryProvider.overrideWith(
        (ref) => ++calls == 1
            ? Future.value(const HomeSummary(
                totalStars: 12,
                learnedDaysThisWeek: 3,
                masteredWriting: 2,
              ))
            : gate.future,
      ),
    ];
    await tester.pumpWidget(_app(overrides, []));
    await tester.pumpAndSettle();
    expect(find.text('Viết'), findsWidgets);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    container.invalidate(homeSummaryProvider);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Viết'), findsWidgets);
  });

  testWidgets('lesson card shows the lesson as done after finishing today',
      (tester) async {
    final visited = <String>[];
    await tester.pumpWidget(_app([
      ..._fakes(),
      homeSummaryProvider.overrideWith(
        (ref) async => const HomeSummary(
          totalStars: 12,
          learnedDaysThisWeek: 3,
          masteredWriting: 2,
          lessonsToday: 2,
        ),
      ),
    ], visited));
    await tester.pumpAndSettle();
    expect(find.text('0/3 bài'), findsNothing);
    expect(find.text('Xong 3/3 bài · 2 lần'), findsOneWidget);
  });

  testWidgets('lesson card shows 0/3 before any lesson today', (tester) async {
    await tester.pumpWidget(_app(_fakes(), <String>[]));
    await tester.pumpAndSettle();
    expect(find.text('0/3 bài'), findsOneWidget);
  });
}

void tabletLayoutTests() {
  for (final size in const [
    Size(1366, 1024),
    Size(1133, 744),
    Size(744, 1133),
    Size(960, 600),
  ]) {
    testWidgets('tablet: no overflow at $size', (tester) async {
      _setSize(tester, size.width, size.height);
      await tester.pumpWidget(_app(_fakes(), []));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  // Larger system text on top of the tablet x1.2 must not overflow.
  for (final (size, scale) in const [
    (Size(1133, 744), 1.3),
    (Size(1180, 820), 1.3),
    (Size(1133, 744), 1.5),
    (Size(1180, 820), 1.5),
    (Size(744, 1133), 1.5),
  ]) {
    testWidgets('tablet: no overflow at $size with user text $scale',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      _setSize(tester, size.width, size.height);
      await tester.pumpWidget(_app(_fakes(), []));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  Rect rectOf(WidgetTester t, Finder f) => t.getRect(f);

  testWidgets(
      'tablet landscape: hero and WeekPanel side by side, subjects in one row',
      (tester) async {
    _setSize(tester, 1366, 1024);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    final hero = rectOf(tester, find.byKey(const ValueKey('home-hero')));
    final week = rectOf(tester, find.byType(WeekPanel));
    expect(week.left, greaterThan(hero.right));
    expect((week.top - hero.top).abs(), lessThanOrEqualTo(1));
    expect(hero.height, greaterThanOrEqualTo(300));
    expect((week.height - hero.height).abs(), lessThanOrEqualTo(1));
    final tops = tester
        .widgetList(find.byType(SubjectCard))
        .map((w) => tester.getTopLeft(find.byWidget(w)).dy)
        .toList();
    expect(tops.length, 4);
    for (final y in tops) {
      expect((y - tops.first).abs(), lessThanOrEqualTo(1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet portrait: subjects 2x2, WeekPanel below them',
      (tester) async {
    _setSize(tester, 1024, 1366);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    final rects = tester
        .widgetList(find.byType(SubjectCard))
        .map((w) => tester.getRect(find.byWidget(w)))
        .toList();
    expect(rects.length, 4);
    expect((rects[0].top - rects[1].top).abs(), lessThanOrEqualTo(1));
    expect((rects[2].top - rects[3].top).abs(), lessThanOrEqualTo(1));
    expect(rects[2].top, greaterThan(rects[0].bottom));
    final hero = rectOf(tester, find.byKey(const ValueKey('home-hero')));
    expect(hero.height, greaterThanOrEqualTo(320));
    final week = rectOf(tester, find.byType(WeekPanel));
    expect(week.top, greaterThan(rects[3].bottom));
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(1366, 1024), Size(1024, 1366)]) {
    testWidgets('tablet $size: parent button at the right edge',
        (tester) async {
      _setSize(tester, size.width, size.height);
      await tester.pumpWidget(_app(_fakes(), []));
      await tester.pumpAndSettle();
      final lock = tester.getRect(find.byIcon(Icons.lock_outline_rounded));
      final hero = rectOf(tester, find.byKey(const ValueKey('home-hero')));
      // The 48 pt round button ends where the content column ends.
      expect(hero.right - lock.center.dx, lessThanOrEqualTo(24 + 1));
    });
  }

  for (final size in const [Size(1366, 1024), Size(1180, 820)]) {
    testWidgets('tablet landscape $size fills the screen without scrolling',
        (tester) async {
      _setSize(tester, size.width, size.height);
      await tester.pumpWidget(_app(_fakes(), []));
      await tester.pumpAndSettle();
      final cards = tester
          .widgetList(find.byType(SubjectCard))
          .map((w) => tester.getRect(find.byWidget(w)))
          .toList();
      expect(cards, hasLength(4));
      for (final r in cards) {
        expect(r.height, inInclusiveRange(180, 260));
        expect(size.height - r.bottom, lessThanOrEqualTo(80));
        expect(r.bottom, lessThanOrEqualTo(size.height));
      }
      final hero = rectOf(tester, find.byKey(const ValueKey('home-hero')));
      expect(hero.height, inInclusiveRange(300, 420));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('phone has no WeekPanel', (tester) async {
    _setSize(tester, 390, 844);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    expect(find.byType(WeekPanel), findsNothing);
    expect(find.byKey(const ValueKey('home-hero')), findsNothing);
  });

  testWidgets('tablet hero: play button 110, Chip >= 260 tall', (tester) async {
    _setSize(tester, 1366, 1024);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    final play = tester.getSize(find.byKey(const ValueKey('home-hero-play')));
    expect(play.width, greaterThanOrEqualTo(110));
    final chip = tester.getSize(find.byKey(const ValueKey('home-hero-chip')));
    expect(chip.height, greaterThanOrEqualTo(260));
    await tester.tap(_labeled('Bắt đầu bài hôm nay'));
    await tester.pumpAndSettle();
  });
}
