import 'dart:math' as math;

/// An immutable 2D point (normalized glyph coordinates, usually 0..1).
class Point2 {
  const Point2(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is Point2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point2($x, $y)';
}

double _dist(Point2 a, Point2 b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

/// Total arc length of the polyline [pts] (0 for fewer than two points).
double pathLength(List<Point2> pts) {
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    total += _dist(pts[i - 1], pts[i]);
  }
  return total;
}

/// Resamples [pts] into [n] points evenly spaced by arc length.
///
/// Zero-length paths yield [n] copies of the first point.
/// Throws [ArgumentError] when [pts] is empty or [n] < 1.
List<Point2> resample(List<Point2> pts, int n) {
  if (pts.isEmpty) throw ArgumentError('pts must not be empty');
  if (n < 1) throw ArgumentError('n must be >= 1');
  final total = pathLength(pts);
  if (total == 0 || n == 1) return List<Point2>.filled(n, pts.first);

  final step = total / (n - 1);
  final out = <Point2>[pts.first];
  var seg = 1; // index of the segment end currently walked
  var segStart = 0.0; // arc length at pts[seg - 1]
  for (var i = 1; i < n - 1; i++) {
    final target = step * i;
    while (seg < pts.length - 1 &&
        segStart + _dist(pts[seg - 1], pts[seg]) < target) {
      segStart += _dist(pts[seg - 1], pts[seg]);
      seg++;
    }
    final a = pts[seg - 1];
    final b = pts[seg];
    final len = _dist(a, b);
    final t = len == 0 ? 0.0 : ((target - segStart) / len).clamp(0.0, 1.0);
    out.add(Point2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t));
  }
  out.add(pts.last);
  return out;
}

void _checkPaired(List<Point2> a, List<Point2> b) {
  if (a.length != b.length || a.isEmpty) {
    throw ArgumentError('lists must be non-empty and of equal length');
  }
}

/// Mean distance between index-paired points of [a] and [b].
double meanDistance(List<Point2> a, List<Point2> b) {
  _checkPaired(a, b);
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    sum += _dist(a[i], b[i]);
  }
  return sum / a.length;
}

/// Maximum distance between index-paired points of [a] and [b].
double maxDistance(List<Point2> a, List<Point2> b) {
  _checkPaired(a, b);
  var m = 0.0;
  for (var i = 0; i < a.length; i++) {
    m = math.max(m, _dist(a[i], b[i]));
  }
  return m;
}

/// Arithmetic mean of [pts]. Throws [ArgumentError] when empty.
Point2 centroid(List<Point2> pts) {
  if (pts.isEmpty) throw ArgumentError('pts must not be empty');
  var sx = 0.0;
  var sy = 0.0;
  for (final p in pts) {
    sx += p.x;
    sy += p.y;
  }
  return Point2(sx / pts.length, sy / pts.length);
}

/// Euclidean distance between two points.
double distance(Point2 a, Point2 b) => _dist(a, b);
