import 'package:flutter/material.dart';

import '../../ui/theme/tokens.dart';

/// Exercise-book background: five horizontal lines; the third (the middle
/// guide line) and the bottom (baseline) are drawn heavier.
class RuledPaper extends StatelessWidget {
  const RuledPaper({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _RuledPainter(), size: Size.infinite);
}

class _RuledPainter extends CustomPainter {
  const _RuledPainter();

  static const _lines = 5;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _lines; i++) {
      final heavy = i == 2 || i == _lines - 1;
      final paint = Paint()
        ..color = AppColors.dot
        ..strokeCap = StrokeCap.round
        ..strokeWidth = heavy ? 3 : 1.5;
      // Lines are spread over the height with a margin of half a gap.
      final y = size.height * (i + 0.5) / _lines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RuledPainter old) => false;
}
