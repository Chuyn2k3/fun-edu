import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../stroke/geometry.dart';
import '../../stroke/glyph.dart';

const Color _guideColor = Color(0xFFD9C6AA);
const Color _inkColor = Color(0xFFE8590C);
const double _inkWidthFactor = 0.06;

/// Square finger-drawing pad. Strokes are reported in normalized [0,1]
/// coordinates of the square, clamped to the square.
class TracePad extends StatefulWidget {
  const TracePad({
    required this.onStrokeEnd,
    this.guide = const [],
    this.inked = const [],
    super.key,
  });

  final void Function(Stroke) onStrokeEnd;
  final List<Stroke> guide;
  final List<Stroke> inked;

  @override
  State<TracePad> createState() => _TracePadState();
}

class _TracePadState extends State<TracePad> {
  int? _activePointer;
  List<Point2> _current = [];

  Point2 _normalize(Offset local, double side) => Point2(
    (local.dx / side).clamp(0.0, 1.0),
    (local.dy / side).clamp(0.0, 1.0),
  );

  void _down(PointerDownEvent e, double side) {
    if (_activePointer != null) return;
    _activePointer = e.pointer;
    setState(() => _current = [_normalize(e.localPosition, side)]);
  }

  void _move(PointerMoveEvent e, double side) {
    if (e.pointer != _activePointer) return;
    setState(() => _current = [..._current, _normalize(e.localPosition, side)]);
  }

  void _up(PointerUpEvent e, double side) {
    if (e.pointer != _activePointer) return;
    final points = [..._current, _normalize(e.localPosition, side)];
    _activePointer = null;
    setState(() => _current = []);
    widget.onStrokeEnd(Stroke(points));
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    setState(() => _current = []);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _down(e, side),
              onPointerMove: (e) => _move(e, side),
              onPointerUp: (e) => _up(e, side),
              onPointerCancel: _cancel,
              child: CustomPaint(
                painter: _PadPainter(
                  guide: widget.guide,
                  inked: [
                    ...widget.inked,
                    if (_current.isNotEmpty) Stroke(_current),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter({required this.guide, required this.inked});

  final List<Stroke> guide;
  final List<Stroke> inked;

  Path _path(Stroke s, double side) {
    final path = Path();
    for (var i = 0; i < s.points.length; i++) {
      final p = s.points[i];
      if (i == 0) {
        path.moveTo(p.x * side, p.y * side);
      } else {
        path.lineTo(p.x * side, p.y * side);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final guidePaint = Paint()
      ..color = _guideColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = side * 0.02;
    for (final s in guide) {
      if (s.points.length < 2) continue;
      for (final PathMetric m in _path(s, side).computeMetrics()) {
        final dash = side * 0.04;
        for (var d = 0.0; d < m.length; d += dash * 2) {
          canvas.drawPath(m.extractPath(d, d + dash), guidePaint);
        }
      }
    }

    final inkPaint = Paint()
      ..color = _inkColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = side * _inkWidthFactor;
    for (final s in inked) {
      if (s.points.isEmpty) continue;
      if (s.points.length == 1) {
        final p = s.points.first;
        canvas.drawCircle(
          Offset(p.x * side, p.y * side),
          side * _inkWidthFactor / 2,
          inkPaint..style = PaintingStyle.fill,
        );
        inkPaint.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(_path(s, side), inkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_PadPainter old) => true;
}
