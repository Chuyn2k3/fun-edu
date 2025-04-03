// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fun_edu/screen/custom_drawer/drawScreen.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import '../helper/global.dart';
// import '../helper/pref.dart';
// import '../model/home_type.dart';
// import '../widget/home_card.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key, this.onDrawerStateChanged});
//   final Function(bool)? onDrawerStateChanged;
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   double _xOffset = 0;
//   double _yOffset = 0;
//   double _scaleFactor = 1;
//   bool isDrawerOpen = false;
//   int currentPage = 0;
//   int page = 0;
//   double value = 0;
//   double kPadding = 20.0;
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     Pref.showOnboarding = false;
//   }

//   void toggleDrawer() {
//     setState(() {
//       isDrawerOpen = !isDrawerOpen;
//       if (isDrawerOpen) {
//         _xOffset = 230;
//         _yOffset = 150;
//         _scaleFactor = 0.6;
//       } else {
//         _xOffset = 0;
//         _yOffset = 0;
//         _scaleFactor = 1;
//       }
//     });
//     widget.onDrawerStateChanged
//         ?.call(isDrawerOpen); // Gửi trạng thái cho MainTabbarScreen
//   }

//   @override
//   Widget build(BuildContext context) {
//     mq = MediaQuery.sizeOf(context);
//     final size = MediaQuery.of(context).size;
//     return Stack(
//       children: <Widget>[
//         const DrawerScreen(),
//         AnimatedContainer(
//           width: double.maxFinite,
//           height: double.maxFinite,
//           curve: Curves.decelerate,
//           transform: Matrix4.translationValues(_xOffset, _yOffset, 0)
//             ..scale(_scaleFactor)
//             ..rotateY(isDrawerOpen ? -0.5 : 0),
//           duration: const Duration(milliseconds: 400),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(isDrawerOpen ? 40.0 : 0),
//           ),
//           child: Stack(
//             children: <Widget>[
//               Container(
//                 margin: const EdgeInsets.only(top: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(isDrawerOpen ? 32 : 0),
//                     topRight: Radius.circular(kPadding * 1.5),
//                     topLeft: Radius.circular(kPadding * 1.5),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: size.height * 0.24,
//                 left: 0,
//                 right: 0,
//                 child: _buildContent(),
//               ),
//               Positioned(
//                 top: 0,
//                 child: Container(
//                   width: size.width,
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF03F0FF).withOpacity(0.7),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(isDrawerOpen ? 32 : 0),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: <Widget>[
//                       IconButton(
//                         icon: Icon(
//                             isDrawerOpen ? Icons.arrow_back_ios : Icons.menu,
//                             size: 30),
//                         onPressed: toggleDrawer,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: size.height * 0.055,
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: _buildHeader(),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       margin: EdgeInsets.fromLTRB(
//         0, 0,
//         //mq.height * 0.02,
//         0,
//         mq.height * 0.54,
//       ),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color(0xFF03F0FF).withOpacity(0.7),
//             const Color(0xFF007AFF).withOpacity(0.3),
//           ],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//         //color: Colors.red,
//         borderRadius: const BorderRadius.only(
//           bottomRight: Radius.circular(32),
//           bottomLeft: Radius.circular(32),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Image.asset(
//             "assets/images/hi.png",
//             width: mq.width * 0.6,
//           ),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Text(
//                   textDirection: TextDirection.ltr,
//                   textAlign: TextAlign.start,
//                   "HỌC\nVUI\nCHƠI\nHAY!\n🚀",
//                   style: GoogleFonts.fredoka(
//                     fontSize: 40,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent() {
//     const list = HomeType.values;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       //color: Colors.black12,
//       height: mq.height * 0.6,
//       child: CarouselSlider.builder(
//         options: CarouselOptions(
//           enableInfiniteScroll: false,
//           scrollDirection: Axis.vertical,
//           autoPlay: false,
//           enlargeCenterPage: true,
//           viewportFraction: 0.40,
//           initialPage: 0,
//         ),
//         itemCount: list.length,
//         itemBuilder: (context, int index, int pageViewIndex) {
//           return HomeCard(
//             homeType: list[index],
//           );
//         },
//       ),
//     );
//   }
// }
/////////////////////////////////////////////////////////////////////////////////////
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import '../helper/global.dart';
// import '../helper/pref.dart';
// import '../model/home_type.dart';
// import '../widget/home_card.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key, this.onDrawerStateChanged});
//   final Function(bool)? onDrawerStateChanged;

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   bool isDrawerOpen = false;

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     Pref.showOnboarding = false;
//   }

//   void toggleDrawer() {
//     setState(() {
//       isDrawerOpen = !isDrawerOpen;
//     });
//     widget.onDrawerStateChanged?.call(isDrawerOpen);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mq = MediaQuery.of(context).size;

//     return Column(
//       children: [
//         _buildHeader(mq),
//         Expanded(child: _buildContent(mq)),
//       ],
//     );
//   }

//   Widget _buildHeader(Size mq) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       height: mq.height * 0.26,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             Color(0xFF03F0FF),
//             Color(0xFF007AFF),
//             Color(0xFFBA68C8)
//           ], // Xanh nhạt -> Xanh đậm -> Tím
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           stops: [0.0, 0.5, 1.0], // Thêm một màu tím ở phía dưới tạo điểm nhấn
//         ),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(32),
//           bottomRight: Radius.circular(32),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.3),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(
//               isDrawerOpen ? Icons.arrow_back_ios : Icons.menu,
//               color: Colors.white,
//               size: 30,
//             ),
//             onPressed: toggleDrawer,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               "HỌC VUI CHƠI HAY! 🚀",
//               textAlign: TextAlign.center,
//               style: GoogleFonts.fredoka(
//                 fontSize: 28,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent(Size mq) {
//     const list = HomeType.values;
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: CarouselSlider.builder(
//         options: CarouselOptions(
//           height: mq.height * 0.6,
//           enableInfiniteScroll: false,
//           scrollDirection: Axis.vertical,
//           enlargeCenterPage: true,
//           viewportFraction: 0.45,
//         ),
//         itemCount: list.length,
//         itemBuilder: (context, index, realIndex) {
//           return HomeCard(homeType: list[index]);
//         },
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fun_edu/screen/custom_drawer/drawScreen.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import '../helper/global.dart';
// import '../helper/pref.dart';
// import '../model/home_type.dart';
// import '../widget/home_card.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key, this.onDrawerStateChanged});
//   final Function(bool)? onDrawerStateChanged;

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   double _xOffset = 0;
//   double _yOffset = 0;
//   double _scaleFactor = 1;
//   bool isDrawerOpen = false;

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     Pref.showOnboarding = false;
//   }

//   void toggleDrawer() {
//     setState(() {
//       isDrawerOpen = !isDrawerOpen;
//       if (isDrawerOpen) {
//         _xOffset = 230;
//         _yOffset = 150;
//         _scaleFactor = 0.6;
//       } else {
//         _xOffset = 0;
//         _yOffset = 0;
//         _scaleFactor = 1;
//       }
//     });
//     widget.onDrawerStateChanged?.call(isDrawerOpen);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final mq = MediaQuery.of(context).size;

//     return Stack(
//       children: [
//         // Drawer Panel
//         // Container(
//         //   color: const Color(0xFF03F0FF).withOpacity(0.8),
//         //   child: SafeArea(
//         //     child: Column(
//         //       crossAxisAlignment: CrossAxisAlignment.start,
//         //       children: [
//         //         const SizedBox(height: 50),
//         //         ListTile(
//         //           leading: const Icon(Icons.home, color: Colors.white),
//         //           title:
//         //               const Text('Home', style: TextStyle(color: Colors.white)),
//         //           onTap: () => toggleDrawer(),
//         //         ),
//         //         ListTile(
//         //           leading: const Icon(Icons.settings, color: Colors.white),
//         //           title: const Text('Settings',
//         //               style: TextStyle(color: Colors.white)),
//         //           onTap: () => toggleDrawer(),
//         //         ),
//         //         ListTile(
//         //           leading: const Icon(Icons.info, color: Colors.white),
//         //           title: const Text('About',
//         //               style: TextStyle(color: Colors.white)),
//         //           onTap: () => toggleDrawer(),
//         //         ),
//         //       ],
//         //     ),
//         //   ),
//         // ),
//         // Container(
//         //   decoration: const BoxDecoration(
//         //     gradient: LinearGradient(
//         //       colors: [
//         //         Color(0xFF03F0FF), // Xanh ngọc nhạt
//         //         Color(0xFF007AFF), // Xanh dương
//         //       ],
//         //       begin: Alignment.topCenter,
//         //       end: Alignment.bottomCenter,
//         //     ),
//         //   ),
//         // ),
//         DrawerScreen(),
//         // Animated Container (Nội dung chính)
//         AnimatedContainer(
//           duration: const Duration(milliseconds: 400),
//           curve: Curves.decelerate,
//           transform: Matrix4.translationValues(_xOffset, _yOffset, 0)
//             ..scale(_scaleFactor),
//           decoration: BoxDecoration(
//             color: isDrawerOpen ? Colors.white : null,
//             borderRadius: BorderRadius.circular(isDrawerOpen ? 40.0 : 0),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(isDrawerOpen ? 40.0 : 0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 _buildHeader(mq),
//                 Expanded(child: _buildContent(mq)),
//                 SizedBox(
//                   height: kBottomNavigationBarHeight,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader(Size mq) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       height: mq.height * 0.2,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF03F0FF), Color(0xFF007AFF), Color(0xFFBA68C8)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(32),
//           bottomRight: Radius.circular(32),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.3),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: Icon(
//               isDrawerOpen ? Icons.arrow_back_ios : Icons.menu,
//               color: Colors.white,
//               size: 30,
//             ),
//             onPressed: toggleDrawer,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               "HỌC VUI, VUI HỌC 🚀",
//               textAlign: TextAlign.center,
//               style: GoogleFonts.fredoka(
//                 fontSize: 28,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent(Size mq) {
//     const list = HomeType.values;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: CarouselSlider.builder(
//         options: CarouselOptions(
//           padEnds: false,
//           enableInfiniteScroll: false,
//           scrollDirection: Axis.vertical,
//           enlargeCenterPage: true,
//           viewportFraction: 0.55,
//         ),
//         itemCount: list.length,
//         itemBuilder: (context, index, realIndex) {
//           return HomeCard(homeType: list[index]);
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/screen/offline_game_screen.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:fun_edu/widget/background_v2.dart';
import 'package:fun_edu/widget/home_card.dart';
import 'package:fun_edu/model/home_type.dart';
import 'package:get_it/get_it.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/HomePage';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "bé";
  @override
  void initState() {
    super.initState();
    userName =
        GetIt.instance.get<SharedPreferencesManager>().getString("user_name") ??
            "bé";
    if (userName.isEmpty) {
      userName = "bé";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorBase.secondaryBackground,
      body: Stack(
        children: [
          BackgroundV2(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingSection(),
                  const SizedBox(height: 20),
                  _buildDailyTaskCard(context),
                  const SizedBox(height: 24),
                  Expanded(child: _buildHomeGrid()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị ảnh nền
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage('assets/images/Home.png'),
        ),
      ),
    );
  }

  /// Widget phần chào hỏi
  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào ${userName}!',
          style: TextStyle(
            fontFamily: 'Sukhumvit Set',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: ColorBase.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hãy cùng nhau học và chơi nhé!',
          style: TextStyle(
            fontFamily: 'Sukhumvit Set',
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
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfflineScreen(),
            ));
      },
      child: Container(
        width: double.infinity,
        height: 168,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('assets/images/dailyTask.png'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khám phá',
                      style: TextStyle(
                        fontFamily: 'Sukhumvit Set',
                        fontSize: 16,
                        color: ColorBase.primaryBackground,
                      ),
                    ),
                    Text(
                      'Nhiệm vụ mỗi ngày',
                      style: TextStyle(
                        fontFamily: 'Sukhumvit Set',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorBase.primaryBackground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 149,
                height: 41,
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
                        fontFamily: 'Sukhumvit Set',
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
    return MasonryGridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: HomeType.values.length,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemBuilder: (context, index) {
        return HomeCard(homeType: HomeType.values[index]);
      },
    );
  }
}
