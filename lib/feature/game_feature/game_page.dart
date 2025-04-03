// import 'package:flutter/material.dart';
// import 'package:animator/animator.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:fun_edu/feature/game_feature/enum/game_enum.dart';
// import 'package:fun_edu/feature/game_feature/widget/custom_stack.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class ListGamePage extends StatelessWidget {
//   const ListGamePage({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final mq = MediaQuery.of(context).size;

//     return Scaffold(
//       body: Container(
//         width: mq.width,
//         height: mq.height,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFB2EBF2), Color(0xFFFDE7E7)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Stack(
//           children: [
//             // Các họa tiết nền dễ thương
//             Positioned(
//               top: 60,
//               left: 40,
//               child: FaIcon(
//                 FontAwesomeIcons.star,
//                 color: Colors.yellowAccent.withOpacity(0.3),
//                 size: 30,
//               ),
//             ),
//             Positioned(
//               bottom: 100,
//               right: 50,
//               child: FaIcon(
//                 FontAwesomeIcons.rocket,
//                 color: Colors.orangeAccent.withOpacity(0.3),
//                 size: 30,
//               ),
//             ),
//             Positioned(
//               top: 200,
//               left: 30,
//               child: FaIcon(
//                 FontAwesomeIcons.gamepad,
//                 color: Colors.blueAccent.withOpacity(0.3),
//                 size: 30,
//               ),
//             ),
//             Positioned(
//               bottom: 200,
//               right: 20,
//               child: FaIcon(
//                 FontAwesomeIcons.gem,
//                 color: Colors.purpleAccent.withOpacity(0.3),
//                 size: 30,
//               ),
//             ),

//             // Nội dung chính
//             ListView(
//               physics: const BouncingScrollPhysics(),
//               children: [
//                 const SizedBox(height: 40),

//                 // Tiêu đề
//                 Text(
//                   'Chọn trò chơi',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 28,
//                     letterSpacing: 1,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//                 const SizedBox(height: 10),

//                 // Mũi tên xuống nhấp nháy
//                 SizedBox(
//                   width: double.infinity,
//                   height: 30,
//                   child: Animator<double>(
//                     duration: const Duration(milliseconds: 800),
//                     cycles: 0,
//                     curve: Curves.easeInOut,
//                     tween: Tween<double>(begin: 0.8, end: 1.2),
//                     builder: (context, animatorState, child) => Transform.scale(
//                       scale: animatorState.value,
//                       child: const Icon(
//                         Icons.keyboard_arrow_down,
//                         size: 40,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Slider hiển thị các game
//                 CarouselSlider(
//                   options: CarouselOptions(
//                     autoPlay: true,
//                     autoPlayInterval: const Duration(seconds: 4),
//                     height: 520,
//                     enlargeCenterPage: true,
//                     padEnds: true,
//                     viewportFraction: .75,
//                   ),
//                   items: GameEnum.values.map((e) {
//                     return Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: InkWell(
//                         onTap: e.onTap,
//                         child: CustomStack(
//                           image: e.getImage,
//                           text1: e.getName,
//                           color: Colors.blueAccent,
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 30),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/digit_feature/enum/digit_enum.dart';
import 'package:fun_edu/feature/digit_feature/number/digit_number.dart';
import 'package:fun_edu/feature/game_feature/enum/game_enum.dart';
import 'package:fun_edu/widget/background_v2.dart';

class ListGamePage extends StatelessWidget {
  const ListGamePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorBase.secondaryBackground,
      body: Stack(
        children: [
          const BackgroundV2(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildBody(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
          child: Text(
            'Học giỏi chơi vui',
            style: TextStyle(
              fontFamily: 'Sukhumvit Set',
              fontSize: 28,
              letterSpacing: 0.0,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Chinh phục thử thách!',
            style: TextStyle(
              fontFamily: 'Sukhumvit Set',
              fontSize: 18,
              letterSpacing: 0.0,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
  ) {
    const digitEnum = GameEnum.values;
    return Column(
        children: digitEnum
            .map((e) => _buildItem(
                  context,
                  e,
                  e.onTap,
                ))
            .toList());
  }

  Widget _buildItem(
      BuildContext context, GameEnum digitRecogize, VoidCallback onTap) {
    return Container(
      //width: MediaQuery.sizeOf(context).width * 0.91,
      margin: const EdgeInsets.symmetric(vertical: 8),
      //height: 180,
      decoration: BoxDecoration(
        color: digitRecogize.color,
        boxShadow: [
          BoxShadow(
            blurRadius: 0,
            color: digitRecogize.colorB,
            offset: const Offset(
              4,
              4,
            ),
            spreadRadius: 0,
          )
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: const AlignmentDirectional(0, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          //mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 6),
                    child: Text(
                      digitRecogize.getName,
                      style: const TextStyle(
                        fontFamily: 'Sukhumvit Set',
                        fontSize: 16,
                        letterSpacing: 0.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onTap,
                    child: Container(
                      //width: 75,
                      //height: 25,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: digitRecogize.colorB,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Khám phá!',
                            style: TextStyle(
                              fontFamily: 'Sukhumvit Set',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // const Spacer(),
            Expanded(flex: 1, child: SizedBox()),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Hình tròn
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/${digitRecogize.getImage}',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
