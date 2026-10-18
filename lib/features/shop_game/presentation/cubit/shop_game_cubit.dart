import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:fun_edu/core/constants/audio_paths.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_state.dart';

class ShopGameCubit extends Cubit<ShopGameState> {
  final IShopGameRepository _repository;
  final TtsService _ttsService;
  final AudioService _audioService;

  DateTime? _orderStartTime;
  Timer? _idleTimer;

  ShopGameCubit({
    required IShopGameRepository repository,
    required TtsService ttsService,
    required AudioService audioService,
  })  : _repository = repository,
        _ttsService = ttsService,
        _audioService = audioService,
        super(ShopGameState.initial());

  Future<void> startGame(String levelId) async {
    emit(state.copyWith(phase: GamePhase.loading));
    await _ttsService.init();
    await _audioService.init();
    await _audioService.playBgm(AudioPaths.bgmShop);

    final level = await _repository.getLevel(levelId);
    final profile = await _repository.getChildProfile();

    final firstOrder = level.orders.isNotEmpty
        ? level.orders.first
        : const OrderEntity(id: 'o_def', requiredItem: ItemType.redApple, requiredQuantity: 1);

    _orderStartTime = DateTime.now();

    emit(state.copyWith(
      phase: GamePhase.customerEntering,
      levelId: levelId,
      childName: profile.name,
      orders: level.orders,
      currentOrder: firstOrder,
      currentOrderIndex: 0,
      totalOrders: level.orders.length,
      basketItems: const [],
      starCount: 0,
      errorsCount: 0,
      isHandTutorVisible: false,
      orderStarsHistory: const [],
    ));

    // Speak initial order
    final speech = TtsScriptBuilder.buildCustomerOrderSpeech(
      profile.name,
      firstOrder.requiredQuantity,
      firstOrder.requiredItem,
    );
    await _ttsService.speak(speech);
  }

  void onCustomerEntered() {
    emit(state.copyWith(phase: GamePhase.collectingItems));
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 7), () {
      if (state.phase == GamePhase.collectingItems) {
        emit(state.copyWith(isHandTutorVisible: true));
      }
    });
  }

  void hideHandTutor() {
    if (state.isHandTutorVisible) {
      emit(state.copyWith(isHandTutorVisible: false));
    }
    _startIdleTimer();
  }

  bool get isMuted => _audioService.isMuted;

  void toggleMute() {
    _audioService.toggleMute();
  }

  void onItemDroppedToBasket(ItemEntity item) => addItemToBasket(item);

  void addItemToBasket(ItemEntity item) {
    hideHandTutor();

    if (item.type != state.currentOrder.requiredItem) {
      rejectItem(item);
      return;
    }

    final newBasket = List<ItemEntity>.from(state.basketItems)..add(item);
    final count = newBasket.length;
    final countWord = TtsScriptBuilder.buildCountingSpeech(count);

    _audioService.playSfx(AudioPaths.sfxDropCorrect);
    _audioService.playSfx(AudioPaths.sfxBasketBounce);
    _ttsService.speak(countWord);

    if (count >= state.currentOrder.requiredQuantity) {
      // Completed this order!
      _handleOrderCompleted(newBasket, countWord);
    } else {
      emit(state.copyWith(
        basketItems: newBasket,
        floatingText: countWord,
      ));
    }
  }

  void rejectItem(ItemEntity item) {
    hideHandTutor();
    final newErrors = state.errorsCount + 1;
    _audioService.playSfx(AudioPaths.sfxDropWrong);
    final wrongSpeech = TtsScriptBuilder.buildWrongItemSpeech(state.currentOrder.requiredItem);
    _ttsService.speak(wrongSpeech);

    emit(state.copyWith(errorsCount: newErrors));
  }

  Future<void> _handleOrderCompleted(List<ItemEntity> newBasket, String countWord) async {
    _idleTimer?.cancel();

    // Calculate stars for this order:
    // 0 errors -> 3 stars, 1-2 errors -> 2 stars, 3+ -> 1 star
    final int earnedStars;
    if (state.errorsCount == 0) {
      earnedStars = 3;
    } else if (state.errorsCount <= 2) {
      earnedStars = 2;
    } else {
      earnedStars = 1;
    }

    final newHistory = List<int>.from(state.orderStarsHistory)..add(earnedStars);

    // Save play session log
    final session = PlaySessionEntity(
      id: const Uuid().v4(),
      levelId: state.levelId,
      orderId: state.currentOrder.id,
      startedAt: _orderStartTime ?? DateTime.now(),
      completedAt: DateTime.now(),
      errorsCount: state.errorsCount,
      starsEarned: earnedStars,
      completed: true,
    );
    await _repository.recordPlaySession(session);

    _audioService.playSfx(AudioPaths.sfxConfetti);
    _audioService.playSfx(AudioPaths.sfxStarCollect);
    _audioService.playSfx(AudioPaths.sfxCoinDrop);

    emit(state.copyWith(
      phase: GamePhase.celebrating,
      basketItems: newBasket,
      floatingText: countWord,
      starCount: state.starCount + earnedStars,
      orderStarsHistory: newHistory,
    ));

    await _ttsService.speak(TtsScriptBuilder.buildOrderCompleteSpeech());
  }

  Future<void> nextCustomerOrFinish() async {
    final nextIndex = state.currentOrderIndex + 1;
    if (nextIndex >= state.totalOrders) {
      // Level Completed!
      await _handleLevelCompleted();
    } else {
      final nextOrder = state.orders[nextIndex];
      _orderStartTime = DateTime.now();
      emit(state.copyWith(
        phase: GamePhase.customerEntering,
        currentOrder: nextOrder,
        currentOrderIndex: nextIndex,
        basketItems: const [],
        errorsCount: 0,
        floatingText: null,
      ));

      final speech = TtsScriptBuilder.buildCustomerOrderSpeech(
        state.childName,
        nextOrder.requiredQuantity,
        nextOrder.requiredItem,
      );
      await _ttsService.speak(speech);
    }
  }

  Future<void> _handleLevelCompleted() async {
    _idleTimer?.cancel();
    final totalOrderStars = state.orderStarsHistory.fold<int>(0, (sum, s) => sum + s);
    final avgStars = (state.orderStarsHistory.isNotEmpty)
        ? (totalOrderStars / state.orderStarsHistory.length).round()
        : 3;

    await _repository.updateLevelStars(state.levelId, avgStars);
    _audioService.playSfx(AudioPaths.sfxLevelComplete);
    await _ttsService.speak(TtsScriptBuilder.buildLevelCompleteSpeech());

    emit(state.copyWith(
      phase: GamePhase.levelComplete,
      floatingText: null,
    ));
  }

  @override
  Future<void> close() {
    _idleTimer?.cancel();
    _audioService.stopBgm();
    _ttsService.stop();
    return super.close();
  }
}
