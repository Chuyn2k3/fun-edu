import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Cream background with a regular grid of soft dots, behind [child].
class DottedBackground extends StatelessWidget {
  const DottedBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _DotsPainter(), child: child);
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    final paint = Paint()..color = AppColors.dot;
    const gap = 24.0;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}
