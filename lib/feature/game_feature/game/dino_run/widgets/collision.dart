import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/game/dino_run.dart';

class CollisionOverlay extends StatefulWidget {
  final DinoRun game;
  const CollisionOverlay(this.game, {Key? key}) : super(key: key);
  static const id = 'CollisionOverlay';

  @override
  _CollisionOverlayState createState() => _CollisionOverlayState();
}

class _CollisionOverlayState extends State<CollisionOverlay>
    with SingleTickerProviderStateMixin {
  late int num1;
  late int num2;
  late int correctAnswer;
  late String operation;
  late List<int> options;
  bool answered = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _generateQuestion();

    // Timeout nếu không trả lời trong 2 giây
    Future.delayed(const Duration(seconds: 10), () {
      if (!answered && widget.game.overlays.isActive(CollisionOverlay.id)) {
        widget.game.playerData.lives -= 1;
        _closeOverlay();
      }
    });
  }

  void _generateQuestion() {
    Random random = Random();
    int a = random.nextInt(10) + 1;
    int b = random.nextInt(10) + 1;
    bool isAddition = random.nextBool();

    if (isAddition) {
      num1 = a;
      num2 = b;
      operation = '+';
      correctAnswer = num1 + num2;
    } else {
      num1 = max(a, b); // Số lớn
      num2 = min(a, b); // Số nhỏ
      operation = '-';
      correctAnswer = num1 - num2;
    }

    // Tạo danh sách đáp án (dùng Set để tránh trùng lặp, sau đó chuyển thành List)
    Set<int> tempOptions = {correctAnswer};

    while (tempOptions.length < 3) {
      int wrongAnswer = correctAnswer + random.nextInt(5) - 2;
      if (wrongAnswer >= 0) {
        tempOptions.add(wrongAnswer);
      }
    }

    options = tempOptions.toList()..shuffle(); // Chuyển về List và xáo trộn
  }

  void _checkAnswer(int selectedAnswer) {
    setState(() => answered = true);
    if (selectedAnswer != correctAnswer) {
      widget.game.playerData.lives -= 1;
    }
    _closeOverlay();
  }

  void _closeOverlay() {
    widget.game.resumeEngine();
    widget.game.overlays.remove(CollisionOverlay.id);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Material(
          color: Colors.black.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vòng tròn đếm ngược
                    TweenAnimationBuilder(
                      tween: Tween(begin: 10.0, end: 0.0),
                      duration: const Duration(seconds: 10),
                      onEnd: () {
                        if (!answered) {
                          widget.game.playerData.lives -= 1;
                          _closeOverlay();
                        }
                      },
                      builder: (context, value, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: value / 10, // Tính tỷ lệ còn lại
                                strokeWidth: 6,
                                valueColor: AlwaysStoppedAnimation(
                                  value > 5
                                      ? Colors.green
                                      : value > 3
                                          ? Colors.yellow
                                          : Colors.red,
                                  // Cảnh báo khi gần hết giờ
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                            Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$num1 $operation $num2 = ?",
                        style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: options
                            .map((option) => _buildAnswerButton(option))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(int value) {
    return GestureDetector(
      onTap: () => _checkAnswer(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        decoration: BoxDecoration(
          color: answered
              ? (value == correctAnswer ? Colors.green : Colors.red)
              : Colors.blue,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        child: Text(
          "$value",
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
