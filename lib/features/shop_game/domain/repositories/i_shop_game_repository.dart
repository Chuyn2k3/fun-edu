import 'package:fun_edu/features/shop_game/domain/entities/child_profile_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/level_entity.dart';
import 'package:fun_edu/features/shop_game/domain/entities/play_session_entity.dart';

abstract class IShopGameRepository {
  Future<ChildProfileEntity> getChildProfile();
  Future<void> saveChildProfile(ChildProfileEntity profile);
  Future<LevelEntity> getLevel(String levelId);
  Future<List<LevelEntity>> getAvailableLevels();
  Future<void> recordPlaySession(PlaySessionEntity session);
  Future<int> getTotalStars();
  Future<void> updateLevelStars(String levelId, int stars);
}
