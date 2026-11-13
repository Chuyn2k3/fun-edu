import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/splash/splash_view.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';

import 'features/setup_helpers.dart';

/// Pumps real time a few times so drift answers and redirects run.
Future<void> _drain(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
  await settle(t);
}

String get _path => appRouter.routerDelegate.state.uri.path;

void main() {
  group('splash while loading', () {
    testWidgets('App shows SplashView, not a spinner, while the kid is loading',
        (t) async {
      setSize(t, 375, 667);
      appRouter.go('/');
      final never = Completer<int?>();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await t.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentKidIdProvider.overrideWith((ref) => never.future),
        ],
        child: const App(),
      ));
      await t.pump();
      expect(find.byKey(const ValueKey('splash')), findsOneWidget);
      expect(find.byType(SplashView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('splash fades out once data is ready', (t) async {
      setSize(t, 375, 667);
      appRouter.go('/');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      late int id;
      await t.runAsync(() async {
        id = await KidRepository(db)
            .addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
        await placeKid(db, id);
      });
      final gate = Completer<int?>();
      await t.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentKidIdProvider.overrideWith((ref) => gate.future),
        ],
        child: const App(),
      ));
      await t.pump();
      expect(find.byKey(const ValueKey('splash')), findsOneWidget);

      gate.complete(id);
      // Let drift answer the remaining providers, then run the 250 ms fade.
      for (var i = 0; i < 6; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('splash')), findsNothing);
      expect(find.text('Bài hôm nay'), findsOneWidget);
    });
  });

  Future<void> openParentCorner(WidgetTester t, {bool push = false}) async {
    if (push) {
      appRouter.push('/parent');
    } else {
      appRouter.go('/parent');
    }
    await settle(t);
    await passGate(t);
  }

  group('leaving the parent corner applies the placement rule', () {
    testWidgets('redo placement, then "Về màn bé" goes to placement',
        (t) async {
      await pumpRealApp(t, seed: (db) async {
        final id = await KidRepository(db)
            .addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
        await placeKid(db, id);
      });
      expect(find.text('Bài hôm nay'), findsOneWidget);
      await openParentCorner(t);
      await t.tap(find.text('Cài đặt'));
      await settle(t);
      await t.tap(find.textContaining('Làm lại bài xếp cấp'));
      await settle(t);
      await t.tap(find.text('Về màn bé'));
      await _drain(t);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_path, '/placement');
      expect(find.text('Bài hôm nay'), findsNothing);
    });

    testWidgets(
        'deleting the current kid leaves an unplaced kid, then "Về màn bé" '
        'goes to placement', (t) async {
      await pumpRealApp(t, seed: (db) async {
        final r = KidRepository(db);
        final id =
            await r.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
        await placeKid(db, id);
        await r.addKid(nickname: 'Bi', avatar: kidAvatars[1], age: 4);
        await r.setCurrentKid(id);
      });
      await openParentCorner(t);
      await t.tap(find.text('Hồ sơ'));
      await settle(t);
      await t.tap(find.text('Xóa').first);
      await settle(t);
      await t.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await settle(t);
      await t.tap(find.text('Về màn bé'));
      await _drain(t);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_path, '/placement');
    });

    testWidgets(
        'redo placement, then system back out of the corner goes to '
        'placement', (t) async {
      await pumpRealApp(t, seed: (db) async {
        final id = await KidRepository(db)
            .addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
        await placeKid(db, id);
      });
      await openParentCorner(t, push: true);
      await t.tap(find.text('Cài đặt'));
      await settle(t);
      await t.tap(find.textContaining('Làm lại bài xếp cấp'));
      await settle(t);
      await t.binding.handlePopRoute();
      await _drain(t);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_path, '/placement');
      expect(find.text('Bài hôm nay'), findsNothing);
    });
  });

  testWidgets('system back from a pushed kid screen returns home', (t) async {
    await pumpRealApp(t, seed: (db) async {
      final id = await KidRepository(db)
          .addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
      await placeKid(db, id);
    });
    appRouter.push('/subject/toan');
    await settle(t);
    expect(find.text('Bài hôm nay'), findsNothing);
    expect(_path, '/subject/toan');

    await t.binding.handlePopRoute();
    await settle(t);
    expect(_path, '/');
    expect(find.text('Bài hôm nay'), findsOneWidget);

    // A second back on home is not swallowed by the guard.
    appRouter.push('/subject/viet');
    await settle(t);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.text('Bài hôm nay'), findsOneWidget);
  });
}
