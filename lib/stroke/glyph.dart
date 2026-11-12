import 'geometry.dart';

bool _listEq(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// One pen stroke: an ordered list of points.
class Stroke {
  const Stroke(this.points);

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke([
        for (final p in json['points'] as List)
          Point2((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ]);

  final List<Point2> points;

  Map<String, dynamic> toJson() => {
        'points': [
          for (final p in points) [p.x, p.y],
        ],
      };

  @override
  bool operator ==(Object other) =>
      other is Stroke && _listEq(points, other.points);

  @override
  int get hashCode => Object.hashAll(points);
}

/// A glyph (letter/digit/shape) made of ordered reference strokes.
class Glyph {
  const Glyph({required this.id, required this.label, required this.strokes});

  factory Glyph.fromJson(Map<String, dynamic> json) => Glyph(
        id: json['id'] as String,
        label: json['label'] as String,
        strokes: [
          for (final s in json['strokes'] as List)
            Stroke.fromJson(s as Map<String, dynamic>),
        ],
      );

  final String id;
  final String label;
  final List<Stroke> strokes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'strokes': [for (final s in strokes) s.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      other is Glyph &&
      other.id == id &&
      other.label == label &&
      _listEq(strokes, other.strokes);

  @override
  int get hashCode => Object.hash(id, label, Object.hashAll(strokes));
}
