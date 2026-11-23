import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/today_lesson_provider.dart';
import '../progress/level_repository.dart';
import '../progress/progress_repository.dart';
import '../rewards/reward_repository.dart';
import 'kid_repository.dart';

/// Re-reads everything that depends on the kid list or the current kid.
/// Call after `addKid`, `setCurrentKid` or any other profile change.
void refreshAfterKidChange(WidgetRef ref) => invalidateKidData(ref.invalidate);

/// Same as [refreshAfterKidChange], for any `invalidate` (WidgetRef or Ref).
void invalidateKidData(void Function(ProviderOrFamily) invalidate) {
  invalidate(currentKidIdProvider);
  invalidate(kidsProvider);
  invalidate(progressRepositoryProvider);
  invalidate(levelRepositoryProvider);
  invalidate(homeSummaryProvider);
  invalidate(todayLessonProvider);
  invalidate(mathLevelIndexProvider);
  invalidate(isPlacedProvider);
  invalidate(pendingRewardProvider);
  invalidate(kidTeaseStickersProvider);
  invalidate(teaseStickersProvider);
  invalidate(kidShowcaseOnProvider);
  invalidate(showcaseOnProvider);
  invalidate(kidShowcaseLearningProvider);
  invalidate(showcaseLearningProvider);
}
