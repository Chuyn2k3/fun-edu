import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/garage_screen.dart';
import 'package:funedu/features/game/reward_offer_sheet.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/router.dart';

import 'game_test_helpers.dart';

Future<void> _seed(AppDatabase db, int kid,
    {int stars = 12, List<String> own = const ['rocket_blue']}) async {
  await db.into(db.gameProfile).insert(GameProfileCompanion.insert(
      kidId: Value(kid), cosmicStars: Value(stars)));
  for (final id in own) {
    await db
        .into(db.gameItems)
        .insert(GameItemsCompanion.insert(kidId: kid, itemId: id));
  }
}

Future<void> _openGarage(WidgetTester t) async {
  appRouter.go('/game/garage');
  await pumpReal(t, times: 6);
  expect(find.byType(GarageScreen), findsOneWidget);
}

Finder _item(String id) => find.byKey(ValueKey('garage-item-$id'));

Future<({String rocket, String trail})> _selected(
        WidgetTester t, GameHarness h) async =>
    (await t.runAsync(() => GameRepository(h.db, kidId: h.kid).selected()))!;

void main() {
  testWidgets('selecting an owned rocket persists and the next race uses it',
      (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seed(db, kid));
    await _openGarage(t);
    expect(find.text('Tên lửa cam'), findsWidgets); // the one in use
    await t.tap(_item('rocket_blue'));
    await pumpReal(t, times: 4);
    expect((await _selected(t, h)).rocket, 'rocket_blue');
    expect(
        find.descendant(
            of: _item('rocket_blue'), matching: find.text('Đang dùng')),
        findsOneWidget);

    await openRace(t, 'toan');
    expect(raceState(t).rocket, 'rocket_blue');
  });

  testWidgets('selecting an owned trail persists', (t) async {
    final h = await bootGame(t,
        seed: (db, kid) => _seed(db, kid, own: ['trail_rainbow']));
    await _openGarage(t);
    await t.tap(find.byKey(const ValueKey('garage-tab-trails')));
    await pumpReal(t, times: 4);
    await t.tap(_item('trail_rainbow'));
    await pumpReal(t, times: 4);
    expect((await _selected(t, h)).trail, 'trail_rainbow');
  });

  testWidgets('locked items show the stars to their milestone', (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seed(db, kid));
    await _openGarage(t);
    // 12 stars, one pick made: green comes at 40, purple at 115.
    expect(
        find.descendant(
            of: _item('rocket_green'),
            matching: find.text('Còn 28 sao vũ trụ')),
        findsOneWidget);
    expect(
        find.descendant(
            of: _item('rocket_purple'),
            matching: find.text('Còn 103 sao vũ trụ')),
        findsOneWidget);
    // Tapping a locked item never equips it.
    await t.tap(_item('rocket_green'));
    await pumpReal(t, times: 4);
    expect((await _selected(t, h)).rocket, 'rocket_orange');

    await t.tap(find.byKey(const ValueKey('garage-tab-trails')));
    await pumpReal(t, times: 4);
    expect(
        find.descendant(
            of: _item('trail_rainbow'),
            matching: find.text('Còn 13 sao vũ trụ')),
        findsOneWidget);
  });

  testWidgets('an item waiting in an offer opens the offer sheet', (t) async {
    final h = await bootGame(t, seed: (db, kid) => _seed(db, kid, own: []));
    await _openGarage(t);
    expect(
        find.descendant(
            of: _item('rocket_blue'), matching: find.text('Quà chờ bé!')),
        findsOneWidget);
    await t.tap(_item('rocket_blue'));
    await pumpReal(t, times: 6);
    expect(find.byType(RewardOfferSheet), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('offer-rocket_blue')));
    await pumpReal(t, times: 6);
    expect(find.byType(RewardOfferSheet), findsNothing);
    final owned =
        (await t.runAsync(() => GameRepository(h.db, kidId: h.kid).owned()))!;
    expect(owned, contains('rocket_blue'));
    expect(
        find.descendant(of: _item('rocket_blue'), matching: find.text('MỚI')),
        findsOneWidget);
  });

  testWidgets('"Bay thử!" plays a 2 s take-off, then lands again', (t) async {
    await bootGame(t, reduceMotion: false, seed: (db, kid) => _seed(db, kid));
    await _openGarage(t);
    final stage = find.byKey(const ValueKey('garage-stage'));
    expect(stage, findsOneWidget);
    RocketStageState s() => t.state<RocketStageState>(find.byType(RocketStage));
    expect(s().flying, isFalse);
    Future<void> frames(int ms) async {
      for (var i = 0; i < ms ~/ 16; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
    }

    await t.tap(find.text('Bay thử!'));
    await frames(1000);
    expect(s().flying, isTrue);
    expect(s().liftOffset, greaterThan(0));
    // A second tap while flying does nothing.
    await t.tap(find.text('Bay thử!'), warnIfMissed: false);
    await frames(1100);
    expect(s().flying, isFalse);
    expect(s().liftOffset, 0);
    await t.pumpWidget(const SizedBox());
  });
}
