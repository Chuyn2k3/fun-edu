import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/screen/enter_name_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EnterNameWidget()),
      );
    }
  }

  void _skipToEnd() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EnterNameWidget()),
    );
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/start.png'),
            fit: BoxFit.fill, // Hiển thị toàn bộ ảnh nền
          ),
        ),
        child: Stack(
          children: [
            // Nội dung onboarding
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                _buildPage(
                  icon: FontAwesomeIcons
                      .handsClapping, // 👏 Chào mừng vui vẻ, thân thiện
                  iconColor: Colors
                      .orangeAccent, // Màu cam tạo cảm giác ấm áp, năng lượng tích cực
                  title: "Chào mừng bạn!",
                  subtitle:
                      "Khám phá thế giới toán học đầy thú vị và thử thách hấp dẫn!",
                ),
                _buildPage(
                  icon: FontAwesomeIcons.brain, // 🧠 Trí tuệ, sáng tạo
                  iconColor: Colors
                      .orangeAccent, // Cam trung tính, gần với orangeAccent nhưng dễ chịu hơn
                  title: "Học toán thật dễ!",
                  subtitle:
                      "Phương pháp học hiện đại, giúp bạn tiếp thu nhanh và hiệu quả.",
                ),
                _buildPage(
                  icon: FontAwesomeIcons
                      .flagCheckered, // 🏁 Đích đến, tượng trưng cho sự thành công
                  iconColor: Colors
                      .orangeAccent, // Cam đậm, thể hiện sự quyết tâm và tiến bộ
                  title: "Tiến bộ mỗi ngày!",
                  subtitle:
                      "Luyện tập thông minh với bài tập sáng tạo và hệ thống đánh giá chi tiết.",
                ),

                _buildFinalPage(), // Trang cuối giống StartWidget
              ],
            ),
            Positioned(
              top: 50,
              left: _currentIndex > 0 ? 20 : null,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    _buildTextButton("Quay lại", _previousPage),
                  if (_currentIndex < 3) _buildTextButton("Bỏ qua", _skipToEnd),
                ],
              ),
            ),
            // Indicator & Button
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
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
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: _nextPage,
                    child: Container(
                      width: 180,
                      height: 64,
                      decoration: BoxDecoration(
                        color: ColorBase.primary, // Sử dụng màu từ ColorBase
                        boxShadow: [
                          BoxShadow(
                            //blurRadius: 8, // Tăng để tạo hiệu ứng bóng rõ hơn
                            color:
                                Colors.black.withOpacity(0.8), // Màu đen rõ hơn
                            offset:
                                const Offset(4, 4), // Điều chỉnh hướng đổ bóng
                            spreadRadius: 0, // Giúp bóng đổ lan rộng hơn
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ColorBase.primaryText,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _currentIndex < 3 ? 'Tiếp tục' : "Bắt đầu",
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle}) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon,
            size: 100,
            color: iconColor, // Thêm màu sắc cho icon
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: iconColor, // Chữ có cùng màu với icon
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 20,
                color: Colors.black87, // Giữ màu chữ phụ dễ đọc
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo3.png',
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          // const Text(
          //   "Sẵn sàng bắt đầu!",
          //   style: TextStyle(
          //     fontFamily: 'LilitaOne',
          //     fontSize: 32,
          //     fontWeight: FontWeight.bold,
          //     color: Colors.black,
          //   ),
          //   textAlign: TextAlign.center,
          // ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "Học toán thông minh, vui vẻ và hiệu quả ngay hôm nay!",
              style: TextStyle(
                fontFamily: 'LilitaOne',
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30), // Giữ hiệu ứng nhấn đẹp hơn
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: ColorBase.accent1B, // Màu nền mới
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'LilitaOne',
            fontSize: 18,
            color: Colors.white, // Màu chữ dễ đọc hơn trên nền vàng
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
