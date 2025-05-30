import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/user/cubit/user_info/get_user_info_cubit.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:fun_edu/widget/background_v2.dart';
import 'package:fun_edu/widget/home_card.dart';
import 'package:fun_edu/model/home_type.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GetUserInfoCubit _getUserInfoCubit;
  late final String? _deviceId;
  String _defaultUserName = "bé";

  @override
  void initState() {
    super.initState();
    _defaultUserName =
        GetIt.instance.get<SharedPreferencesManager>().getString("user_name") ??
            "bé";
    if (_defaultUserName.isEmpty) {
      // fallback nếu rỗng
      _defaultUserName = "bé";
    }
    _deviceId =
        GetIt.instance.get<SharedPreferencesManager>().getString("deviceId");

    _getUserInfoCubit = GetUserInfoCubit();

    if (_deviceId != null) {
      _getUserInfoCubit.getDeviceInfo(deviceId: _deviceId);
    }
  }

  @override
  void dispose() {
    _getUserInfoCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _getUserInfoCubit,
      child: Scaffold(
        backgroundColor: ColorBase.secondaryBackground,
        body: Stack(
          children: [
            const BackgroundV2(),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<GetUserInfoCubit, GetUserInfoState>(
                      builder: (context, state) {
                        final userName = (state is GetUserInfoLoadedState)
                            ? state.user.userName ?? _defaultUserName
                            : _defaultUserName;

                        final userCoin = (state is GetUserInfoLoadedState)
                            ? state.user.coin
                            : null;

                        return _GreetingSection(
                          userName: userName,
                          userCoin: userCoin,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _DailyTaskCard(
                      height: size.height * 0.18,
                      userCoin: context.select<GetUserInfoCubit, int?>((cubit) {
                        final state = cubit.state;
                        return state is GetUserInfoLoadedState
                            ? state.user.coin
                            : null;
                      }),
                      onTap: () {
                        final coin = context.read<GetUserInfoCubit>().state
                                is GetUserInfoLoadedState
                            ? (context.read<GetUserInfoCubit>().state
                                    as GetUserInfoLoadedState)
                                .user
                                .coin
                            : null;
                        context.pushNamed(
                          GoRouterName.dailyTask.routeName,
                          queryParams: {"userCoin": coin?.toString() ?? ""},
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          if (_deviceId != null) {
                            _getUserInfoCubit.getDeviceInfo(
                                deviceId: _deviceId);
                          }
                        },
                        child: MasonryGridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2),
                          itemCount: HomeType.values.length,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          itemBuilder: (context, index) {
                            return HomeCard(homeType: HomeType.values[index]);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 72),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final String userName;
  final int? userCoin;

  const _GreetingSection({
    required this.userName,
    required this.userCoin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              flex: 2,
              child: Text(
                'Chào $userName!',
                style: const TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: ColorBase.primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
                      userCoin?.toString() ?? "-",
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
        const SizedBox(height: 4),
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
}

class _DailyTaskCard extends StatelessWidget {
  final double height;
  final int? userCoin;
  final VoidCallback onTap;

  const _DailyTaskCard({
    required this.height,
    required this.userCoin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('assets/images/dailyTask.png'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 13, bottom: 4),
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
}
