import 'package:hive_flutter/hive_flutter.dart';
import 'package:fun_edu/core/storage/storage_keys.dart';

class HiveStorageService {
  final Box _userBox;
  final Box _gameBox;

  HiveStorageService({required Box userBox, required Box gameBox})
      : _userBox = userBox,
        _gameBox = gameBox;

  int getCoins() => _userBox.get(StorageKeys.coins, defaultValue: 0) as int;

  Future<void> saveCoins(int amount) async {
    await _userBox.put(StorageKeys.coins, amount);
  }

  int getTreeWateringStreak() =>
      _gameBox.get(StorageKeys.treeWateringStreak, defaultValue: 0) as int;

  Future<void> incrementTreeWateringStreak() async {
    final current = getTreeWateringStreak();
    await _gameBox.put(StorageKeys.treeWateringStreak, current + 1);
  }

  int? getLastWateredTimestamp() =>
      _gameBox.get(StorageKeys.lastWateredTimestamp) as int?;

  Future<void> recordWateredToday() async {
    await _gameBox.put(
      StorageKeys.lastWateredTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
