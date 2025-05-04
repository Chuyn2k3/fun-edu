import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/feature/math_feature/customWidget/custom_app_bar.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/math_feature/screen/Quiz/ask_operator.dart';
import 'package:fun_edu/screen/home_screen.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/colorConst.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:lottie/lottie.dart';
import 'user_answer_screen.dart';

class AnswerScreen extends StatelessWidget {
  const AnswerScreen({
    super.key,
    required this.score,
    required this.maxScore,
    required this.questions,
    required this.answers,
    required this.userAnswer,
  });
  final int score;
  final int maxScore;
  final List<dynamic> questions;
  final List<dynamic> answers;
  final List<dynamic> userAnswer;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: AppBar().preferredSize,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomAppbar.basic(onTap: () => Navigator.pop(context)),
              ),
            )
          : PreferredSize(
              preferredSize: AppBar().preferredSize,
              child: CustomAppbar.basic(onTap: () => Navigator.pop(context)),
            ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (score * 100 / maxScore > 75 == true)
              Lottie.asset(
                'assets/lottie/congratulation.json',
                width: 300,
                height: 300,
              )
            else if (score * 100 / maxScore > 40 == true)
              Lottie.asset(
                'assets/nice-try.gif',
                width: 300,
                height: 300,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 60, 0),
                child: Image.asset(
                  'assets/images/betterluck.png',
                  width: 300,
                ),
              ),
            const SizedBox(
              height: 30,
            ),
            Text('Điểm số của bạn là ${score.toString()}',
                style: const TextStyle(
                  fontSize: 25,
                  color: baseColorLight,
                )),
            const SizedBox(
              height: 30,
            ),
            Text('Điểm số lớn nhất: ${maxScore.toString()}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                )),
            const SizedBox(
              height: 30,
            ),
            MaterialButton(
              onPressed: () {

Navigator.popUntil(context, ModalRoute.withName('/askOperator'));
                // Navigator.pushReplacement(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => AskOperator(isQuiz: true)));
              },
              child: const Text('Trở về màn chính ->',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
            const SizedBox(
              height: 30,
            ),
            MaterialButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserAnswerScreen(
                          answers: answers,
                          questions: questions,
                          userAnswer: userAnswer))),
              child: const Text('Kiểm tra đáp án',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
