// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:fun_edu/helper/ad_helper.dart';
// import 'package:fun_edu/helper/global.dart';
// import 'package:fun_edu/model/home_type.dart';
// import 'package:google_fonts/google_fonts.dart';

// class HomeCard extends StatelessWidget {
//   final HomeType homeType;

//   const HomeCard({super.key, required this.homeType});

//   @override
//   Widget build(BuildContext context) {
//     Animate.restartOnHotReload = true;

//     return InkWell(
//         onTap: ()
//             //homeType.onTap,
//             =>
//             AdHelper.showInterstitialAd(homeType.onTap),
//         child: _buildCard());
//   }

//   Widget _buildCard() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _buildImage(),
//           Expanded(
//             child: Container(
//               margin: EdgeInsets.only(
//                   bottom: mq.height * .03, top: mq.height * .02),
//               decoration: BoxDecoration(
//                   // color: const Color(0xFF03F0FF).withOpacity(0.7),
//                   color: homeType.color,
//                   shape: BoxShape.rectangle,
//                   borderRadius: const BorderRadius.only(
//                     topRight: Radius.circular(20),
//                     bottomRight: Radius.circular(20),
//                   )),
//               child: InkWell(
//                 borderRadius: const BorderRadius.all(Radius.circular(20)),
//                 onTap: ()
//                     //homeType.onTap,
//                     =>
//                     AdHelper.showInterstitialAd(homeType.onTap),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 8,
//                   ),
//                   child: Column(
//                     children: [
//                       const SizedBox(
//                         height: 6,
//                       ),
//                       _buildTitle(),
//                       SizedBox(
//                         height: mq.height * 0.018,
//                       ),
//                       _buildDesc()
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           )
//         ],
//       ).animate().fade(duration: 1.seconds, curve: Curves.easeIn),
//     );
//   }

//   Widget _buildImage() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             // color: const Color(0xFF03F0FF).withOpacity(0.5),
//             color: homeType.color,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           height: mq.height * 0.24,
//           width: mq.width * 0.4,
//         ),
//         Image.asset(
//           "assets/images/${homeType.image}",
//           fit: BoxFit.cover,
//           height: mq.height * 0.18,
//           width: mq.width * 0.32,
//         ),
//       ],
//     );
//   }

//   Widget _buildTitle() {
//     return Text(
//       homeType.title,
//       style: GoogleFonts.fredoka(
//         fontSize: 30,
//         color: Colors.white,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//   }

//   Widget _buildDesc() {
//     return Text(
//       homeType.desc,
//       style: GoogleFonts.fredoka(
//         fontSize: 16,
//         color: Colors.white,
//         fontWeight: FontWeight.bold,
//       ),
//       overflow: TextOverflow.ellipsis,
//       maxLines: 2,
//     );
//   }
// }
/////////////////////////////////////////////////////
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:fun_edu/helper/ad_helper.dart';
// import 'package:fun_edu/model/home_type.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class HomeCard extends StatelessWidget {
//   final HomeType homeType;

//   const HomeCard({super.key, required this.homeType});

//   @override
//   Widget build(BuildContext context) {
//     Animate.restartOnHotReload = true;

//     return GestureDetector(
//       onTap: () => AdHelper.showInterstitialAd(homeType.onTap),
//       child: _buildCard()
//           .animate()
//           .fade(duration: 400.ms)
//           .slideX(begin: -0.3)
//           .then() // Sau khi xuất hiện, lắc nhẹ một lần rồi dừng
//           .rotate(begin: -0.01, end: 0.01, duration: 300.ms)
//           .then()
//           .rotate(begin: 0.01, end: -0.01, duration: 300.ms)
//           .then()
//           .rotate(begin: -0.005, end: 0, duration: 200.ms),
//     );
//   }

//   Widget _buildCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.symmetric(horizontal: 24),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             Color(0xFF03F0FF),
//             Color(0xFF007AFF)
//           ], // Xanh nhạt -> Xanh đậm
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.2),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: 12,
//           ),
//           _buildIcon(homeType.title),
//           const SizedBox(width: 16),
//           Expanded(child: _buildText()),
//         ],
//       ),
//     );
//   }

//   Widget _buildIcon(String title) {
//     IconData icon;
//     Color iconColor;

//     switch (title.toLowerCase()) {
//       case "chữ số":
//         icon = FontAwesomeIcons.dragon;
//         iconColor = const Color(0xFF6FCF97);
//         break;
//       case "dấu toán":
//         icon = FontAwesomeIcons.userNinja;
//         iconColor = const Color(0xFFF2C94C);
//         break;
//       case "phép tính":
//         icon = FontAwesomeIcons.rocket;
//         iconColor = const Color(0xFFEB5757);
//         break;
//       default:
//         icon = FontAwesomeIcons.star;
//         iconColor = Colors.yellow;
//     }

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: FaIcon(
//         icon,
//         color: iconColor,
//         size: 50,
//       ),
//     );
//   }

//   Widget _buildText() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             homeType.title,
//             style: GoogleFonts.balooBhaijaan2(
//               fontSize: 32,
//               color: Colors.white,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             homeType.desc,
//             style: GoogleFonts.balooBhaijaan2(
//               fontSize: 18,
//               color: Colors.white.withOpacity(0.9),
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildButton(),
//         ],
//       ),
//     );
//   }

//   Widget _buildButton() {
//     return ElevatedButton(
//       onPressed: () => AdHelper.showInterstitialAd(homeType.onTap),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//       child: Text(
//         'Khám Phá Ngay!',
//         style: GoogleFonts.fredoka(
//           fontSize: 18,
//           color: Colors.purple,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/model/home_type.dart';

class HomeCard extends StatelessWidget {
  final HomeType homeType;

  const HomeCard({super.key, required this.homeType});

  @override
  Widget build(BuildContext context) {
    Color titleColor = _getContrastingTextColor(homeType.color);
    Color descColor = titleColor.withOpacity(0.8);

    return GestureDetector(
      onTap: homeType.onTap,
      child: Container(
        width: 100,
        height: 150,
        decoration: BoxDecoration(
          color: homeType.color,
          boxShadow: [
            BoxShadow(
              blurRadius: 0,
              color: homeType.colorB,
              offset: const Offset(4, 4),
              spreadRadius: 0,
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.asset(
                      "assets/images/${homeType.image}", // Sử dụng đường dẫn đến ảnh trong assets
                      height: 48, // Chiều cao của ảnh
                      width: 48, // Chiều rộng của ảnh (tuỳ chọn, nếu cần)
                      // Áp dụng màu sắc nếu cần (có thể sử dụng để tô màu cho ảnh)
                    ),
                  ),
                  Expanded(
                    child: Text(
                      textAlign: TextAlign.end,
                      homeType.title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontFamily: 'Sukhumvit Set',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color:
                            ColorBase.primaryText, // Màu tự động đổi để nổi bật
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  homeType.desc,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Sukhumvit Set',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: descColor, // Màu mô tả nhẹ hơn tiêu đề
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hàm xác định màu chữ tương phản để tiêu đề dễ đọc
  Color _getContrastingTextColor(Color background) {
    double luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
