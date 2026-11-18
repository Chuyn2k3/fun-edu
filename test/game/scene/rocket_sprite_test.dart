import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/game/scene/rocket_sprite.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  group('RocketSprite', () {
    test('chip uses clean sculpted AppImages.rocketChip without double overlay',
        () {
      expect(RocketSprite.chip.asset, AppImages.rocketChip);
      expect(RocketSprite.forItem('rocket_blue'), RocketSprite.blue);
      expect(RocketSprite.forItem('rocket_green'), RocketSprite.green);
      expect(RocketSprite.forItem('rocket_purple'), RocketSprite.purple);
      expect(RocketSprite.forItem('unknown'), RocketSprite.orange);
    });
  });

  group('RaceScene asset resolution', () {
    testWidgets('RaceScene loads core rocket, planet, and comet assets only',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 390,
            height: 480,
            child: RaceScene(
              kidSteps: 0,
              chipSteps: 0,
              kidRocket: 'rocket_orange',
              kidTrail: 'trail_flame',
              boosting: false,
              won: false,
            ),
          ),
        ),
      );

      final state = tester.state<RaceSceneState>(find.byType(RaceScene));
      expect(state.loadedAssets, contains(AppImages.rocketChip));
      expect(state.loadedAssets, contains(AppImages.rocketOrange));
      expect(state.loadedAssets, contains(AppImages.planet));
      expect(state.loadedAssets, contains(AppImages.comet));
      expect(state.loadedAssets, isNot(contains(AppImages.stickerPilotGoggles)));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
