import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/travel_screen.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/travel/trip.dart';
import 'package:funedu/game/travel/trip_progress.dart';
import 'package:funedu/router.dart';

import 'game_test_helpers.dart';

Future<void> _seedStep(AppDatabase db, int kid, int step) =>
    db.into(db.gameCounters).insertOnConflictUpdate(GameCountersCompanion
        .insert(kidId: kid, key: 'trip.step', value: Value(step)));

Future<int> _step(WidgetTester t, GameHarness h) async =>
    (await t.runAsync(() => GameRepository(h.db, kidId: h.kid).tripStep()))!;

Future<int> _stars(WidgetTester t, GameHarness h) async =>
    (await t.runAsync(() => GameRepository(h.db, kidId: h.kid).totalStars()))!;

Future<void> _open(WidgetTester t) async {
  appRouter.go('/game/travel');
  // Loading reads ~40 glyph files: wait for the first question.
  for (var i = 0; i < 40 && debugTravelQuestion == null; i++) {
    await pumpReal(t, times: 2);
  }
  expect(debugTravelQuestion, isNotNull);
}

int _right() => debugTravelQuestion!.correctIndex;

Future<void> _tapKey(WidgetTester t, int i) async {
  await t.tap(find.byKey(ValueKey('race-key-$i')));
  await t.pump();
}

/// Lets the writes land and Chíp finish hopping.
Future<void> _settleMove(WidgetTester t) =>
    pumpReal(t, times: 12, step: const Duration(milliseconds: 120));

Future<void> _answer(WidgetTester t) async {
  await _tapKey(t, _right());
  await _settleMove(t);
  if (find.byKey(const ValueKey('trip-continue')).evaluate().isNotEmpty) {
    await t.tap(find.byKey(const ValueKey('trip-continue')));
    await _settleMove(t);
  }
}

/// Serves every asset except geography pictures, which fail to load.
class _BrokenGeoBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('/geo-')) throw FlutterError('broken $key');
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('right first try moves two steps and pays a star', (t) async {
    final h = await bootGame(t);
    await _open(t);
    final before = await _stars(t, h);
    await _tapKey(t, _right());
    await _settleMove(t);
    expect(await _step(t, h), 2);
    expect(await _stars(t, h), before + 1);
  });

  testWidgets('wrong then right moves one step, no star', (t) async {
    final h = await bootGame(t);
    await _open(t);
    final before = await _stars(t, h);
    await _tapKey(t, (_right() + 1) % 3);
    await pumpReal(t);
    await _tapKey(t, _right());
    await _settleMove(t);
    expect(await _step(t, h), 1);
    expect(await _stars(t, h), before);
  });

  testWidgets('reaching a stop shows the postcard and waits for Đi tiếp',
      (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seedStep(db, kid, 2));
    await _open(t);
    final first = debugTravelQuestion;
    await _tapKey(t, _right());
    await _settleMove(t);
    expect(find.byKey(const ValueKey('trip-postcard')), findsOneWidget);
    expect(find.text('Hồ Gươm'), findsWidgets);
    expect(h.speaker.spoken.last, startsWith('Chíp tới Hồ Gươm rồi!'));
    expect(debugTravelQuestion, same(first));
    await t.tap(find.byKey(const ValueKey('trip-continue')));
    await _settleMove(t);
    expect(find.byKey(const ValueKey('trip-postcard')), findsNothing);
    expect(debugTravelQuestion, isNot(same(first)));
  });

  testWidgets('crossing a stop on a two-step move', (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seedStep(db, kid, 3));
    await _open(t);
    await _tapKey(t, _right());
    await _settleMove(t);
    expect(find.byKey(const ValueKey('trip-postcard')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('trip-continue')));
    await _settleMove(t);
    expect(await _step(t, h), 5);
  });

  testWidgets('double tap counts once', (t) async {
    final h = await bootGame(t);
    await _open(t);
    final before = await _stars(t, h);
    final i = _right();
    await _tapKey(t, i);
    await _tapKey(t, i);
    await _settleMove(t);
    expect(await _step(t, h), 2);
    expect(await _stars(t, h), before + 1);
  });

  testWidgets('keys are locked while Chíp hops', (t) async {
    final h = await bootGame(t);
    await _open(t);
    await _tapKey(t, _right());
    // Mid-move: tap every key.
    for (var i = 0; i < 3; i++) {
      await _tapKey(t, i);
    }
    await _settleMove(t);
    expect(await _step(t, h), 2);
  });

  testWidgets('leaving mid-round keeps progress', (t) async {
    final h = await bootGame(t);
    await _open(t);
    for (var i = 0; i < 3; i++) {
      await _answer(t);
    }
    await t.tap(find.byKey(const ValueKey('trip-back')));
    await pumpReal(t, times: 6);
    expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/game');
    expect(await _step(t, h), 6);
  });

  testWidgets('ten answers show the summary', (t) async {
    final h = await bootGame(t);
    await _open(t);
    final before = await _stars(t, h);
    for (var i = 0; i < 10; i++) {
      await _answer(t);
    }
    expect(find.byKey(const ValueKey('trip-summary')), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(await _stars(t, h), before + 10);
    await t.tap(find.byKey(const ValueKey('trip-again')));
    await t.pump();
    expect(find.byKey(const ValueKey('trip-summary')), findsNothing);
    for (var i = 0; i < 40 && debugTravelQuestion == null; i++) {
      await pumpReal(t, times: 2);
    }
    expect(find.byKey(const ValueKey('trip-summary')), findsNothing);
    expect(debugTravelQuestion, isNotNull);
  });

  testWidgets('finished trip shows trip-done and still plays', (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seedStep(db, kid, 120));
    await _open(t);
    expect(find.byKey(const ValueKey('trip-done')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('trip-done-play')));
    await pumpReal(t);
    final before = await _stars(t, h);
    await _answer(t);
    expect(await _step(t, h), 120);
    expect(await _stars(t, h), before + 1);
  });


  testWidgets('playing never hides postcards earned on another device',
      (t) async {
    final h = await bootGame(t, seed: (db, kid) async {
      await _seedStep(db, kid, 22);
      await markTripShown(db, kid, 0);
    });
    await _open(t);
    await _answer(t);
    expect(await _step(t, h), 24);
    expect(await t.runAsync(() => tripShown(h.db, h.kid)), 0);
  });

  testWidgets('a postcard seen in the game is not new on the hub', (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seedStep(db, kid, 2));
    await _open(t);
    final c = containerOf(t);
    // Keep the provider alive like the hub does under the game.
    final sub = c.listen(tripProgressProvider, (_, __) {});
    addTearDown(sub.close);
    await _answer(t);
    await pumpReal(t, times: 6);
    expect(await t.runAsync(() => tripShown(h.db, h.kid)), 4);
    expect((await t.runAsync(() => c.read(tripProgressProvider.future)))!.unseen, 0);
  });

  testWidgets('leaving right after an answer throws nothing', (t) async {
    await bootGame(t);
    await _open(t);
    await _tapKey(t, _right());
    await t.tap(find.byKey(const ValueKey('trip-back')));
    await pumpReal(t, times: 12, step: const Duration(milliseconds: 120));
    expect(t.takeException(), isNull);
  });

  testWidgets('answer keys stay big on iPad landscape', (t) async {
    await bootGame(t, size: const Size(1180, 820));
    await _open(t);
    final key = t.getSize(find.byKey(const ValueKey('race-key-0')));
    expect(key.height, greaterThanOrEqualTo(80));
  });

  testWidgets('double tap on Chơi tiếp starts one round', (t) async {
    final h = await bootGame(t);
    await _open(t);
    for (var i = 0; i < 10; i++) {
      await _answer(t);
    }
    final spokenBefore = h.speaker.spoken.length;
    await t.tap(find.byKey(const ValueKey('trip-again')));
    await t.tap(find.byKey(const ValueKey('trip-again')), warnIfMissed: false);
    for (var i = 0; i < 40; i++) {
      await pumpReal(t, times: 2);
    }
    final after = h.speaker.spoken.sublist(spokenBefore);
    expect(after.length, 1, reason: '$after');
  });

  testWidgets('broken stop image shows the name', (t) async {
    await t.pumpWidget(MaterialApp(
      home: DefaultAssetBundle(
        bundle: _BrokenGeoBundle(),
        child: Center(
          child: TripStamp(stop: tripStops.first, size: 96, reached: true),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('Hồ Gươm'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final (size, scale) in const [
    (Size(375, 667), 1.3),
    (Size(390, 844), 1.0),
    (Size(820, 1180), 1.0),
    (Size(1180, 820), 1.0),
  ]) {
    testWidgets('lays out cleanly at $size, text x$scale', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await bootGame(t, size: size);
      await _open(t);
      expect(t.takeException(), isNull);
    });
  }
}
