import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

void main() {
  group('ShopGameLevelsData Tests', () {
    test('provides 3 distinct levels with correct order counts and items', () {
      final levels = ShopGameLevelsData.levels;
      expect(levels.length, 3);

      // Level 1: Tiệm Trái Cây
      final level1 = levels.firstWhere((l) => l.id == 'level_1');
      expect(level1.starsToUnlock, 0);
      expect(level1.orders.length, 5);
      expect(level1.orders[0].requiredItem, ItemType.redApple);
      expect(level1.orders[0].requiredQuantity, 2);

      // Level 2: Chợ Rau Củ
      final level2 = levels.firstWhere((l) => l.id == 'level_2');
      expect(level2.starsToUnlock, 8);
      expect(level2.orders.length, 5);

      // Level 3: Siêu Thị Mini
      final level3 = levels.firstWhere((l) => l.id == 'level_3');
      expect(level3.starsToUnlock, 20);
      expect(level3.orders.length, 6);
    });

    test('shelfItems provides all 5 item types with multiple shelf slots', () {
      final items = ShopGameLevelsData.shelfItems;
      expect(items.length, greaterThanOrEqualTo(5));
      final types = items.map((e) => e.type).toSet();
      expect(types.contains(ItemType.redApple), isTrue);
      expect(types.contains(ItemType.banana), isTrue);
      expect(types.contains(ItemType.pumpkin), isTrue);
      expect(types.contains(ItemType.orange), isTrue);
      expect(types.contains(ItemType.watermelon), isTrue);
    });
  });
}
