import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../profile/kid_repository.dart';
import '../progress/progress_repository.dart';

const int minRewardStars = 10;
const int maxRewardStars = 200;
const int maxRewardTitleLength = 60;

/// Real-life rewards of every kid (see [RealRewards]).
class RewardRepository {
  RewardRepository(this._db, {Clock now = DateTime.now}) : _now = now;

  final AppDatabase _db;
  final Clock _now;

  /// Adds a reward; throws [ArgumentError] for a bad title or star count.
  Future<int> add(int kidId, String title, int starsNeeded) {
    final t = title.trim();
    if (t.isEmpty || t.length > maxRewardTitleLength) {
      throw ArgumentError.value(title, 'title', 'Must be 1..60 characters');
    }
    if (starsNeeded < minRewardStars || starsNeeded > maxRewardStars) {
      throw ArgumentError.value(starsNeeded, 'starsNeeded', 'Must be 10..200');
    }
    return _db.into(_db.realRewards).insert(
          RealRewardsCompanion.insert(
            kidId: kidId,
            title: t,
            starsNeeded: starsNeeded,
            createdAt: _now(),
          ),
        );
  }

  /// All rewards of the kid, oldest first.
  Future<List<RealReward>> list(int kidId) => (_db.select(_db.realRewards)
        ..where((t) => t.kidId.equals(kidId))
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .get();

  /// The oldest reward not yet given, or null.
  Future<RealReward?> pending(int kidId) => (_db.select(_db.realRewards)
        ..where((t) => t.kidId.equals(kidId) & t.redeemedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
        ..limit(1))
      .getSingleOrNull();

  /// Marks the reward as given. Does not touch the kid's stars.
  Future<void> redeem(int id) =>
      (_db.update(_db.realRewards)..where((t) => t.id.equals(id)))
          .write(RealRewardsCompanion(redeemedAt: Value(_now())));

  Future<int> totalStars(int kidId) =>
      ProgressRepository(_db, kidId: kidId).totalStars();
}

final rewardRepositoryProvider = Provider<RewardRepository>(
  (ref) => RewardRepository(ref.watch(databaseProvider)),
);

/// Stars and rewards of one kid, for the parent's rewards tab.
class RewardsData {
  const RewardsData({required this.stars, required this.rewards});

  final int stars;
  final List<RealReward> rewards;
}

final rewardsDataProvider =
    FutureProvider.autoDispose.family<RewardsData, int>((ref, kidId) async {
  final repo = ref.watch(rewardRepositoryProvider);
  return RewardsData(
    stars: await repo.totalStars(kidId),
    rewards: await repo.list(kidId),
  );
});

/// The current kid's next reward with their stars, or null.
class PendingReward {
  const PendingReward({
    required this.title,
    required this.starsNeeded,
    required this.stars,
  });

  final String title;
  final int starsNeeded;
  final int stars;
}

final pendingRewardProvider = FutureProvider<PendingReward?>((ref) async {
  final kid = await ref.watch(currentKidIdProvider.future);
  if (kid == null) return null;
  final reward = await ref.watch(rewardRepositoryProvider).pending(kid);
  if (reward == null) return null;
  // Following the home summary keeps the star count fresh after a lesson.
  final summary = await ref.watch(homeSummaryProvider.future);
  return PendingReward(
    title: reward.title,
    starsNeeded: reward.starsNeeded,
    stars: summary.totalStars,
  );
});
