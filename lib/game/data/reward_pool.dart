/// Items offered at milestones, in offer order.
const rewardPool = [
  'rocket_blue',
  'trail_rainbow',
  'sticker_clap',
  'rocket_green',
  'trail_sparkle',
  'sticker_laugh',
  'rocket_purple',
  'trail_blue_flame',
];

/// Owned from the start.
const starterItems = {'rocket_orange', 'trail_flame'};

const _fixedMilestones = [10, 25, 40, 60, 85, 115, 150, 190];

/// Cosmic-star milestones up to [upTo]: 10, 25, 40, 60, 85, 115, 150, 190,
/// then every 50 more.
List<int> milestones({int upTo = 2000}) {
  final out = [..._fixedMilestones];
  while (out.last + 50 <= upTo) {
    out.add(out.last + 50);
  }
  return out.where((m) => m <= upTo).toList();
}

/// Milestones m with [before] < m <= [after], ascending.
List<int> milestonesBetween(int before, int after) =>
    [for (final m in milestones(upTo: after)) if (m > before) m];

/// The first two pool items not yet owned (fewer when the pool runs out).
List<String> nextOffer(Set<String> owned) =>
    rewardPool.where((i) => !owned.contains(i)).take(2).toList();
