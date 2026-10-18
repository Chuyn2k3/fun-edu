import 'package:equatable/equatable.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final ItemType requiredItem;
  final int requiredQuantity;
  final int difficulty;

  const OrderEntity({
    required this.id,
    required this.requiredItem,
    required this.requiredQuantity,
    this.difficulty = 1,
  });

  @override
  List<Object?> get props => [id, requiredItem, requiredQuantity, difficulty];
}
