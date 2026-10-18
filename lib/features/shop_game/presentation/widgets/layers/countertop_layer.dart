import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/basket_drag_target.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/cash_register_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/coin_jar_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/spring_scale_widget.dart';

class CountertopLayer extends StatelessWidget {
  final List<ItemEntity> basketItems;
  final ValueChanged<ItemEntity> onItemDropped;
  final int totalCoins;

  const CountertopLayer({
    super.key,
    required this.basketItems,
    required this.onItemDropped,
    this.totalCoins = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 160,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Wooden countertop surface
          Container(
            height: 140,
            decoration: const BoxDecoration(
              color: Color(0xFF8D5B28), // Oak wood counter
              border: Border(
                top: BorderSide(color: Color(0xFFB87E43), width: 8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  offset: Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          // Countertop Props Row
          Positioned(
            bottom: 20,
            left: 200,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BasketDragTarget(
                  items: basketItems,
                  onItemDropped: onItemDropped,
                ),
                SpringScaleWidget(itemCount: basketItems.length),
                CashRegisterWidget(displayCount: basketItems.length),
                CoinJarWidget(coins: totalCoins),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
