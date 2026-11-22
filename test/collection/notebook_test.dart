import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/collection/notebook.dart';
import 'package:funedu/stroke/geometry.dart';

/// One logged stroke: (index, ok, points or null).
NotebookAttempt a(int i, bool ok, {double x = 0.5, bool points = true, int minute = 0}) =>
    NotebookAttempt(
      strokeIndex: i,
      ok: ok,
      points: points ? [Point2(x, 0.1), Point2(x, 0.9)] : null,
      at: DateTime(2026, 11, 22, 8, minute),
    );

void main() {
  test('a full run of ok strokes is a page', () {
    final pages = bestWritings([a(0, true), a(1, true)], strokeCount: 2);
    expect(pages, isNotNull);
    expect(pages!.strokes, hasLength(2));
    expect(pages.mistakes, 0);
  });

  test('retries of a stroke count as mistakes and only the ok one is kept', () {
    final p = bestWritings([a(0, false, x: 0.1), a(0, false, x: 0.2), a(0, true, x: 0.3), a(1, true)],
        strokeCount: 2)!;
    expect(p.mistakes, 2);
    expect(p.strokes.first.points.first.x, 0.3);
  });

  test('an unfinished run is not a page', () {
    expect(bestWritings([a(0, true)], strokeCount: 2), isNull);
  });

  test('a new start (index back to 0) drops the unfinished run', () {
    final p = bestWritings([a(0, true, x: 0.1), a(0, true, x: 0.7), a(1, true)], strokeCount: 2)!;
    expect(p.strokes.first.points.first.x, 0.7);
  });

  test('the best page has the fewest mistakes, then the latest', () {
    final p = bestWritings([
      a(0, false, minute: 1), a(0, true, x: 0.1, minute: 1), // 1 mistake
      a(0, true, x: 0.2, minute: 2), // clean
      a(0, true, x: 0.3, minute: 3), // clean, later: wins
      a(0, false, minute: 4), a(0, true, x: 0.4, minute: 4), // 1 mistake
    ], strokeCount: 1)!;
    expect(p.mistakes, 0);
    expect(p.strokes.single.points.first.x, 0.3);
    expect(p.writtenAt, DateTime(2026, 11, 22, 8, 3));
  });

  test('strokes logged without coordinates (old app) never make a page', () {
    expect(bestWritings([a(0, true, points: false)], strokeCount: 1), isNull);
  });

  test('a dot stroke (one point) is kept', () {
    final p = bestWritings([
      NotebookAttempt(strokeIndex: 0, ok: true, points: const [Point2(0.5, 0.5)], at: DateTime(2026)),
    ], strokeCount: 1)!;
    expect(p.strokes.single.points, hasLength(1));
  });

  test('decodes the stored JSON points', () {
    expect(decodePoints('[[0.1,0.2],[0.3,0.4]]'), const [Point2(0.1, 0.2), Point2(0.3, 0.4)]);
    expect(decodePoints(null), isNull);
    expect(decodePoints('not json'), isNull);
  });
}
