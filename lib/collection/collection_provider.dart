import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/kid_repository.dart';
import '../progress/progress_repository.dart';
import 'collection_model.dart';

/// Clock used by the Collection screen (overridable in tests).
final collectionClockProvider = Provider<Clock>((_) => DateTime.now);

/// Currently viewed calendar month (always normalized to day 1).
final collectionMonthProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = ref.watch(collectionClockProvider)();
  return DateTime(now.year, now.month, 1);
});

/// Aggregated learning-only snapshot for the current kid and viewed month.
final collectionSnapshotProvider =
    FutureProvider.autoDispose<LearningSnapshot>((ref) async {
  final summary = await ref.watch(homeSummaryProvider.future);
  final repo = await ref.watch(progressRepositoryProvider.future);
  final kids = await ref.watch(kidsProvider.future);
  final kidId = await ref.watch(currentKidIdProvider.future);
  final viewed = ref.watch(collectionMonthProvider);

  final kid = kids.where((k) => k.id == kidId).firstOrNull;
  final totalLessons = await repo.totalLessons();
  final totalLearnedDays = await repo.totalLearnedDays();
  final learnedDaysInMonth =
      await repo.learnedDaysInMonth(viewed.year, viewed.month);

  return LearningSnapshot(
    kidName: kid?.nickname ?? 'Bé',
    totalStars: summary.totalStars,
    totalLessons: totalLessons,
    totalLearnedDays: totalLearnedDays,
    learnedDaysThisWeek: summary.learnedDaysThisWeek,
    masteredWriting: summary.masteredWriting,
    mathLevelIndex: summary.mathLevelIndex,
    vietnameseLevelIndex: summary.vietnameseLevelIndex,
    englishLevelIndex: summary.englishLevelIndex,
    viewedYear: viewed.year,
    viewedMonth: viewed.month,
    learnedDaysInMonth: learnedDaysInMonth,
    learnedToday: summary.lessonsToday > 0,
  );
});
