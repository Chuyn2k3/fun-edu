import 'package:fun_edu/features/shop_game/data/models/order_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';

class LevelModel {
  final String id;
  final String shopName;
  final List<OrderModel> orders;
  final int starsToUnlock;

  const LevelModel({
    required this.id,
    required this.shopName,
    required this.orders,
    required this.starsToUnlock,
  });

  LevelEntity toEntity() => LevelEntity(
        id: id,
        shopName: shopName,
        orders: orders.map((o) => o.toEntity()).toList(),
        starsToUnlock: starsToUnlock,
      );

  factory LevelModel.fromEntity(LevelEntity entity) => LevelModel(
        id: entity.id,
        shopName: entity.shopName,
        orders: entity.orders.map((o) => OrderModel.fromEntity(o)).toList(),
        starsToUnlock: entity.starsToUnlock,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'shopName': shopName,
        'orders': orders.map((o) => o.toMap()).toList(),
        'starsToUnlock': starsToUnlock,
      };

  factory LevelModel.fromMap(Map<String, dynamic> map) => LevelModel(
        id: map['id'] as String,
        shopName: map['shopName'] as String,
        orders: (map['orders'] as List<dynamic>)
            .map((o) => OrderModel.fromMap(Map<String, dynamic>.from(o as Map)))
            .toList(),
        starsToUnlock: map['starsToUnlock'] as int,
      );
}
