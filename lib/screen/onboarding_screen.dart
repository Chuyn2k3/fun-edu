import 'package:design_system_sl/theme/colors.dart';
import 'package:design_system_sl/theme/components/button/enums.dart';
import 'package:design_system_sl/theme/components/button/sl_button.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/data/term/constants.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/tab_bar/tab_bar.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import '../helper/global.dart';
import '../model/onboard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final int _numPages = 3;
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  void _comleteOnBoardind(BuildContext context) async {
    await GetIt.instance
        .get<SharedPreferencesManager>()
        .putBool("isFirstTime", false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainTabbarScreen()),
    );
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: isActive ? 24.0 : 16.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFF7B51D3),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);
    final listOnBoard = [
      //onboarding 1
      Onboard(
        title: 'Hỏi gì cũng được!',
        subtitle:
            'Mình có thể trở thành người bạn đồng hành của bạn. Hãy hỏi bất cứ điều gì, mình sẽ giúp bạn!',
        lottie: 'ai_ask_me',
      ),

      Onboard(
        title: 'Biến tưởng tượng thành hiện thực',
        subtitle:
            'Chỉ cần bạn tưởng tượng, mình sẽ giúp bạn tạo ra những điều tuyệt vời!',
        lottie: 'ai_onboard2',
      ),

      Onboard(
        title: 'Luôn bên bạn mọi lúc',
        subtitle:
            'Dù là học tập, giải trí hay làm việc, mình luôn sẵn sàng hỗ trợ bạn!',
        lottie: 'ai_onboard1',
      ),
    ];

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.1, 0.4, 0.7, 0.9],
              colors: [
                Color(0xFF3594DD),
                Color(0xFF4563DB),
                Color(0xFF5036D5),
                Color(0xFF5B16D0),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          _comleteOnBoardind(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color.fromARGB(255, 37, 96, 234),
                          ),
                          child: const Center(
                            child: Text(
                              'Skip',
                              style: style20White,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                SizedBox(
                  height: mq.height * .6,
                  child: PageView(
                    physics: const ClampingScrollPhysics(),
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: listOnBoard.map((e) {
                      return Column(children: [
                        //lottie
                        Lottie.asset('assets/lottie/${e.lottie}.json',
                            height: mq.height * .4,
                            width: _currentPage == _numPages
                                ? mq.width * .7
                                : null),

                        //title
                        Text(
                          e.title,
                          style: style18White,
                        ),

                        //for adding some space
                        SizedBox(height: mq.height * .015),

                        //subtitle
                        SizedBox(
                          width: mq.width * .7,
                          child: Text(
                            e.subtitle,
                            textAlign: TextAlign.center,
                            style: style16White,
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPageIndicator(),
                ),
                if (_currentPage == _numPages - 1) ...[
                  const SizedBox(
                    height: 16,
                  ),
                  SLButton.brand(
                    label: "Bắt đầu",
                    onTap: () {
                      _comleteOnBoardind(context);
                    },
                    isMaxWidth: true,
                    size: SLSize.large,
                    padding:
                        const EdgeInsetsDirectional.symmetric(horizontal: 16),
                  ),
                ] else ...[
                  const SizedBox(
                    height: 16,
                  ),
                  Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: InkWell(
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: SLColor.blueLight,
                        ),
                        child: const Center(
                          child: Text(
                            'Tiếp tục',
                            style: style20White,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
