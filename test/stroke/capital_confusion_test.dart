import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_session.dart';

/// Capitals (2G): each is accepted when written as the model, a wrong
/// capital is never praised, and capitals are not graded looser than the
/// digit 0 (same rules as the lowercase letters, letter_confusion_test).

Glyph _load(String id) => Glyph.fromJson(
      jsonDecode(File('assets/glyphs/$id.json').readAsStringSync())
          as Map<String, dynamic>,
    );

List<Stroke> _intoWindowOf(Glyph target, List<Stroke> strokes) => Glyph(
      id: target.id,
      label: target.label,
      ruling: target.ruling,
      strokes: strokes,
    ).inWindow().strokes;

bool _praised(Glyph target, List<Stroke> drawn) {
  final session = GlyphSession(target.inWindow());
  for (final s in drawn) {
    if (session.isComplete) break;
    if (!session.submit(s).ok) return false;
  }
  return session.isComplete;
}

const _capitals = [
  'hoa-o', 'hoa-oo', 'hoa-ow', 'hoa-c', 'hoa-i', 'hoa-l', 'hoa-t', 'hoa-h', //
  'hoa-u', 'hoa-uw', 'hoa-v', 'hoa-x', 'hoa-n', 'hoa-m', 'hoa-a', 'hoa-aw',
  'hoa-aa', 'hoa-e', 'hoa-ee', 'hoa-s', 'hoa-p', 'hoa-r', 'hoa-b', 'hoa-d',
  'hoa-dd', 'hoa-k', 'hoa-q', 'hoa-g', 'hoa-y',
];

/// (target, drawn): the target is the first strokes of the drawn capital,
/// so drawing that prefix IS the target letter. A ⊂ Ă/Â, O ⊂ Ô/Ơ/Q, E ⊂ Ê,
/// U ⊂ Ư, D ⊂ Đ, and the C curve that starts G.
const _subsetPairs = {
  ('hoa-a', 'hoa-aw'), ('hoa-a', 'hoa-aa'), //
  ('hoa-o', 'hoa-oo'), ('hoa-o', 'hoa-ow'), ('hoa-o', 'hoa-q'),
  ('hoa-c', 'hoa-g'),
  ('hoa-e', 'hoa-ee'), ('hoa-u', 'hoa-uw'), ('hoa-d', 'hoa-dd'),
};

/// Whether [a] equals the first strokes of [b] after one common translation.
bool _isPrefix(List<Stroke> a, List<Stroke> b) {
  if (b.length <= a.length) return false;
  final sx = b[0].points[0].x - a[0].points[0].x;
  final sy = b[0].points[0].y - a[0].points[0].y;
  for (var i = 0; i < a.length; i++) {
    final pa = a[i].points, pb = b[i].points;
    if (pa.length != pb.length) return false;
    for (var j = 0; j < pa.length; j++) {
      if ((pa[j].x + sx - pb[j].x).abs() > 1e-3 || (pa[j].y + sy - pb[j].y).abs() > 1e-3) {
        return false;
      }
    }
  }
  return true;
}

void main() {
  final glyphs = {for (final id in _capitals) id: _load(id)};

  test('every capital file exists with a writing window', () {
    for (final id in _capitals) {
      expect(glyphs[id]!.ruling, isNotNull, reason: id);
      expect(glyphs[id]!.spokenName, endsWith(' hoa'), reason: id);
    }
  });

  for (final id in _capitals) {
    test('$id written as the model is praised', () {
      final g = glyphs[id]!;
      expect(_praised(g, g.inWindow().strokes), isTrue);
    });
  }

  test('subset pairs are exactly the listed ones', () {
    final found = <(String, String)>{};
    for (final a in _capitals) {
      for (final b in _capitals) {
        if (a != b && _isPrefix(glyphs[a]!.strokes, glyphs[b]!.strokes)) found.add((a, b));
      }
    }
    expect(found, _subsetPairs);
  });

  group('capital confusion', () {
    for (final a in _capitals) {
      for (final b in _capitals) {
        if (a == b) continue;
        test('$b drawn for $a is graded wrong', () {
          final target = glyphs[a]!, other = glyphs[b]!;
          if (other.strokes.length != target.strokes.length) return;
          expect(_praised(target, _intoWindowOf(target, other.strokes)), isFalse);
        });
      }
    }
    for (final a in _capitals) {
      for (final b in _capitals) {
        if (a == b || _subsetPairs.contains((a, b))) continue;
        test('first strokes of $b drawn for $a are graded wrong', () {
          final target = glyphs[a]!, other = glyphs[b]!;
          if (other.strokes.length <= target.strokes.length) return;
          final drawn = _intoWindowOf(target, other.strokes.sublist(0, target.strokes.length));
          expect(_praised(target, drawn), isFalse);
        });
      }
    }
  });

  group('size parity with digits', () {
    double height(Glyph g) {
      final ys = [for (final s in g.strokes) ...s.points.map((p) => p.y)];
      return ys.reduce(math.max) - ys.reduce(math.min);
    }

    double maxShift(Glyph raw) {
      final g = raw.inWindow();
      final h = height(g);
      var best = 0.0;
      for (var i = 1; i < 400; i++) {
        final dx = i * h / 1000;
        final session = GlyphSession(g);
        var ok = true;
        for (final s in g.strokes) {
          if (!session.submit(Stroke([for (final p in s.points) Point2(p.x + dx, p.y)])).ok) {
            ok = false;
            break;
          }
        }
        if (!ok) break;
        best = dx / h;
      }
      return best;
    }

    final digit = maxShift(_load('so-0'));
    for (final id in ['hoa-o', 'hoa-a', 'hoa-e', 'hoa-n', 'hoa-m', 'hoa-h', 'hoa-g']) {
      test('$id is not graded looser than so-0', () {
        final shift = maxShift(glyphs[id]!);
        expect(shift, lessThanOrEqualTo(1.25 * digit),
            reason: '$id accepts ${shift.toStringAsFixed(3)} of its height; '
                'so-0 ${digit.toStringAsFixed(3)}');
      });
    }
  });
}
