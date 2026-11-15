import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_session.dart';
import 'package:funedu/stroke/grader.dart';

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

/// [s] resampled, scaled by the size about its centroid, moved by
/// (dx, dy) and waved sideways by the amplitude (1.5 waves along it).
Stroke _wobble(Stroke s, (double, double, double, double) w) {
  final (dx, dy, amp, size) = w;
  final pts = resample(s.points, 40);
  final c = centroid(pts);
  final n = pts.length;
  return Stroke([
    for (var i = 0; i < n; i++)
      () {
        final a = pts[math.max(0, i - 1)], b = pts[math.min(n - 1, i + 1)];
        final tx = b.x - a.x, ty = b.y - a.y;
        final l = math.sqrt(tx * tx + ty * ty);
        final nx = l == 0 ? 0.0 : -ty / l, ny = l == 0 ? 0.0 : tx / l;
        final off = amp * math.sin(2 * math.pi * 1.5 * i / (n - 1));
        final p = pts[i];
        return Point2(c.x + size * (p.x - c.x) + dx + off * nx,
            c.y + size * (p.y - c.y) + dy + off * ny);
      }(),
  ]);
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

  // Owner decision (mark-zoom): the marks are drawn big on the pad, so a
  // child's honest mark is accepted while a different mark is not. Wobble and
  // offsets are in pad units (what the child's hand does on screen): an offset
  // of 0.05 of the pad is about 4 mm on a phone, about 0.15 of the zoomed
  // mark's length. Under the old 5-ô-li window most of these were rejected.
  group('tone marks a child can write', () {
    const lineMarks = ['dau-huyen', 'dau-sac', 'dau-hoi', 'dau-nga'];
    // (dx, dy, wobble amplitude, size) in pad units.
    const wobbles = [
      (0.035, 0.035, 0.025, 1.1),
      (0.04, -0.03, 0.03, 0.9),
      (-0.04, 0.03, 0.03, 1.1),
    ];

    test('each mark fills at least a third of the pad', () {
      for (final id in lineMarks) {
        final pts = glyphs[id]!.inWindow().strokes.single.points;
        final w = pts.map((p) => p.x).reduce(math.max) -
            pts.map((p) => p.x).reduce(math.min);
        final h = pts.map((p) => p.y).reduce(math.max) -
            pts.map((p) => p.y).reduce(math.min);
        expect(math.max(w, h), greaterThanOrEqualTo(0.35), reason: id);
      }
    });

    for (final (i, w) in wobbles.indexed) {
      for (final id in lineMarks) {
        test('$id drawn with wobble ${i + 1} is accepted', () {
          final g = glyphs[id]!.inWindow();
          final drawn = _wobble(g.strokes.single, w);
          final r = GlyphSession(g).submit(drawn);
          expect(r.ok, isTrue,
              reason: 'error ${r.error}, deviation '
                  '${r.deviation.toStringAsFixed(3)}');
        });
        for (final other in lineMarks) {
          if (other == id) continue;
          test('$other drawn with wobble ${i + 1} for $id is graded wrong', () {
            final target = glyphs[id]!;
            final drawn = _wobble(
                _intoWindowOf(target, glyphs[other]!.strokes).single, w);
            expect(_praised(target, [drawn]), isFalse);
          });
        }
      }
    }

    test('dau-nang: a tap 0.06 of the pad off the dot is accepted', () {
      final g = glyphs['dau-nang']!.inWindow();
      final p = g.strokes.single.points.single;
      final r =
          GlyphSession(g).submit(Stroke([Point2(p.x + 0.04, p.y - 0.045)]));
      expect(r.ok, isTrue);
    });

    test('a mark that stops early is told to draw longer', () {
      final g = glyphs['dau-huyen']!.inWindow();
      final pts = g.strokes.single.points;
      final r = GlyphSession(g)
          .submit(Stroke(pts.sublist(0, (pts.length * 0.65).round())));
      expect(r.ok, isFalse);
      expect(r.error, StrokeError.tooShort);
    });
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
