import 'package:fun_edu/core/constants/app_shop_assets.dart';
import 'package:fun_edu/features/shop_game/data/models/item_model.dart';
import 'package:fun_edu/features/shop_game/data/models/level_model.dart';
import 'package:fun_edu/features/shop_game/data/models/order_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class ShopGameLevelsData {
  ShopGameLevelsData._();

  static const List<ItemModel> shelfItems = [
    ItemModel(
      id: 'red_apple',
      type: ItemType.redApple,
      nameVi: 'Táo đỏ',
      assetPath: AppShopAssets.redApple,
      shelfPosition: 0,
    ),
    ItemModel(
      id: 'banana',
      type: ItemType.banana,
      nameVi: 'Chuối',
      assetPath: AppShopAssets.banana,
      shelfPosition: 1,
    ),
    ItemModel(
      id: 'orange',
      type: ItemType.orange,
      nameVi: 'Cam',
      assetPath: AppShopAssets.orange,
      shelfPosition: 2,
    ),
    ItemModel(
      id: 'pumpkin',
      type: ItemType.pumpkin,
      nameVi: 'Bí ngô',
      assetPath: AppShopAssets.pumpkin,
      shelfPosition: 3,
    ),
    ItemModel(
      id: 'watermelon',
      type: ItemType.watermelon,
      nameVi: 'Dưa hấu',
      assetPath: AppShopAssets.watermelon,
      shelfPosition: 4,
    ),
  ];

  static const List<LevelModel> levels = [
    // Level 1: Tiệm Trái Cây (⭐ Dễ, mở khóa: 0 sao)
    LevelModel(
      id: 'level_1',
      shopName: 'Tiệm Trái Cây',
      starsToUnlock: 0,
      orders: [
        OrderModel(id: 'l1_o1', requiredItem: ItemType.redApple, requiredQuantity: 2, difficulty: 1),
        OrderModel(id: 'l1_o2', requiredItem: ItemType.banana, requiredQuantity: 1, difficulty: 1),
        OrderModel(id: 'l1_o3', requiredItem: ItemType.orange, requiredQuantity: 2, difficulty: 1),
        OrderModel(id: 'l1_o4', requiredItem: ItemType.redApple, requiredQuantity: 3, difficulty: 1),
        OrderModel(id: 'l1_o5', requiredItem: ItemType.banana, requiredQuantity: 3, difficulty: 1),
      ],
    ),
    // Level 2: Chợ Rau Củ (⭐⭐ Vừa, mở khóa: 8 sao)
    LevelModel(
      id: 'level_2',
      shopName: 'Chợ Rau Củ',
      starsToUnlock: 8,
      orders: [
        OrderModel(id: 'l2_o1', requiredItem: ItemType.pumpkin, requiredQuantity: 2, difficulty: 2),
        OrderModel(id: 'l2_o2', requiredItem: ItemType.orange, requiredQuantity: 3, difficulty: 2),
        OrderModel(id: 'l2_o3', requiredItem: ItemType.watermelon, requiredQuantity: 2, difficulty: 2),
        OrderModel(id: 'l2_o4', requiredItem: ItemType.redApple, requiredQuantity: 4, difficulty: 2),
        OrderModel(id: 'l2_o5', requiredItem: ItemType.pumpkin, requiredQuantity: 3, difficulty: 2),
      ],
    ),
    // Level 3: Siêu Thị Mini (⭐⭐⭐ Thử thách, mở khóa: 20 sao)
    LevelModel(
      id: 'level_3',
      shopName: 'Siêu Thị Mini',
      starsToUnlock: 20,
      orders: [
        OrderModel(id: 'l3_o1', requiredItem: ItemType.orange, requiredQuantity: 3, difficulty: 3),
        OrderModel(id: 'l3_o2', requiredItem: ItemType.watermelon, requiredQuantity: 2, difficulty: 3),
        OrderModel(id: 'l3_o3', requiredItem: ItemType.banana, requiredQuantity: 4, difficulty: 3),
        OrderModel(id: 'l3_o4', requiredItem: ItemType.pumpkin, requiredQuantity: 3, difficulty: 3),
        OrderModel(id: 'l3_o5', requiredItem: ItemType.redApple, requiredQuantity: 5, difficulty: 3),
        OrderModel(id: 'l3_o6', requiredItem: ItemType.watermelon, requiredQuantity: 3, difficulty: 3),
      ],
    ),
  ];
}
