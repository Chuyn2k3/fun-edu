import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/collection/notebook_pages.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';

void main() {
  test('simplifyStrokes preserves endpoints and rounds to 3 decimals', () {
    final points = <Point2>[
      Point2(0.12345, 0.67891),
      for (var i = 1; i < 100; i++) Point2(i * 0.01, i * 0.02),
      Point2(0.99999, 1.88888),
    ];

    final simplified = simplifyStrokes([points], maxPoints: 40);
    expect(simplified, hasLength(1));
    final coords = simplified.single;
    // 40 points -> 80 coords
    expect(coords, hasLength(80));

    // First point
    expect(coords[0], 0.123);
    expect(coords[1], 0.679);

    // Last point
    expect(coords[78], 1.0);
    expect(coords[79], 1.889);
  });

  test('6 strokes x 40 points payload is under 4 KB JSON', () {
    final sixStrokes = <List<Point2>>[];
    for (var s = 0; s < 6; s++) {
      sixStrokes.add([
        for (var i = 0; i < 50; i++)
          Point2(s * 0.1 + i * 0.005, math.sin(i * 0.1)),
      ]);
    }

    final simplified = simplifyStrokes(sixStrokes, maxPoints: 40);
    final payload = {
      's': simplified,
      'm': 0,
      'at': DateTime.now().millisecondsSinceEpoch,
    };
    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr).length;

    expect(bytes, lessThan(4096));
  });

  test('simplification error on circle/curve is <= 0.01', () {
    // Circle arc with radius 0.5 centered at (0.5, 0.5)
    final circlePoints = <Point2>[
      for (var i = 0; i <= 200; i++)
        Point2(
          0.5 + 0.5 * math.cos(i * math.pi / 200),
          0.5 + 0.5 * math.sin(i * math.pi / 200),
        ),
    ];

    final simplified = simplifyStrokes([circlePoints], maxPoints: 40);
    final coords = simplified.single;
    for (var i = 0; i < coords.length; i += 2) {
      final x = coords[i];
      final y = coords[i + 1];
      final distFromCenter = math.sqrt((x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5));
      expect((distFromCenter - 0.5).abs(), lessThanOrEqualTo(0.01));
    }
  });

  test('isBetterPage gives precedence to fewer mistakes, then newer timestamp', () {
    final t1 = DateTime(2026, 11, 20, 10, 0);
    final t2 = DateTime(2026, 11, 20, 11, 0);

    // Fewer mistakes is always better
    expect(isBetterPage(0, t1, 1, t2), isTrue);
    expect(isBetterPage(2, t2, 1, t1), isFalse);

    // Same mistakes: newer is better
    expect(isBetterPage(1, t2, 1, t1), isTrue);
    expect(isBetterPage(1, t1, 1, t2), isFalse);
  });

  test('decodeStrokes reconstitutes Stroke objects accurately', () {
    final original = [
      [0.1, 0.2, 0.3, 0.4],
      [0.5, 0.6, 0.7, 0.8],
    ];
    final jsonStr = jsonEncode(original);
    final strokes = decodeStrokes(jsonStr);

    expect(strokes, hasLength(2));
    expect(strokes[0].points, hasLength(2));
    expect(strokes[0].points[0].x, 0.1);
    expect(strokes[0].points[0].y, 0.2);
    expect(strokes[1].points[1].x, 0.7);
    expect(strokes[1].points[1].y, 0.8);
  });

  test('refreshNotebookPage picks the best run and writes to notebook_pages', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    const kidId = 1;
    const glyphId = 'net-ngang'; // 1 stroke

    final strokePoints = [
      Point2(0.1, 0.5),
      Point2(0.5, 0.5),
      Point2(0.9, 0.5),
    ];

    // Attempt 1: mistake on stroke 0, then success
    await db.into(db.strokeAttempts).insert(
          StrokeAttemptsCompanion.insert(
            kidId: kidId,
            glyphId: glyphId,
            strokeIndex: 0,
            ok: false,
            deviation: 0.5,
            points: Value(encodePoints(Stroke(strokePoints))),
            createdAt: DateTime(2026, 11, 22, 10, 0),
          ),
        );
    await db.into(db.strokeAttempts).insert(
          StrokeAttemptsCompanion.insert(
            kidId: kidId,
            glyphId: glyphId,
            strokeIndex: 0,
            ok: true,
            deviation: 0.1,
            points: Value(encodePoints(Stroke(strokePoints))),
            createdAt: DateTime(2026, 11, 22, 10, 1),
          ),
        );

    await refreshNotebookPage(db, kidId, glyphId);

    var pages = await db.select(db.notebookPages).get();
    expect(pages, hasLength(1));
    expect(pages.single.mistakes, 1);

    // Attempt 2: perfect run (0 mistakes)
    await db.into(db.strokeAttempts).insert(
          StrokeAttemptsCompanion.insert(
            kidId: kidId,
            glyphId: glyphId,
            strokeIndex: 0,
            ok: true,
            deviation: 0.05,
            points: Value(encodePoints(Stroke(strokePoints))),
            createdAt: DateTime(2026, 11, 22, 10, 5),
          ),
        );

    await refreshNotebookPage(db, kidId, glyphId);

    pages = await db.select(db.notebookPages).get();
    expect(pages, hasLength(1));
    expect(pages.single.mistakes, 0);
  });
}
