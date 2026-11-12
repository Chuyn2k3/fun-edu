import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/dev/recorder_controller.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';

void main() {
  test('addStroke, undo, clear and exportJson', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(recorderProvider.notifier);
    n.addStroke(const Stroke([Point2(0, 0), Point2(1, 1)]));
    n.addStroke(const Stroke([Point2(0, 1), Point2(1, 0)]));
    n.undo();
    expect(c.read(recorderProvider), hasLength(1));
    final g = Glyph.fromJson(
      jsonDecode(n.exportJson('b', 'b')) as Map<String, dynamic>,
    );
    expect(g.id, 'b');
    expect(g.strokes, hasLength(1));
    n.clear();
    n.undo();
    expect(c.read(recorderProvider), isEmpty);
  });
}
