import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/learning/writing_ladder.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_session.dart';
import 'package:funedu/stroke/grader.dart';

Glyph _load(String id) => Glyph.fromJson(
      jsonDecode(File('assets/glyphs/$id.json').readAsStringSync())
          as Map<String, dynamic>,
    );

double _length(Stroke s) {
  var total = 0.0;
  for (var i = 1; i < s.points.length; i++) {
    final a = s.points[i - 1];
    final b = s.points[i];
    total += sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
  }
  return total;
}

void main() {
  test('writingLadder lists the 15 ids in teaching order', () {
    expect(writingLadder, hasLength(15));
    expect(writingLadder.first, 'net-ngang');
    expect(writingLadder.last, 'so-9');
    expect(writingLadder.toSet(), hasLength(15));
  });

  for (final id in writingLadder) {
    group(id, () {
      test('has a glyph file whose id matches', () {
        final file = File('assets/glyphs/$id.json');
        expect(file.existsSync(), isTrue);
        expect(_load(id).id, id);
      });

      test('submitting stroke 2 first is wrongOrder', () {
        final glyph = _load(id);
        if (glyph.strokes.length < 2) return;
        final result = GlyphSession(glyph).submit(glyph.strokes[1]);
        expect(result.ok, isFalse);
        expect(result.error, StrokeError.wrongOrder);
      });

      test('every reversed stroke is rejected', () {
        final glyph = _load(id);
        for (var i = 0; i < glyph.strokes.length; i++) {
          final stroke = glyph.strokes[i];
          if (_length(stroke) <= 0.05) continue;
          final reversed = Stroke(stroke.points.reversed.toList());
          final session = GlyphSession(glyph);
          for (var j = 0; j < i; j++) {
            session.submit(glyph.strokes[j]);
          }
          expect(session.submit(reversed).ok, isFalse,
              reason: 'reversed stroke $i of $id still grades ok');
        }
      });
    });
  }
}
