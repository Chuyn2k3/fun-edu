import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/today_lesson_provider.dart';
import '../progress/level_repository.dart';
import '../progress/progress_repository.dart';
import '../rewards/reward_repository.dart';
import 'kid_repository.dart';

/// Re-reads everything that depends on the kid list or the current kid.
/// Call after `addKid`, `setCurrentKid` or any other profile change.
void refreshAfterKidChange(WidgetRef ref) {
  ref.invalidate(currentKidIdProvider);
  ref.invalidate(kidsProvider);
  ref.invalidate(progressRepositoryProvider);
  ref.invalidate(levelRepositoryProvider);
  ref.invalidate(homeSummaryProvider);
  ref.invalidate(todayLessonProvider);
  ref.invalidate(mathLevelIndexProvider);
  ref.invalidate(isPlacedProvider);
  ref.invalidate(pendingRewardProvider);
}
