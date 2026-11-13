import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../voice/speaker.dart';
import 'speech_bubble.dart';

/// Chíp Chíp with a speech bubble beside it. The line is read aloud when it
/// first appears (unless [speakFirst] is false) and whenever [text] changes.
class ChipSays extends ConsumerStatefulWidget {
  const ChipSays({
    required this.image,
    required this.text,
    this.speakFirst = true,
    super.key,
  });

  final String image;
  final String text;

  /// Set to false when the screen reads something else on opening, so the
  /// two do not talk over each other.
  final bool speakFirst;

  @override
  ConsumerState<ChipSays> createState() => _ChipSaysState();
}

class _ChipSaysState extends ConsumerState<ChipSays> {
  late final Speaker _speaker;

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    if (widget.speakFirst) _speaker.speak(widget.text);
  }

  @override
  void didUpdateWidget(ChipSays old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _speaker.speak(widget.text);
  }

  @override
  void dispose() {
    _speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(widget.image, width: 88, height: 88, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SpeechBubble(text: widget.text),
            ),
          ),
        ],
      ),
    );
  }
}
