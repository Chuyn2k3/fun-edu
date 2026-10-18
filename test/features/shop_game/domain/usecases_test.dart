import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/generate_order_usecase.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/record_play_log_usecase.dart';

class MockShopGameRepository extends Mock implements IShopGameRepository {}

void main() {
  late MockShopGameRepository mockRepo;
  late GenerateOrderUseCase generateOrderUseCase;
  late RecordPlayLogUseCase recordPlayLogUseCase;

  setUpAll(() {
    registerFallbackValue(PlaySessionEntity(
      id: 'mock_session',
      levelId: 'level_1',
      orderId: 'order_1',
      startedAt: DateTime.now(),
      errorsCount: 0,
      starsEarned: 3,
      completed: true,
    ));
  });

  setUp(() {
    mockRepo = MockShopGameRepository();
    generateOrderUseCase = GenerateOrderUseCase(mockRepo);
    recordPlayLogUseCase = RecordPlayLogUseCase(mockRepo);
  });

  group('UseCases Tests', () {
    test('GenerateOrderUseCase returns order list for given level', () async {
      final mockLevel = LevelEntity(
        id: 'level_1',
        shopName: 'Tiệm Trái Cây',
        starsToUnlock: 0,
        orders: const [
          OrderEntity(id: 'o1', requiredItem: ItemType.redApple, requiredQuantity: 2),
          OrderEntity(id: 'o2', requiredItem: ItemType.banana, requiredQuantity: 1),
        ],
      );

      when(() => mockRepo.getLevel('level_1')).thenAnswer((_) async => mockLevel);

      final orders = await generateOrderUseCase('level_1');
      expect(orders.length, 2);
      expect(orders.first.requiredItem, ItemType.redApple);
      verify(() => mockRepo.getLevel('level_1')).called(1);
    });

    test('RecordPlayLogUseCase calls repository recordPlaySession', () async {
      final session = PlaySessionEntity(
        id: 's1',
        levelId: 'level_1',
        orderId: 'o1',
        startedAt: DateTime.now(),
        errorsCount: 1,
        starsEarned: 2,
        completed: true,
      );

      when(() => mockRepo.recordPlaySession(any())).thenAnswer((_) async => {});

      await recordPlayLogUseCase(session);
      verify(() => mockRepo.recordPlaySession(session)).called(1);
    });
  });
}
