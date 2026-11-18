import 'dart:math' as math;

import '../learning/writing_ladder.dart';
import '../progress/progress_repository.dart';
import '../stroke/glyph.dart';

/// How glyphs on a printable worksheet are chosen.
enum WorksheetSelectionMode {
  weak('Bé đang yếu'),
  section('Theo nhóm'),
  custom('Tự chọn');

  const WorksheetSelectionMode(this.label);

  final String label;
}

/// Guidance level across the 6 ô li cells in each worksheet row.
enum WorksheetStyle {
  guided('Có hướng dẫn', '1 mẫu đậm · 3 nét mờ · 2 ô tự viết'),
  traceHeavy('Tô theo nhiều', '1 mẫu đậm · 5 nét mờ để bé tô theo'),
  practice('Tự luyện', '1 mẫu đậm · 1 nét mờ · 4 ô tự viết');

  const WorksheetStyle(this.label, this.description);

  final String label;
  final String description;
}

/// Visual kind of a single square ô li cell in a row.
enum WorksheetCellKind { model, trace, blank }

/// Complete configuration needed to preview or build a printable A4 worksheet.
class WorksheetConfig {
  const WorksheetConfig({
    required this.kidName,
    required this.glyphIds,
    required this.style,
    required this.date,
  });

  final String kidName;
  final List<String> glyphIds;
  final WorksheetStyle style;
  final DateTime date;

  static const int rowsPerPage = 6;
  static const int cellsPerRow = 6;
  static const int maxSelectableGlyphs = 30;

  String get displayKidName {
    final trimmed = kidName.trim();
    return trimmed.isEmpty ? 'Bé' : trimmed;
  }

  String get formattedDate =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

/// Picks up to [maxCount] glyph ids for the "Bé đang yếu" mode:
/// 1. Glyphs with mistakes (`completions - cleanCompletions > 0`), descending
///    by mistake gap (ties broken by teaching order in [writingLadder]).
/// 2. Practicing glyphs (`completions > 0 && !mastered`) not yet included.
/// 3. Unlearned glyphs in teaching order (skipping already mastered ones), and
///    finally mastered glyphs only if the ladder runs out.
List<String> weakGlyphIds(
  Map<String, GlyphStat> stats, {
  int maxCount = WorksheetConfig.rowsPerPage,
}) {
  if (maxCount <= 0) return const [];
  final out = <String>[];
  final seen = <String>{};

  void add(String id) {
    if (out.length < maxCount && seen.add(id)) out.add(id);
  }

  // 1. Mistake-ranked glyphs.
  final withGaps = <(String id, int gap, int order)>[];
  for (var i = 0; i < writingLadder.length; i++) {
    final id = writingLadder[i];
    final s = stats[id];
    if (s == null) continue;
    final gap = s.completions - s.cleanCompletions;
    if (gap > 0) withGaps.add((id, gap, i));
  }
  withGaps.sort((a, b) {
    final byGap = b.$2.compareTo(a.$2);
    return byGap != 0 ? byGap : a.$3.compareTo(b.$3);
  });
  for (final item in withGaps) {
    add(item.$1);
  }

  // 2. Practicing (started but not mastered).
  for (final id in writingLadder) {
    final s = stats[id];
    if (s != null && s.completions > 0 && !s.mastered) {
      add(id);
    }
  }

  // 3. Unlearned glyphs in teaching order.
  for (final id in writingLadder) {
    final s = stats[id];
    if (s == null || s.completions <= 0) {
      add(id);
    }
  }

  // 4. Fallback if kid mastered every glyph in the ladder.
  for (final id in writingLadder) {
    add(id);
  }

  return out;
}

/// Returns glyph ids whose mistake gap (`completions - cleanCompletions`) > 0.
Set<String> mistakeGlyphIds(Map<String, GlyphStat> stats) => {
      for (final e in stats.entries)
        if (e.value.completions - e.value.cleanCompletions > 0) e.key,
    };

/// Splits [ids] into pages of at most [perPage] rows.
List<List<String>> paginateGlyphs(
  List<String> ids, {
  int perPage = WorksheetConfig.rowsPerPage,
}) {
  if (ids.isEmpty || perPage <= 0) return const [];
  final pages = <List<String>>[];
  for (var i = 0; i < ids.length; i += perPage) {
    final end = (i + perPage < ids.length) ? i + perPage : ids.length;
    pages.add(ids.sublist(i, end));
  }
  return pages;
}

/// The 6 cell kinds across one row for [style].
List<WorksheetCellKind> cellKindsFor(WorksheetStyle style) => switch (style) {
      WorksheetStyle.guided => const [
          WorksheetCellKind.model,
          WorksheetCellKind.trace,
          WorksheetCellKind.trace,
          WorksheetCellKind.trace,
          WorksheetCellKind.blank,
          WorksheetCellKind.blank,
        ],
      WorksheetStyle.traceHeavy => const [
          WorksheetCellKind.model,
          WorksheetCellKind.trace,
          WorksheetCellKind.trace,
          WorksheetCellKind.trace,
          WorksheetCellKind.trace,
          WorksheetCellKind.trace,
        ],
      WorksheetStyle.practice => const [
          WorksheetCellKind.model,
          WorksheetCellKind.trace,
          WorksheetCellKind.blank,
          WorksheetCellKind.blank,
          WorksheetCellKind.blank,
          WorksheetCellKind.blank,
        ],
    };

/// Safe ASCII filename for sharing/saving a worksheet PDF.
String worksheetFileName(String kidName, DateTime date) {
  final slug = _asciiSlug(kidName);
  final stamp = '${date.year}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';
  return 'phieu-tap-to-${slug.isEmpty ? 'be' : slug}-$stamp.pdf';
}

const _vnMap = <String, String>{
  'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
  'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
  'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
  'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
  'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
  'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
  'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
  'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
  'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
  'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
  'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
  'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
  'đ': 'd',
};

String _asciiSlug(String input) {
  final lower = input.trim().toLowerCase();
  final buf = StringBuffer();
  var lastDash = true;
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _vnMap[ch] ?? ch;
    final code = mapped.codeUnitAt(0);
    final isAlphaNum =
        (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
    if (isAlphaNum) {
      buf.write(mapped);
      lastDash = false;
    } else if (!lastDash) {
      buf.write('-');
      lastDash = true;
    }
  }
  final s = buf.toString();
  return s.endsWith('-') ? s.substring(0, s.length - 1) : s;
}

/// Computes non-overlapping top-left `(left, top)` badge coordinates inside a
/// square cell of [cellSize] for each stroke's starting point. When two strokes
/// start very close together (e.g. `a`, `d`, `g`), their badges nudge apart
/// horizontally so both numbers stay clearly legible.
List<(double left, double top)> badgePositionsForStrokes(
  List<Stroke> strokes, {
  required double cellSize,
  double badgeSize = 10.0,
}) {
  final out = <(double, double)>[];
  final maxPos = math.max(1.0, cellSize - badgeSize - 1.0);
  for (final s in strokes) {
    if (s.points.isEmpty) {
      out.add((1.0, 1.0));
      continue;
    }
    final p = s.points.first;
    var left = (p.x * cellSize - badgeSize * 0.9).clamp(1.0, maxPos);
    var top = (p.y * cellSize - badgeSize * 0.95).clamp(1.0, maxPos);

    for (var prev = 0; prev < out.length; prev++) {
      final (pl, pt) = out[prev];
      final dx = left - pl;
      final dy = top - pt;
      if (dx.abs() < badgeSize * 0.95 && dy.abs() < badgeSize * 0.95) {
        // Nudge previous badge slightly left and current badge slightly right.
        final midX = (pl + left) / 2;
        final newPrevL = (midX - badgeSize * 0.65).clamp(1.0, maxPos);
        out[prev] = (newPrevL, pt);
        left = (newPrevL + badgeSize * 1.05).clamp(1.0, maxPos);
      }
    }
    out.add((left, top));
  }
  return out;
}
