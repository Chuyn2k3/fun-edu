import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/travel/trip_progress.dart';
import 'package:funedu/router.dart';

import 'game_test_helpers.dart';

Future<void> _seed(AppDatabase db, int kid, {required int step, int shown = 0}) async {
  await db.into(db.gameCounters).insertOnConflictUpdate(GameCountersCompanion
      .insert(kidId: kid, key: 'trip.step', value: Value(step)));
  await markTripShown(db, kid, shown);
}

Future<void> _open(WidgetTester t) async {
  appRouter.go('/game/postcards');
  await pumpReal(t, times: 10);
}

void main() {
  testWidgets('earned postcards show their name, the rest a question mark',
      (t) async {
    await bootGame(t, seed: (db, kid) => _seed(db, kid, step: 9, shown: 9));
    await _open(t);
    expect(find.descendant(
            of: find.byKey(const ValueKey('postcard-ho-guom')),
            matching: find.text('Hồ Gươm')),
        findsOneWidget);
    expect(find.descendant(
            of: find.byKey(const ValueKey('postcard-vinh-ha-long')),
            matching: find.text('Vịnh Hạ Long')),
        findsOneWidget);
    expect(find.descendant(
            of: find.byKey(const ValueKey('postcard-van-mieu')),
            matching: find.text('?')),
        findsOneWidget);
  });

  testWidgets('a postcard not reached yet makes Chíp say so', (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seed(db, kid, step: 9, shown: 9));
    await _open(t);
    await t.tap(find.byKey(const ValueKey('postcard-van-mieu')));
    await t.pump();
    expect(h.speaker.spoken.last, 'Chíp chưa tới đây, mình đi tiếp nhé!');
  });

  testWidgets('an earned postcard opens big and is read aloud', (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seed(db, kid, step: 9, shown: 9));
    await _open(t);
    await t.tap(find.byKey(const ValueKey('postcard-ho-guom')));
    await pumpReal(t);
    expect(find.byKey(const ValueKey('postcard-big')), findsOneWidget);
    expect(h.speaker.spoken.last, startsWith('Hồ Gươm. '));
  });

  testWidgets('postcards from another device are revealed, then marked shown',
      (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seed(db, kid, step: 9, shown: 4));
    await _open(t);
    expect(find.byKey(const ValueKey('postcard-reveal')), findsOneWidget);
    expect(find.descendant(
            of: find.byKey(const ValueKey('postcard-reveal')),
            matching: find.text('Vịnh Hạ Long')),
        findsOneWidget);
    await t.tap(find.byKey(const ValueKey('postcard-reveal-next')));
    await pumpReal(t, times: 6);
    expect(find.byKey(const ValueKey('postcard-reveal')), findsNothing);
    expect(await t.runAsync(() => tripShown(h.db, h.kid)), 9);
  });

  testWidgets('a sync during the reveal marks only what was shown',
      (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seed(db, kid, step: 9, shown: 4));
    await _open(t);
    expect(find.byKey(const ValueKey('postcard-reveal')), findsOneWidget);
    await t.runAsync(() => h.db.into(h.db.gameCounters).insertOnConflictUpdate(
        GameCountersCompanion.insert(
            kidId: h.kid, key: 'trip.step', value: const Value(40))));
    containerOf(t).read(gameDataRevisionProvider.notifier).state++;
    await pumpReal(t, times: 4);
    while (find.byKey(const ValueKey('postcard-reveal-next')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const ValueKey('postcard-reveal-next')));
      await pumpReal(t, times: 4);
    }
    expect(await t.runAsync(() => tripShown(h.db, h.kid)), 9);
  });

  for (final (size, scale) in const [
    (Size(375, 667), 1.3),
    (Size(1180, 820), 1.0),
  ]) {
    testWidgets('lays out cleanly at $size, text x$scale', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await bootGame(t, size: size, seed: (db, kid) => _seed(db, kid, step: 40, shown: 40));
      await _open(t);
      expect(t.takeException(), isNull);
    });
  }
}
