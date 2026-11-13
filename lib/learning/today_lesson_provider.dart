import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/level_repository.dart';
import '../progress/progress_repository.dart';
import '../stroke/glyph_repository.dart';
import 'lesson_composer.dart';
import 'lesson_item.dart';
import 'writing_ladder.dart';

/// Today's lesson items (writing and math), based on bundled glyphs and the
/// child's progress and placed levels.
final todayLessonProvider = FutureProvider<List<LessonItem>>((ref) async {
  final available = await ref.watch(glyphRepositoryProvider).listIds();
  final stats =
      await (await ref.watch(progressRepositoryProvider.future)).glyphStats();
  final levels = await ref.watch(levelRepositoryProvider.future);
  final writingStart = await levels.levelOf('viet') ?? 0;
  final mathLevel = await levels.levelOf('toan') ?? 0;
  return composeTodayLessonItems(
    ladder: writingLadder,
    stats: stats,
    available: available.toSet(),
    writingStartIndex: writingStart,
    mathLevelIndex: mathLevel,
  );
});
