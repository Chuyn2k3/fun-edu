import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FloatingCountingText extends StatelessWidget {
  final String text;

  const FloatingCountingText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFF5D4037),
        ),
      ),
    )
        .animate()
        .scale(duration: 300.ms, curve: Curves.easeOutBack)
        .moveY(begin: 20, end: -30, duration: 800.ms, curve: Curves.easeOut)
        .fadeOut(delay: 500.ms, duration: 300.ms);
  }
}
