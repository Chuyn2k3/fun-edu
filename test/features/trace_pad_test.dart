import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/trace/trace_pad.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:flutter/material.dart';

Future<List<Stroke>> _pump(WidgetTester t, double side) async {
  final got = <Stroke>[];
  await t.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: side,
          height: side,
          child: TracePad(onStrokeEnd: got.add),
        ),
      ),
    ),
  );
  return got;
}

void main() {
  _crayonTest();
  testWidgets('maps drag to normalized coordinates (300)', (t) async {
    final got = await _pump(t, 300);
    final o = t.getTopLeft(find.byType(TracePad));
    await t.dragFrom(o + const Offset(30, 30), const Offset(240, 0));
    expect(got, hasLength(1));
    expect(got.first.points.first.x, closeTo(0.1, 0.01));
    expect(got.first.points.first.y, closeTo(0.1, 0.01));
    expect(got.first.points.last.x, closeTo(0.9, 0.01));
    expect(got.first.points.last.y, closeTo(0.1, 0.01));
  });

  testWidgets('same result at 600', (t) async {
    final got = await _pump(t, 600);
    final o = t.getTopLeft(find.byType(TracePad));
    await t.dragFrom(o + const Offset(60, 60), const Offset(480, 0));
    expect(got.first.points.first.x, closeTo(0.1, 0.01));
    expect(got.first.points.last.x, closeTo(0.9, 0.01));
    expect(got.first.points.last.y, closeTo(0.1, 0.01));
  });

  testWidgets('clamps points outside the square', (t) async {
    final got = await _pump(t, 300);
    final o = t.getTopLeft(find.byType(TracePad));
    await t.dragFrom(o + const Offset(30, 30), const Offset(370, -80));
    for (final p in got.first.points) {
      expect(p.x, inInclusiveRange(0, 1));
      expect(p.y, inInclusiveRange(0, 1));
    }
    expect(got.first.points.last.x, 1.0);
    expect(got.first.points.last.y, 0.0);
  });

  testWidgets('ignores a second pointer; cancel ends without callback', (
    t,
  ) async {
    final got = await _pump(t, 300);
    final o = t.getTopLeft(find.byType(TracePad));
    final a = await t.startGesture(o + const Offset(30, 30), pointer: 1);
    final b = await t.startGesture(o + const Offset(100, 100), pointer: 2);
    await b.moveTo(o + const Offset(200, 200));
    await a.moveTo(o + const Offset(60, 30));
    await a.up();
    await b.moveTo(o + const Offset(250, 250));
    await b.up();
    expect(got, hasLength(1));
    expect(got.first.points.every((p) => p.x <= 0.21 && p.y <= 0.11), isTrue);

    final c = await t.startGesture(o + const Offset(30, 30), pointer: 3);
    await c.moveTo(o + const Offset(60, 30));
    await c.cancel();
    expect(got, hasLength(1));
  });
}

void _crayonTest() {
  testWidgets('crayon pad builds and draws without error', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: TracePad(
              crayon: true,
              onStrokeEnd: (_) {},
              inked: const [
                Stroke([Point2(0.1, 0.1), Point2(0.9, 0.9)]),
              ],
            ),
          ),
        ),
      ),
    );
    final o = t.getTopLeft(find.byType(TracePad));
    await t.dragFrom(o + const Offset(30, 30), const Offset(100, 0));
    expect(t.takeException(), isNull);
  });
}
