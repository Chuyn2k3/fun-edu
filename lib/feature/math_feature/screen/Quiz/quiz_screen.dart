import 'dart:async';
import 'dart:math';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/feature/math_feature/customWidget/QuizButtonIcon.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/colorConst.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'answer_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    required this.duration,
    this.operator = 'sum',
    super.key,
    this.numOfQuestions = '5',
    this.range1 = '5',
    this.range2 = '5',
  });
  final String operator;
  final String numOfQuestions;
  final String range1;
  final int duration;

  final String range2;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> questions = [];
  List<dynamic> answers = [];
  bool isMarked = false;
  List<List<dynamic>> mcq = [];
  List<dynamic> userAnswer = [];
  List<dynamic> ansData = [];
  List<dynamic> ans = [];
  var j = 0;
  final CountDownController _controller = CountDownController();

  //
  late AnimationController _animationController;

  late Animation<double> _animation;
  Timer? timer;
  int timeLeft = 10;
  @override
  void initState() {
    super.initState();
    for (var i = 1; i < int.parse(widget.numOfQuestions) + 1; i++) {
      ans = [];
      final val1 = Random().nextInt(int.parse(widget.range1)) + 1;
      final val2 = Random().nextInt(int.parse(widget.range2)) + 1;
      if (widget.operator == 'sum') {
        questions.add('$val1  +  $val2 =  ? ');
        answers.add(val1 + val2);
        ansData = [
          val1 + val2,
          val1 + val2 + Random().nextInt(10) + 1,
          val1 + val2 - Random().nextInt(10) - 1,
          val1 + val2 + Random().nextInt(16) + 1,
        ];
      } else if (widget.operator == 'minus') {
        questions.add('$val1  -  $val2 =  ? ');
        answers.add(val1 - val2);
        ansData = [
          val1 - val2,
          val1 - val2 + Random().nextInt(10) + 1,
          val1 - val2 - Random().nextInt(10) - 1,
          val1 - val2 + Random().nextInt(16) + 1,
        ];
      } else if (widget.operator == 'multiplication') {
        questions.add('$val1  *  $val2 =  ? ');
        answers.add(val1 * val2);
        ansData = [
          val1 * val2,
          val1 * val2 + Random().nextInt(10) + 1,
          val1 * val2 - Random().nextInt(10) - 1,
          val1 * val2 + Random().nextInt(16) + 1,
        ];
      } else {
        questions.add('$val1  /  $val2 =  ? ');
        answers.add((val1 / val2).toStringAsFixed(2));
        ansData = [
          (val1 / val2).toStringAsFixed(2),
          (val1 / val2 + Random().nextInt(10) + 1).toStringAsFixed(2),
          (val1 / val2 - Random().nextInt(10) - 1).toStringAsFixed(2),
          (val1 / val2 + Random().nextInt(16) + 1).toStringAsFixed(2),
        ];
      }
      for (var j = 0; j < 4; j++) {
        final rNum = Random().nextInt(ansData.length).round();
        ans.add(ansData[rNum]);
        ansData.removeAt(rNum);
      }
      mcq.add(ans);
    }

    //
    _animationController = AnimationController(
        vsync: this, duration: Duration(seconds: widget.duration));
    _animation = Tween<double>(begin: 1, end: 0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timeLeft = widget.duration;
    _animationController.reset();
    _animationController.forward();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        if (!isMarked) {
          _changeQuestion('TimeOut');
        }
      }
    });
  }

  void _changeQuestion(ans) {
    userAnswer.add(ans);
    if (j + 1 >= questions.length) {
      int score = 0;
      for (var i = 0; i < answers.length; i++) {
        if (userAnswer[i].toString() == answers[i].toString()) {
          score++;
        }
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnswerScreen(
            maxScore: int.parse(widget.numOfQuestions),
            score: score,
            answers: answers,
            questions: questions,
            userAnswer: userAnswer,
          ),
        ),
      );
    } else {
      setState(() {
        ++j;
        isMarked = false;
      });
      _controller.restart(duration: widget.duration);
    }
  }
  Color valueColorCountdown(){
    if(timeLeft>widget.duration*0.6){
      return Colors.green;
    } else if(timeLeft<=widget.duration*0.6||timeLeft<=widget.duration*0.3){
      return Colors.orange;
    }
    else {
      return Colors.red;
    }
  }
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        onTap: () => Navigator.pop(context),
      ),
      //backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, constraint) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraint.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.quiz,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                "${j + 1}/${widget.numOfQuestions}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle),
                              child: CircularProgressIndicator(
                                value: _animation.value,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  valueColorCountdown()
                                ),
                                strokeWidth: 5,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  // CircularCountDownTimer(
                  //     duration: widget.duration,
                  //     controller: _controller,
                  //     width: MediaQuery.of(context).size.width > 500
                  //         ? MediaQuery.of(context).size.width / 10
                  //         : MediaQuery.of(context).size.width / 6,
                  //     height: MediaQuery.of(context).size.height / 2,
                  //     ringColor: Colors.grey[300] ?? Colors.grey,
                  //     fillColor: baseColor,
                  //     backgroundColor: Colors.white,
                  //     strokeWidth: 20.0,
                  //     textStyle: const TextStyle(
                  //         fontSize: 33.0,
                  //         color: baseColorLight,
                  //         fontWeight: FontWeight.bold),
                  //     textFormat: CountdownTextFormat.SS,
                  //     isReverse: true,
                  //     onStart: () {},
                  //     onComplete: () {
                  //       if (!isMarked) {
                  //         _changeQuestion('TimeOut');
                  //       }
                  //     }),
                  Text(questions[j].toString(),
                      style: TextStyle(
                          color: baseColor,
                          fontSize:
                              MediaQuery.of(context).size.width > 500 ? 45 : 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                          onTap: () {
                            _changeQuestion(mcq[j][0].toString());
                          },
                          child: QuizButtonIcon(option: mcq[j][0].toString())),
                      GestureDetector(
                          onTap: () {
                            _changeQuestion(mcq[j][1].toString());
                          },
                          child: QuizButtonIcon(option: mcq[j][1].toString())),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      GestureDetector(
                          onTap: () {
                            _changeQuestion(mcq[j][2].toString());
                          },
                          child: QuizButtonIcon(option: mcq[j][2].toString())),
                      GestureDetector(
                          onTap: () {
                            _changeQuestion(mcq[j][3].toString());
                          },
                          child: QuizButtonIcon(option: mcq[j][3].toString())),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
