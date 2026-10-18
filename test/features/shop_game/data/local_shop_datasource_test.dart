import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/models/child_profile_model.dart';
import 'package:fun_edu/features/shop_game/data/models/play_session_model.dart';

void main() {
  late Directory tempDir;
  late LocalShopDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    dataSource = LocalShopDataSource();
    await dataSource.init();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalShopDataSource Tests', () {
    test('returns default profile when none exists and allows saving', () async {
      final profile = await dataSource.getChildProfile();
      expect(profile.name, isNotEmpty);
      expect(profile.totalStars, 0);

      final updated = ChildProfileModel(
        id: profile.id,
        name: 'Bé Tít',
        age: 5,
        totalStars: 10,
        totalCoins: 30,
        levelStars: const {'level_1': 3},
        createdAt: profile.createdAt,
      );
      await dataSource.saveChildProfile(updated);

      final reloaded = await dataSource.getChildProfile();
      expect(reloaded.name, 'Bé Tít');
      expect(reloaded.totalStars, 10);
      expect(reloaded.levelStars['level_1'], 3);
    });

    test('records and retrieves play session logs', () async {
      final session = PlaySessionModel(
        id: 'sess_123',
        levelId: 'level_1',
        orderId: 'l1_o1',
        startedAt: DateTime.now().toIso8601String(),
        errorsCount: 0,
        starsEarned: 3,
        completed: true,
      );

      await dataSource.recordPlaySession(session);
      final logs = await dataSource.getPlaySessions();
      expect(logs.length, 1);
      expect(logs.first.id, 'sess_123');
    });

    test('updates and returns level stars progress', () async {
      await dataSource.saveLevelStars('level_1', 3);
      final stars = await dataSource.getLevelStars('level_1');
      expect(stars, 3);
    });
  });
}
