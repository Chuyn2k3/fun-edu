import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';

class LocalShopDataSource {
  static const String profileBoxName = 'child_profile';
  static const String levelProgressBoxName = 'level_progress';
  static const String playSessionsBoxName = 'play_sessions';
  static const String appSettingsBoxName = 'app_settings';

  Box? _profileBox;
  Box? _progressBox;
  Box? _sessionsBox;
  Box? _settingsBox;

  Future<void> init() async {
    _profileBox = await Hive.openBox(profileBoxName);
    _progressBox = await Hive.openBox(levelProgressBoxName);
    _sessionsBox = await Hive.openBox(playSessionsBoxName);
    _settingsBox = await Hive.openBox(appSettingsBoxName);
  }

  Future<ChildProfileModel> getChildProfile() async {
    final raw = _profileBox?.get('current_child');
    if (raw == null) {
      final defaultProfile = ChildProfileModel(
        id: const Uuid().v4(),
        name: 'Bé',
        age: 4,
        totalStars: 0,
        totalCoins: 0,
        levelStars: const {},
        createdAt: DateTime.now().toIso8601String(),
      );
      await saveChildProfile(defaultProfile);
      return defaultProfile;
    }
    return ChildProfileModel.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> saveChildProfile(ChildProfileModel profile) async {
    await _profileBox?.put('current_child', profile.toMap());
  }

  Future<void> recordPlaySession(PlaySessionModel session) async {
    final list = _sessionsBox?.get('logs', defaultValue: <dynamic>[]) as List<dynamic>;
    final mutableList = List<dynamic>.from(list)..add(session.toMap());
    await _sessionsBox?.put('logs', mutableList);
  }

  Future<List<PlaySessionModel>> getPlaySessions() async {
    final list = _sessionsBox?.get('logs', defaultValue: <dynamic>[]) as List<dynamic>;
    return list
        .map((e) => PlaySessionModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveLevelStars(String levelId, int stars) async {
    await _progressBox?.put(levelId, stars);

    // Sync total stars into child profile
    final current = await getChildProfile();
    final updatedStarsMap = Map<String, int>.from(current.levelStars);
    final prevStars = updatedStarsMap[levelId] ?? 0;
    if (stars > prevStars) {
      updatedStarsMap[levelId] = stars;
      final newTotal = updatedStarsMap.values.fold<int>(0, (sum, v) => sum + v);
      await saveChildProfile(
        ChildProfileModel(
          id: current.id,
          name: current.name,
          age: current.age,
          totalStars: newTotal,
          totalCoins: current.totalCoins + (stars - prevStars) * 5,
          levelStars: updatedStarsMap,
          createdAt: current.createdAt,
        ),
      );
    }
  }

  Future<int> getLevelStars(String levelId) async {
    return (_progressBox?.get(levelId, defaultValue: 0) as int?) ?? 0;
  }
}
