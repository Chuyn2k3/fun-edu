import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HandTutorWidget extends StatelessWidget {
  const HandTutorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: const Text(
        '👉',
        style: TextStyle(fontSize: 48),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveX(begin: 0, end: 120, duration: 1200.ms, curve: Curves.easeInOut)
          .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 600.ms),
    );
  }
}
