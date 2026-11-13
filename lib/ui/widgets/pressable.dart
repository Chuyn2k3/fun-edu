import 'package:flutter/material.dart';

import '../theme/depth.dart';

/// Wraps a kid-facing card so it sinks while touched. [builder] receives the
/// pressed state (pass it to `raisedDecoration`). When [onTap] is null the
/// card is inert and never sinks.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onTap,
    this.semanticsLabel,
  });

  final Widget Function(bool pressed) builder;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  static const _sink = AppDepth.lip - AppDepth.pressedLip;
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final pressed = enabled && _pressed;
    Widget child = TweenAnimationBuilder<double>(
      tween: Tween(end: pressed ? _sink : 0),
      duration: const Duration(milliseconds: 80),
      builder: (context, dy, child) =>
          Transform.translate(offset: Offset(0, dy), child: child),
      child: widget.builder(pressed),
    );
    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: child,
    );
    if (widget.semanticsLabel != null || enabled) {
      child = Semantics(
        button: enabled,
        label: widget.semanticsLabel,
        child: child,
      );
    }
    return child;
  }
}
