import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/core/event_bus/app_event_bus.dart';
import 'package:fun_edu/core/event_bus/app_events.dart';
import 'package:fun_edu/core/storage/hive_storage_service.dart';
import 'package:fun_edu/features/wonder_tree/domain/models/wonder_tree_stage.dart';

abstract class WonderTreeEvent extends Equatable {
  const WonderTreeEvent();
  @override
  List<Object?> get props => [];
}

class LoadWonderTreeEvent extends WonderTreeEvent {
  const LoadWonderTreeEvent();
}

class WaterTreeEvent extends WonderTreeEvent {
  const WaterTreeEvent();
}

class WonderTreeState extends Equatable {
  final int streak;
  final WonderTreeStage stage;
  final bool canWaterToday;

  const WonderTreeState({
    required this.streak,
    required this.stage,
    required this.canWaterToday,
  });

  @override
  List<Object?> get props => [streak, stage, canWaterToday];
}

class WonderTreeBloc extends Bloc<WonderTreeEvent, WonderTreeState> {
  final HiveStorageService _storage;
  final AppEventBus _eventBus;

  WonderTreeBloc({
    required HiveStorageService storage,
    required AppEventBus eventBus,
  })  : _storage = storage,
        _eventBus = eventBus,
        super(WonderTreeState(
          streak: storage.getTreeWateringStreak(),
          stage: WonderTreeStageExt.fromStreak(storage.getTreeWateringStreak()),
          canWaterToday: true,
        )) {
    on<WaterTreeEvent>(_onWaterTree);
  }

  Future<void> _onWaterTree(
    WaterTreeEvent event,
    Emitter<WonderTreeState> emit,
  ) async {
    await _storage.incrementTreeWateringStreak();
    await _storage.recordWateredToday();
    final newStreak = _storage.getTreeWateringStreak();
    final newStage = WonderTreeStageExt.fromStreak(newStreak);

    _eventBus.fire(TreeWateredEvent(currentStreak: newStreak));

    emit(WonderTreeState(
      streak: newStreak,
      stage: newStage,
      canWaterToday: false,
    ));
  }
}
