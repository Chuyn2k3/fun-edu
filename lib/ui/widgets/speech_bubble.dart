import 'package:flutter/material.dart';

import '../theme/depth.dart';
import '../theme/tokens.dart';

/// White speech bubble with a squared bottom-left corner (the "tail").
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: raisedDecoration(radius: 20).copyWith(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.3,
          color: AppColors.text,
        ),
      ),
    );
  }
}
