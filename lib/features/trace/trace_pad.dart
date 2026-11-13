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
    this.crayon = false,
    super.key,
  });

  final void Function(Stroke) onStrokeEnd;
  final List<Stroke> guide;
  final List<Stroke> inked;

  /// Draws ink like a crayon: the main line plus faint offset thin lines.
  final bool crayon;

  @override
  State<TracePad> createState() => _TracePadState();
}

class _TracePadState extends State<TracePad> {
  int? _activePointer;
  final _CurrentStroke _current = _CurrentStroke();

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  Point2 _normalize(Offset local, double side) => Point2(
    (local.dx / side).clamp(0.0, 1.0),
    (local.dy / side).clamp(0.0, 1.0),
  );

  void _down(PointerDownEvent e, double side) {
    if (_activePointer != null) return;
    _activePointer = e.pointer;
    _current.start(_normalize(e.localPosition, side), side);
  }

  void _move(PointerMoveEvent e, double side) {
    if (e.pointer != _activePointer) return;
    _current.add(_normalize(e.localPosition, side), side);
  }

  void _up(PointerUpEvent e, double side) {
    if (e.pointer != _activePointer) return;
    _current.add(_normalize(e.localPosition, side), side);
    final points = List<Point2>.of(_current.points);
    _activePointer = null;
    _current.clear();
    widget.onStrokeEnd(Stroke(points));
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    _current.clear();
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Static layer: dashed guide, painted once per guide/size.
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: GuidePainter(widget.guide),
                    ),
                  ),
                  // Live layer: repainted by the notifier, not by setState.
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _InkPainter(
                        inked: widget.inked,
                        current: _current,
                        crayon: widget.crayon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Path _pathOf(Stroke s, double side) {
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

/// The stroke being drawn. Points and the pixel path grow in place; listeners
/// (the ink painter) are told after each change.
class _CurrentStroke extends ChangeNotifier {
  final List<Point2> points = [];
  Path path = Path();

  void start(Point2 p, double side) {
    points
      ..clear()
      ..add(p);
    path = Path()..moveTo(p.x * side, p.y * side);
    notifyListeners();
  }

  void add(Point2 p, double side) {
    points.add(p);
    path.lineTo(p.x * side, p.y * side);
    notifyListeners();
  }

  void clear() {
    if (points.isEmpty) return;
    points.clear();
    path = Path();
    notifyListeners();
  }
}

/// Paints the dashed guide strokes. Dash paths are computed once per size and
/// cached; repaints only when the guide list or the size changes.
@visibleForTesting
class GuidePainter extends CustomPainter {
  GuidePainter(this.guide);

  /// Number of times any guide painter has painted (test hook).
  static int paintCount = 0;

  final List<Stroke> guide;
  double? _cachedSide;
  List<Path> _dashes = const [];

  List<Path> _dashPaths(double side) {
    if (_cachedSide == side) return _dashes;
    final dash = side * 0.04;
    final out = <Path>[];
    for (final s in guide) {
      if (s.points.length < 2) continue;
      for (final PathMetric m in _pathOf(s, side).computeMetrics()) {
        for (var d = 0.0; d < m.length; d += dash * 2) {
          out.add(m.extractPath(d, d + dash));
        }
      }
    }
    _cachedSide = side;
    return _dashes = out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintCount++;
    final side = size.shortestSide;
    final paint = Paint()
      ..color = _guideColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = side * 0.02;
    for (final d in _dashPaths(side)) {
      canvas.drawPath(d, paint);
    }
  }

  @override
  bool shouldRepaint(GuidePainter oldDelegate) {
    final old = oldDelegate;
    if (identical(old.guide, guide)) return false;
    if (old.guide.length != guide.length) return true;
    for (var i = 0; i < guide.length; i++) {
      if (!identical(old.guide[i], guide[i])) return true;
    }
    return false;
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter({
    required this.inked,
    required this.current,
    required this.crayon,
  }) : super(repaint: current);

  final List<Stroke> inked;
  final _CurrentStroke current;
  final bool crayon;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final inkPaint = Paint()
      ..color = _inkColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = side * _inkWidthFactor;
    for (final s in inked) {
      if (s.points.isEmpty) continue;
      _paintStroke(canvas, inkPaint, side, s.points, _pathOf(s, side));
    }
    if (current.points.isNotEmpty) {
      _paintStroke(canvas, inkPaint, side, current.points, current.path);
    }
  }

  void _paintStroke(
    Canvas canvas,
    Paint inkPaint,
    double side,
    List<Point2> points,
    Path path,
  ) {
    if (points.length == 1) {
      final p = points.first;
      canvas.drawCircle(
        Offset(p.x * side, p.y * side),
        side * _inkWidthFactor / 2,
        inkPaint..style = PaintingStyle.fill,
      );
      inkPaint.style = PaintingStyle.stroke;
    } else {
      canvas.drawPath(path, inkPaint);
      if (crayon) _paintCrayonTexture(canvas, path, side);
    }
  }

  // Fixed offsets (fractions of the side) keep the texture from flickering.
  static const _crayonOffsets = [
    Offset(0.012, -0.008),
    Offset(-0.010, 0.010),
    Offset(0.004, 0.014),
  ];

  void _paintCrayonTexture(Canvas canvas, Path base, double side) {
    final thin = Paint()
      ..color = _inkColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = side * _inkWidthFactor * 0.25;
    for (final o in _crayonOffsets) {
      canvas.drawPath(base.shift(Offset(o.dx * side, o.dy * side)), thin);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) =>
      !identical(old.inked, inked) ||
      old.crayon != crayon ||
      !identical(old.current, current);
}
