import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';

/// Colours of one answer key: light top, body, bottom edge and ink.
class KeyColors {
  const KeyColors(this.top, this.body, this.edge, this.ink);
  final Color top;
  final Color body;
  final Color edge;
  final Color ink;

  static const orange = KeyColors(GameColors.keyOrangeTop, GameColors.keyOrange,
      GameColors.keyOrangeEdge, GameColors.keyOrangeInk);
  static const blue = KeyColors(GameColors.keyBlueTop, GameColors.keyBlue,
      GameColors.keyBlueEdge, GameColors.keyBlueInk);
  static const green = KeyColors(GameColors.keyGreenTop, GameColors.keyGreen,
      GameColors.keyGreenEdge, GameColors.keyGreenInk);

  static const all = [orange, blue, green];
}

/// The three chunky answer keys of a race question, side by side (or
/// stacked when [vertical]). [labelOf] builds key i's face in its ink
/// colour. A wrong press shakes that key (not under reduce motion); a right
/// press shows a tick while the next question loads.
class AnswerKeys extends StatelessWidget {
  const AnswerKeys({
    super.key,
    required this.labelOf,
    required this.semanticsOf,
    required this.onPressed,
    this.wrongKey,
    this.wrongSeq = 0,
    this.correctKey,
    this.vertical = false,
    this.gap = 12,
  });

  final Widget Function(int index, Color ink) labelOf;
  final String Function(int index) semanticsOf;
  final ValueChanged<int>? onPressed;
  final int? wrongKey;
  final int wrongSeq;
  final int? correctKey;
  final bool vertical;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final keys = [
      for (var i = 0; i < 3; i++)
        Expanded(
          child: _ShakeOnWrong(
            seq: wrongKey == i ? wrongSeq : 0,
            child: _Key(
              key: ValueKey('race-key-$i'),
              colors: KeyColors.all[i],
              label: labelOf(i, KeyColors.all[i].ink),
              semantics: semanticsOf(i),
              correct: correctKey == i,
              dimmed: correctKey != null && correctKey != i,
              onTap: onPressed == null ? null : () => onPressed!(i),
            ),
          ),
        ),
    ];
    final spaced = <Widget>[
      for (var i = 0; i < keys.length; i++) ...[
        if (i > 0)
          SizedBox(width: vertical ? 0 : gap, height: vertical ? gap : 0),
        keys[i],
      ],
    ];
    // Room under the keys for their lip.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.colors,
    required this.label,
    required this.semantics,
    required this.correct,
    required this.dimmed,
    required this.onTap,
  });

  final KeyColors colors;
  final Widget label;
  final String semantics;
  final bool correct;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticsLabel: semantics,
      builder: (pressed) => AnimatedOpacity(
        opacity: dimmed ? 0.55 : 1,
        duration: const Duration(milliseconds: 150),
        child: DecoratedBox(
          decoration: raisedKeyDecoration(
            top: colors.top,
            body: colors.body,
            edge: colors.edge,
            pressed: pressed,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(child: Center(child: label)),
              if (correct)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    key: const ValueKey('race-key-tick'),
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: GameColors.correctRing,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 22, color: AppColors.card),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shakes its child sideways when [seq] grows (skipped under reduce motion).
class _ShakeOnWrong extends StatefulWidget {
  const _ShakeOnWrong({required this.seq, required this.child});

  final int seq;
  final Widget child;

  @override
  State<_ShakeOnWrong> createState() => _ShakeOnWrongState();
}

class _ShakeOnWrongState extends State<_ShakeOnWrong>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(_ShakeOnWrong old) {
    super.didUpdateWidget(old);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.seq > old.seq && widget.seq != 0 && !reduce) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // Damped wobble: 3 swings, 9 pt at most.
        final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
