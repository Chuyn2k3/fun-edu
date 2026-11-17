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

/// Vietnamese names of every garage item (pool and starters).
const itemTitles = {
  'rocket_orange': 'Tên lửa cam',
  'rocket_blue': 'Tên lửa xanh dương',
  'rocket_green': 'Tên lửa xanh lá',
  'rocket_purple': 'Tên lửa tím',
  'trail_flame': 'Lửa thường',
  'trail_rainbow': 'Khói cầu vồng',
  'trail_sparkle': 'Sao lấp lánh',
  'trail_blue_flame': 'Lửa xanh',
  'sticker_clap': 'Sticker Chíp vỗ tay',
  'sticker_laugh': 'Sticker Chíp cười',
};

String itemTitle(String id) => itemTitles[id] ?? id;

/// Cosmic stars still needed before [itemId] can be offered: 0 while it is
/// on offer now, null when it is owned or not a pool item.
///
/// Rewards are never bought: milestone n (0-based) brings offer n, the first
/// two unowned pool items. To keep the number simple and deterministic we
/// assume every future pick follows pool order (the kid takes the first item
/// of each offer). Then, with `picked` items taken so far, the unowned item at
/// position i (pool order) first shows up in offer `picked + max(0, i - 1)`:
/// positions 0 and 1 share the next offer, every later one comes one
/// milestone after its predecessor.
int? starsUntilOffered(
  String itemId, {
  required Set<String> owned,
  required int stars,
}) {
  final unowned = rewardPool.where((i) => !owned.contains(i)).toList();
  final i = unowned.indexOf(itemId);
  if (i < 0) return null;
  final picked = owned.difference(starterItems).length;
  final offer = picked + (i > 0 ? i - 1 : 0);
  var all = milestones(upTo: 200);
  while (all.length <= offer) {
    all = milestones(upTo: all.last + 50 * (offer - all.length + 1));
  }
  final m = all[offer];
  return m > stars ? m - stars : 0;
}
