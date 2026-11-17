import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/game/scene/rocket_sprite.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  group('RocketSprite', () {
    test('chip defines asset AppImages.rocketChip and pilotAsset AppImages.stickerPilotGoggles', () {
      expect(RocketSprite.chip.asset, AppImages.rocketChip);
      expect(RocketSprite.chip.pilotAsset, AppImages.stickerPilotGoggles);
    });

    test('garage rockets do not have a pilotAsset', () {
      expect(RocketSprite.orange.pilotAsset, isNull);
      expect(RocketSprite.blue.pilotAsset, isNull);
      expect(RocketSprite.green.pilotAsset, isNull);
      expect(RocketSprite.purple.pilotAsset, isNull);
      expect(RocketSprite.forItem('rocket_blue').pilotAsset, isNull);
      expect(RocketSprite.forItem('rocket_green').pilotAsset, isNull);
      expect(RocketSprite.forItem('rocket_purple').pilotAsset, isNull);
      expect(RocketSprite.forItem('unknown').pilotAsset, isNull);
    });
  });

  group('RaceScene pilot asset resolution', () {
    testWidgets('RaceScene includes AppImages.stickerPilotGoggles in loaded assets', (tester) async {
      await tester.pumpWidget(
        Directionality(
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
      expect(state.loadedAssets, contains(AppImages.stickerPilotGoggles));
      expect(state.loadedAssets, contains(AppImages.rocketChip));
      expect(state.loadedAssets, contains(AppImages.rocketOrange));
    });
  });
}
