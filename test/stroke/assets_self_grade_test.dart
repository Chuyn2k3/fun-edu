import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph_session.dart';

void main() {
  final files = Directory('assets/glyphs')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('assets/glyphs contains at least one glyph file', () {
    expect(
      files,
      isNotEmpty,
      reason: 'no glyph JSON found; run tests from the app/ directory',
    );
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    test('$name grades its own reference strokes as complete', () {
      final glyph = Glyph.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(
        glyph.id,
        name.substring(0, name.length - '.json'.length),
        reason: 'id inside the file must match the file name',
      );
      expect(glyph.strokes, isNotEmpty);

      final session = GlyphSession(glyph.inWindow());
      final win = glyph.inWindow();
      for (var i = 0; i < glyph.strokes.length; i++) {
        final result = session.submit(win.strokes[i]);
        expect(
          result.ok,
          isTrue,
          reason: 'stroke $i of ${glyph.id} rejected: ${result.error}',
        );
      }
      expect(session.isComplete, isTrue);
    });

    if (name.startsWith('chu-') || name.startsWith('dau-')) {
      test('$name rejects reversed and misordered strokes', () {
        final glyph = Glyph.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        );
        final win = glyph.inWindow();
        const dotLength = 0.02;
        final longIdx = [
          for (var i = 0; i < win.strokes.length; i++)
            if (pathLength(win.strokes[i].points) > dotLength) i,
        ];
        // Single-point glyphs (dau-nang) have nothing to reverse.
        if (longIdx.isEmpty) return;
        final first = win.strokes.first;
        if (pathLength(first.points) > dotLength) {
          final rev = Stroke(first.points.reversed.toList());
          expect(GlyphSession(win).submit(rev).ok, isFalse,
              reason: 'reversed first stroke of ${glyph.id} accepted');
        }
        if (win.strokes.length > 1) {
          expect(GlyphSession(win).submit(win.strokes[1]).ok, isFalse,
              reason: 'stroke 2 first accepted for ${glyph.id}');
        }
      });
    }
  }

  Glyph load(String id) => Glyph.fromJson(
        jsonDecode(File('assets/glyphs/$id.json').readAsStringSync())
            as Map<String, dynamic>,
      );

  test('chu-a body shifted right by one o li is graded wrong', () {
    final g = load('chu-a');
    final cell = g.ruling!.cell;
    final shifted = Stroke([
      for (final p in g.strokes.first.points) Point2(p.x + cell, p.y),
    ]);
    final win = g.inWindow();
    final shiftedWin = Glyph(
      id: g.id,
      label: g.label,
      ruling: g.ruling,
      strokes: [shifted],
    ).inWindow();
    expect(GlyphSession(win).submit(shiftedWin.strokes.single).ok, isFalse);
  });

  test('chu-b with loop replaced by a straight line is graded wrong', () {
    final g = load('chu-b');
    expect(g.strokes.length, 1);
    final pts = g.strokes.single.points;
    final line = Glyph(
      id: g.id,
      label: g.label,
      ruling: g.ruling,
      strokes: [
        Stroke([pts.first, pts.last]),
      ],
    ).inWindow();
    expect(GlyphSession(g.inWindow()).submit(line.strokes.single).ok, isFalse);
  });
}
