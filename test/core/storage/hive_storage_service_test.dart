import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/core/storage/hive_storage_service.dart';
import 'package:fun_edu/core/storage/storage_keys.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  late HiveStorageService storage;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    final userBox = await Hive.openBox(StorageKeys.userBox);
    final gameBox = await Hive.openBox(StorageKeys.gameBox);
    storage = HiveStorageService(userBox: userBox, gameBox: gameBox);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('getCoins returns default 0, saveCoins updates value', () async {
    expect(storage.getCoins(), 0);
    await storage.saveCoins(50);
    expect(storage.getCoins(), 50);
  });

  test('tree watering day streak is incremented correctly', () async {
    expect(storage.getTreeWateringStreak(), 0);
    await storage.incrementTreeWateringStreak();
    expect(storage.getTreeWateringStreak(), 1);
  });

  test('recordWateredToday stores timestamp', () async {
    expect(storage.getLastWateredTimestamp(), isNull);
    await storage.recordWateredToday();
    expect(storage.getLastWateredTimestamp(), isNotNull);
  });
}
