import 'package:design_system_sl/theme/colors.dart';
import 'package:design_system_sl/theme/components/button/enums.dart';
import 'package:design_system_sl/theme/components/button/sl_button.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/tab_bar/tab_bar.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../helper/global.dart';

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
    return List.generate(
      _numPages,
      (i) => _indicator(i == _currentPage),
    );
  }

  void _completeOnboarding(BuildContext context) async {
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
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      height: 12.0,
      width: isActive ? 28.0 : 12.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.pinkAccent : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);

    final List<Map<String, dynamic>> onBoardingData = [
      {
        'title': 'Học chữ số',
        'subtitle': 'Cùng học đếm số từ 1 đến 10 thật vui!',
        'icon': FontAwesomeIcons.sortNumericDown,
        'color': Colors.orange,
      },
      {
        'title': 'Học phép so sánh',
        'subtitle': 'So sánh số lớn hơn, bé hơn dễ ơi là dễ!',
        'icon': FontAwesomeIcons.balanceScaleLeft,
        'color': Colors.purple,
      },
      {
        'title': 'Học phép cộng trừ',
        'subtitle': 'Cộng trừ dễ dàng, vừa học vừa chơi!',
        'icon': FontAwesomeIcons.plusMinus,
        'color': Colors.green,
      },
    ];

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA3E7FC), Color(0xFFC3A5F6)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _completeOnboarding(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.redAccent,
                        ),
                        child: Text(
                          'Bỏ qua',
                          style: GoogleFonts.baloo2(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _numPages,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      final data = onBoardingData[index];
                      return SingleChildScrollView(
                        // Dùng Scroll để tránh lỗi overflow
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data['color']!.withOpacity(0.2),
                              ),
                              child: FaIcon(
                                data['icon'],
                                size: 120,
                                color: data['color'],
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              data['title']!,
                              style: GoogleFonts.baloo2(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                data['subtitle']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.baloo2(
                                  fontSize: 24,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPageIndicator(),
                ),
                const SizedBox(height: 20),
                if (_currentPage == _numPages - 1)
                  SLButton.brand(
                    label: "Bắt đầu học",
                    onTap: () => _completeOnboarding(context),
                    isMaxWidth: true,
                    size: SLSize.large,
                    padding:
                        const EdgeInsetsDirectional.symmetric(horizontal: 16),
                  )
                else
                  Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.lightBlue,
                        ),
                        child: Center(
                          child: Text(
                            'Tiếp tục',
                            style: GoogleFonts.baloo2(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
