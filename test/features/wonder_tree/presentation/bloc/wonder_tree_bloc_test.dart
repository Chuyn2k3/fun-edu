import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/features/wonder_tree/domain/models/wonder_tree_stage.dart';
import 'package:fun_edu/features/wonder_tree/presentation/bloc/wonder_tree_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fun_edu/core/storage/hive_storage_service.dart';
import 'package:fun_edu/core/event_bus/app_event_bus.dart';

class MockHiveStorageService extends Mock implements HiveStorageService {}

void main() {
  late MockHiveStorageService mockStorage;
  late AppEventBus eventBus;

  setUp(() {
    mockStorage = MockHiveStorageService();
    eventBus = AppEventBus();
  });

  blocTest<WonderTreeBloc, WonderTreeState>(
    'emits updated streak and stage when WaterTreeEvent is added',
    setUp: () {
      var streak = 0;
      when(() => mockStorage.getTreeWateringStreak()).thenAnswer((_) => streak);
      when(() => mockStorage.incrementTreeWateringStreak())
          .thenAnswer((_) async {
        streak++;
      });
      when(() => mockStorage.recordWateredToday()).thenAnswer((_) async {});
    },
    build: () => WonderTreeBloc(storage: mockStorage, eventBus: eventBus),
    act: (bloc) => bloc.add(const WaterTreeEvent()),
    expect: () => [
      const WonderTreeState(streak: 1, stage: WonderTreeStage.seed, canWaterToday: false),
    ],
  );

  test('WonderTreeStageExt maps streak to correct stages', () {
    expect(WonderTreeStageExt.fromStreak(0), WonderTreeStage.seed);
    expect(WonderTreeStageExt.fromStreak(1), WonderTreeStage.seed);
    expect(WonderTreeStageExt.fromStreak(2), WonderTreeStage.seedling);
    expect(WonderTreeStageExt.fromStreak(3), WonderTreeStage.seedling);
    expect(WonderTreeStageExt.fromStreak(4), WonderTreeStage.blooming);
    expect(WonderTreeStageExt.fromStreak(5), WonderTreeStage.goldenFruit);
  });
}
