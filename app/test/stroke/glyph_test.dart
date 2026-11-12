import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';

void main() {
  test('Glyph JSON round trip', () {
    final json = <String, dynamic>{
      'id': 'b',
      'label': 'b',
      'strokes': [
        {
          'points': [
            [0.4, 0.1],
            [0.4, 0.95]
          ]
        },
        {
          'points': [
            [0.4, 0.5]
          ]
        },
      ],
    };
    final g = Glyph.fromJson(json);
    expect(g.id, 'b');
    expect(g.strokes.length, 2);
    expect(g.strokes.first.points.last, const Point2(0.4, 0.95));
    expect(Glyph.fromJson(g.toJson()), g);
    expect(g.toJson(), json);
  });

  test('Glyph accepts integer coordinates', () {
    final g = Glyph.fromJson({
      'id': 'x',
      'label': 'x',
      'strokes': [
        {
          'points': [
            [0, 1]
          ]
        }
      ],
    });
    expect(g.strokes.single.points.single, const Point2(0, 1));
  });
}
