import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';
import 'package:fun_edu/features/shop_game/data/repositories/shop_game_repository_impl.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

class MockLocalShopDataSource extends Mock implements LocalShopDataSource {}

void main() {
  late MockLocalShopDataSource mockDataSource;
  late ShopGameRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(ChildProfileModel(
      id: 'id',
      name: 'name',
      age: 4,
      totalStars: 0,
      totalCoins: 0,
      levelStars: const {},
      createdAt: DateTime.now().toIso8601String(),
    ));
    registerFallbackValue(PlaySessionModel(
      id: 'id',
      levelId: 'level_1',
      orderId: 'o1',
      startedAt: DateTime.now().toIso8601String(),
      errorsCount: 0,
      starsEarned: 3,
      completed: true,
    ));
  });

  setUp(() {
    mockDataSource = MockLocalShopDataSource();
    repository = ShopGameRepositoryImpl(mockDataSource);
  });

  group('ShopGameRepositoryImpl Tests', () {
    test('getChildProfile converts Model to Entity', () async {
      final model = ChildProfileModel(
        id: 'c1',
        name: 'Bé Miu',
        age: 5,
        totalStars: 9,
        totalCoins: 45,
        levelStars: const {'level_1': 3},
        createdAt: DateTime(2026, 1, 1).toIso8601String(),
      );
      when(() => mockDataSource.getChildProfile()).thenAnswer((_) async => model);

      final profile = await repository.getChildProfile();
      expect(profile.name, 'Bé Miu');
      expect(profile.totalStars, 9);
    });

    test('getLevel returns level from hardcoded data', () async {
      final level = await repository.getLevel('level_1');
      expect(level.id, 'level_1');
      expect(level.orders.length, 5);
    });

    test('getAvailableLevels returns all 3 levels', () async {
      final levels = await repository.getAvailableLevels();
      expect(levels.length, 3);
    });

    test('recordPlaySession delegates to datasource', () async {
      when(() => mockDataSource.recordPlaySession(any())).thenAnswer((_) async => {});

      final session = PlaySessionEntity(
        id: 's1',
        levelId: 'level_1',
        orderId: 'o1',
        startedAt: DateTime.now(),
        errorsCount: 0,
        starsEarned: 3,
        completed: true,
      );

      await repository.recordPlaySession(session);
      verify(() => mockDataSource.recordPlaySession(any())).called(1);
    });
  });
}
