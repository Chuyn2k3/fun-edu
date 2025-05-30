import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final ValueNotifier<int> _pageIndex = ValueNotifier(0);

  final List<Widget> _pages = const [
    OnboardingPage(
      icon: FontAwesomeIcons.handsClapping,
      iconColor: Colors.orangeAccent,
      title: "Chào mừng bạn!",
      subtitle: "Khám phá thế giới toán học đầy thú vị và thử thách hấp dẫn!",
    ),
    OnboardingPage(
      icon: FontAwesomeIcons.brain,
      iconColor: Colors.orangeAccent,
      title: "Học toán thật dễ!",
      subtitle:
          "Phương pháp học hiện đại, giúp bạn tiếp thu nhanh và hiệu quả.",
    ),
    OnboardingPage(
      icon: FontAwesomeIcons.flagCheckered,
      iconColor: Colors.orangeAccent,
      title: "Tiến bộ mỗi ngày!",
      subtitle:
          "Luyện tập thông minh với bài tập sáng tạo và hệ thống đánh giá chi tiết.",
    ),
    FinalOnboardingPage(),
  ];

  void _nextPage() {
    final index = _pageIndex.value;
    if (index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _goToHome();
    }
  }

  void _goToHome() {
    context.pushReplacementNamed(GoRouterName.nameScreen.routeName);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/start.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (index) => _pageIndex.value = index,
              children: _pages,
            ),
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: ValueListenableBuilder<int>(
                valueListenable: _pageIndex,
                builder: (_, index, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (index > 0)
                      OnboardingTextButton(
                          text: "Quay lại",
                          onPressed: () {
                            _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }),
                    if (index < _pages.length - 1)
                      OnboardingTextButton(
                          text: "Bỏ qua", onPressed: _goToHome),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: _BottomNavigation(
                controller: _controller,
                pageIndex: _pageIndex,
                onNext: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 100, color: iconColor),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinalOnboardingPage extends StatelessWidget {
  const FinalOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo3.png', height: 100),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Học toán thông minh, vui vẻ và hiệu quả ngay hôm nay!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OnboardingTextButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: ColorBase.accent1B,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'LilitaOne',
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final PageController controller;
  final ValueNotifier<int> pageIndex;
  final VoidCallback onNext;

  const _BottomNavigation({
    required this.controller,
    required this.pageIndex,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pageIndex,
      builder: (_, index, __) {
        final isLast = index == 3;
        return Column(
          children: [
            SmoothPageIndicator(
              controller: controller,
              count: 4,
              effect: const WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: ColorBase.primary,
                dotColor: ColorBase.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: onNext,
              child: Container(
                width: 180,
                height: 64,
                decoration: BoxDecoration(
                  color: ColorBase.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(4, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorBase.primaryText, width: 1),
                ),
                child: Center(
                  child: Text(
                    isLast ? 'Bắt đầu' : 'Tiếp tục',
                    style: const TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
