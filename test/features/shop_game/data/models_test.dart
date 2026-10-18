import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/data/models/item_model.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

void main() {
  group('Data Models Tests', () {
    test('ItemModel toEntity and fromEntity round-trip', () {
      final entity = ItemEntity(
        id: 'apple_1',
        type: ItemType.redApple,
        nameVi: 'Táo đỏ',
        assetPath: 'assets/shop_game/items/red_apple.webp',
        shelfPosition: 0,
      );

      final model = ItemModel.fromEntity(entity);
      expect(model.id, 'apple_1');
      expect(model.toEntity(), equals(entity));
    });

    test('ChildProfileModel JSON / Map serialization', () {
      final model = ChildProfileModel(
        id: 'child_1',
        name: 'Bé Bắp',
        age: 4,
        totalStars: 5,
        totalCoins: 20,
        levelStars: const {'level_1': 3},
        createdAt: DateTime(2026, 1, 1).toIso8601String(),
      );

      final map = model.toMap();
      final restored = ChildProfileModel.fromMap(map);
      expect(restored.name, 'Bé Bắp');
      expect(restored.totalStars, 5);
      expect(restored.levelStars['level_1'], 3);
    });

    test('PlaySessionModel JSON / Map serialization', () {
      final model = PlaySessionModel(
        id: 'sess_1',
        levelId: 'level_1',
        orderId: 'order_1',
        startedAt: DateTime(2026, 1, 1, 10, 0).toIso8601String(),
        completedAt: DateTime(2026, 1, 1, 10, 2).toIso8601String(),
        errorsCount: 1,
        starsEarned: 2,
        completed: true,
      );

      final map = model.toMap();
      final restored = PlaySessionModel.fromMap(map);
      expect(restored.id, 'sess_1');
      expect(restored.errorsCount, 1);
      expect(restored.completed, isTrue);
    });
  });
}
