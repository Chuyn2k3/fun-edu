import 'package:flutter/material.dart';

/// Vẽ con đường mòn uốn lượn lát đá thần tiên (Adventure Cobblestone Path)
/// kết nối các trạm trò chơi trong thế giới hoạt hình.
class AdventurePathPainter extends CustomPainter {
  final List<Offset> stationPoints;
  final bool isTablet;

  AdventurePathPainter({
    required this.stationPoints,
    this.isTablet = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stationPoints.length < 2) return;

    // 1. Path Under-Shadow (Bóng đất lún dưới đường)
    final shadowPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.35)
      ..strokeWidth = isTablet ? 46.0 : 36.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = _generateSmoothCurve();
    canvas.drawPath(path, shadowPaint);

    // 2. Main Sandy Dirt Road (Mặt đường đất cát vàng mịn)
    final roadPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFFCA28)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = isTablet ? 38.0 : 28.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, roadPaint);

    // 3. Dashed Cobblestone Stepping Stones (Các viên đá bước chân lát đường)
    final stonePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = isTablet ? 5.0 : 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Vẽ các viên sỏi trang trí rải rác dọc theo các điểm trạm
    final pebblePaint = Paint()..color = const Color(0xFFFFF9C4);
    for (int i = 0; i < stationPoints.length; i++) {
      final pt = stationPoints[i];
      // Hạt sỏi xung quanh trạm
      canvas.drawCircle(Offset(pt.dx + 12, pt.dy + 8), isTablet ? 4.0 : 3.0, pebblePaint);
      canvas.drawCircle(Offset(pt.dx - 14, pt.dy - 6), isTablet ? 3.0 : 2.5, pebblePaint);
      canvas.drawCircle(Offset(pt.dx + 6, pt.dy - 12), isTablet ? 2.5 : 2.0, pebblePaint);
    }
  }

  Path _generateSmoothCurve() {
    final path = Path();
    path.moveTo(stationPoints.first.dx, stationPoints.first.dy);

    for (int i = 0; i < stationPoints.length - 1; i++) {
      final p0 = stationPoints[i];
      final p1 = stationPoints[i + 1];

      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;

      // Độ võng tự nhiên của con đường
      final controlX = midX + (i.isEven ? 30.0 : -30.0);
      path.quadraticBezierTo(controlX, midY, p1.dx, p1.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant AdventurePathPainter oldDelegate) {
    return oldDelegate.stationPoints != stationPoints || oldDelegate.isTablet != isTablet;
  }
}
