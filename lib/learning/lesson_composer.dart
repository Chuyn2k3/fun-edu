import '../progress/progress_repository.dart';

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
