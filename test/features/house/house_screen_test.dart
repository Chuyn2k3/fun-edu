import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/house/house_screen.dart';
import 'package:funedu/house/house_repository.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/widgets/floating_nav_bar.dart';
import 'package:funedu/ui/widgets/nav_rail.dart';
import 'package:funedu/voice/speaker.dart';
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

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _app(List<Override> overrides) {
  final router = GoRouter(
    initialLocation: '/house',
    routes: [
      GoRoute(path: '/house', builder: (_, __) => const HouseScreen()),
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
      GoRoute(path: '/game', builder: (_, __) => const Scaffold(body: Text('game'))),
      GoRoute(
          path: '/collection',
          builder: (_, __) => const Scaffold(body: Text('collection'))),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<({AppDatabase db, int kidId})> _seedDb({int stars = 20}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final kids = KidRepository(db);
  final kidId = await kids.addKid(
    nickname: 'Bông',
    avatar: AppImages.chipMain,
    age: 5,
  );
  if (stars > 0) {
    final progress = ProgressRepository(db, kidId: kidId);
    // recordLessonCompleted gives itemsCompleted + 2 stars.
    await progress.recordLessonCompleted(itemsCompleted: stars - 2);
  }
  return (db: db, kidId: kidId);
}

void main() {
  for (final size in const [
    Size(375, 667),
    Size(390, 844),
    Size(820, 1180),
    Size(1194, 834),
  ]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('$name: renders Feed and Decor tabs without overflow',
        (tester) async {
      _setSize(tester, size);
      final seeded = await _seedDb(stars: 20);
      addTearDown(seeded.db.close);
      final speaker = _SpySpeaker();

      await tester.pumpWidget(_app([
        databaseProvider.overrideWithValue(seeded.db),
        speakerProvider.overrideWithValue(speaker),
        houseClockProvider.overrideWithValue(() => DateTime(2026, 11, 18)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Nhà của Chíp'), findsOneWidget);
      if (size.shortestSide >= 600) {
        expect(find.byType(NavRail), findsOneWidget);
      } else {
        expect(find.byType(FloatingNavBar), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('house-tab-decor')));
      await tester.pumpAndSettle();
      expect(find.text('Phòng nắng ấm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('petting Chíp speaks friendly message with kid name',
      (tester) async {
    _setSize(tester, const Size(390, 844));
    final seeded = await _seedDb(stars: 10);
    addTearDown(seeded.db.close);
    final speaker = _SpySpeaker();

    await tester.pumpWidget(_app([
      databaseProvider.overrideWithValue(seeded.db),
      speakerProvider.overrideWithValue(speaker),
      houseClockProvider.overrideWithValue(() => DateTime(2026, 11, 18)),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('house-pet-chip')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(speaker.spoken, isNotEmpty);
    expect(speaker.spoken.last, contains('Bông'));

    // Let bounce timer finish cleanly.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('feeding free treat & buying decor persist without touching total learning stars',
      (tester) async {
    _setSize(tester, const Size(1194, 834));
    final seeded = await _seedDb(stars: 20);
    addTearDown(seeded.db.close);
    final speaker = _SpySpeaker();

    await tester.pumpWidget(_app([
      databaseProvider.overrideWithValue(seeded.db),
      speakerProvider.overrideWithValue(speaker),
      houseClockProvider.overrideWithValue(() => DateTime(2026, 11, 18)),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('20 sao'), findsOneWidget);

    // Feed daily free acorn (0 stars, +10 XP)
    await tester.tap(find.byKey(const ValueKey('house-treat-acorn_free')));
    await tester.pumpAndSettle();
    expect(find.text('Đã ăn hôm nay'), findsOneWidget);
    expect(find.text('20 sao'), findsOneWidget);

    // Switch to Decor tab & buy wall_forest (8 stars)
    await tester.tap(find.byKey(const ValueKey('house-tab-decor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('house-item-wall_forest')));
    await tester.pumpAndSettle();

    // Available stars in house dropped to 12, while DB learning stars remain 20!
    expect(find.text('12 sao'), findsOneWidget);
    final learningStars =
        await ProgressRepository(seeded.db, kidId: seeded.kidId).totalStars();
    expect(learningStars, 20);

    // Cleanly finish bounce timer.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('120fps custom feed, decor, and pet FX step cleanly without errors',
      (tester) async {
    _setSize(tester, const Size(390, 844));
    final seeded = await _seedDb(stars: 30);
    addTearDown(seeded.db.close);
    final speaker = _SpySpeaker();

    await tester.pumpWidget(_app([
      databaseProvider.overrideWithValue(seeded.db),
      speakerProvider.overrideWithValue(speaker),
      houseClockProvider.overrideWithValue(() => DateTime(2026, 11, 18)),
    ]));
    await tester.pumpAndSettle();

    // 1. Feed star cake (triggers level-up + flying treat + confetti burst)
    final starCake = find.byKey(const ValueKey('house-treat-star_cake'));
    await tester.ensureVisible(starCake);
    await tester.pumpAndSettle();
    await tester.tap(starCake);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 70));
    }
    await tester.pumpAndSettle();
    expect(find.text('Lên cấp 2!'), findsOneWidget);

    // 2. Decorate wall with sparkle shimmer
    final decorTab = find.byKey(const ValueKey('house-tab-decor'));
    await tester.ensureVisible(decorTab);
    await tester.pumpAndSettle();
    await tester.tap(decorTab);
    await tester.pumpAndSettle();
    final wallForest = find.byKey(const ValueKey('house-item-wall_forest'));
    await tester.ensureVisible(wallForest);
    await tester.pumpAndSettle();
    await tester.tap(wallForest);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();
    expect(find.text('Mở mới!'), findsOneWidget);

    // 3. Pet Chíp with floating hearts
    final petTarget = find.byKey(const ValueKey('house-pet-chip'));
    await tester.ensureVisible(petTarget);
    await tester.pumpAndSettle();
    await tester.tap(petTarget);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
