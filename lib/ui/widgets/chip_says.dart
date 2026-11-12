import 'package:flutter/material.dart';

import 'speech_bubble.dart';

/// Chíp Chíp with a speech bubble beside it.
class ChipSays extends StatelessWidget {
  const ChipSays({required this.image, required this.text, super.key});

  final String image;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(image, width: 88, height: 88, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SpeechBubble(text: text),
            ),
          ),
        ],
      ),
    );
  }
}
