import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/race_controller.dart';

/// The race's fallback names (used only when a glyph file cannot be read)
/// must say exactly what the glyph files say.
void main() {
  test('fallback letter and tone names match the glyph speech', () {
    final files = Directory('assets/glyphs')
        .listSync()
        .whereType<File>()
        .where((f) {
          final name = f.uri.pathSegments.last;
          return name.startsWith('chu-') || name.startsWith('dau-');
        })
        .toList();
    expect(files.length, greaterThanOrEqualTo(34)); // 29 letters + 5 tones
    for (final f in files) {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final id = f.uri.pathSegments.last.replaceAll('.json', '');
      expect(spokenNameFromId(id), json['speech'], reason: id);
    }
  });
}
