import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/learning/lesson_item.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/ui/theme/tokens.dart';
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

void main() {
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
    expect(decorated.first.color, AppColors.card);
  });

  testWidgets('hiện đủ nội dung trang chủ', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();

    expect(find.text('Bài hôm nay'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3 ngày học tuần này'), findsOneWidget);
    expect(find.text('Cấp 1'), findsOneWidget);
    expect(find.text('2/15'), findsOneWidget);
    expect(find.text('0/3 bài'), findsOneWidget);
    expect(
      find.text('Hôm nay mình viết Nét xiên và làm Toán nhé!'),
      findsOneWidget,
    );
    expect(find.text('Sắp có'), findsNWidgets(2));
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

  testWidgets('mục điều hướng khác hiện Sắp có', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chơi'));
    await tester.pump();
    expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Sắp có'),
        ),
        findsOneWidget);
  });

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

  testWidgets('đang tải thì hiện vòng quay', (tester) async {
    _setSize(tester, 375, 667);
    await tester.pumpWidget(_app(_fakes(), []));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
