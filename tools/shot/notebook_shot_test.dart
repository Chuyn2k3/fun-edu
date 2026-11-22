// Shot harness for "Vở của bé" (6 child-like pages). Usage:
//   mkdir -p test/_shot && cp tools/shot/notebook_shot_test.dart test/_shot/
//   flutter test test/_shot/notebook_shot_test.dart --update-goldens; rm -rf test/_shot
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/collection/collection_screen.dart';
import 'package:funedu/router.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';

import '../../test/features/game/game_test_helpers.dart';

/// The model strokes, wobbled a little like a child's hand.
List<Stroke> _childLike(String id, int seed) {
  final g = Glyph.fromJson(jsonDecode(File('assets/glyphs/$id.json').readAsStringSync()) as Map<String, dynamic>)
      .inWindow();
  final r = math.Random(seed);
  return [
    for (final s in g.strokes)
      Stroke([
        for (var i = 0; i < s.points.length; i++)
          Point2(s.points[i].x + 0.012 * math.sin(i / 3 + seed) + r.nextDouble() * 0.004,
              s.points[i].y + 0.012 * math.cos(i / 4 + seed)),
      ]),
  ];
}

void main() {
  setUp(() => rootBundle.clear());
  for (final size in const [Size(390, 844)]) {
    testWidgets('notebook shot', (t) async {
      await t.runAsync(() async {
        final loader = FontLoader('Nunito');
        for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
          loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
        }
        await loader.load();
      });
      await bootGame(t, size: size, seed: (db, kid) async {
        var seed = 0;
        for (final id in ['so-2', 'chu-a', 'chu-b', 'chu-oo', 'hoa-a', 'hoa-g']) {
          final strokes = _childLike(id, seed++);
          for (var i = 0; i < strokes.length; i++) {
            await db.logAttempt(kidId: kid, glyphId: id, strokeIndex: i, ok: true,
                error: null, deviation: 0.05, drawn: strokes[i]);
          }
        }
      });
      appRouter.go('/collection');
      await pumpReal(t, times: 6);
      final tab = find.byKey(const ValueKey('collection-tab-notebook'));
      await t.runAsync(() => Scrollable.ensureVisible(t.element(tab), alignment: 0.2));
      await t.pump();
      await t.tap(tab);
      for (var i = 0; i < 20; i++) {
        await pumpReal(t, times: 1);
      }
      await t.runAsync(() => Scrollable.ensureVisible(
          t.element(find.byKey(const ValueKey('notebook-print'))), alignment: 0.05));
      await pumpReal(t, times: 4);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump();
      await expectLater(find.byType(CollectionScreen), matchesGoldenFile('goldens/notebook.png'));
    });
  }
}
