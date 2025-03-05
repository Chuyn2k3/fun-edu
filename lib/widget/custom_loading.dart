import 'package:flutter/material.dart';
import 'package:fun_edu/widget/flutter_dash_image.dart';
import 'package:fun_edu/widget/gradient_border_paint.dart';
import 'package:lottie/lottie.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // return Lottie.asset(
    //   'assets/lottie/loading.json',
    //   width: 160,
    // );
    return const SizedBox(
      height: 100,
      width: 100,
      child: Stack(
        children: [
          FlutterDashImage(),
          GradientBorderPaint(),
        ],
      ),
    );
  }
}
