import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/my_game.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/game/overlay_widgets/game_header.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/colors.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/enums.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/styles.dart';
import 'package:fun_edu/feature/math_feature/customWidget/QuizButtonIcon.dart';
import 'game_over_menu.dart';
import 'overlay_frame.dart';

class EnvMessageOverlay extends StatefulWidget {
  static const id = 'EnvMessageOverlay';
  final MyGame game;

  const EnvMessageOverlay(this.game, {super.key});

  @override
  State<EnvMessageOverlay> createState() => _EnvMessageOverlayState();
}

class _EnvMessageOverlayState extends State<EnvMessageOverlay> {
  static const listImage = [
    "assets/image_math/apple.png",
    "assets/image_math/banana.png",
    "assets/image_math/corgi.png",
    "assets/image_math/happy-face.png",
    "assets/image_math/monster.png",
    "assets/image_math/panda.png",
    "assets/image_math/pine-tree.png",
    "assets/image_math/strawberry.png",
    "assets/image_math/table.png",
  ];

  late int val1, val2, ramImageIndex, ramOperatorIndex;
  late int correctAnswer;
  late List<int> answerOptions;
  List<String> operatorList = ["sum", "minus"];

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    setState(() {
      val1 = Random().nextInt(3) + 1;
      val2 = Random().nextInt(3) + 1;
      ramImageIndex = Random().nextInt(listImage.length);
      ramOperatorIndex = Random().nextInt(operatorList.length);

      correctAnswer =
          operatorList[ramOperatorIndex] == "sum" ? val1 + val2 : val1 - val2;

      answerOptions = [
        correctAnswer,
        correctAnswer + Random().nextInt(5) + 1,
        correctAnswer - Random().nextInt(5) - 1,
        correctAnswer + Random().nextInt(10) + 1,
      ];
      answerOptions.shuffle();
    });
  }

  Icon getOperation(String operator) {
    if (operator == "sum") {
      return const Icon(FontAwesomeIcons.plus, size: 24);
    } else if (operator == "minus") {
      return const Icon(FontAwesomeIcons.minus, size: 24);
    }
    return const Icon(FontAwesomeIcons.plus, size: 24);
  }

  Widget questionBuild() {
    final imageList1 = List.generate(val1, (_) => listImage[ramImageIndex]);
    final imageList2 = List.generate(val2, (_) => listImage[ramImageIndex]);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: imageList1
                .map((e) =>
                    Image.asset(e, width: 48, height: 48, fit: BoxFit.contain))
                .toList(),
          ),
        ),
        const SizedBox(width: 4),
        getOperation(operatorList[ramOperatorIndex]),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: imageList2
                .map((e) =>
                    Image.asset(e, width: 48, height: 48, fit: BoxFit.contain))
                .toList(),
          ),
        ),
        const SizedBox(width: 50),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              const Text('= ?', style: TextStyle(fontSize: 26)),
              Image.asset(listImage[ramImageIndex],
                  width: 48, height: 48, fit: BoxFit.cover),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  void _selectAnswer(int selectedAnswer) {
    if (selectedAnswer == correctAnswer) {
      widget.game.gameState = GameState.playing; // Đặt lại trạng thái game
      widget.game.resumeEngine(); // Tiếp tục game
      widget.game.overlays.remove(EnvMessageOverlay.id);
      widget.game.overlays.add(GameHeader.id); // Hiển thị HUD lại
    } else {
      widget.game.overlays.remove(EnvMessageOverlay.id);
      widget.game.overlays.add(GameOverMenu.id);
       widget.game.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    int imageNumber = Random().nextInt(6) + 1;

    return OverlayFrame(
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('dive_deeper', style: titleTextStyle),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/frame_$imageNumber.png',
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    questionBuild(),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      children: answerOptions.map((option) {
                        return GestureDetector(
                          onTap: () => _selectAnswer(option),
                          child: QuizButtonIcon(option: option.toString()),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
