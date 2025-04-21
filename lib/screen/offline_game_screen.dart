import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:styled_divider/styled_divider.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({Key? key}) : super(key: key);

  @override
  _OfflineScreenState createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  late int num1, num2;
  late String question;
  late int correctAnswer;
  late List<int> answers;
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double progress = 0.0;
  int correctCount = 0;
  int currentQuestion = 1;
  final int totalQuestions = 10;
  int selectAnswer = -1;
  bool isAnswered = false;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    generateNewQuestion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void generateNewQuestion() {
    if (currentQuestion > totalQuestions) return;

    bool isAddition = Random().nextBool();
    num1 = Random().nextInt(10);
    num2 = Random().nextInt(10);

    if (!isAddition) {
      if (num1 < num2) {
        int temp = num1;
        num1 = num2;
        num2 = temp;
      }
      correctAnswer = num1 - num2;
      question = '$num1 - $num2 = ?';
    } else {
      correctAnswer = num1 + num2;
      question = '$num1 + $num2 = ?';
    }

    Set<int> answerSet = {correctAnswer};
    while (answerSet.length < 3) {
      int wrongAnswer = correctAnswer + (Random().nextInt(5) - 2);
      if (wrongAnswer >= 0) {
        answerSet.add(wrongAnswer);
      }
    }

    answers = answerSet.toList();
    answers.shuffle();
  }

  void checkAnswer(int selectedAnswer) {
    if (selectedAnswer == correctAnswer) {
      setState(() {
        correctCount++;
        progress += 1 / totalQuestions;

        _controller.forward(from: 0);
      });
    }
  }

  void nextQuestion() {
    if (currentQuestion < totalQuestions) {
      setState(() {
        currentQuestion++;
        generateNewQuestion();
        selectAnswer = -1;
      });
    } else {
      showEndDialog();
    }
    setState(() {
      isAnswered = false;
    });
  }

  void showEndDialog() {
    bool isSuccess = correctCount == totalQuestions;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess ? '🎉 Chúc mừng!' : '😅 Thử lại nhé!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Icon(
              isSuccess ? Icons.emoji_events : Icons.refresh,
              color: isSuccess ? Colors.green : Colors.orange,
              size: 50,
            ),
          ],
        ),
        content: Text(
          isSuccess
              ? 'Bạn đã hoàn thành tất cả câu hỏi một cách xuất sắc!'
              : 'Bạn chưa trả lời đúng hết. Hãy thử lại để đạt điểm tối đa!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                correctCount = 0;
                currentQuestion = 1;
                progress = 0.0;
                selectAnswer = -1;
                _controller.reset();
                _progressAnimation =
                    Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

                generateNewQuestion();
              });
            },
            icon: const Icon(Icons.replay),
            label: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Thanh năng lượng
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF05518B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // 🌌 Thanh năng lượng
                                        Container(
                                          height: 28,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: const Color(0xFF46D9BF)),
                                        ),

                                        // 🚀 Tên lửa (Đặt trong Stack với Positioned)
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Positioned(
                                right: 5, // Cờ nằm sát mép phải
                                top: 3,
                                child: FaIcon(
                                  FontAwesomeIcons
                                      .flagCheckered, // 🏁 Biểu tượng cờ đích
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildHeaderQuestion(),
                      // Số câu hỏi
                      Expanded(child: _buildContentQuestion())
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage('assets/images/Background_1.png'),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: ColorBase.primaryBackground,
              size: 24,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          const Text(
            'Thử thách hằng ngày',
            style: TextStyle(
              fontFamily: 'LilitaOne',
              color: ColorBase.primaryBackground,
              fontSize: 24,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderQuestion() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 15),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                textScaler: MediaQuery.of(context).textScaler,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Câu hỏi $currentQuestion',
                      style: const TextStyle(
                        fontFamily: 'LilitaOne',
                        color: ColorBase.primaryBackground,
                        fontSize: 30,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' / $totalQuestions',
                      style: const TextStyle(
                        color: ColorBase.primaryBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    )
                  ],
                  style: const TextStyle(
                    fontFamily: 'LilitaOne',
                    letterSpacing: 0.0,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  if (isAnswered == true) {
                    nextQuestion();
                  }
                },
                child: Container(
                  width: 82,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0x21FFFFFF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tiếp tục',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          color: ColorBase.primaryBackground,
                          fontSize: 13,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(4, 0, 10, 0),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: ColorBase.primaryBackground,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const StyledDivider(
          height: 1,
          thickness: 2,
          indent: 16,
          endIndent: 16,
          color: ColorBase.primaryBackground,
          lineStyle: DividerLineStyle.dashed,
        ),
      ],
    );
  }

  Widget _buildContentQuestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            textAlign: TextAlign.center,
            question,
            style: const TextStyle(
                fontSize: 36,
                color: Colors.black,
                fontFamily: 'LilitaOne',
                fontWeight: FontWeight.w500),
          ),
          for (var answer in answers)
            AnswerCard(
              answer: answer,
              onTap: isAnswered
                  ? null
                  : () {
                      setState(() {
                        selectAnswer = answer;
                        isAnswered = true;
                      });
                      checkAnswer(answer);
                    },
              status: checkAnswerStatus(answer),
            ),
        ],
      ),
    );
  }

  AnswerStatus checkAnswerStatus(int answer) {
    return selectAnswer == -1
        ? AnswerStatus.neutral
        : (answer == correctAnswer
            ? AnswerStatus.correct
            : (answer == selectAnswer
                ? AnswerStatus.incorrect
                : AnswerStatus.neutral));
  }
}

enum AnswerStatus { correct, incorrect, neutral }

class AnswerCard extends StatefulWidget {
  const AnswerCard({
    super.key,
    required this.answer,
    required this.onTap,
    required this.status,
  });

  final int answer;
  final VoidCallback? onTap;
  final AnswerStatus status;

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor(widget.status),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor(widget.status), width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "${widget.answer}",
                style: TextStyle(
                  color: textColor(widget.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              adaptiveIcon(widget.status),
              color: textColor(widget.status),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm lấy màu nền
  Color bgColor(AnswerStatus status) {
    switch (status) {
      case AnswerStatus.correct:
        return const Color.fromARGB(55, 69, 255, 76);
      case AnswerStatus.incorrect:
        return const Color.fromARGB(71, 255, 79, 62);
      default:
        return Colors.white;
    }
  }

  // Hàm lấy màu viền
  Color borderColor(AnswerStatus status) {
    switch (status) {
      case AnswerStatus.correct:
        return Colors.green;
      case AnswerStatus.incorrect:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Hàm lấy màu chữ
  Color textColor(AnswerStatus status) {
    switch (status) {
      case AnswerStatus.correct:
        return Colors.green.shade900;
      case AnswerStatus.incorrect:
        return Colors.red.shade900;
      default:
        return Colors.black;
    }
  }

  // Hàm lấy icon hiển thị
  IconData adaptiveIcon(AnswerStatus status) {
    switch (status) {
      case AnswerStatus.correct:
        return Icons.check_circle;
      case AnswerStatus.incorrect:
        return Icons.error;
      default:
        return Icons.circle_outlined;
    }
  }
}
