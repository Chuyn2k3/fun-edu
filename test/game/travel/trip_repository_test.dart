import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/game/data/game_repository.dart';
import 'package:funedu/game/travel/trip.dart';
import 'package:funedu/game/travel/trip_progress.dart';
import 'package:funedu/online/sync/sync_store.dart';
import 'package:funedu/profile/kid_repository.dart';

void main() {
  late AppDatabase db;
  late int kid;
  late GameRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    kid = await KidRepository(db).addKid(nickname: 'Na', avatar: 'a', age: 5);
    repo = GameRepository(db, kidId: kid);
  });
  tearDown(() => db.close());

  Future<int> raw() async =>
      (await (db.select(db.gameCounters)
                ..where((t) => t.key.equals('trip.step')))
              .getSingleOrNull())
          ?.value ??
      0;

  test('advancing reaches the first stop at step 4', () async {
    var a = await repo.advanceTrip(2);
    expect((a.from, a.to), (0, 2));
    expect(a.newStops, isEmpty);
    a = await repo.advanceTrip(2);
    expect(a.newStops.map((s) => s.id), ['ho-guom']);
    expect(await repo.tripStep(), 4);
  });

  test('the trip stops at its end and never lowers the counter', () async {
    await repo.advanceTrip(119);
    var a = await repo.advanceTrip(2);
    expect(a.to, 120);
    expect(a.newStops.single.id, tripStops.last.id);
    final before = await raw();
    a = await repo.advanceTrip(2);
    expect(a.to, 120);
    expect(a.newStops, isEmpty);
    expect(await raw(), greaterThanOrEqualTo(before));
  });

  test('a synced counter above the trip reads as the end', () async {
    await db.into(db.gameCounters).insertOnConflictUpdate(
        GameCountersCompanion.insert(
            kidId: kid, key: 'trip.step', value: const Value(150)));
    expect(await repo.tripStep(), 120);
    await repo.advanceTrip(2);
    expect(await raw(), greaterThanOrEqualTo(150));
  });

  test('a first-try move adds its star in the same write', () async {
    final before = await repo.totalStars();
    final a = await repo.advanceTrip(2, star: true);
    expect(a.to, 2);
    expect(await repo.totalStars(), before + 1);
  });

  test('a trip star adds one cosmic star and no race', () async {
    final before = await repo.totalStars();
    expect(await repo.addTripStar(), before + 1);
    expect(await db.select(db.raceResults).get(), isEmpty);
  });

  test('the shown mark stays on the device', () async {
    await markTripShown(db, kid, 8);
    expect(await tripShown(db, kid), 8);
    final exported = await SyncStore(db).exportAll();
    expect(exported.keys.where((k) => k.contains('tripShown')), isEmpty);
  });

  test('progress counts unseen postcards, never negative', () async {
    await repo.advanceTrip(9);
    await markTripShown(db, kid, 4);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    final p = await c.read(tripProgressProvider.future);
    expect((p.step, p.postcards, p.unseen), (9, 2, 1));
    expect(p.nextStop?.id, 'van-mieu');
    await markTripShown(db, kid, 40);
    c.invalidate(tripProgressProvider);
    expect((await c.read(tripProgressProvider.future)).unseen, 0);
  });
}
