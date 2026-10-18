import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/counter/basket_drag_target.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/countertop_layer.dart';

void main() {
  testWidgets('BasketDragTarget accepts item on drop callback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CountertopLayer(
                basketItems: const [],
                onItemDropped: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CountertopLayer), findsOneWidget);
    expect(find.byType(BasketDragTarget), findsOneWidget);
  });

  testWidgets('BasketDragTarget invokes onItemDropped when Draggable is dropped', (tester) async {
    ItemEntity? droppedItem;
    const testItem = ItemEntity(
      id: '1',
      type: ItemType.redApple,
      nameVi: 'Táo đỏ',
      assetPath: 'assets/shop_game/items/apple.png',
      shelfPosition: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CountertopLayer(
                basketItems: const [],
                onItemDropped: (item) => droppedItem = item,
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Draggable<ItemEntity>(
                  data: testItem,
                  feedback: const Text('🍎'),
                  child: const Text('🍎'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final dragLocation = tester.getCenter(find.text('🍎'));
    final dropLocation = tester.getCenter(find.byType(BasketDragTarget));

    final gesture = await tester.startGesture(dragLocation);
    await tester.pump();
    await gesture.moveTo(dropLocation);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(droppedItem, equals(testItem));
  });
}
