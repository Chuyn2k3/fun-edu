import 'package:dio/dio.dart';
import 'package:fun_edu/core/repositories/question_repository.dart';
import 'package:fun_edu/core/repositories/user_repository.dart';
import 'package:fun_edu/core/services/audio_service.dart';
import 'package:fun_edu/core/services/question_service.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/core/services/user_service.dart';
import 'package:fun_edu/cubit/sidebar/sidebar_cubit.dart';
import 'package:fun_edu/features/shop_game/data/datasources/local_shop_datasource.dart';
import 'package:fun_edu/features/shop_game/data/repositories/shop_game_repository_impl.dart';
import 'package:fun_edu/features/shop_game/domain/repositories/i_shop_game_repository.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/generate_order_usecase.dart';
import 'package:fun_edu/features/shop_game/domain/usecases/record_play_log_usecase.dart';
import 'package:fun_edu/features/shop_game/presentation/cubit/shop_game_cubit.dart';
import 'package:fun_edu/utils/http_services.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

GetIt serviceLocator = GetIt.instance;
GetIt get locator => serviceLocator;

Future<void> setupShopGameLocator() async {
  final localDataSource = LocalShopDataSource();
  await localDataSource.init();
  serviceLocator.registerLazySingleton<LocalShopDataSource>(() => localDataSource);

  serviceLocator.registerLazySingleton<IShopGameRepository>(
      () => ShopGameRepositoryImpl(serviceLocator<LocalShopDataSource>()));

  serviceLocator.registerFactory<GenerateOrderUseCase>(
      () => GenerateOrderUseCase(serviceLocator<IShopGameRepository>()));
  serviceLocator.registerFactory<RecordPlayLogUseCase>(
      () => RecordPlayLogUseCase(serviceLocator<IShopGameRepository>()));

  serviceLocator.registerLazySingleton<TtsService>(() => TtsService());
  serviceLocator.registerLazySingleton<AudioService>(() => AudioService());

  serviceLocator.registerFactory<ShopGameCubit>(() => ShopGameCubit(
        repository: serviceLocator<IShopGameRepository>(),
        ttsService: serviceLocator<TtsService>(),
        audioService: serviceLocator<AudioService>(),
      ));
}

Future<void> setupLocator() async {
  //serviceLocator
  serviceLocator.registerLazySingleton(() => NavigationService());
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerLazySingleton(
      () => SharedPreferencesManager(sharedPreferences: sharedPreferences));

  final Dio dio =
      await setupDio(baseUrl: "http://202.191.56.11:80", isHaveToken: true);
  serviceLocator.registerLazySingleton<SidebarCubit>(() => SidebarCubit());
  serviceLocator
      .registerLazySingleton<QuestionService>(() => QuestionService(dio));
  serviceLocator.registerLazySingleton<UserServices>(() => UserServices(dio));
//
  serviceLocator.registerFactory<QuestionRepository>(() =>
      QuestionRepositoryImpl(
          questionService: serviceLocator<QuestionService>()));
  serviceLocator.registerFactory<UserRepository>(
      () => UserRepositoryImpl(userServices: serviceLocator<UserServices>()));

  await setupShopGameLocator();
}
