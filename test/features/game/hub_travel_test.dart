import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/explore/explore_flags.dart';
import 'package:funedu/features/game/game_hub_screen.dart';
import 'package:funedu/game/travel/trip_progress.dart';
import 'package:funedu/router.dart';

import 'game_test_helpers.dart';

Future<void> _seed(AppDatabase db, int kid, {required int step, int shown = 0}) async {
  await db.into(db.gameCounters).insertOnConflictUpdate(GameCountersCompanion
      .insert(kidId: kid, key: 'trip.step', value: Value(step)));
  await markTripShown(db, kid, shown);
}

Future<void> _openHub(WidgetTester t) async {
  appRouter.go('/game');
  await pumpReal(t, times: 8);
  expect(find.byType(GameHubScreen), findsOneWidget);
}

final _on = [exploreIslandEnabledProvider.overrideWithValue(true)];

String _path() => appRouter.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('switch off: no travel game and no postcard book', (t) async {
    await bootGame(t);
    await _openHub(t);
    expect(find.byKey(const ValueKey('hub-travel')), findsNothing);
    expect(find.byKey(const ValueKey('hub-postcards')), findsNothing);
    expect(find.byKey(const ValueKey('hub-race')), findsOneWidget);
  });

  testWidgets('switch on: the travel card shows postcards and opens the game',
      (t) async {
    await bootGame(t, extra: _on, seed: (db, kid) => _seed(db, kid, step: 9, shown: 9));
    await _openHub(t);
    expect(find.text('2/30 bưu thiếp'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-race')), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('hub-travel')));
    await t.tap(find.byKey(const ValueKey('hub-travel')));
    await pumpReal(t, times: 4);
    expect(_path(), '/game/travel');
  });

  testWidgets('switch on: the postcard book opens from the hub', (t) async {
    await bootGame(t, extra: _on, seed: (db, kid) => _seed(db, kid, step: 9, shown: 9));
    await _openHub(t);
    await t.ensureVisible(find.byKey(const ValueKey('hub-postcards')));
    await pumpReal(t);
    expect(find.byKey(const ValueKey('hub-postcards-new')), findsNothing);
    await t.tap(find.byKey(const ValueKey('hub-postcards')));
    await pumpReal(t, times: 4);
    expect(_path(), '/game/postcards');
  });

  testWidgets('postcards from another device light up the book', (t) async {
    await bootGame(t, extra: _on, seed: (db, kid) => _seed(db, kid, step: 9, shown: 4));
    await _openHub(t);
    await t.ensureVisible(find.byKey(const ValueKey('hub-postcards')));
    await pumpReal(t);
    expect(find.byKey(const ValueKey('hub-postcards-new')), findsOneWidget);
  });

  for (final (size, scale) in const [
    (Size(375, 667), 1.3),
    (Size(390, 844), 1.0),
    (Size(820, 1180), 1.0),
    (Size(1180, 820), 1.3),
    (Size(1366, 1024), 1.0),
  ]) {
    testWidgets('switch on: hub lays out at $size, text x$scale', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await bootGame(t, size: size, extra: _on);
      await _openHub(t);
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('hub-travel')), findsOneWidget);
    });
  }
}
