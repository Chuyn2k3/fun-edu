import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/core/colors/app_colors.dart';
import 'package:fun_edu/core/theme/app_themes.dart';
import 'package:fun_edu/cubit/sidebar/sidebar_cubit.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/feature/manager_user/cubit/get_user_all_cubit.dart';
import 'package:fun_edu/feature/user/cubit/user_info/get_user_info_cubit.dart';
import 'package:fun_edu/helper/pref.dart';
import 'package:fun_edu/router/app_router.dart';
import 'package:fun_edu/utils/device_id_service.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:fun_edu/widget/breakpoint_label.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:toastification/toastification.dart';

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
  List<Breakpoint> get breakpoints {
    return [
      const Breakpoint(start: 0, end: 480, name: MOBILE),
      const Breakpoint(start: 481, end: 767, name: TABLET),
      const Breakpoint(
        start: 768,
        end: 1024,
        name: smallDesktop,
      ), // Laptops and small screen
      const Breakpoint(
        start: 1025,
        end: 1200,
        name: DESKTOP,
      ), // Large screens and Desktops
      const Breakpoint(
        start: 1201,
        end: double.infinity,
        name: tv,
      ), // TV and Extra Large Screens
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppRouter appRouter = AppRouter();
    return AppThemes(
      appColors: appColors,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => deviceId != null
                ? (GetUserInfoCubit()..getDeviceInfo(deviceId: deviceId ?? ""))
                : GetUserInfoCubit(),
          ),
          BlocProvider(
            create: (context) => serviceLocator<SidebarCubit>(),
          ),
          BlocProvider(
            create: (context) => serviceLocator<GetAllUserCubit>(),
          ),
        ],
        child: ToastificationWrapper(
          child: MaterialApp.router(
            themeMode: Pref.defaultTheme,
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
            routerConfig: appRouter.router, // Sử dụng GoRouter ở đây
            debugShowCheckedModeBanner: false,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: breakpoints,
            ),
          ),
        ),
      ),
    );
  }
}
