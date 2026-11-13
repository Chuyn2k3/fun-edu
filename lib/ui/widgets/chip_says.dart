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
    this.layout,
    super.key,
  });

  final String image;
  final String text;

  /// Set to false when the screen reads something else on opening, so the
  /// two do not talk over each other.
  final bool speakFirst;

  /// Custom arrangement of the Chíp image and the line (tablet layouts).
  /// When null, the image sits left of a speech bubble, 88 pt tall.
  final Widget Function(BuildContext context, String image, String text)?
      layout;

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
    // Assumes in-place swaps keep the new line; a route replacement would
    // clip it (old element unmounts after the new one speaks).
    _speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    if (layout != null) return layout(context, widget.image, widget.text);
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
