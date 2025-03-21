import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/data/models/score_info_model.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/data/repositories/game_repository.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';

part 'score_provider.freezed.dart';

@freezed
class ScoreState with _$ScoreState {
  const factory ScoreState({
    @Default(0) int score,
    @Default(0) int highScore,
    @Default([]) List<ScoreInfo> topHighScores,
    @Default(false) bool isLoading,
    @Default('') String nickname,
  }) = _ScoreState;

  const ScoreState._();
}

final scoreNotifierProvider = StateNotifierProvider<ScoreNotifier, ScoreState>(
  (ref) => ScoreNotifier(ref.read(gameRepositoryProvider), ref),
);

class ScoreNotifier extends StateNotifier<ScoreState> {
  final GameRepository _gameRepository;
  Ref ref;

  ScoreNotifier(this._gameRepository, this.ref) : super(const ScoreState());

  Future<void> loadScores() async {
    final currentScore = state.score;
    final highScore = 
        GetIt.instance.get<SharedPreferencesManager>().getInt("high_score");
    state.copyWith(
      highScore: highScore ?? 0,
    );
    if (currentScore > state.highScore) {
      state = state.copyWith(
        highScore: currentScore,
      );
      GetIt.instance
          .get<SharedPreferencesManager>()
          .putInt("high_score", currentScore);
    }
  }

  resetScore() {
    state = state.copyWith(score: 0);
  }

  bool encreaseScore() {
    state = state.copyWith(score: state.score + 1);
    final currentScore = state.score;
    final highScore =
        GetIt.instance.get<SharedPreferencesManager>().getInt("high_score");
    state.copyWith(
      highScore: highScore ?? 0,
    );
    if (currentScore > state.highScore) {
      state = state.copyWith(
        highScore: currentScore,
      );
      GetIt.instance
          .get<SharedPreferencesManager>()
          .putInt("high_score", currentScore);
    }
    return state.score % 10 == 0;
  }
}

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});
