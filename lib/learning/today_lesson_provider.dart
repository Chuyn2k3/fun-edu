import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/progress_repository.dart';
import '../stroke/glyph_repository.dart';
import 'lesson_composer.dart';
import 'writing_ladder.dart';

/// Today's lesson glyph ids, based on bundled glyphs and the child's progress.
final todayLessonProvider = FutureProvider<List<String>>((ref) async {
  final available = await ref.watch(glyphRepositoryProvider).listIds();
  final stats = await ref.watch(progressRepositoryProvider).glyphStats();
  return composeTodayLesson(
    ladder: writingLadder,
    stats: stats,
    available: available.toSet(),
  );
});
