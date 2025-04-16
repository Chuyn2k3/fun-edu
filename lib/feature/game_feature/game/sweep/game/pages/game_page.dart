import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/my_game.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/booster_progress_overlay.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/env_message_overlay.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/game_header.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/game_over_menu.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/instructions_overlay.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/leaderboard_overlay.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/main_menu.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/pause_menu.dart';
import 'dart:async';

import 'package:fun_edu/utils/game_time_manager.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  late DateTime _startTime;
  Timer? _timer;
  @override
  void initState() {
    _startTime = DateTime.now();

    // Kiểm tra định kỳ mỗi 1 phút
    _timer = Timer?.periodic(const Duration(seconds: 1), (_) async {
      final canPlay = await GameTimeManager("sweep").canPlay();
      if (!canPlay) {
        _timer?.cancel();

        // // Lưu thời gian đã chơi tới thời điểm này
        // final played = DateTime.now().difference(_startTime);
        // await GameTimeManager("dinoRun").addPlayTime(played);

        // Hiện thông báo và thoát game
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Hết giờ chơi!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Bé đã sử dụng hết 15 phút chơi hôm nay.\nHẹn gặp lại bé vào ngày mai nhé!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Xác nhận",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget.controlled(
      loadingBuilder: (context) => const Center(
        child: SizedBox(
          width: 200,
          child: LinearProgressIndicator(),
        ),
      ),
      gameFactory: () => MyGame(context, ref),
      overlayBuilderMap: {
        MainMenu.id: (_, MyGame game) => MainMenu(game),
        PauseMenu.id: (_, MyGame game) => PauseMenu(game),
        GameOverMenu.id: (_, MyGame game) => GameOverMenu(game),
        GameHeader.id: (_, MyGame game) => GameHeader(game),
        EnvMessageOverlay.id: (_, MyGame game) => EnvMessageOverlay(game),
        LeaderBoardOverlay.id: (_, MyGame game) => LeaderBoardOverlay(game),
        InstructionsOverlay.id: (_, MyGame game) => InstructionsOverlay(game),
        BoosterProgressOverlay.id: (_, MyGame game) =>
            BoosterProgressOverlay(game),
      },
      initialActiveOverlays: const [MainMenu.id],
    );
  }
}
