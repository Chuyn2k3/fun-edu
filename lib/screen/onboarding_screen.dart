// import 'package:design_system_sl/theme/colors.dart';
// import 'package:design_system_sl/theme/components/button/enums.dart';
// import 'package:design_system_sl/theme/components/button/sl_button.dart';
// import 'package:flutter/services.dart';
// import 'package:fun_edu/tab_bar/tab_bar.dart';
// import 'package:fun_edu/utils/shared_preferences_manager.dart';
// import 'package:get_it/get_it.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../helper/global.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final int _numPages = 3;
//   final PageController _pageController = PageController(initialPage: 0);
//   int _currentPage = 0;

//   List<Widget> _buildPageIndicator() {
//     return List.generate(
//       _numPages,
//       (i) => _indicator(i == _currentPage),
//     );
//   }

//   void _completeOnboarding(BuildContext context) async {
//     await GetIt.instance
//         .get<SharedPreferencesManager>()
//         .putBool("isFirstTime", false);
//     if (!mounted) return;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const MainTabbarScreen()),
//     );
//   }

//   Widget _indicator(bool isActive) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 150),
//       margin: const EdgeInsets.symmetric(horizontal: 6.0),
//       height: 12.0,
//       width: isActive ? 28.0 : 12.0,
//       decoration: BoxDecoration(
//         color: isActive ? Colors.pinkAccent : Colors.white,
//         borderRadius: const BorderRadius.all(Radius.circular(12)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     mq = MediaQuery.sizeOf(context);

//     final List<Map<String, dynamic>> onBoardingData = [
//       {
//         'title': 'Học chữ số',
//         'subtitle': 'Cùng học đếm số từ 1 đến 10 thật vui!',
//         'icon': FontAwesomeIcons.sortNumericDown,
//         'color': Colors.orange,
//       },
//       {
//         'title': 'Học phép so sánh',
//         'subtitle': 'So sánh số lớn hơn, bé hơn dễ ơi là dễ!',
//         'icon': FontAwesomeIcons.balanceScaleLeft,
//         'color': Colors.purple,
//       },
//       {
//         'title': 'Học phép cộng trừ',
//         'subtitle': 'Cộng trừ dễ dàng, vừa học vừa chơi!',
//         'icon': FontAwesomeIcons.plusMinus,
//         'color': Colors.green,
//       },
//     ];

//     return Scaffold(
//       body: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: SystemUiOverlayStyle.light,
//         child: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [Color(0xFFA3E7FC), Color(0xFFC3A5F6)],
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: <Widget>[
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     InkWell(
//                       onTap: () => _completeOnboarding(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 8,
//                           horizontal: 16,
//                         ),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(30),
//                           color: Colors.redAccent,
//                         ),
//                         child: Text(
//                           'Bỏ qua',
//                           style: GoogleFonts.baloo2(
//                             fontSize: 18,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: PageView.builder(
//                     controller: _pageController,
//                     itemCount: _numPages,
//                     onPageChanged: (int page) {
//                       setState(() {
//                         _currentPage = page;
//                       });
//                     },
//                     itemBuilder: (context, index) {
//                       final data = onBoardingData[index];
//                       return SingleChildScrollView(
//                         // Dùng Scroll để tránh lỗi overflow
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(30),
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: data['color']!.withOpacity(0.2),
//                               ),
//                               child: FaIcon(
//                                 data['icon'],
//                                 size: 120,
//                                 color: data['color'],
//                               ),
//                             ),
//                             const SizedBox(height: 30),
//                             Text(
//                               data['title']!,
//                               style: GoogleFonts.baloo2(
//                                 fontSize: 34,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(horizontal: 16),
//                               child: Text(
//                                 data['subtitle']!,
//                                 textAlign: TextAlign.center,
//                                 style: GoogleFonts.baloo2(
//                                   fontSize: 24,
//                                   color: Colors.black54,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: _buildPageIndicator(),
//                 ),
//                 const SizedBox(height: 20),
//                 if (_currentPage == _numPages - 1)
//                   SLButton.brand(
//                     label: "Bắt đầu học",
//                     onTap: () => _completeOnboarding(context),
//                     isMaxWidth: true,
//                     size: SLSize.large,
//                     padding:
//                         const EdgeInsetsDirectional.symmetric(horizontal: 16),
//                   )
//                 else
//                   Align(
//                     alignment: Alignment.center,
//                     child: InkWell(
//                       onTap: () {
//                         _pageController.nextPage(
//                           duration: const Duration(milliseconds: 500),
//                           curve: Curves.ease,
//                         );
//                       },
//                       child: Container(
//                         width: 160,
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 16,
//                         ),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(30),
//                           color: Colors.lightBlue,
//                         ),
//                         child: Center(
//                           child: Text(
//                             'Tiếp tục',
//                             style: GoogleFonts.baloo2(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 const SizedBox(height: 30),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/screen/enter_name_widget.dart';
import 'package:fun_edu/tab_bar/tab_bar.dart';
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
                          style: TextStyle(
                            fontFamily: 'Sukhumvit Set',
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
              fontFamily: 'Sukhumvit Set',
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
                fontFamily: 'Sukhumvit Set',
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
          //     fontFamily: 'Sukhumvit Set',
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
                fontFamily: 'Sukhumvit Set',
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
          style: TextStyle(
            fontFamily: 'Sukhumvit Set',
            fontSize: 18,
            color: Colors.white, // Màu chữ dễ đọc hơn trên nền vàng
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
