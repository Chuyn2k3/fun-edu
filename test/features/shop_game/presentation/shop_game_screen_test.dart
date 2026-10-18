import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_cubit.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';
import 'package:fun_edu/features/shop_game/presentation/screens/shop_game_screen.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/background_scenery_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/countertop_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/customer_character_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/fruit_shelf_draggable_layer.dart';
import 'package:fun_edu/features/shop_game/presentation/widgets/layers/game_hud_overlay.dart';

class MockShopGameCubit extends MockCubit<ShopGameState> implements ShopGameCubit {}

void main() {
  late MockShopGameCubit mockCubit;

  final testOrders = [
    const OrderEntity(id: 'o1', requiredItem: ItemType.redApple, requiredQuantity: 2),
  ];

  setUp(() {
    mockCubit = MockShopGameCubit();
    when(() => mockCubit.startGame(any())).thenAnswer((_) async {});
  });

  testWidgets('ShopGameScreen renders loading indicator when status is loading', (tester) async {
    when(() => mockCubit.state).thenReturn(
      ShopGameState.initial().copyWith(phase: GamePhase.loading),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ShopGameScreen(cubit: mockCubit, levelId: 'level_1'),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ShopGameScreen renders all 6 layers when active in collectingItems phase', (tester) async {
    when(() => mockCubit.state).thenReturn(
      ShopGameState.initial().copyWith(
        phase: GamePhase.collectingItems,
        levelId: 'level_1',
        orders: testOrders,
        currentOrder: testOrders.first,
        childName: 'Bé Na',
        basketItems: const [],
        starCount: 2,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ShopGameScreen(cubit: mockCubit, levelId: 'level_1'),
      ),
    );

    expect(find.byType(BackgroundSceneryLayer), findsOneWidget);
    expect(find.byType(CustomerCharacterLayer), findsOneWidget);
    expect(find.byType(CountertopLayer), findsOneWidget);
    expect(find.byType(FruitShelfDraggableLayer), findsOneWidget);
    expect(find.byType(GameHudOverlay), findsOneWidget);
  });
}
