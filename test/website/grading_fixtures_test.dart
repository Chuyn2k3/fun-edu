// Writes website/test/fixtures/grading.json: how the app grades a set of
// strokes for the website's tracing items. The website's TypeScript grader
// must give the same results. Run with UPDATE_FIXTURES=1 to rewrite.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_session.dart';
import 'package:funedu/stroke/grader.dart';

const _items = [
  'so-1', 'so-2', 'so-3', 'chu-a', 'chu-o', 'chu-b', 'chu-c', 'chu-e', //
];
const _path = 'website/test/fixtures/grading.json';

Object _num(double v) => v.isNaN ? 'NaN' : (v.isInfinite ? 'Infinity' : v);

List<Object> _stroke(Stroke s) => [
      for (final p in s.points) [_num(p.x), _num(p.y)]
    ];

Stroke _shift(Stroke s, double dx) =>
    Stroke([for (final p in s.points) Point2(p.x + dx, p.y)]);

Map<String, Object> _fixture(Glyph raw) {
  final g = raw.inWindow();
  final s = g.strokes;
  final cases = <String, List<Stroke>>{
    'exact': s,
    'reversed-first': [Stroke(s.first.points.reversed.toList())],
    'shift-0.05': [_shift(s.first, 0.05)],
    'shift-0.15': [_shift(s.first, 0.15)],
    'shift-0.3': [_shift(s.first, 0.3)],
    'cut-40': [
      Stroke(s.first.points
          .sublist(0, (s.first.points.length * 0.4).ceil().clamp(1, 1 << 30)))
    ],
    'nan': [
      Stroke([
        ...s.first.points.take(1),
        const Point2(double.nan, 0.5),
        ...s.first.points.skip(1),
      ])
    ],
    if (s.length >= 2) 'order': [s[1]],
  };
  final session = GlyphSession(g);
  return {
    'glyph': raw.id,
    'tolerance': session.config.tolerance,
    'maxPointDistance': session.config.maxPointDistance,
    'cases': [
      for (final e in cases.entries)
        () {
          final run = GlyphSession(g);
          final results = <Object>[];
          for (final d in e.value) {
            if (run.isComplete) break;
            final r = run.submit(d);
            results.add({
              'ok': r.ok,
              'error': r.error?.name,
              'deviation': _num(r.deviation),
            });
          }
          return {
            'name': e.key,
            'inputs': [for (final d in e.value) _stroke(d)],
            'results': results,
            'complete': run.isComplete,
          };
        }(),
    ],
  };
}

void main() {
  test('website grading fixtures match the app grader', () {
    final data = [
      for (final id in _items)
        _fixture(Glyph.fromJson(jsonDecode(
                File('assets/glyphs/$id.json').readAsStringSync())
            as Map<String, dynamic>)),
    ];
    final text = '${const JsonEncoder.withIndent(' ').convert(data)}\n';
    final file = File(_path);
    if (Platform.environment['UPDATE_FIXTURES'] == '1') {
      file.writeAsStringSync(text);
    }
    expect(file.existsSync(), isTrue, reason: 'run with UPDATE_FIXTURES=1');
    expect(file.readAsStringSync(), text,
        reason: 'grading changed: rerun with UPDATE_FIXTURES=1 and check '
            'the website grader still passes');
  });
}
