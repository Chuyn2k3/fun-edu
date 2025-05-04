import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/user/cubit/user_info/get_user_info_cubit.dart';
import 'package:fun_edu/screen/offline_game_screen.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:fun_edu/widget/background_v2.dart';
import 'package:fun_edu/widget/home_card.dart';
import 'package:fun_edu/model/home_type.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/HomePage';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "bé";
  int? userCoin;
  late GetUserInfoCubit getUserInfoCubit;
  String? deviceId;
  @override
  void initState() {
    super.initState();
    userName =
        GetIt.instance.get<SharedPreferencesManager>().getString("user_name") ??
            "bé";
    if (userName.isEmpty) {
      userName = "bé";
    }
    final _deviceId =
        GetIt.instance.get<SharedPreferencesManager>().getString("deviceId");
    deviceId = _deviceId;
    print(_deviceId);
    getUserInfoCubit = GetUserInfoCubit();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (context) => deviceId != null
              ? (getUserInfoCubit..getDeviceInfo(deviceId: deviceId ?? ""))
              : getUserInfoCubit,
        )
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<GetUserInfoCubit, GetUserInfoState>(
            listener: (context, state) {
              if (state is GetUserInfoLoadedState) {
                final name = state.user.userName;
                final coin = state.user.coin;
                print(name ?? "" + "hehe");
                print(coin ?? "" + "hehe");
                setState(() {
                  userName = name ?? userName;
                  userCoin = coin ?? userCoin;
                });
              }
            },
          )
        ],
        child: Scaffold(
          backgroundColor: ColorBase.secondaryBackground,
          body: Stack(
            children: [
              const BackgroundV2(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreetingSection(),
                      const SizedBox(height: 8),
                      _buildDailyTaskCard(context),
                      const SizedBox(height: 12),
                      Expanded(child: _buildHomeGrid()),
                      const SizedBox(height: 72
                          //MediaQuery.of(context).size.height * 0.12
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget phần chào hỏi
  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Chào $userName!',
              style: const TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: ColorBase.primaryText,
              ),
            ),
            SizedBox(
              width: 8,
            ),
            // Coin display
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      userCoin != null ? '${userCoin ?? 0}' : "-",
                      style: const TextStyle(
                        fontFamily: 'LilitaOne',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorBase.primaryText,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),

        //const SizedBox(height: 4),
        const Text(
          'Hãy cùng nhau học và chơi nhé!',
          style: TextStyle(
            fontFamily: 'LilitaOne',
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: ColorBase.secondaryText,
          ),
        ),
      ],
    );
  }

  /// Widget hiển thị daily task card
  Widget _buildDailyTaskCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfflineScreen(userCoin: userCoin ?? 0),
            ));
      },
      child: Container(
        width: double.infinity,
        height: size.height * 0.18,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('assets/images/dailyTask.png'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 13,
            bottom: 4,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khám phá',
                      style: TextStyle(
                        fontFamily: 'LilitaOne',
                        fontSize: 16,
                        color: ColorBase.primaryBackground,
                      ),
                    ),
                    Text(
                      'Nhiệm vụ mỗi ngày',
                      style: TextStyle(
                        fontFamily: 'LilitaOne',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorBase.primaryBackground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorBase.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 4,
                      color: Colors.black26,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow,
                        color: ColorBase.primaryText, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Bắt đầu chơi!',
                      style: TextStyle(
                        fontFamily: 'LilitaOne',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorBase.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget hiển thị danh sách các mục học tập
  Widget _buildHomeGrid() {
    return RefreshIndicator(
      onRefresh: () async {
        if (deviceId != null) {
          getUserInfoCubit.getDeviceInfo(deviceId: deviceId ?? "");
        }
      },
      child: MasonryGridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: HomeType.values.length,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemBuilder: (context, index) {
          return HomeCard(homeType: HomeType.values[index]);
        },
      ),
    );
  }
}
