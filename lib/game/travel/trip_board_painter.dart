
import 'package:flutter/rendering.dart';

/// Paints Chíp's trip path: a dashed road through every step, a dot per
/// step and a bigger ring where a stop stands. The part already walked is
/// drawn in [walked]. Stops and Chíp are widgets on top.
class TripBoardPainter extends CustomPainter {
  TripBoardPainter({
    required this.length,
    required this.stopEvery,
    required this.reached,
    required this.pointAt,
    required this.path,
    required this.walked,
  });

  final int length;
  final int stopEvery;
  final int reached;
  final Offset Function(int step) pointAt;
  final Color path;
  final Color walked;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var s = 0; s < length; s++) {
      road.color = s < reached ? walked : path;
      final a = pointAt(s);
      final b = pointAt(s + 1);
      // Dashed: draw the middle 60 % of each step.
      canvas.drawLine(Offset.lerp(a, b, 0.2)!, Offset.lerp(a, b, 0.8)!, road);
    }
    final dot = Paint();
    for (var s = 0; s <= length; s++) {
      if (s > 0 && s % stopEvery == 0) continue;
      dot.color = s <= reached ? walked : path;
      canvas.drawCircle(pointAt(s), 7, dot);
    }
  }

  @override
  bool shouldRepaint(TripBoardPainter oldDelegate) =>
      oldDelegate.reached != reached ||
      oldDelegate.length != length ||
      oldDelegate.path != path ||
      oldDelegate.walked != walked;
}
