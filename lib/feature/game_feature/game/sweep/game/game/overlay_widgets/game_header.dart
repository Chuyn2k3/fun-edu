import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/data/providers/score_provider.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/my_game.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/styles.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/widget/logout_button.dart';

class GameHeader extends ConsumerStatefulWidget {
  static const id = 'GameHeader';
  final MyGame game;

  const GameHeader(this.game, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GameHeaderState();
}

class _GameHeaderState extends ConsumerState<GameHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      lowerBound: 18,
      upperBound: 30,
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );
    _controller.addListener(() {
      try {
        setState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scoreNotifierProvider, (previous, next) {
      if (previous?.score != next.score) {
        _controller
            .forward(from: 16.0)
            .whenComplete(() => _controller.reverse());
      }
    });

    final currentScore = ref.watch(scoreNotifierProvider).score;
    final highestScore = ref.watch(scoreNotifierProvider).highScore;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 10.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LogoutButton(),
                Row(
                  children: [
                    Text(
                      'Highest Score:',
                      style: subtitleStyle,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      highestScore.toString(),
                      style:
                          subtitleStyle.copyWith(fontSize: _controller.value),
                    )
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Score:',
                      style: subtitleStyle,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      currentScore.toString(),
                      style:
                          subtitleStyle.copyWith(fontSize: _controller.value),
                    )
                  ],
                ),
              ],
            ),
            Material(
              color: Colors.transparent,
              child: IconButton(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                onPressed: () {
                  widget.game.pauseEngine();
                },
                icon: const Icon(
                  Icons.pause,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
