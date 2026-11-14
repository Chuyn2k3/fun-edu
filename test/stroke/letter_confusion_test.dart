import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_session.dart';

/// Regression tests for the phase 2A review: wrong tone marks and similar
/// letters must not be praised, and small letters must not be graded looser
/// than digits (design §2 anti-goals, §6b).

Glyph _load(String id) => Glyph.fromJson(
      jsonDecode(File('assets/glyphs/$id.json').readAsStringSync())
          as Map<String, dynamic>,
    );

/// [strokes] (frame coordinates) mapped into [target]'s writing window.
List<Stroke> _intoWindowOf(Glyph target, List<Stroke> strokes) => Glyph(
      id: target.id,
      label: target.label,
      ruling: target.ruling,
      strokes: strokes,
    ).inWindow().strokes;

/// True when submitting [drawn] in order completes [target] with every stroke
/// accepted (what the writing screen praises).
bool _praised(Glyph target, List<Stroke> drawn) {
  final session = GlyphSession(target.inWindow());
  for (final s in drawn) {
    if (session.isComplete) break;
    if (!session.submit(s).ok) return false;
  }
  return session.isComplete;
}

const _marks = ['dau-huyen', 'dau-sac', 'dau-nang', 'dau-hoi', 'dau-nga'];

const _letters = [
  'chu-i', 'chu-t', 'chu-u', 'chu-uw', 'chu-n', 'chu-m', 'chu-v', 'chu-r', //
  'chu-s', 'chu-o', 'chu-oo', 'chu-ow', 'chu-c', 'chu-x', 'chu-e', 'chu-ee',
  'chu-a', 'chu-aw', 'chu-aa', 'chu-d', 'chu-dd', 'chu-q', 'chu-l', 'chu-b',
  'chu-h', 'chu-k', 'chu-g', 'chu-y', 'chu-p',
];

/// (target, drawn) where the target's strokes are the first strokes of the
/// drawn letter, up to moving them as a whole: a ⊂ ă/â, o ⊂ ô/ơ, e ⊂ ê,
/// u ⊂ ư, d ⊂ đ, and the oval of o that starts a/ă/â/d/đ/q/g. Drawing that
/// prefix IS the smaller letter, so it is rightly accepted (the o-in-a case
/// sits 0.35 ô li left of o's own place, which the shift tests cover).
/// No other subset pairs exist among the 29 letters (checked below).
const _subsetPairs = {
  ('chu-a', 'chu-aw'), ('chu-a', 'chu-aa'), //
  ('chu-o', 'chu-oo'), ('chu-o', 'chu-ow'),
  ('chu-e', 'chu-ee'), ('chu-u', 'chu-uw'), ('chu-d', 'chu-dd'),
  ('chu-o', 'chu-a'), ('chu-o', 'chu-aw'), ('chu-o', 'chu-aa'), //
  ('chu-o', 'chu-d'), ('chu-o', 'chu-dd'), ('chu-o', 'chu-q'),
  ('chu-o', 'chu-g'),
};

/// Whether [a] equals the first strokes of [b] after one common translation.
bool _isPrefixUpToShift(List<Stroke> a, List<Stroke> b) {
  if (b.length <= a.length) return false;
  final dx = b[0].points[0].x - a[0].points[0].x;
  final dy = b[0].points[0].y - a[0].points[0].y;
  for (var i = 0; i < a.length; i++) {
    final pa = a[i].points, pb = b[i].points;
    if (pa.length != pb.length) return false;
    for (var j = 0; j < pa.length; j++) {
      if ((pa[j].x + dx - pb[j].x).abs() > 1e-3 ||
          (pa[j].y + dy - pb[j].y).abs() > 1e-3) {
        return false;
      }
    }
  }
  return true;
}

void main() {
  final glyphs = {for (final id in [..._marks, ..._letters]) id: _load(id)};

  group('tone marks', () {
    for (final a in _marks) {
      for (final b in _marks) {
        if (a == b) continue;
        test('$b drawn for $a is graded wrong', () {
          final target = glyphs[a]!;
          final drawn = _intoWindowOf(target, glyphs[b]!.strokes);
          expect(_praised(target, drawn), isFalse);
        });
      }
    }
  });

  group('letter confusion', () {
    test('subset pairs are exactly the listed ones', () {
      final found = <(String, String)>{};
      for (final a in _letters) {
        for (final b in _letters) {
          if (a == b) continue;
          if (_isPrefixUpToShift(glyphs[a]!.strokes, glyphs[b]!.strokes)) {
            found.add((a, b));
          }
        }
      }
      expect(found, _subsetPairs);
    });

    // Same stroke count: the whole of letter B drawn for letter A.
    for (final a in _letters) {
      for (final b in _letters) {
        if (a == b) continue;
        test('$b drawn for $a is graded wrong', () {
          final target = glyphs[a]!, other = glyphs[b]!;
          if (other.strokes.length != target.strokes.length) return;
          final drawn = _intoWindowOf(target, other.strokes);
          expect(_praised(target, drawn), isFalse);
        });
      }
    }

    // Body strokes of a longer letter drawn for a shorter one (r vs i, t),
    // except the listed prefix pairs.
    for (final a in _letters) {
      for (final b in _letters) {
        if (a == b || _subsetPairs.contains((a, b))) continue;
        test('first strokes of $b drawn for $a are graded wrong', () {
          final target = glyphs[a]!, other = glyphs[b]!;
          if (other.strokes.length <= target.strokes.length) return;
          final drawn = _intoWindowOf(
              target, other.strokes.sublist(0, target.strokes.length));
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

    /// Largest sideways shift (fraction of glyph height) still praised.
    double maxShift(Glyph raw) {
      final g = raw.inWindow();
      final h = height(g);
      var best = 0.0;
      for (var i = 1; i < 400; i++) {
        final dx = i * h / 1000;
        final drawn = [
          for (final s in g.strokes)
            Stroke([for (final p in s.points) Point2(p.x + dx, p.y)]),
        ];
        final session = GlyphSession(g);
        var ok = true;
        for (final s in drawn) {
          if (!session.submit(s).ok) {
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

    test('so-0 baseline is the grader tolerance over its height', () {
      expect(digit, closeTo(0.15, 0.005));
    });

    for (final id in ['chu-o', 'chu-a', 'chu-e', 'chu-n', 'chu-m']) {
      test('$id is not graded looser than so-0', () {
        final shift = maxShift(glyphs[id]!);
        expect(shift, lessThanOrEqualTo(1.25 * digit),
            reason: '$id accepts a shift of ${shift.toStringAsFixed(3)} of '
                'its height; so-0 accepts ${digit.toStringAsFixed(3)}');
      });
    }
  });
}
