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

/// Ruled-line frame of a glyph: cell size, baseline and the square writing
/// window, all in frame units (the frame is 12 o li wide).
class GlyphRuling {
  const GlyphRuling({
    required this.cell,
    required this.baseline,
    required this.windowX,
    required this.windowY,
    required this.windowSide,
  });

  factory GlyphRuling.fromJson(Map<String, dynamic> json) {
    final w = json['window'] as List;
    return GlyphRuling(
      cell: (json['cell'] as num).toDouble(),
      baseline: (json['baseline'] as num).toDouble(),
      windowX: (w[0] as num).toDouble(),
      windowY: (w[1] as num).toDouble(),
      windowSide: (w[2] as num).toDouble(),
    );
  }

  final double cell;
  final double baseline;
  final double windowX;
  final double windowY;
  final double windowSide;

  Map<String, dynamic> toJson() => {
        'cell': cell,
        'baseline': baseline,
        'window': [windowX, windowY, windowSide],
      };

  @override
  bool operator ==(Object other) =>
      other is GlyphRuling &&
      other.cell == cell &&
      other.baseline == baseline &&
      other.windowX == windowX &&
      other.windowY == windowY &&
      other.windowSide == windowSide;

  @override
  int get hashCode => Object.hash(cell, baseline, windowX, windowY, windowSide);
}

/// A glyph (letter/digit/shape) made of ordered reference strokes.
class Glyph {
  const Glyph({
    required this.id,
    required this.label,
    required this.strokes,
    this.ruling,
    this.context,
    this.speech,
  });

  factory Glyph.fromJson(Map<String, dynamic> json) => Glyph(
        id: json['id'] as String,
        label: json['label'] as String,
        speech: json['speech'] as String?,
        ruling: json['ruling'] == null
            ? null
            : GlyphRuling.fromJson(json['ruling'] as Map<String, dynamic>),
        context: json['context'] as String?,
        strokes: [
          for (final s in json['strokes'] as List)
            Stroke.fromJson(s as Map<String, dynamic>),
        ],
      );

  final String id;
  final String label;
  final List<Stroke> strokes;
  final GlyphRuling? ruling;

  /// Id of the glyph this one is drawn on top of (tone marks over a letter).
  final String? context;

  /// Text read aloud; falls back to [label] (see [spokenName]).
  final String? speech;

  String get spokenName => speech ?? label;

  /// This glyph in writing-window coordinates: strokes mapped with
  /// `(p - windowOrigin) / windowSide`, ruling re-expressed in the window.
  /// Returns `this` when there is no [ruling].
  Glyph inWindow() {
    final r = ruling;
    if (r == null) return this;
    final side = r.windowSide;
    return Glyph(
      id: id,
      label: label,
      speech: speech,
      context: context,
      ruling: GlyphRuling(
        cell: r.cell / side,
        baseline: (r.baseline - r.windowY) / side,
        windowX: 0,
        windowY: 0,
        windowSide: 1,
      ),
      strokes: [
        for (final s in strokes)
          Stroke([
            for (final p in s.points)
              Point2((p.x - r.windowX) / side, (p.y - r.windowY) / side),
          ]),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (speech != null) 'speech': speech,
        if (ruling != null) 'ruling': ruling!.toJson(),
        if (context != null) 'context': context,
        'strokes': [for (final s in strokes) s.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      other is Glyph &&
      other.id == id &&
      other.label == label &&
      other.speech == speech &&
      other.context == context &&
      other.ruling == ruling &&
      _listEq(strokes, other.strokes);

  @override
  int get hashCode =>
      Object.hash(id, label, speech, context, ruling, Object.hashAll(strokes));
}
