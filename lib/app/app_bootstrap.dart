import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/app/app_bloc_observer.dart';
import 'package:fun_edu/core/audio/audio_manager.dart';
import 'package:fun_edu/core/event_bus/app_event_bus.dart';
import 'package:fun_edu/core/storage/hive_storage_service.dart';
import 'package:fun_edu/core/storage/storage_keys.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppBootstrap {
  static Future<void> init() async {
    // 1. Khởi tạo BLoC Observer toàn cục
    Bloc.observer = AppBlocObserver();

    // 2. Khởi tạo Hive Offline Storage
    await Hive.initFlutter();
    final userBox = await Hive.openBox(StorageKeys.userBox);
    final gameBox = await Hive.openBox(StorageKeys.gameBox);

    final storage = HiveStorageService(userBox: userBox, gameBox: gameBox);
    final eventBus = AppEventBus();
    final audioManager = AudioManager();

    // 3. Đăng ký Service Locator (GetIt)
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<HiveStorageService>()) {
      getIt.registerSingleton<HiveStorageService>(storage);
    }
    if (!getIt.isRegistered<AppEventBus>()) {
      getIt.registerSingleton<AppEventBus>(eventBus);
    }
    if (!getIt.isRegistered<AudioManager>()) {
      getIt.registerSingleton<AudioManager>(audioManager);
    }
  }
}
