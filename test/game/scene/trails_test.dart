import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/rocket_sprite.dart';
import 'package:funedu/game/scene/trails.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  test('trail ids map to styles, unknown ids fall back to the flame', () {
    expect(TrailStyle.fromId('trail_flame'), TrailStyle.flame);
    expect(TrailStyle.fromId('trail_rainbow'), TrailStyle.rainbow);
    expect(TrailStyle.fromId('trail_sparkle'), TrailStyle.sparkle);
    expect(TrailStyle.fromId('trail_blue_flame'), TrailStyle.blueFlame);
    expect(TrailStyle.fromId('nope'), TrailStyle.flame);
    expect(TrailStyle.blueFlame.palette, isNot(TrailStyle.flame.palette));
  });

  test('rocket ids map to their images; Chip has the white rocket', () {
    expect(RocketSprite.forItem('rocket_orange').asset, AppImages.rocketOrange);
    expect(RocketSprite.forItem('rocket_blue').asset, AppImages.rocketBlue);
    expect(RocketSprite.forItem('rocket_green').asset, AppImages.rocketGreen);
    expect(RocketSprite.forItem('rocket_purple').asset, AppImages.rocketPurple);
    expect(RocketSprite.forItem('???').asset, AppImages.rocketOrange);
    expect(RocketSprite.chip.asset, AppImages.rocketChip);
  });
}
