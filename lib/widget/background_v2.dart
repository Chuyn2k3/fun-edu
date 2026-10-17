import 'package:flutter/widgets.dart';

class BackgroundV2 extends StatelessWidget {
  /// {@macro background_v2}
  const BackgroundV2({
    super.key, // ignore: unused_element
  });

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   decoration: const BoxDecoration(
    //     image: DecorationImage(
    //       fit: BoxFit.fill,
    //       image: AssetImage('assets/images/Home.png'),
    //     ),
    //   ),
    // );
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFFDE7), // Vàng sữa nhạt (nhẹ hơn nhiều)
            Color(0xFFFFF9C4), // Vàng pastel
            Color(0xFFB2EBF2), // Xanh ngọc pastel (tươi sáng)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
