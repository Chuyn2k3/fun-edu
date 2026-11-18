import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/collection/collection_model.dart';
import 'package:funedu/collection/collection_provider.dart';
import 'package:funedu/features/collection/collection_screen.dart';
import 'package:funedu/ui/widgets/floating_nav_bar.dart';
import 'package:funedu/ui/widgets/nav_rail.dart';
import 'package:funedu/voice/speaker.dart';
import 'package:funedu/worksheet/worksheet_printer.dart';
import 'package:go_router/go_router.dart';

class _SpySpeaker implements Speaker {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}

class _SpyPrinter extends WorksheetPrinter {
  final sharedFiles = <String>[];
  final sharedBytes = <Uint8List>[];

  @override
  Future<void> printPdf(Uint8List bytes, {required String jobName}) async {}

  @override
  Future<void> sharePdf(Uint8List bytes, {required String fileName}) async {
    sharedFiles.add(fileName);
    sharedBytes.add(bytes);
  }
}

LearningSnapshot _richSnapshot({
  int viewedYear = 2026,
  int viewedMonth = 11,
  Set<int> learnedDays = const {2, 5, 11, 18},
}) =>
    LearningSnapshot(
      kidName: 'Bông',
      totalStars: 55,
      totalLessons: 6,
      totalLearnedDays: 5,
      learnedDaysThisWeek: 3,
      masteredWriting: 12,
      mathLevelIndex: 2,
      vietnameseLevelIndex: 2,
      englishLevelIndex: 2,
      viewedYear: viewedYear,
      viewedMonth: viewedMonth,
      learnedDaysInMonth: learnedDays,
      learnedToday: true,
    );

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _app({
  required List<Override> overrides,
  List<String>? visited,
}) {
  final router = GoRouter(
    initialLocation: '/collection',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) {
          visited?.add('/');
          return const Scaffold(body: Text('home stub'));
        },
      ),
      GoRoute(
        path: '/game',
        builder: (_, __) {
          visited?.add('/game');
          return const Scaffold(body: Text('game stub'));
        },
      ),
      GoRoute(
        path: '/collection',
        builder: (_, __) => const CollectionScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  for (final size in const [
    Size(375, 667),
    Size(390, 844),
    Size(820, 1180),
    Size(1194, 834),
  ]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('$name: renders all 3 Collection tabs without overflow',
        (tester) async {
      _setSize(tester, size);
      final speaker = _SpySpeaker();
      DateTime clock() => DateTime(2026, 11, 18);

      await tester.pumpWidget(_app(overrides: [
        collectionClockProvider.overrideWithValue(clock),
        speakerProvider.overrideWithValue(speaker),
        collectionSnapshotProvider.overrideWith((ref) async {
          final viewed = ref.watch(collectionMonthProvider);
          return _richSnapshot(
            viewedYear: viewed.year,
            viewedMonth: viewed.month,
          );
        }),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Sưu tập của Bông'), findsOneWidget);
      if (size.shortestSide >= 600) {
        expect(find.byType(NavRail), findsOneWidget);
      } else {
        expect(find.byType(FloatingNavBar), findsOneWidget);
      }

      // Switch to Calendar tab.
      await tester.tap(find.byKey(const ValueKey('collection-tab-calendar')));
      await tester.pumpAndSettle();
      expect(find.text('Tháng 11 / 2026'), findsOneWidget);

      // Switch to Certificates tab.
      await tester.tap(find.byKey(const ValueKey('collection-tab-certificates')));
      await tester.pumpAndSettle();
      expect(find.text('Bé Chăm Học'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tapping unlocked sticker opens detail dialog and speaks praise',
      (tester) async {
    _setSize(tester, const Size(390, 844));
    final speaker = _SpySpeaker();
    await tester.pumpWidget(_app(overrides: [
      collectionClockProvider.overrideWithValue(() => DateTime(2026, 11, 18)),
      speakerProvider.overrideWithValue(speaker),
      collectionSnapshotProvider
          .overrideWith((ref) async => _richSnapshot()),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('learning-sticker-first_lesson')));
    await tester.pumpAndSettle();

    expect(find.text('Bước đầu tiên'), findsWidgets);
    expect(speaker.spoken, isNotEmpty);
    expect(speaker.spoken.last, contains('Bông'));

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('calendar month navigation goes back and caps at current month',
      (tester) async {
    _setSize(tester, const Size(390, 844));
    await tester.pumpWidget(_app(overrides: [
      collectionClockProvider.overrideWithValue(() => DateTime(2026, 11, 18)),
      speakerProvider.overrideWithValue(_SpySpeaker()),
      collectionSnapshotProvider.overrideWith((ref) async {
        final viewed = ref.watch(collectionMonthProvider);
        return _richSnapshot(
          viewedYear: viewed.year,
          viewedMonth: viewed.month,
          learnedDays: viewed.month == 11 ? {2, 18} : {10},
        );
      }),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('collection-tab-calendar')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 11 / 2026'), findsOneWidget);
    expect(find.text('Tháng 11: 2 ngày học'), findsOneWidget);

    // Next month is disabled at current month.
    await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 11 / 2026'), findsOneWidget);

    // Previous month works.
    await tester.tap(find.byKey(const ValueKey('calendar-prev-month')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 10 / 2026'), findsOneWidget);
    expect(find.text('Tháng 10: 1 ngày học'), findsOneWidget);

    // Going forward returns to November.
    await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 11 / 2026'), findsOneWidget);
  });

  testWidgets(
      'opening unlocked certificate shows kid name, speaks, and exports PDF',
      (tester) async {
    _setSize(tester, const Size(820, 1180));
    final speaker = _SpySpeaker();
    final printer = _SpyPrinter();
    await tester.pumpWidget(_app(overrides: [
      collectionClockProvider.overrideWithValue(() => DateTime(2026, 11, 18)),
      speakerProvider.overrideWithValue(speaker),
      worksheetPrinterProvider.overrideWithValue(printer),
      collectionSnapshotProvider
          .overrideWith((ref) async => _richSnapshot()),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('collection-tab-certificates')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('learning-cert-cert_diligent')));
    await tester.pumpAndSettle();

    expect(find.text('CHÍP CHÍP TRAO TẶNG BÉ'), findsOneWidget);
    expect(find.text('Bông'), findsOneWidget);
    expect(speaker.spoken.last, contains('Bé Chăm Học'));

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('cert-export-pdf')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(printer.sharedFiles, ['giay-khen-cert_diligent.pdf']);
    expect(printer.sharedBytes.single.length, greaterThan(1000));
  });
}
