import 'dart:math';

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

/// Rare stickers: a lucky drop after a race with friends, gold-framed in
/// the album. Never bought, never required for anything.
const rareStickers = [
  'rare_chip_sleep',
  'rare_chip_write',
  'rare_rocket_chip',
  'rare_crown',
  'rare_comet',
  'rare_planet',
];

const rareStickerTitles = {
  'rare_chip_sleep': 'Chíp ngủ say',
  'rare_chip_write': 'Chíp tập viết',
  'rare_rocket_chip': 'Chíp lái tên lửa',
  'rare_crown': 'Vương miện vàng',
  'rare_comet': 'Sao chổi rực rỡ',
  'rare_planet': 'Hành tinh vành đai',
};

/// After this many races with friends without a rare sticker, the next one
/// always brings one (no long unlucky streaks).
const rareStickerPity = 6;

/// The rare sticker this online race drops, or null. Winners are luckier
/// (1 in 3, otherwise 1 in 5); never a sticker the kid already has.
String? rareStickerDrop({
  required Set<String> owned,
  required int racesWithoutRare,
  required int? rank,
  required Random rng,
}) {
  final left = rareStickers.where((s) => !owned.contains(s)).toList();
  if (left.isEmpty) return null;
  final lucky = racesWithoutRare + 1 >= rareStickerPity ||
      rng.nextInt(rank == 1 ? 3 : 5) == 0;
  return lucky ? left[rng.nextInt(left.length)] : null;
}
