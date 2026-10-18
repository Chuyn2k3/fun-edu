import 'package:fun_edu/features/shop_game/domain/entities/order_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';

class GenerateOrderUseCase {
  final IShopGameRepository _repository;

  const GenerateOrderUseCase(this._repository);

  Future<List<OrderEntity>> call(String levelId) async {
    final level = await _repository.getLevel(levelId);
    return level.orders;
  }
}
