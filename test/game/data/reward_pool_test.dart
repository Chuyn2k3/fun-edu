import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/data/badges.dart';
import 'package:funedu/game/data/reward_pool.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  test('milestones follow the spec then every 50', () {
    expect(milestones(upTo: 190), [10, 25, 40, 60, 85, 115, 150, 190]);
    expect(milestones(upTo: 300), [10, 25, 40, 60, 85, 115, 150, 190, 240, 290]);
  });

  test('milestonesBetween is exclusive before, inclusive after', () {
    expect(milestonesBetween(22, 41), [25, 40]);
    expect(milestonesBetween(10, 24), isEmpty);
    expect(milestonesBetween(0, 10), [10]);
  });

  test('nextOffer is the first two unowned pool items', () {
    expect(nextOffer(starterItems), ['rocket_blue', 'trail_rainbow']);
    expect(nextOffer({...starterItems, 'trail_rainbow'}),
        ['rocket_blue', 'sticker_clap']);
    expect(nextOffer({...starterItems, ...rewardPool}), isEmpty);
    expect(nextOffer({...starterItems, ...rewardPool}..remove('rocket_purple')),
        ['rocket_purple']);
  });

  test('badges have unique ids and Vietnamese titles', () {
    expect(GameBadge.values.map((b) => b.id).toSet(), hasLength(12));
    expect(GameBadge.values.where((b) => b.online), hasLength(4));
    // Every badge gives its own sticker, and every sticker has art.
    expect(GameBadge.values.map((b) => b.stickerId).toSet(), hasLength(12));
    for (final b in GameBadge.values) {
      expect(AppImages.stickers[b.stickerId], isNotNull, reason: b.id);
    }
    for (final r in rareStickers) {
      expect(AppImages.stickers[r], isNotNull, reason: r);
      expect(rareStickerTitles[r], isNotNull, reason: r);
    }
    expect(GameBadge.speedKing.title, 'Vua Thần Tốc');
    expect(GameBadge.byId('pilot'), GameBadge.pilot);
    expect(GameBadge.byId('nope'), isNull);
  });
  group('starsUntilOffered (rewards are offers, picks assumed in pool order)',
      () {
    test('from the start: first offer at 10, then one milestone per item', () {
      int? left(String id, {int stars = 0, Set<String> owned = starterItems}) =>
          starsUntilOffered(id, owned: owned, stars: stars);
      expect(left('rocket_blue'), 10);
      expect(left('trail_rainbow'), 10);
      expect(left('sticker_clap'), 25);
      expect(left('rocket_green'), 40);
      expect(left('trail_sparkle'), 60);
      expect(left('sticker_laugh'), 85);
      expect(left('rocket_purple'), 115);
      expect(left('trail_blue_flame'), 150);
      expect(left('rocket_blue', stars: 3), 7);
    });

    test('counts from the picks already made', () {
      final owned = {...starterItems, 'rocket_blue'};
      expect(starsUntilOffered('trail_rainbow', owned: owned, stars: 12), 13);
      expect(starsUntilOffered('sticker_clap', owned: owned, stars: 12), 13);
      expect(starsUntilOffered('rocket_green', owned: owned, stars: 12), 28);
      expect(starsUntilOffered('rocket_purple', owned: owned, stars: 12), 103);
    });

    test('0 while on offer now; null when owned or not a pool item', () {
      expect(starsUntilOffered('trail_rainbow', owned: starterItems, stars: 11),
          0);
      expect(starsUntilOffered('rocket_orange', owned: starterItems, stars: 0),
          isNull);
      expect(
          starsUntilOffered('rocket_blue',
              owned: {...starterItems, 'rocket_blue'}, stars: 0),
          isNull);
      expect(starsUntilOffered('nope', owned: starterItems, stars: 0), isNull);
    });
  });
}
