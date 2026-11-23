import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../learning/writing_ladder.dart';
import '../profile/kid_repository.dart';
import '../stroke/geometry.dart';
import '../stroke/glyph.dart';
import '../stroke/glyph_repository.dart';
import 'notebook_pages.dart';

/// "Vở của bé": the kid's own best writing of every glyph, rebuilt from the
/// logged strokes (stroke_attempts keeps each stroke's points in the
/// writing pad's coordinates). Nothing new is stored and nothing leaves the
/// device.

/// One logged stroke.
class NotebookAttempt {
  const NotebookAttempt({
    required this.strokeIndex,
    required this.ok,
    required this.points,
    required this.at,
  });

  final int strokeIndex;
  final bool ok;

  /// Null for strokes logged before points were kept.
  final List<Point2>? points;
  final DateTime at;
}

/// A finished writing of one glyph: the accepted strokes, how many strokes
/// were wrong on the way, and when it was finished.
class NotebookPage {
  const NotebookPage({
    required this.strokes,
    required this.mistakes,
    required this.writtenAt,
    this.glyph,
  });

  final List<Stroke> strokes;
  final int mistakes;
  final DateTime writtenAt;

  /// The model glyph (label, ruling for the paper); set by the provider.
  final Glyph? glyph;

  NotebookPage withGlyph(Glyph g) => NotebookPage(
      strokes: strokes, mistakes: mistakes, writtenAt: writtenAt, glyph: g);
}

/// Points as stored by `encodePoints` (`[[x, y], ...]`); null when missing
/// or unreadable.
List<Point2>? decodePoints(String? json) {
  if (json == null) return null;
  try {
    final list = jsonDecode(json) as List;
    return [
      for (final p in list)
        Point2((p as List)[0].toDouble() as double, p[1].toDouble() as double),
    ];
  } catch (_) {
    return null;
  }
}

/// The best finished writing among [attempts] (in logging order) of a glyph
/// with [strokeCount] strokes: fewest wrong strokes, then the latest. A run
/// starts at stroke 0 and is finished when the last stroke is accepted;
/// wrong tries of a stroke are mistakes. Null when no run was finished.
NotebookPage? bestWritings(List<NotebookAttempt> attempts,
    {required int strokeCount}) {
  NotebookPage? best;
  var kept = <Stroke>[];
  var mistakes = 0;
  var expected = 0;
  var usable = true;

  void reset() {
    kept = <Stroke>[];
    mistakes = 0;
    expected = 0;
    usable = true;
  }

  for (final a in attempts) {
    if (a.strokeIndex != expected) {
      // A new writing started (back to stroke 0) or the log skipped: drop
      // the unfinished run.
      reset();
      if (a.strokeIndex != 0) continue;
    }
    if (!a.ok) {
      mistakes++;
      continue;
    }
    final pts = a.points;
    if (pts == null || pts.isEmpty) usable = false;
    kept.add(Stroke(pts ?? const []));
    expected++;
    if (expected == strokeCount) {
      if (usable) {
        final page =
            NotebookPage(strokes: kept, mistakes: mistakes, writtenAt: a.at);
        if (best == null || page.mistakes <= best.mistakes) best = page;
      }
      reset();
    }
  }
  return best;
}

/// The current kid's notebook: one page per glyph they finished, in ladder
/// order.
final notebookProvider =
    FutureProvider.autoDispose<List<NotebookPage>>((ref) async {
  final kidId = await ref.watch(currentKidIdProvider.future);
  if (kidId == null) return const [];
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.notebookPages)
        ..where((t) => t.kidId.equals(kidId)))
      .get();
  final byGlyph = {for (final r in rows) r.glyphId: r};
  final pages = <NotebookPage>[];
  for (final id in writingLadder) {
    final row = byGlyph[id];
    if (row == null) continue;
    final Glyph glyph;
    try {
      glyph = await ref.watch(glyphProvider(id).future);
    } catch (_) {
      continue;
    }
    final strokes = decodeStrokes(row.strokes);
    pages.add(NotebookPage(
      strokes: strokes,
      mistakes: row.mistakes,
      writtenAt: row.writtenAt,
      glyph: glyph,
    ));
  }
  return pages;
});
