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
                          queryParams: {"userCoin": coin?.toString() ?? "9999"},
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ShopGameBanner(
                      onTap: () {
                        context.pushNamed(GoRouterName.shopGameLevelSelect.routeName);
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
        //margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Phiên bản 1: Gradient tím-hồng hiện đại
          gradient: const LinearGradient(
            colors: [
              Color(0xFF667eea), // Tím nhạt
              Color(0xFF764ba2), // Tím đậm
              Color(0xFFf093fb), // Hồng nhạt
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          
          // Phiên bản 2: Gradient xanh dương-xanh lá (bỏ comment để dùng)
          // gradient: const LinearGradient(
          //   colors: [
          //     Color(0xFF4facfe), // Xanh dương nhạt
          //     Color(0xFF00f2fe), // Xanh cyan
          //   ],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
          
          // Phiên bản 3: Gradient cam-hồng hoàng hôn (bỏ comment để dùng)
          // gradient: const LinearGradient(
          //   colors: [
          //     Color(0xFFfa709a), // Hồng
          //     Color(0xFFfee140), // Vàng cam
          //   ],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        // decoration: const BoxDecoration(
        //   image: DecorationImage(
        //     fit: BoxFit.fill,
        //     image: AssetImage('assets/images/dailyTask.png'),
        //   ),
        // ),
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

class _ShopGameBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ShopGameBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF9966),
              Color(0xFFFF5E62),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E62).withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Text('🏪', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'MỚI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Mini-game Toán Học',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tiệm Tạp Hóa Nhí',
                    style: TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tập đếm & bán hàng cùng Bác Ba 🍎🐻',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFFFF5E62),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
