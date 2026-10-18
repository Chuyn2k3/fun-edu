import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:get_it/get_it.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/generate_order_usecase.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/record_play_log_usecase.dart';
import 'package:fun_edu/di/locator.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_di_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('setupShopGameLocator registers all shop game services and use cases', () async {
    await setupShopGameLocator();

    expect(GetIt.instance.isRegistered<LocalShopDataSource>(), isTrue);
    expect(GetIt.instance.isRegistered<IShopGameRepository>(), isTrue);
    expect(GetIt.instance.isRegistered<GenerateOrderUseCase>(), isTrue);
    expect(GetIt.instance.isRegistered<RecordPlayLogUseCase>(), isTrue);
    expect(GetIt.instance.isRegistered<TtsService>(), isTrue);
    expect(GetIt.instance.isRegistered<AudioService>(), isTrue);
  });
}
