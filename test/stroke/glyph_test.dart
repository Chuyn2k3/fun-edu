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

  Map<String, dynamic> rulingJson() => {
        'id': 'chu-t',
        'label': 'Chữ t',
        'speech': 'chữ tê',
        'ruling': {
          'cell': 0.1,
          'baseline': 0.7,
          'window': [0.2, 0.3, 0.4],
        },
        'context': 'chu-a',
        'strokes': [
          {
            'points': [
              [0.2, 0.3],
              [0.6, 0.7]
            ]
          },
        ],
      };

  test('Glyph JSON round trip with ruling, context, speech', () {
    final json = rulingJson();
    final g = Glyph.fromJson(json);
    expect(g.speech, 'chữ tê');
    expect(g.context, 'chu-a');
    expect(g.ruling!.cell, 0.1);
    expect(g.ruling!.windowSide, 0.4);
    expect(g.toJson(), json);
    expect(Glyph.fromJson(g.toJson()), g);
    expect(g.hashCode, Glyph.fromJson(json).hashCode);
    final other = Glyph.fromJson({...json, 'speech': 'khác'});
    expect(other == g, isFalse);
  });

  test('old JSON without new keys omits them in toJson', () {
    final g = Glyph.fromJson({
      'id': 'a',
      'label': 'a',
      'strokes': [
        {
          'points': [
            [0.1, 0.2]
          ]
        }
      ],
    });
    expect(g.ruling, isNull);
    expect(g.toJson().keys, ['id', 'label', 'strokes']);
  });

  test('inWindow maps window corners to the unit square', () {
    final g = Glyph.fromJson(rulingJson()).inWindow();
    expect(g.strokes.single.points.first.x, closeTo(0, 1e-9));
    expect(g.strokes.single.points.first.y, closeTo(0, 1e-9));
    expect(g.strokes.single.points.last.x, closeTo(1, 1e-9));
    expect(g.strokes.single.points.last.y, closeTo(1, 1e-9));
    final corner = Glyph.fromJson({
      ...rulingJson(),
      'strokes': [
        {
          'points': [
            [0.6, 0.7]
          ]
        }
      ],
    }).inWindow();
    expect(corner.strokes.single.points.single.x, closeTo(1, 1e-9));
    expect(corner.strokes.single.points.single.y, closeTo(1, 1e-9));
    expect(g.ruling!.cell, closeTo(0.25, 1e-9));
    expect(g.ruling!.baseline, closeTo(1.0, 1e-9));
    expect(g.ruling!.windowX, 0);
    expect(g.ruling!.windowY, 0);
    expect(g.ruling!.windowSide, 1);
    expect(g.context, 'chu-a');
    expect(g.speech, 'chữ tê');
  });

  test('inWindow without ruling returns the same instance', () {
    final g = Glyph.fromJson({
      'id': 'a',
      'label': 'a',
      'strokes': [
        {
          'points': [
            [0.1, 0.2]
          ]
        }
      ],
    });
    expect(identical(g.inWindow(), g), isTrue);
  });

  test('spokenName falls back to label', () {
    final plain = Glyph.fromJson({'id': 'a', 'label': 'A', 'strokes': []});
    expect(plain.spokenName, 'A');
    expect(Glyph.fromJson(rulingJson()).spokenName, 'chữ tê');
  });
}
