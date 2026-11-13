import 'package:flutter/widgets.dart';

/// Lays [child] out at the available width with no height limit and, when
/// it ends up taller than the available height, scales it down to fit.
/// Unlike a bare `FittedBox`, text keeps wrapping at the real width.
///
/// With [fillHeight] the child is also given at least the available height,
/// so a `Column` with `MainAxisAlignment.spaceBetween` still spreads out
/// when it fits. With an unbounded height the child is returned as is.
class ScaleDownToFit extends StatelessWidget {
  const ScaleDownToFit({
    super.key,
    required this.child,
    this.fillHeight = false,
    this.alignment = Alignment.topLeft,
  });

  final Widget child;
  final bool fillHeight;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (!c.hasBoundedHeight || !c.hasBoundedWidth) return child;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: c.maxWidth,
              maxWidth: c.maxWidth,
              minHeight: fillHeight ? c.maxHeight : 0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
