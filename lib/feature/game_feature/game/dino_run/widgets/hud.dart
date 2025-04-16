import 'package:flutter/material.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/audio_manager.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/dino_run.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/models/player_data.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/widgets/pause_menu.dart';
import 'package:fun_edu/utils/game_time_manager.dart';
import 'package:fun_edu/widget/game_count_down_time.dart';
import 'package:provider/provider.dart';

class Hud extends StatefulWidget {
  static const id = 'Hud';
  final DinoRun game;

  const Hud(this.game, {super.key});

  @override
  State<Hud> createState() => _HudState();
}

class _HudState extends State<Hud> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previousScore = 0;
  late GameTimeManager _timeManager;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 20,
      upperBound: 30,
    );

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _timeManager = GameTimeManager("dinoRun");
    _initGameTime();
  }

  Future<void> _initGameTime() async {
    final canPlay = await _timeManager.canPlay();
    if (!canPlay) {
      _showTimeUpDialog();
      return;
    }

    await _timeManager.startPlay();
    setState(() {}); // để render GameCountdownTimer
  }

  void _showTimeUpDialog() {
      widget.game.overlays.remove(Hud.id);

                    widget.game.pauseEngine();
                    AudioManager.instance.pauseBgm();
  }

  @override
  void dispose() {
    // _timeManager.endPlay(); // Lưu thời gian đã chơi
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.game.playerData,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Selector<PlayerData, int>(
                  selector: (_, playerData) => playerData.currentScore,
                  builder: (_, score, __) {
                    // Kiểm tra nếu đạt mốc điểm thì chạy hiệu ứng
                    if ((score ~/ 50) > (_previousScore ~/ 50)) {
                      _controller.forward(from: 20).whenComplete(() {
                        _controller.reverse();
                      });
                    }
                    _previousScore = score;

                    // Đổi màu chữ theo khoảng điểm
                    Color scoreColor = Colors.white;
                    if (score >= 50 && score < 100) {
                      scoreColor = Colors.yellow; // Xanh biển nhạt
                    } else if (score >= 100 && score < 200) {
                      scoreColor = Colors.red;
                    } else if (score >= 200 && score < 300) {
                      scoreColor = Colors.blue;
                    } else if (score >= 300) {
                      scoreColor = Colors.green;
                    }

                    return AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: _controller.value,
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                      child: Text('Điểm: $score'),
                    );
                  },
                ),
                Expanded(
                  child: Selector<PlayerData, int>(
                    selector: (_, playerData) => playerData.highScore,
                    builder: (_, highScore, __) {
                      return AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20, // Đồng nhất kích thước với số điểm
                            ),
                            children: [
                              const TextSpan(text: 'Điểm cao nhất: '),
                              TextSpan(
                                text: '$highScore',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                  fontSize: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              child: GameCountdownTimer(
                timeManager: _timeManager,
                onTimeUp: _showTimeUpDialog,
              ),
            ),
            TextButton(
              onPressed: () {
                widget.game.overlays.remove(Hud.id);
                widget.game.overlays.add(PauseMenu.id);
                widget.game.pauseEngine();
                AudioManager.instance.pauseBgm();
              },
              child: const Icon(Icons.pause, color: Colors.white),
            ),
            Selector<PlayerData, int>(
              selector: (_, playerData) => playerData.lives,
              builder: (_, lives, __) {
                return Row(
                  children: List.generate(5, (index) {
                    if (index < lives) {
                      return const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      );
                    } else {
                      return const Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                      );
                    }
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
