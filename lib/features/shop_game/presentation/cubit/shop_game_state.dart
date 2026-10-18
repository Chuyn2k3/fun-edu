import 'package:equatable/equatable.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

enum GamePhase {
  loading,
  customerEntering,
  collectingItems,
  celebrating,
  levelComplete,
}

class ShopGameState extends Equatable {
  final GamePhase phase;
  final String levelId;
  final String childName;
  final List<OrderEntity> orders;
  final OrderEntity currentOrder;
  final List<ItemEntity> basketItems;
  final int currentOrderIndex;
  final int totalOrders;
  final int starCount;
  final int errorsCount;
  final bool isHandTutorVisible;
  final String? floatingText;
  final List<int> orderStarsHistory;

  const ShopGameState({
    required this.phase,
    required this.levelId,
    required this.childName,
    required this.orders,
    required this.currentOrder,
    required this.basketItems,
    required this.currentOrderIndex,
    required this.totalOrders,
    required this.starCount,
    required this.errorsCount,
    required this.isHandTutorVisible,
    this.floatingText,
    required this.orderStarsHistory,
  });

  factory ShopGameState.initial() => const ShopGameState(
        phase: GamePhase.loading,
        levelId: '',
        childName: 'Bé',
        orders: [],
        currentOrder: OrderEntity(id: '', requiredItem: ItemType.redApple, requiredQuantity: 1),
        basketItems: [],
        currentOrderIndex: 0,
        totalOrders: 0,
        starCount: 0,
        errorsCount: 0,
        isHandTutorVisible: false,
        floatingText: null,
        orderStarsHistory: [],
      );

  ShopGameState copyWith({
    GamePhase? phase,
    String? levelId,
    String? childName,
    List<OrderEntity>? orders,
    OrderEntity? currentOrder,
    List<ItemEntity>? basketItems,
    int? currentOrderIndex,
    int? totalOrders,
    int? starCount,
    int? errorsCount,
    bool? isHandTutorVisible,
    String? floatingText,
    List<int>? orderStarsHistory,
  }) {
    return ShopGameState(
      phase: phase ?? this.phase,
      levelId: levelId ?? this.levelId,
      childName: childName ?? this.childName,
      orders: orders ?? this.orders,
      currentOrder: currentOrder ?? this.currentOrder,
      basketItems: basketItems ?? this.basketItems,
      currentOrderIndex: currentOrderIndex ?? this.currentOrderIndex,
      totalOrders: totalOrders ?? this.totalOrders,
      starCount: starCount ?? this.starCount,
      errorsCount: errorsCount ?? this.errorsCount,
      isHandTutorVisible: isHandTutorVisible ?? this.isHandTutorVisible,
      floatingText: floatingText,
      orderStarsHistory: orderStarsHistory ?? this.orderStarsHistory,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        levelId,
        childName,
        orders,
        currentOrder,
        basketItems,
        currentOrderIndex,
        totalOrders,
        starCount,
        errorsCount,
        isHandTutorVisible,
        floatingText,
        orderStarsHistory,
      ];
}
