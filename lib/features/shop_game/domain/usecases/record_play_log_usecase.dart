import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';

class RecordPlayLogUseCase {
  final IShopGameRepository _repository;

  const RecordPlayLogUseCase(this._repository);

  Future<void> call(PlaySessionEntity session) async {
    await _repository.recordPlaySession(session);
  }
}
