import '../progress/progress_repository.dart';
import 'lesson_item.dart';

/// Picks today's glyphs: up to `size - 1` new ones, one review, then fillers.
///
/// Only ids in both [ladder] and [available] are considered, in ladder order.
List<String> composeTodayLesson({
  required List<String> ladder,
  required Map<String, GlyphStat> stats,
  required Set<String> available,
  int size = 3,
}) {
  final candidates = [
    for (final id in ladder)
      if (available.contains(id)) id,
  ];
  bool mastered(String id) => stats[id]?.mastered ?? false;
  final unmastered = [
    for (final id in candidates)
      if (!mastered(id)) id
  ];
  final masteredIds = [
    for (final id in candidates)
      if (mastered(id)) id
  ];

  final picked = <String>[...unmastered.take(size - 1)];

  // Review: the mastered glyph with the most failed attempts (earliest wins ties).
  String? review;
  var worst = -1;
  for (final id in masteredIds) {
    final s = stats[id]!;
    final misses = s.completions - s.cleanCompletions;
    if (misses > worst) {
      worst = misses;
      review = id;
    }
  }
  if (review != null && picked.length < size) picked.add(review);

  // Fill: remaining unmastered, then remaining mastered, in ladder order.
  for (final id in [...unmastered, ...masteredIds]) {
    if (picked.length >= size) break;
    if (!picked.contains(id)) picked.add(id);
  }
  return picked;
}

/// Today's lesson as [LessonItem]s: one new glyph, a math session, then one
/// review glyph (the next new glyph when nothing is mastered yet). Glyphs before [writingStartIndex] in [ladder] count as already
/// learned (unless real stats exist). Missing glyphs drop their writing item;
/// the math item is always present.
List<LessonItem> composeTodayLessonItems({
  required List<String> ladder,
  required Map<String, GlyphStat> stats,
  required Set<String> available,
  required int writingStartIndex,
  required int mathLevelIndex,
}) {
  final effective = Map<String, GlyphStat>.of(stats);
  for (final id in ladder.take(writingStartIndex)) {
    effective.putIfAbsent(
      id,
      () => const GlyphStat(completions: 1, cleanCompletions: 1),
    );
  }
  final glyphs = composeTodayLesson(
    ladder: ladder,
    stats: effective,
    available: available,
    size: 2,
  );
  return [
    if (glyphs.isNotEmpty) WritingItem(glyphs[0]),
    MathItem(mathLevelIndex),
    if (glyphs.length > 1) WritingItem(glyphs[1]),
  ];
}
