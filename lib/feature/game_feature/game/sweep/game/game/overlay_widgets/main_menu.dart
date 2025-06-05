import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/data/providers/score_provider.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/my_game.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/instructions_overlay.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/action_button.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/logout_button.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/sound_toggle.dart';

import '../../helper/colors.dart';

class MainMenu extends ConsumerWidget {
  static const id = 'MainMenu';
  final MyGame game;

  const MainMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoreNotifierProvider);
    return Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image.asset(
                //   "assets/images/logo.png",
                //   width: 230,
                // ),
                const SizedBox(height: 40),
                state.isLoading
                    ? const CircularProgressIndicator(
                        color: AppColors.primary,
                      )
                    : Text(
                        state.nickname,
                        style: const TextStyle(
                          fontSize: 30,
                          color: AppColors.white,
                          fontFamily: 'LilitaOne',
                        ),
                      ),
                const SizedBox(height: 40),
                ActionButton(
                  title: 'Chơi',
                  onPressed: () => {
                    game.overlays.remove(MainMenu.id),
                    game.startGame(),
                  },
                ),
                const SizedBox(height: 10),
                ActionButton(
                  title: 'Hướng dẫn',
                  customColor: AppColors.green,
                  onPressed: () {
                    game.overlays.remove(MainMenu.id);
                    game.overlays.add(InstructionsOverlay.id);
                  },
                ),
                const SizedBox(height: 30),
                if (!kIsWeb) const LogoutButton(),
                const SizedBox(
                  height: 40,
                ),
                SoundToggle(game)
              ],
            ),
          ),
        ));
  }
}
