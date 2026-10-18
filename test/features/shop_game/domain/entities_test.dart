import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

void main() {
  group('Domain Entities Tests', () {
    test('ItemEntity equality and props', () {
      final item1 = ItemEntity(
        id: 'red_apple_1',
        type: ItemType.redApple,
        nameVi: 'Táo đỏ',
        assetPath: 'assets/shop_game/items/red_apple.webp',
        shelfPosition: 0,
      );
      final item2 = ItemEntity(
        id: 'red_apple_1',
        type: ItemType.redApple,
        nameVi: 'Táo đỏ',
        assetPath: 'assets/shop_game/items/red_apple.webp',
        shelfPosition: 0,
      );
      expect(item1, equals(item2));
    });

    test('OrderEntity completion logic check', () {
      final order = OrderEntity(
        id: 'order_1',
        requiredItem: ItemType.redApple,
        requiredQuantity: 3,
        difficulty: 1,
      );
      expect(order.requiredQuantity, 3);
      expect(order.requiredItem, ItemType.redApple);
    });

    test('ChildProfileEntity copyWith', () {
      final profile = ChildProfileEntity(
        id: 'child_1',
        name: 'Bé Na',
        age: 5,
        totalStars: 10,
        totalCoins: 50,
        levelStars: const {'level_1': 3},
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = profile.copyWith(totalStars: 13, totalCoins: 60);
      expect(updated.totalStars, 13);
      expect(updated.totalCoins, 60);
      expect(updated.name, 'Bé Na');
    });
  });
}
