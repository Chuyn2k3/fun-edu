import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/data/providers/score_provider.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/my_game.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/overlay_frame.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/colors.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/styles.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/action_button.dart';

class GameOverMenu extends ConsumerWidget {
  static const id = 'GameOverMenu';
  final MyGame game;
  const GameOverMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoreNotifierProvider);

    return OverlayFrame(
        child: SizedBox(
      width: MediaQuery.of(context).size.width - 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: titleTextStyle,
            child: const Text('Kết thúc trò chơi'),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: titleTextStyle.copyWith(fontSize: 20),
                    child: const Text('Điểm'),
                  ),
                  const SizedBox(width: 16),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: titleTextStyle.copyWith(fontSize: 22),
                    child: Text('${state.score}'),
                  ),
                ],
              ),
            ),
          ),
          ActionButton(
            title: 'Chơi lại',
            onPressed: () {
              game.reset();
              game.overlays.remove(GameOverMenu.id);
              game.resumeEngine();
              game.startGame();
            },
          ),
          const SizedBox(height: 20),
          //const LogoutButton(),
        ],
      ),
    ));
  }
}
