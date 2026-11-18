import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/house/house_model.dart';
import 'package:funedu/house/house_repository.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  group('house_model pure logic', () {
    test('stageForXp and stageProgressForXp advance across all 5 stages', () {
      expect(stageForXp(0).level, 1);
      expect(stageForXp(29).level, 1);
      expect(stageForXp(30).level, 2);
      expect(stageForXp(80).level, 3);
      expect(stageForXp(150).level, 4);
      expect(stageForXp(250).level, 5);
      expect(nextStageForXp(250), isNull);
      expect(stageProgressForXp(250), 1.0);
      expect(stageProgressForXp(15), closeTo(0.5, 0.001));
    });

    test('daily free acorn works once per calendar day with 0 stars', () {
      final freeTreat = houseTreats.firstWhere((t) => t.isDailyFree);
      final day1 = DateTime(2026, 11, 18, 9, 0);
      final day2 = DateTime(2026, 11, 19, 8, 0);

      final r1 = applyFeed(
        current: const ChipHouseState(),
        treat: freeTreat,
        totalLearningStars: 0,
        now: day1,
      );
      expect(r1.ok, isTrue);
      expect(r1.state.xp, freeTreat.xpGain);
      expect(r1.state.spentStars, 0);

      // Same day blocked cleanly.
      final r2 = applyFeed(
        current: r1.state,
        treat: freeTreat,
        totalLearningStars: 0,
        now: day1,
      );
      expect(r2.ok, isFalse);

      // Next day allowed again.
      final r3 = applyFeed(
        current: r1.state,
        treat: freeTreat,
        totalLearningStars: 0,
        now: day2,
      );
      expect(r3.ok, isTrue);
      expect(r3.state.xp, freeTreat.xpGain * 2);
    });

    test('paid treats deduct availableStars and trigger level up', () {
      final cake = houseTreats.firstWhere((t) => t.id == 'star_cake');
      final fail = applyFeed(
        current: const ChipHouseState(),
        treat: cake,
        totalLearningStars: 4,
        now: DateTime(2026, 11, 18),
      );
      expect(fail.ok, isFalse);
      expect(fail.message, contains('2 sao'));

      final ok = applyFeed(
        current: const ChipHouseState(),
        treat: cake,
        totalLearningStars: 10,
        now: DateTime(2026, 11, 18),
      );
      expect(ok.ok, isTrue);
      expect(ok.leveledUp, isTrue);
      expect(ok.state.stage.level, 2);
      expect(ok.state.spentStars, cake.costStars);
      expect(ok.state.availableStars(10), 4);
    });

    test('buy and equip decor updates ownership and equipped slot', () {
      final forest = houseCatalog.firstWhere((i) => i.id == 'wall_forest');
      final noStars = applyBuyOrEquip(
        current: const ChipHouseState(),
        item: forest,
        totalLearningStars: 5,
      );
      expect(noStars.ok, isFalse);

      final bought = applyBuyOrEquip(
        current: const ChipHouseState(),
        item: forest,
        totalLearningStars: 10,
      );
      expect(bought.ok, isTrue);
      expect(bought.purchased, isTrue);
      expect(bought.state.isOwned('wall_forest'), isTrue);
      expect(bought.state.equippedId(HouseSlot.wall), 'wall_forest');
      expect(bought.state.availableStars(10), 2);

      // Re-equipping an owned default item costs 0 stars.
      final sunny = houseCatalog.firstWhere((i) => i.id == 'wall_sunny');
      final swapped = applyBuyOrEquip(
        current: bought.state,
        item: sunny,
        totalLearningStars: 10,
      );
      expect(swapped.ok, isTrue);
      expect(swapped.purchased, isFalse);
      expect(swapped.state.equippedId(HouseSlot.wall), 'wall_sunny');
      expect(swapped.state.availableStars(10), 2);
    });

    test('JSON encode/decode roundtrips and handles corrupted data safely', () {
      final s = ChipHouseState(
        xp: 95,
        spentStars: 18,
        ownedIds: {...defaultOwnedHouseItems, 'wall_forest', 'rug_rainbow'},
        equipped: {
          ...defaultEquippedHouseItems,
          HouseSlot.wall: 'wall_forest',
          HouseSlot.rug: 'rug_rainbow',
        },
        lastFreeTreatDay: '2026-11-18',
      );
      final back = ChipHouseState.decode(s.encode());
      expect(back.xp, 95);
      expect(back.spentStars, 18);
      expect(back.equippedId(HouseSlot.wall), 'wall_forest');
      expect(back.equippedId(HouseSlot.rug), 'rug_rainbow');
      expect(back.lastFreeTreatDay, '2026-11-18');

      // Corrupted JSON falls back cleanly to default state.
      final fallback = ChipHouseState.decode('{bad json');
      expect(fallback.xp, 0);
      expect(fallback.equippedId(HouseSlot.wall), 'wall_sunny');
    });
  });

  group('ChipHouseRepository persistence & kid isolation', () {
    late AppDatabase db;
    late KidRepository kids;
    late ChipHouseRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      kids = KidRepository(db);
      repo = ChipHouseRepository(kids);
    });

    tearDown(() async => db.close());

    test('saves per kid and cleans up when kid is deleted', () async {
      final k1 = await kids.addKid(
        nickname: 'Bông',
        avatar: AppImages.chipMain,
        age: 5,
      );
      final k2 = await kids.addKid(
        nickname: 'Bin',
        avatar: AppImages.chipJoy,
        age: 6,
      );

      final saved = const ChipHouseState(xp: 45, spentStars: 6);
      await repo.save(k1, saved);

      expect((await repo.load(k1)).xp, 45);
      expect((await repo.load(k2)).xp, 0);

      await kids.deleteKid(k1);
      expect(await kids.setting(ChipHouseRepository.keyForKid(k1)), isNull);
    });
  });
}
