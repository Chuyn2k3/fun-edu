import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_session.dart';

void main() {
  final files =
      Directory('assets/glyphs')
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

      final session = GlyphSession(glyph);
      for (var i = 0; i < glyph.strokes.length; i++) {
        final result = session.submit(glyph.strokes[i]);
        expect(
          result.ok,
          isTrue,
          reason: 'stroke $i of ${glyph.id} rejected: ${result.error}',
        );
      }
      expect(session.isComplete, isTrue);
    });
  }
}
