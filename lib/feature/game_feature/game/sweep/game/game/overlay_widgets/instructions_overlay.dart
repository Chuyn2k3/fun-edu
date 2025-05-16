
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/my_game.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/main_menu.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/overlay_frame.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/enums.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/styles.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/action_button.dart';

class InstructionsOverlay extends StatelessWidget {
  static const id = 'InstructionsOverlay';
  final MyGame game;
  const InstructionsOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return OverlayFrame(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: titleTextStyle,
              child: Text('Hướng dẫn'),
            ),
            const SizedBox(height: 40),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: titleTextStyle.copyWith(fontSize: 24),
              child: Text('Điều khiển'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset(
                    'assets/images/player.png',
                    height: 80,
                  ),
                  SvgPicture.asset(
                    'assets/images/path.svg',
                    width: 120,
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: SvgPicture.asset(
                      'assets/images/hand.svg',
                      height: 40,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: titleTextStyle.copyWith(fontSize: 24),
              child: Text('Nguy hiểm'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: Enemy.values
                  .map((e) => Image.asset(
                        'assets/images/${e.imagePath}',
                        height: 65,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 30),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: titleTextStyle.copyWith(fontSize: 24),
              child: Text('Vật phẩm thu thập'),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                'assets/images/pearl.png',
                width: 70,
              ),
            ),
            Center(
              child: ActionButton(
                title: 'Quay lại',
                onPressed: () {
                  game.overlays.remove(InstructionsOverlay.id);
                  game.overlays.add(MainMenu.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
