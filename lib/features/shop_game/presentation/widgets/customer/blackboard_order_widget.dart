import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';

class BlackboardOrderWidget extends StatelessWidget {
  final OrderEntity order;

  const BlackboardOrderWidget({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B), // Blackboard slate
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 6), // Wooden frame
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            offset: Offset(2, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${order.requiredQuantity}',
            style: const TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '${order.requiredItem.emoji} ${order.requiredItem.vietnameseName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD54F), // Chalk yellow
              ),
            ),
          ),
        ],
      ),
    );
  }
}
