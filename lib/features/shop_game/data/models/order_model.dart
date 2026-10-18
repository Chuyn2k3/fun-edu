import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

class OrderModel {
  final String id;
  final ItemType requiredItem;
  final int requiredQuantity;
  final int difficulty;

  const OrderModel({
    required this.id,
    required this.requiredItem,
    required this.requiredQuantity,
    this.difficulty = 1,
  });

  OrderEntity toEntity() => OrderEntity(
        id: id,
        requiredItem: requiredItem,
        requiredQuantity: requiredQuantity,
        difficulty: difficulty,
      );

  factory OrderModel.fromEntity(OrderEntity entity) => OrderModel(
        id: entity.id,
        requiredItem: entity.requiredItem,
        requiredQuantity: entity.requiredQuantity,
        difficulty: entity.difficulty,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'requiredItem': requiredItem.name,
        'requiredQuantity': requiredQuantity,
        'difficulty': difficulty,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] as String,
        requiredItem: ItemType.values.firstWhere((e) => e.name == map['requiredItem']),
        requiredQuantity: map['requiredQuantity'] as int,
        difficulty: map['difficulty'] as int? ?? 1,
      );
}
