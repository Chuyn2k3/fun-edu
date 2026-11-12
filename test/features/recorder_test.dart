import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/dev/recorder_controller.dart';
import 'package:funedu/features/dev/recorder_screen.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:flutter/material.dart';

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

  test('exportJson is single-line, rounded to 4 decimals and round-trips', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(recorderProvider.notifier);
    n.addStroke(const Stroke([Point2(0.123456, 0.5), Point2(0.98765, 0.25)]));
    final json = n.exportJson('b', 'B');
    expect(json.contains('\n'), isFalse);
    expect(json.contains('0.123456'), isFalse);
    final g = Glyph.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(g.strokes.single.points.first, const Point2(0.1235, 0.5));
    expect(g.strokes.single.points.last, const Point2(0.9877, 0.25));
  });

  testWidgets('export with empty id shows a hint and copies nothing', (
    t,
  ) async {
    String? clip;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clip = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await t.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RecorderScreen())),
    );
    await t.tap(find.text('Xuất'));
    await t.pump();
    expect(find.text('Nhập id trước khi xuất'), findsOneWidget);
    expect(clip, isNull);
  });
}
