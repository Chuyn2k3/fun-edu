import 'package:equatable/equatable.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

class LevelEntity extends Equatable {
  final String id;
  final String shopName;
  final List<OrderEntity> orders;
  final int starsToUnlock;

  const LevelEntity({
    required this.id,
    required this.shopName,
    required this.orders,
    required this.starsToUnlock,
  });

  @override
  List<Object?> get props => [id, shopName, orders, starsToUnlock];
}
