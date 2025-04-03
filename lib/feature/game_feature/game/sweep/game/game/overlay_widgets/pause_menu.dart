import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/my_game.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/overlay_frame.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/styles.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/action_button.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/logout_button.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/sound_toggle.dart';

class PauseMenu extends ConsumerWidget {
  static const id = 'PauseMenu';
  final MyGame game;

  const PauseMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OverlayFrame(
        child: SizedBox(
      width: 300,
      height: 300,
      child: Center(
        child: Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: titleTextStyle,
              child: Text('Tạm dừng'),
            ),
            const SizedBox(
              height: 60,
            ),
            // SizedBox(
            //     height: 80,
            //     width: 80,
            //     child: Expanded(child: SoundToggle(game))),
            //Expanded(child: SoundToggle(game)),
            const SizedBox(
              height: 60,
            ),
            ActionButton(
              title: 'Tiếp tục',
              onPressed: () {
                game.resumeEngine();
              },
            ),
            const SizedBox(height: 20),
            const LogoutButton()
          ],
        ),
      ),
    ));
  }
}
