import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../data/app_database.dart';
import '../stroke/geometry.dart';
import '../stroke/glyph.dart';
import 'notebook.dart';

/// Precomputed stroke counts for all 78 bundled glyphs so migrations and
/// background calculations never require async AssetBundle loading.
const Map<String, int> glyphStrokeCounts = {
  'so-9': 2, 'net-thang-dung': 1, 'dau-nga': 1, 'net-xien': 1, 'hoa-b': 2,
  'so-5': 3, 'chu-ee': 2, 'chu-s': 1, 'dau-huyen': 1, 'hoa-n': 1,
  'dau-hoi': 1, 'dau-sac': 1, 'hoa-dd': 3, 'hoa-o': 1, 'chu-r': 1,
  'so-4': 3, 'hoa-aw': 3, 'chu-g': 2, 'hoa-c': 1, 'hoa-v': 1,
  'so-8': 1, 'chu-k': 1, 'chu-aw': 3, 'so-3': 1, 'chu-u': 1,
  'hoa-h': 3, 'chu-l': 1, 'hoa-q': 2, 'chu-y': 1, 'hoa-d': 2,
  'hoa-e': 1, 'net-moc': 1, 'chu-x': 2, 'hoa-p': 2, 'chu-m': 1,
  'chu-dd': 3, 'hoa-i': 1, 'chu-t': 2, 'hoa-ee': 2, 'so-2': 2,
  'chu-a': 2, 'chu-oo': 2, 'net-ngang': 1, 'so-1': 2, 'chu-b': 1,
  'hoa-uw': 2, 'hoa-s': 1, 'chu-n': 1, 'chu-o': 1, 'chu-ow': 2,
  'hoa-r': 2, 'hoa-g': 2, 'chu-c': 1, 'so-0': 1, 'dau-nang': 1,
  'chu-aa': 3, 'chu-v': 1, 'hoa-k': 2, 'hoa-u': 1, 'chu-h': 1,
  'hoa-ow': 2, 'hoa-l': 1, 'hoa-aa': 3, 'chu-q': 2, 'so-7': 2,
  'hoa-y': 1, 'chu-d': 2, 'chu-e': 1, 'hoa-x': 2, 'so-6': 1,
  'net-cong': 1, 'chu-p': 1, 'hoa-oo': 2, 'hoa-m': 1, 'chu-i': 2,
  'hoa-t': 2, 'chu-uw': 2, 'hoa-a': 2,
};

/// Compares two notebook page versions: fewer mistakes wins; equal mistakes
/// breaks ties with newer completion timestamp.
bool isBetterPage(int newMistakes, DateTime newAt, int oldMistakes, DateTime oldAt) {
  if (newMistakes < oldMistakes) return true;
  if (newMistakes > oldMistakes) return false;
  return newAt.isAfter(oldAt);
}

double _round3(double v) => (v * 1000).round() / 1000.0;

/// Simplifies a list of strokes (each a list of points) to at most [maxPoints]
/// per stroke, preserving first and last point, evenly distributed along arc length.
/// Coordinates are rounded to 3 decimal places.
/// Returns a list of flattened coordinate arrays `[[x0, y0, x1, y1, ...], ...]`.
List<List<double>> simplifyStrokes(
  List<List<Point2>> strokes, {
  int maxPoints = 40,
}) {
  final out = <List<double>>[];
  for (final stroke in strokes) {
    if (stroke.isEmpty) {
      out.add(const []);
      continue;
    }
    if (stroke.length <= maxPoints) {
      final coords = <double>[];
      for (final p in stroke) {
        coords.add(_round3(p.x));
        coords.add(_round3(p.y));
      }
      out.add(coords);
      continue;
    }

    // Cumulative distances along arc length
    final dists = <double>[0.0];
    for (var i = 0; i < stroke.length - 1; i++) {
      final p1 = stroke[i];
      final p2 = stroke[i + 1];
      final d = math.sqrt((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y));
      dists.add(dists.last + d);
    }
    final totalLength = dists.last;

    final coords = <double>[];
    if (totalLength == 0) {
      for (var i = 0; i < maxPoints; i++) {
        coords.add(_round3(stroke.first.x));
        coords.add(_round3(stroke.first.y));
      }
      out.add(coords);
      continue;
    }

    var seg = 0;
    for (var j = 0; j < maxPoints; j++) {
      if (j == 0) {
        coords.add(_round3(stroke.first.x));
        coords.add(_round3(stroke.first.y));
        continue;
      }
      if (j == maxPoints - 1) {
        coords.add(_round3(stroke.last.x));
        coords.add(_round3(stroke.last.y));
        continue;
      }

      final target = j * (totalLength / (maxPoints - 1));
      while (seg + 1 < dists.length && dists[seg + 1] < target) {
        seg++;
      }
      final d0 = dists[seg];
      final d1 = dists[seg + 1];
      final span = d1 - d0;
      final t = span > 0 ? (target - d0) / span : 0.0;
      final p0 = stroke[seg];
      final p1 = stroke[seg + 1];
      final x = p0.x + t * (p1.x - p0.x);
      final y = p0.y + t * (p1.y - p0.y);
      coords.add(_round3(x));
      coords.add(_round3(y));
    }
    out.add(coords);
  }
  return out;
}

/// Decodes JSON array `[[x0, y0, ...], ...]` back to [Stroke] objects.
List<Stroke> decodeStrokes(String jsonStr) {
  try {
    final list = jsonDecode(jsonStr) as List;
    final strokes = <Stroke>[];
    for (final s in list) {
      final coords = (s as List).map((n) => (n as num).toDouble()).toList();
      final points = <Point2>[];
      for (var i = 0; i + 1 < coords.length; i += 2) {
        points.add(Point2(coords[i], coords[i + 1]));
      }
      strokes.add(Stroke(points));
    }
    return strokes;
  } catch (_) {
    return const [];
  }
}

/// Refreshes the notebook page for [glyphId] by inspecting all stroke attempts
/// for that kid, finding the best writing, simplifying, and updating `notebook_pages`
/// if better than what is currently stored.
Future<void> refreshNotebookPage(
  AppDatabase db,
  int kidId,
  String glyphId, {
  int? strokeCount,
}) async {
  final attempts = await db.attemptsFor(kidId, glyphId);
  if (attempts.isEmpty) return;

  final count = strokeCount ??
      glyphStrokeCounts[glyphId] ??
      (attempts.map((a) => a.strokeIndex).reduce((a, b) => a > b ? a : b) + 1);

  final notebookAttempts = attempts
      .map((r) => NotebookAttempt(
            strokeIndex: r.strokeIndex,
            ok: r.ok,
            points: decodePoints(r.points),
            at: r.createdAt,
          ))
      .toList();

  final best = bestWritings(notebookAttempts, strokeCount: count);
  if (best == null) return;

  final simplified = simplifyStrokes(
    best.strokes.map((s) => s.points).toList(),
    maxPoints: 40,
  );

  final existing = await (db.select(db.notebookPages)
        ..where((t) => t.kidId.equals(kidId) & t.glyphId.equals(glyphId)))
      .getSingleOrNull();

  if (existing == null ||
      isBetterPage(best.mistakes, best.writtenAt, existing.mistakes, existing.writtenAt)) {
    await db.into(db.notebookPages).insertOnConflictUpdate(
          NotebookPagesCompanion.insert(
            kidId: kidId,
            glyphId: glyphId,
            strokes: jsonEncode(simplified),
            mistakes: best.mistakes,
            writtenAt: best.writtenAt,
          ),
        );
  }
}
