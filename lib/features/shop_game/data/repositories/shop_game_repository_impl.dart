import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/datasources/shop_game_levels_data.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';
import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';

class ShopGameRepositoryImpl implements IShopGameRepository {
  final LocalShopDataSource _localDataSource;

  ShopGameRepositoryImpl(this._localDataSource);

  @override
  Future<ChildProfileEntity> getChildProfile() async {
    final model = await _localDataSource.getChildProfile();
    return model.toEntity();
  }

  @override
  Future<void> saveChildProfile(ChildProfileEntity profile) async {
    final model = ChildProfileModel.fromEntity(profile);
    await _localDataSource.saveChildProfile(model);
  }

  @override
  Future<LevelEntity> getLevel(String levelId) async {
    final levelModel = ShopGameLevelsData.levels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => ShopGameLevelsData.levels.first,
    );
    return levelModel.toEntity();
  }

  @override
  Future<List<LevelEntity>> getAvailableLevels() async {
    return ShopGameLevelsData.levels.map((l) => l.toEntity()).toList();
  }

  @override
  Future<void> recordPlaySession(PlaySessionEntity session) async {
    final model = PlaySessionModel.fromEntity(session);
    await _localDataSource.recordPlaySession(model);
  }

  @override
  Future<int> getTotalStars() async {
    final profile = await getChildProfile();
    return profile.totalStars;
  }

  @override
  Future<void> updateLevelStars(String levelId, int stars) async {
    await _localDataSource.saveLevelStars(levelId, stars);
  }
}
