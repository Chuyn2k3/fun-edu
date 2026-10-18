import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/shelf/draggable_fruit_item.dart';

void main() {
  const testItems = [
    ItemEntity(
      id: 'apple_1',
      type: ItemType.redApple,
      nameVi: 'Táo đỏ',
      assetPath: 'assets/shop_game/items/apple.png',
      shelfPosition: 0,
    ),
    ItemEntity(
      id: 'banana_1',
      type: ItemType.banana,
      nameVi: 'Chuối',
      assetPath: 'assets/shop_game/items/banana.png',
      shelfPosition: 1,
    ),
  ];

  testWidgets('FruitShelfDraggableLayer renders shelf items when enabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FruitShelfDraggableLayer(
                availableItems: testItems,
                isEnabled: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FruitShelfDraggableLayer), findsOneWidget);
    expect(find.byType(DraggableFruitItem), findsNWidgets(2));
    expect(find.text('🍎'), findsOneWidget);
    expect(find.text('🍌'), findsOneWidget);
  });

  testWidgets('DraggableFruitItem is draggable when isEnabled is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FruitShelfDraggableLayer(
                availableItems: testItems,
                isEnabled: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Draggable<ItemEntity>), findsNWidgets(2));
  });

  testWidgets('DraggableFruitItem is not draggable when isEnabled is false', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FruitShelfDraggableLayer(
                availableItems: testItems,
                isEnabled: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Draggable<ItemEntity>), findsNothing);
    expect(find.byType(DraggableFruitItem), findsNWidgets(2));
  });
}
