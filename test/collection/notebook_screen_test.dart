import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/collection/notebook.dart';
import 'package:funedu/collection/notebook_pdf.dart';
import 'package:funedu/features/collection/collection_screen.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/stroke/geometry.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/worksheet/worksheet_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../features/game/game_test_helpers.dart';

/// The collection page's own scroll view.
Finder _scroll() => find
    .descendant(of: find.byType(CollectionScreen), matching: find.byType(Scrollable))
    .first;

Stroke _line(double x) => Stroke([Point2(x, 0.2), Point2(x, 0.8)]);

Future<void> _openNotebook(WidgetTester t) async {
  appRouter.go('/collection');
  await pumpReal(t, times: 6);
  final tab = find.byKey(const ValueKey('collection-tab-notebook'));
  // Bring the tab to the upper part of the page: at the bottom the
  // floating nav bar would take the tap.
  await t.runAsync(() => Scrollable.ensureVisible(t.element(tab), alignment: 0.2));
  await t.pump();
  await t.tap(tab);
  // Loading the notebook reads the database and the glyph files.
  for (var i = 0; i < 30; i++) {
    await pumpReal(t, times: 1);
    if (find.byKey(const ValueKey('notebook-print')).evaluate().isNotEmpty ||
        find.byKey(const ValueKey('notebook-empty')).evaluate().isNotEmpty) {
      break;
    }
  }
  expect(find.byType(CollectionScreen), findsOneWidget);
}

void main() {
  // rootBundle caches loadString futures across tests; a cached future from
  // an earlier test's fake-async zone never completes in the next one.
  setUp(() => rootBundle.clear());

  for (final size in const [Size(320, 568), Size(390, 844), Size(1366, 1024)]) {
    testWidgets('a finished writing shows as a notebook page at $size', (t) async {
      await bootGame(t, size: size, seed: (db, kid) async {
        // chu-i: stroke 0 wrong once, then right; stroke 1 (the dot) right.
        await db.logAttempt(kidId: kid, glyphId: 'chu-i', strokeIndex: 0, ok: false,
            error: 'offPath', deviation: 0.3, drawn: _line(0.2));
        await db.logAttempt(kidId: kid, glyphId: 'chu-i', strokeIndex: 0, ok: true,
            error: null, deviation: 0.05, drawn: _line(0.5));
        await db.logAttempt(kidId: kid, glyphId: 'chu-i', strokeIndex: 1, ok: true,
            error: null, deviation: 0.02, drawn: const Stroke([Point2(0.5, 0.1)]));
        await ProgressRepository(db, kidId: kid).recordGlyphCompleted('chu-i', failedStrokes: 1);
        // so-1 started but not finished: no page.
        await db.logAttempt(kidId: kid, glyphId: 'so-1', strokeIndex: 0, ok: true,
            error: null, deviation: 0.05, drawn: _line(0.4));
      });
      await _openNotebook(t);
      expect(t.takeException(), isNull);
      // The grid is lazy: scroll down to it.
      await t.scrollUntilVisible(find.byKey(const ValueKey('notebook-chu-i')), 200,
          scrollable: _scroll());
      expect(find.byKey(const ValueKey('notebook-chu-i')), findsOneWidget);
      expect(find.byKey(const ValueKey('notebook-so-1')), findsNothing);
      expect(find.text('1 trang vở'), findsOneWidget);
    });
  }

  testWidgets('an empty notebook explains itself', (t) async {
    await bootGame(t);
    await _openNotebook(t);
    expect(find.byKey(const ValueKey('notebook-empty')), findsOneWidget);
  });

  testWidgets('printing asks for the parent gate first', (t) async {
    await bootGame(t, seed: (db, kid) async {
      for (final i in [0, 1]) {
        await db.logAttempt(kidId: kid, glyphId: 'chu-i', strokeIndex: i, ok: true,
            error: null, deviation: 0.05, drawn: _line(0.5));
      }
      await ProgressRepository(db, kidId: kid).recordGlyphCompleted('chu-i', failedStrokes: 0);
    });
    await _openNotebook(t);
    await t.scrollUntilVisible(find.byKey(const ValueKey('notebook-print')), 200,
        scrollable: _scroll());
    await t.tap(find.byKey(const ValueKey('notebook-print')));
    await pumpReal(t);
    expect(find.text('Bố mẹ ơi'), findsNothing); // no share before the gate
    expect(find.byType(Navigator), findsWidgets);
    expect(find.textContaining('×').evaluate().isNotEmpty || find.textContaining('nhân').evaluate().isNotEmpty,
        isTrue, reason: 'the parent gate (a multiplication) is shown');
  });

  test('the notebook PDF is a real PDF with one sheet per 12 pages', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Bold.ttf'));
    final pages = [
      for (var i = 0; i < 13; i++)
        NotebookPage(strokes: [_line(0.5)], mistakes: 0, writtenAt: DateTime(2026, 11, 22)),
    ];
    final bytes = await buildNotebookPdf(
        pages: pages, kidName: 'Na', fonts: WorksheetPdfFonts(regular: regular, bold: bold));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(bytes)).length, 2);
  });
}
