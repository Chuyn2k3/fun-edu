import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/customer_character_layer.dart';

void main() {
  testWidgets('CustomerCharacterLayer displays blackboard order correctly', (tester) async {
    const order = OrderEntity(
      id: 'o1',
      requiredItem: ItemType.redApple,
      requiredQuantity: 3,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CustomerCharacterLayer(
                phase: GamePhase.collectingItems,
                currentOrder: order,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('🍎 Táo đỏ'), findsOneWidget);
  });
}
