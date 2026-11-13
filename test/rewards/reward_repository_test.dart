import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/rewards/reward_repository.dart';

void main() {
  late AppDatabase db;
  late KidRepository kids;
  late RewardRepository rewards;
  late int na;
  late int bo;
  var clock = DateTime(2026, 11, 13, 9);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    kids = KidRepository(db);
    rewards = RewardRepository(db, now: () => clock);
    na = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    bo = await kids.addKid(nickname: 'Bo', avatar: kidAvatars[1], age: 6);
  });
  tearDown(() => db.close());

  test('add and list are per kid, oldest first', () async {
    await rewards.add(na, 'Đi công viên', 10);
    clock = clock.add(const Duration(minutes: 1));
    await rewards.add(na, 'Ăn kem', 30);
    await rewards.add(bo, 'Xem phim', 50);
    final list = await rewards.list(na);
    expect(list.map((r) => r.title), ['Đi công viên', 'Ăn kem']);
    expect(list.first.starsNeeded, 10);
    expect(list.first.redeemedAt, isNull);
    expect(await rewards.list(bo), hasLength(1));
  });

  test('validates title and stars', () async {
    expect(() => rewards.add(na, '   ', 10), throwsArgumentError);
    expect(() => rewards.add(na, 'a' * 61, 10), throwsArgumentError);
    expect(() => rewards.add(na, 'ok', 9), throwsArgumentError);
    expect(() => rewards.add(na, 'ok', 201), throwsArgumentError);
    await rewards.add(na, '  Ăn kem  ', 200);
    expect((await rewards.list(na)).single.title, 'Ăn kem');
  });

  test('redeem marks redeemedAt and keeps stars', () async {
    await db.into(db.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
            kidId: na,
            completedAt: DateTime(2026, 11, 13),
            starsEarned: 12,
          ),
        );
    final id = await rewards.add(na, 'Đi công viên', 10);
    await rewards.redeem(id);
    final r = (await rewards.list(na)).single;
    expect(r.redeemedAt, clock);
    expect(await rewards.totalStars(na), 12);
  });

  test('pending is the oldest unredeemed reward', () async {
    expect(await rewards.pending(na), isNull);
    final a = await rewards.add(na, 'A', 10);
    clock = clock.add(const Duration(minutes: 1));
    await rewards.add(na, 'B', 20);
    expect((await rewards.pending(na))!.title, 'A');
    await rewards.redeem(a);
    expect((await rewards.pending(na))!.title, 'B');
  });

  test('deleteKid and deleteAllData remove rewards', () async {
    await rewards.add(na, 'A', 10);
    await rewards.add(bo, 'B', 10);
    await kids.deleteKid(na);
    expect(await rewards.list(na), isEmpty);
    expect(await rewards.list(bo), hasLength(1));
    await kids.deleteAllData();
    expect(await db.select(db.realRewards).get(), isEmpty);
  });

  test('clearLevels forgets the placement of one kid only', () async {
    await LevelRepository(db, kidId: na).setLevel('viet', 0);
    await LevelRepository(db, kidId: na).setLevel('toan', 1);
    await LevelRepository(db, kidId: bo).setLevel('toan', 1);
    await LevelRepository(db, kidId: na).clearLevels();
    expect(await LevelRepository(db, kidId: na).isPlaced(), isFalse);
    expect(await LevelRepository(db, kidId: bo).levelOf('toan'), 1);
  });
}
