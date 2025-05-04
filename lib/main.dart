import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/core/colors/app_colors.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/feature/user/cubit/user_info/get_user_info_cubit.dart';
import 'package:fun_edu/helper/ad_helper.dart';
import 'package:fun_edu/helper/pref.dart';
import 'package:fun_edu/routes.dart';
import 'package:fun_edu/screen/splash_screen.dart';
import 'package:fun_edu/utils/device_id.dart';
import 'package:fun_edu/utils/device_id_service.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_it/get_it.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  // init hive
  await Pref.initialize();
  // for initializing facebook ads sdk
  //AdHelper.init();
  await DeviceIdService.getDeviceId();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const ProviderScope(child: MyApp()));
}

final navigatorKey = GetIt.instance<NavigationService>().navigatorKey;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

@override
void initState() {
  if (!kIsWeb) {
    saveDeviceId();
  }
}

void saveDeviceId() async {
  final deviceId = await DeviceIdService.getDeviceId();
  final pref = GetIt.instance<SharedPreferencesManager>();
  if (deviceId != null) {
    await pref.putString("deviceId", deviceId);
  }
}

class _MyAppState extends State<MyApp> {
  final appColors = AppColors.light();
  final deviceId =
      GetIt.instance.get<SharedPreferencesManager>().getString('deviceId');
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => deviceId != null
              ? (GetUserInfoCubit()..getDeviceInfo(deviceId: deviceId ?? ""))
              : GetUserInfoCubit(),
        ),
      ],
      child: GetMaterialApp(
        themeMode: Pref.defaultTheme,

        //dark
        // darkTheme: ThemeData(
        //     useMaterial3: false,
        //     brightness: Brightness.dark,
        //     appBarTheme: const AppBarTheme(
        //       elevation: 1,
        //       centerTitle: true,
        //       titleTextStyle:
        //           TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        //     )),

        //light
        theme: ThemeData(
            fontFamily: 'LilitaOne',
            useMaterial3: false,
            appBarTheme: const AppBarTheme(
              elevation: 1,
              centerTitle: true,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.blue),
              titleTextStyle: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            )),
        navigatorKey: navigatorKey,
        routes: routes,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: SplashScreen(),
        ),
      ),
    );
  }
}
