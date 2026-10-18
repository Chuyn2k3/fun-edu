import 'package:flutter/material.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/customer/bear_character_widget.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/customer/blackboard_order_widget.dart';

class CustomerCharacterLayer extends StatelessWidget {
  final GamePhase phase;
  final OrderEntity currentOrder;

  const CustomerCharacterLayer({
    super.key,
    required this.phase,
    required this.currentOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BlackboardOrderWidget(order: currentOrder),
          const SizedBox(width: 24),
          BearCharacterWidget(phase: phase),
        ],
      ),
    );
  }
}
