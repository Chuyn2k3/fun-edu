import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/offline_multiplayer_result_screen.dart';
import 'package:fun_edu/providers/offline.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/widget/answer_card.dart';
import 'package:fun_edu/widget/custom_button.dart';

class OfflineMultiplayerScreen extends ConsumerWidget {
  const OfflineMultiplayerScreen(this.user1Name, this.user2Name, {Key? key})
      : super(key: key);
  final String user1Name;
  final String user2Name;
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
  static List<String> operatorList = [
    "sum",
    "minus",
    "greater",
    "less",
    "equal"
  ];
  static int ramImageIndex = Random().nextInt(9);
  Icon getOperation(String operator) {
    if (operator == "+") {
      return const Icon(FontAwesomeIcons.plus, size: 24);
    } else if (operator == "-") {
      return const Icon(FontAwesomeIcons.minus, size: 24);
    }
    // else if (operator == ">") {
    //   return const Icon(FontAwesomeIcons.greaterThan, size: 24);
    // } else if (operator == "<") {
    //   return const Icon(FontAwesomeIcons.lessThan, size: 24);
    // } else if (operator == "=") {
    //   return const Icon(FontAwesomeIcons.equals, size: 24);
    // }
    return const Icon(
      FontAwesomeIcons.square,
      size: 40,
    );
  }

  Widget questionBuild(String val1, String val2, String operator) {
    final imageList1 =
        List.generate(int.parse(val1), (_) => listImage[ramImageIndex]);
    final imageList2 =
        List.generate(int.parse(val2), (_) => listImage[ramImageIndex]);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: imageList1
                  .map((e) => Image.asset(e,
                      width: 48, height: 48, fit: BoxFit.contain))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        getOperation(operator),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineProvider);

    ref.listen<Offline>(offlineProvider, (previous, next) {
      if (next.isFinish) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OfflineMultiplayerResultScreen(),
            ));
      }
    });
    return SafeArea(
      child: BaseScaffold(
        appBar: CustomAppbar.basic(
          onTap: () => Navigator.pop(context),
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SvgPicture.asset(
              'assets/images/circles.svg',
              fit: BoxFit.fitHeight,
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildUserCard(
                        user1Name,
                        "assets/images/warrior.png",
                        offline.userScore,
                        const Color(0xff189AFE),
                      ),
                      const SizedBox(width: 20),
                      // const Text(
                      //   'VS',
                      //   style: TextStyle(
                      //       fontSize: 30, fontWeight: FontWeight.bold),
                      // ),
                      Image.asset(
                        "assets/images/vs.png",
                        height: 96,
                        width: 96,
                      ),
                      const SizedBox(width: 20),
                      _buildUserCard(
                        user2Name,
                        "assets/images/warrior_1.png",
                        offline.enemyScore,
                        const Color(0xff16968B),
                      ),
                    ],
                  ),
                ),
                //const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  width: double.infinity,
                  child: Text(
                    'Câu hỏi ${offline.currentQuestionIndex + 1}/10',
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Text(
                        //   offline.currentQuestion.question,
                        //   style: const TextStyle(color: Colors.black),
                        //   textAlign: TextAlign.start,
                        // ),
                        questionBuild(
                          offline.currentQuestion.questionList[0],
                          offline.currentQuestion.questionList[2],
                          offline.currentQuestion.questionList[1],
                        ),
                        // if (offline.currentQuestion.image != null)
                        //   Image.asset(
                        //       'assets/t-images/${offline.currentQuestion.image}'),
                        for (int i = 0; i < offline.currentAnswers.length; i++)
                          AnswerCard(
                            answer: offline.currentAnswers[i],
                            answerCardStatus: offline.answersStatus[i],
                            onTap: offline.isUserAnswering == null ||
                                    offline.isChoseAnswer
                                ? null
                                : () {
                                    offline.answerQuestion(i);
                                  },
                          ),
                        if (offline.isChoseAnswer) ...[
                          const SizedBox(height: 20),
                          CustomButton(
                            padding: 0,
                            onPressed: offline.nextQuestion,
                            text: 'Câu tiếp theo',
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HandButton(
                                color: Color(0xff189AFE),
                                isUser: true,
                              ),
                              HandButton(
                                color: Color(0xff16968B),
                                isUser: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildUserCard(
      String userName, String image, int score, Color colorScore) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: Column(
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Image.asset(
                    image,
                    fit: BoxFit.fill,
                    width: 64,
                    height: 64,
                  )
                ],
              ),
            ),
            const Divider(
              thickness: 2,
              color: Colors.black54,
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                score.toString(),
                style: TextStyle(
                    color: colorScore,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HandButton extends ConsumerWidget {
  const HandButton({
    required this.color,
    required this.isUser,
    Key? key,
  }) : super(key: key);

  final Color color;
  final bool isUser;

  @override
  Widget build(BuildContext context, ref) {
    final offline = ref.watch(offlineProvider);
    return InkWell(
      onTap: offline.isUserAnswering != null
          ? null
          : () {
              offline.chooseAnswerer(isUser);
            },
      child: CircleAvatar(
        backgroundColor: color.withOpacity((offline.isUserAnswering != null &&
                offline.isUserAnswering != isUser)
            ? .4
            : 1),
        radius: 50,
        child: SvgPicture.asset('assets/images/hand.svg'),
      ),
    );
  }
}

// getOpacity(bool? isAnswering, bool isUser) {
//   if (isAnswering != null && !isUser) {
//     return .4;
//   }
//   return 1;
// }
