import 'package:flutter/material.dart';

import '../../stroke/glyph.dart';
import '../../ui/theme/tokens.dart';

const double _eps = 1e-6;

/// Exercise-book background.
///
/// Without a [ruling]: five horizontal lines; the third (the middle guide
/// line) and the bottom (baseline) are drawn heavier.
///
/// With a [ruling]: ô li squares over the ruling's window — a horizontal and
/// a vertical line every cell (a closed grid, edges included), with the
/// baseline and the x-height line (baseline − 2 cells) drawn heavier.
class RuledPaper extends StatelessWidget {
  const RuledPaper({this.ruling, super.key});

  final GlyphRuling? ruling;

  /// Window-relative y (0 = top, 1 = bottom) of every horizontal ô li line.
  @visibleForTesting
  static List<double> horizontalLines(GlyphRuling r) =>
      _gridLines(r.baseline, r.cell, r.windowY, r.windowSide);

  /// Window-relative x of every vertical ô li line (cells start at frame 0).
  @visibleForTesting
  static List<double> verticalLines(GlyphRuling r) =>
      _gridLines(0, r.cell, r.windowX, r.windowSide);

  /// Window-relative y of the x-height line and the baseline, in that order.
  @visibleForTesting
  static List<double> heavyLines(GlyphRuling r) => [
        (r.baseline - 2 * r.cell - r.windowY) / r.windowSide,
        (r.baseline - r.windowY) / r.windowSide,
      ];

  static List<double> _gridLines(
    double anchor,
    double cell,
    double start,
    double side,
  ) {
    if (cell <= 0 || side <= 0) return const [];
    final first = ((start - anchor) / cell - _eps).ceil();
    final out = <double>[];
    for (var k = first;; k++) {
      final t = (anchor + k * cell - start) / side;
      if (t > 1 + _eps) break;
      out.add(t.clamp(0.0, 1.0));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final r = ruling;
    return CustomPaint(
      painter: r == null ? const _RuledPainter() : _OLiPainter(r),
      size: Size.infinite,
    );
  }
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

/// Ô li squares; light lines in [AppColors.dot], the baseline and x-height
/// line heavier in a muted ink so the child sees where letters sit.
class _OLiPainter extends CustomPainter {
  const _OLiPainter(this.ruling);

  final GlyphRuling ruling;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()
      ..color = AppColors.dot
      ..strokeWidth = 1.5;
    final heavyPaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.35)
      ..strokeWidth = 3;
    final heavy = RuledPaper.heavyLines(ruling);
    bool isHeavy(double y) => heavy.any((h) => (h - y).abs() < _eps);
    for (final x in RuledPaper.verticalLines(ruling)) {
      canvas.drawLine(
        Offset(x * size.width, 0),
        Offset(x * size.width, size.height),
        light,
      );
    }
    // Heavy lines last so they stay on top of the crossings.
    final ys = RuledPaper.horizontalLines(ruling);
    for (final y in [...ys.where((y) => !isHeavy(y)), ...ys.where(isHeavy)]) {
      canvas.drawLine(
        Offset(0, y * size.height),
        Offset(size.width, y * size.height),
        isHeavy(y) ? heavyPaint : light,
      );
    }
  }

  @override
  bool shouldRepaint(_OLiPainter old) => old.ruling != ruling;
}

/// A letter drawn faintly as a position reference (the "a" under a tone
/// mark). Points are in [0,1] of the square; never graded.
class FaintLetter extends StatelessWidget {
  const FaintLetter({required this.strokes, super.key});

  final List<Stroke> strokes;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _FaintPainter(strokes),
          size: Size.infinite,
        ),
      );
}

class _FaintPainter extends CustomPainter {
  const _FaintPainter(this.strokes);

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final paint = Paint()
      ..color = AppColors.dot.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = side * 0.03;
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final first = s.points.first;
      if (s.points.length == 1) {
        canvas.drawCircle(Offset(first.x * side, first.y * side),
            side * 0.015, Paint()..color = paint.color);
        continue;
      }
      final path = Path()..moveTo(first.x * side, first.y * side);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.x * side, p.y * side);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FaintPainter old) => !identical(old.strokes, strokes);
}
