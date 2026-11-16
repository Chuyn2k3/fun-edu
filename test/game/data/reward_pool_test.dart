import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/data/badges.dart';
import 'package:funedu/game/data/reward_pool.dart';

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
    expect(GameBadge.values.map((b) => b.id).toSet(), hasLength(8));
    expect(GameBadge.speedKing.title, 'Vua Thần Tốc');
    expect(GameBadge.byId('pilot'), GameBadge.pilot);
    expect(GameBadge.byId('nope'), isNull);
  });
}
