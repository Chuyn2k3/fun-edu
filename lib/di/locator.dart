import 'package:dio/dio.dart';
import 'package:fun_edu/core/repositories/question_repository.dart';
import 'package:fun_edu/core/repositories/user_repository.dart';
import 'package:fun_edu/core/services/question_service.dart';
import 'package:fun_edu/core/services/user_service.dart';
import 'package:fun_edu/cubit/sidebar/sidebar_cubit.dart';
import 'package:fun_edu/utils/http_services.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

GetIt serviceLocator = GetIt.instance;

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
}
