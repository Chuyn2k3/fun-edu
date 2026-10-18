import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_cubit.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';

class MockShopGameRepository extends Mock implements IShopGameRepository {}
class MockTtsService extends Mock implements TtsService {}
class MockAudioService extends Mock implements AudioService {}

void main() {
  late MockShopGameRepository mockRepo;
  late MockTtsService mockTts;
  late MockAudioService mockAudio;

  final testOrders = [
    const OrderEntity(id: 'o1', requiredItem: ItemType.redApple, requiredQuantity: 2),
    const OrderEntity(id: 'o2', requiredItem: ItemType.banana, requiredQuantity: 1),
  ];

  final testLevel = LevelEntity(
    id: 'level_1',
    shopName: 'Tiệm Trái Cây',
    starsToUnlock: 0,
    orders: testOrders,
  );

  final testProfile = ChildProfileEntity(
    id: 'c1',
    name: 'Bé Na',
    age: 4,
    totalStars: 0,
    totalCoins: 0,
    levelStars: const {},
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(PlaySessionEntity(
      id: 'sess',
      levelId: 'level_1',
      orderId: 'o1',
      startedAt: DateTime.now(),
      errorsCount: 0,
      starsEarned: 3,
      completed: true,
    ));
  });

  setUp(() {
    mockRepo = MockShopGameRepository();
    mockTts = MockTtsService();
    mockAudio = MockAudioService();

    when(() => mockRepo.getLevel('level_1')).thenAnswer((_) async => testLevel);
    when(() => mockRepo.getChildProfile()).thenAnswer((_) async => testProfile);
    when(() => mockRepo.recordPlaySession(any())).thenAnswer((_) async => {});
    when(() => mockRepo.updateLevelStars(any(), any())).thenAnswer((_) async => {});
    when(() => mockTts.init()).thenAnswer((_) async => {});
    when(() => mockTts.speak(any())).thenAnswer((_) async => {});
    when(() => mockAudio.init()).thenAnswer((_) async => {});
    when(() => mockAudio.playBgm(any())).thenAnswer((_) async => {});
    when(() => mockAudio.playSfx(any())).thenAnswer((_) async => {});
    when(() => mockAudio.stopBgm()).thenAnswer((_) async => {});
    when(() => mockTts.stop()).thenAnswer((_) async => {});
  });

  group('ShopGameCubit Tests', () {
    test('initial state is loading', () {
      final cubit = ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      );
      expect(cubit.state.phase, GamePhase.loading);
      cubit.close();
    });

    blocTest<ShopGameCubit, ShopGameState>(
      'startGame loads level and transitions to customerEntering',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      act: (cubit) => cubit.startGame('level_1'),
      expect: () => [
        isA<ShopGameState>().having((s) => s.phase, 'phase', GamePhase.loading),
        isA<ShopGameState>()
            .having((s) => s.phase, 'phase', GamePhase.customerEntering)
            .having((s) => s.currentOrder.id, 'order id', 'o1')
            .having((s) => s.childName, 'child name', 'Bé Na'),
      ],
    );

    blocTest<ShopGameCubit, ShopGameState>(
      'onCustomerEntered transitions to collectingItems',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      seed: () => ShopGameState.initial().copyWith(
        phase: GamePhase.customerEntering,
        currentOrder: testOrders.first,
        totalOrders: 2,
      ),
      act: (cubit) => cubit.onCustomerEntered(),
      expect: () => [
        isA<ShopGameState>().having((s) => s.phase, 'phase', GamePhase.collectingItems),
      ],
    );

    blocTest<ShopGameCubit, ShopGameState>(
      'addItemToBasket adds correct item, updates floatingText, and triggers celebrating on match',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      seed: () => ShopGameState.initial().copyWith(
        phase: GamePhase.collectingItems,
        currentOrder: testOrders.first, // requiredQuantity: 2, redApple
        totalOrders: 2,
      ),
      act: (cubit) async {
        const apple = ItemEntity(
          id: 'apple_1',
          type: ItemType.redApple,
          nameVi: 'Táo đỏ',
          assetPath: '',
          shelfPosition: 0,
        );
        cubit.addItemToBasket(apple);
        cubit.addItemToBasket(apple);
      },
      expect: () => [
        isA<ShopGameState>()
            .having((s) => s.basketItems.length, 'basket count 1', 1)
            .having((s) => s.floatingText, 'floating text', 'Một!'),
        isA<ShopGameState>()
            .having((s) => s.basketItems.length, 'basket count 2', 2)
            .having((s) => s.floatingText, 'floating text', 'Hai!')
            .having((s) => s.phase, 'celebrating', GamePhase.celebrating),
      ],
    );

    blocTest<ShopGameCubit, ShopGameState>(
      'rejectItem increments errorsCount without changing phase',
      build: () => ShopGameCubit(
        repository: mockRepo,
        ttsService: mockTts,
        audioService: mockAudio,
      ),
      seed: () => ShopGameState.initial().copyWith(
        phase: GamePhase.collectingItems,
        currentOrder: testOrders.first,
        errorsCount: 0,
      ),
      act: (cubit) => cubit.rejectItem(const ItemEntity(
        id: 'b1',
        type: ItemType.banana,
        nameVi: 'Chuối',
        assetPath: '',
        shelfPosition: 1,
      )),
      expect: () => [
        isA<ShopGameState>().having((s) => s.errorsCount, 'errorsCount', 1),
      ],
    );
  });
}
