// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fun_edu/data/color/color.dart';
// import 'package:styled_divider/styled_divider.dart';

// class OfflineScreen extends StatefulWidget {
//   const OfflineScreen({Key? key}) : super(key: key);

//   @override
//   _OfflineScreenState createState() => _OfflineScreenState();
// }

// class _OfflineScreenState extends State<OfflineScreen>
//     with SingleTickerProviderStateMixin {
//   late int num1, num2;
//   late String question;
//   late int correctAnswer;
//   late List<int> answers;
//   late AnimationController _controller;
//   late Animation<double> _progressAnimation;
//   double progress = 0.0;
//   int correctCount = 0;
//   int currentQuestion = 1;
//   final int totalQuestions = 10;
//   int selectAnswer = -1;
//   bool isAnswered = false;
//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );

//     _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );

//     generateNewQuestion();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void generateNewQuestion() {
//     if (currentQuestion > totalQuestions) return;

//     bool isAddition = Random().nextBool();
//     num1 = Random().nextInt(10);
//     num2 = Random().nextInt(10);

//     if (!isAddition) {
//       if (num1 < num2) {
//         int temp = num1;
//         num1 = num2;
//         num2 = temp;
//       }
//       correctAnswer = num1 - num2;
//       question = '$num1 - $num2 = ?';
//     } else {
//       correctAnswer = num1 + num2;
//       question = '$num1 + $num2 = ?';
//     }

//     Set<int> answerSet = {correctAnswer};
//     while (answerSet.length < 3) {
//       int wrongAnswer = correctAnswer + (Random().nextInt(5) - 2);
//       if (wrongAnswer >= 0) {
//         answerSet.add(wrongAnswer);
//       }
//     }

//     answers = answerSet.toList();
//     answers.shuffle();
//   }

//   void checkAnswer(int selectedAnswer) {
//     if (selectedAnswer == correctAnswer) {
//       setState(() {
//         correctCount++;
//         progress += 1 / totalQuestions;

//         _controller.forward(from: 0);
//       });
//     }
//   }

//   void nextQuestion() {
//     if (currentQuestion < totalQuestions) {
//       setState(() {
//         currentQuestion++;
//         generateNewQuestion();
//         selectAnswer = -1;
//       });
//     } else {
//       showEndDialog();
//     }
//     setState(() {
//       isAnswered = false;
//     });
//   }

//   void showEndDialog() {
//     bool isSuccess = correctCount == totalQuestions;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               isSuccess ? '🎉 Chúc mừng!' : '😅 Thử lại nhé!',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Icon(
//               isSuccess ? Icons.emoji_events : Icons.refresh,
//               color: isSuccess ? Colors.green : Colors.orange,
//               size: 50,
//             ),
//           ],
//         ),
//         content: Text(
//           isSuccess
//               ? 'Bạn đã hoàn thành tất cả câu hỏi một cách xuất sắc!'
//               : 'Bạn chưa trả lời đúng hết. Hãy thử lại để đạt điểm tối đa!',
//           textAlign: TextAlign.center,
//           style: const TextStyle(fontSize: 16),
//         ),
//         actionsAlignment: MainAxisAlignment.center,
//         actions: [
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isSuccess ? Colors.green : Colors.orange,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 correctCount = 0;
//                 currentQuestion = 1;
//                 progress = 0.0;
//                 selectAnswer = -1;
//                 _controller.reset();
//                 _progressAnimation =
//                     Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

//                 generateNewQuestion();
//               });
//             },
//             icon: const Icon(Icons.replay),
//             label: const Text('Chơi lại'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           _buildBackground(),
//           SafeArea(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildAppBar(),
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Thanh năng lượng
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                             vertical: 20, horizontal: 16),
//                         child: Container(
//                           width: MediaQuery.of(context).size.width,
//                           height: 28,
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF05518B),
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.white, width: 2),
//                           ),
//                           child: Stack(
//                             clipBehavior: Clip.none,
//                             children: [
//                               AnimatedBuilder(
//                                 animation: _progressAnimation,
//                                 builder: (context, child) {
//                                   return FractionallySizedBox(
//                                     alignment: Alignment.centerLeft,
//                                     widthFactor: progress,
//                                     child: Stack(
//                                       clipBehavior: Clip.none,
//                                       children: [
//                                         // 🌌 Thanh năng lượng
//                                         Container(
//                                           height: 28,
//                                           decoration: BoxDecoration(
//                                               borderRadius:
//                                                   BorderRadius.circular(20),
//                                               color: const Color(0xFF46D9BF)),
//                                         ),

//                                         // 🚀 Tên lửa (Đặt trong Stack với Positioned)
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                               const Positioned(
//                                 right: 5, // Cờ nằm sát mép phải
//                                 top: 3,
//                                 child: FaIcon(
//                                   FontAwesomeIcons
//                                       .flagCheckered, // 🏁 Biểu tượng cờ đích
//                                   color: Colors.white,
//                                   size: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       _buildHeaderQuestion(),
//                       // Số câu hỏi
//                       Expanded(child: _buildContentQuestion())
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           fit: BoxFit.fill,
//           image: AssetImage('assets/images/Background_1.png'),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return Padding(
//       padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 0),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           InkWell(
//             splashColor: Colors.transparent,
//             focusColor: Colors.transparent,
//             hoverColor: Colors.transparent,
//             highlightColor: Colors.transparent,
//             onTap: () {
//               Navigator.pop(context);
//             },
//             child: const Icon(
//               Icons.arrow_back_ios_new,
//               color: ColorBase.primaryBackground,
//               size: 24,
//             ),
//           ),
//           const SizedBox(
//             width: 4,
//           ),
//           const Text(
//             'Thử thách hằng ngày',
//             style: TextStyle(
//               fontFamily: 'LilitaOne',
//               color: ColorBase.primaryBackground,
//               fontSize: 24,
//               letterSpacing: 0.0,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderQuestion() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 15),
//           child: Row(
//             mainAxisSize: MainAxisSize.max,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               RichText(
//                 textScaler: MediaQuery.of(context).textScaler,
//                 text: TextSpan(
//                   children: [
//                     TextSpan(
//                       text: 'Câu hỏi $currentQuestion',
//                       style: const TextStyle(
//                         fontFamily: 'LilitaOne',
//                         color: ColorBase.primaryBackground,
//                         fontSize: 30,
//                         letterSpacing: 0.0,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     TextSpan(
//                       text: ' / $totalQuestions',
//                       style: const TextStyle(
//                         color: ColorBase.primaryBackground,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 18,
//                       ),
//                     )
//                   ],
//                   style: const TextStyle(
//                     fontFamily: 'LilitaOne',
//                     letterSpacing: 0.0,
//                   ),
//                 ),
//               ),
//               InkWell(
//                 onTap: () {
//                   if (isAnswered == true) {
//                     nextQuestion();
//                   }
//                 },
//                 child: Container(
//                   width: 82,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: const Color(0x21FFFFFF),
//                     borderRadius: BorderRadius.circular(22),
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       Text(
//                         'Tiếp tục',
//                         textAlign: TextAlign.end,
//                         style: TextStyle(
//                           fontFamily: 'LilitaOne',
//                           color: ColorBase.primaryBackground,
//                           fontSize: 13,
//                           letterSpacing: 0.0,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsetsDirectional.fromSTEB(4, 0, 10, 0),
//                         child: Icon(
//                           Icons.arrow_forward_ios,
//                           color: ColorBase.primaryBackground,
//                           size: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const StyledDivider(
//           height: 1,
//           thickness: 2,
//           indent: 16,
//           endIndent: 16,
//           color: ColorBase.primaryBackground,
//           lineStyle: DividerLineStyle.dashed,
//         ),
//       ],
//     );
//   }

//   Widget _buildContentQuestion() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         color: Colors.white,
//       ),
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           Text(
//             textAlign: TextAlign.center,
//             question,
//             style: const TextStyle(
//                 fontSize: 36,
//                 color: Colors.black,
//                 fontFamily: 'LilitaOne',
//                 fontWeight: FontWeight.w500),
//           ),
//           for (var answer in answers)
//             AnswerCard(
//               answer: answer,
//               onTap: isAnswered
//                   ? null
//                   : () {
//                       setState(() {
//                         selectAnswer = answer;
//                         isAnswered = true;
//                       });
//                       checkAnswer(answer);
//                     },
//               status: checkAnswerStatus(answer),
//             ),
//         ],
//       ),
//     );
//   }

//   AnswerStatus checkAnswerStatus(int answer) {
//     return selectAnswer == -1
//         ? AnswerStatus.neutral
//         : (answer == correctAnswer
//             ? AnswerStatus.correct
//             : (answer == selectAnswer
//                 ? AnswerStatus.incorrect
//                 : AnswerStatus.neutral));
//   }
// }

// enum AnswerStatus { correct, incorrect, neutral }

// class AnswerCard extends StatefulWidget {
//   const AnswerCard({
//     super.key,
//     required this.answer,
//     required this.onTap,
//     required this.status,
//   });

//   final int answer;
//   final VoidCallback? onTap;
//   final AnswerStatus status;

//   @override
//   State<AnswerCard> createState() => _AnswerCardState();
// }

// class _AnswerCardState extends State<AnswerCard> {
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: widget.onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 100),
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//         decoration: BoxDecoration(
//           color: bgColor(widget.status),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: borderColor(widget.status), width: 3),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 "${widget.answer}",
//                 style: TextStyle(
//                   color: textColor(widget.status),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             Icon(
//               adaptiveIcon(widget.status),
//               color: textColor(widget.status),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Hàm lấy màu nền
//   Color bgColor(AnswerStatus status) {
//     switch (status) {
//       case AnswerStatus.correct:
//         return const Color.fromARGB(55, 69, 255, 76);
//       case AnswerStatus.incorrect:
//         return const Color.fromARGB(71, 255, 79, 62);
//       default:
//         return Colors.white;
//     }
//   }

//   // Hàm lấy màu viền
//   Color borderColor(AnswerStatus status) {
//     switch (status) {
//       case AnswerStatus.correct:
//         return Colors.green;
//       case AnswerStatus.incorrect:
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   // Hàm lấy màu chữ
//   Color textColor(AnswerStatus status) {
//     switch (status) {
//       case AnswerStatus.correct:
//         return Colors.green.shade900;
//       case AnswerStatus.incorrect:
//         return Colors.red.shade900;
//       default:
//         return Colors.black;
//     }
//   }

//   // Hàm lấy icon hiển thị
//   IconData adaptiveIcon(AnswerStatus status) {
//     switch (status) {
//       case AnswerStatus.correct:
//         return Icons.check_circle;
//       case AnswerStatus.incorrect:
//         return Icons.error;
//       default:
//         return Icons.circle_outlined;
//     }
//   }
// }

import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/core/repositories/question_repository.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/feature/user/cubit/coin/update_user_coin_cubit.dart';
import 'package:fun_edu/feature/user/cubit/user_info/get_user_info_cubit.dart';
import 'package:fun_edu/model/question.dart';
import 'package:fun_edu/model/question_model.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';
import 'package:fun_edu/providers/questions.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:fun_edu/widget/answer_card.dart';
import 'package:get_it/get_it.dart';
import 'package:styled_divider/styled_divider.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({
    Key? key,
    required this.userCoin,
  }) : super(key: key);
  final int userCoin;
  @override
  _OfflineScreenState createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double progress = 0.0;
  int correctCount = 0;
  int currentQuestionIndex = 0;
  final int totalQuestions = 10;
  int selectedAnswerIndex = -1;
  bool isAnswered = false;
  bool isLoading = true;
  String? errorMessage;
  int earnedCoins = 0;
  final QuestionRepository _questionRepository = serviceLocator();
  // For API integration
  List<QuestionModel> questions = [];
  QuestionModel? currentQuestion;
  late UpdateUserCoinCubit updateUserCoinCubit;
  String? deviceId;
  bool isDailyTaskCompleted = false;
  late ConfettiController _confettiController;
  int streakCount = 0;
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

    // Initialize user info cubit
    updateUserCoinCubit = UpdateUserCoinCubit();
    deviceId =
        GetIt.instance.get<SharedPreferencesManager>().getString("deviceId");

    // Check if daily tasks need to be reset

    // Check if daily task is already completed
    isDailyTaskCompleted = GetIt.instance
            .get<SharedPreferencesManager>()
            .getBool("daily_task_completed") ??
        false;
    //if (deviceId != null && deviceId!.isNotEmpty) {
    checkAndResetDailyTasks();
    //}
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    // Start confetti if task is completed
    if (isDailyTaskCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
    // Only load questions if the daily task is not completed
    if (!isDailyTaskCompleted) {
      loadQuestions();
    }
  }

  Future<void> checkAndResetDailyTasks() async {
    try {
      // Get the last completion date from SharedPreferences
      final lastCompletionDate = GetIt.instance
          .get<SharedPreferencesManager>()
          .getString("last_daily_task_date");

      // Get current date as string (just the date part)
      final currentDate = DateTime.now().toIso8601String().split('T')[0];

      // Check if it's a new day
      if (lastCompletionDate != currentDate) {
        // Check if the last completion was yesterday to maintain streak
        bool maintainStreak = false;
        if (lastCompletionDate != null) {
          final yesterday = DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0];
          maintainStreak = lastCompletionDate == yesterday;
        }

        // Reset daily task completion status
        await GetIt.instance
            .get<SharedPreferencesManager>()
            .putString("last_daily_task_date", currentDate);
        await GetIt.instance
            .get<SharedPreferencesManager>()
            .putBool("daily_task_completed", false);

        // Update streak
        if (maintainStreak) {
          streakCount = GetIt.instance
                  .get<SharedPreferencesManager>()
                  .getInt("streak_count") ??
              0;
        } else {
          // Reset streak if missed a day
          await GetIt.instance
              .get<SharedPreferencesManager>()
              .putInt("streak_count", 0);
          streakCount = 0;
        }
      } else {
        // If same day, just get the current streak
        streakCount = GetIt.instance
                .get<SharedPreferencesManager>()
                .getInt("streak_count") ??
            0;
      }

      // Check if daily task is already completed
      isDailyTaskCompleted = GetIt.instance
              .get<SharedPreferencesManager>()
              .getBool("daily_task_completed") ??
          false;
    } catch (e) {
      print('Error checking daily tasks: $e');
    }
  }

  Future<void> loadQuestions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _questionRepository.getQuestionDaily();
      final _questions = result.data?.content ?? [];

      final fetchedQuestions = _questions;

      // Limit to 10 questions if more are returned
      if (fetchedQuestions.length > totalQuestions) {
        fetchedQuestions.length = totalQuestions;
      }

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
        if (questions.isNotEmpty) {
          currentQuestion = questions[0];
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get isRightIndex {
    final list = currentQuestion?.answers;
    if (list == null || list.isEmpty) return -1;
    return list.indexWhere((e) => e.isCorrect ?? false);
  }

  void checkAnswer(int selectedIndex) {
    if (currentQuestion == null) return;

    bool isCorrect = selectedIndex == isRightIndex;

    if (isCorrect) {
      setState(() {
        correctCount++;
        progress += 1 / totalQuestions;
        earnedCoins += 5; // Award 5 coins for each correct answer
        _controller.forward(from: 0);
      });
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        currentQuestion = questions[currentQuestionIndex];
        selectedAnswerIndex = -1;
        isAnswered = false;
      });
    } else {
      showEndDialog();
    }
  }

  void updateUserCoins(int earnedCoins) async {
    if (deviceId != null && deviceId!.isNotEmpty) {
      try {
        // Update user's coin count
        final request = UserInfoByDeviceIdModel(
          deviceId: deviceId,
          coin: widget.userCoin + earnedCoins,
        );

        updateUserCoinCubit.updateUserCoin(request: request);

        // Mark daily task as completed
        await GetIt.instance
            .get<SharedPreferencesManager>()
            .putBool("daily_task_completed", true);

        // Set the last completion date
        final currentDate = DateTime.now().toIso8601String().split('T')[0];
        await GetIt.instance
            .get<SharedPreferencesManager>()
            .putString("last_daily_task_date", currentDate);
        streakCount++;
        await GetIt.instance
            .get<SharedPreferencesManager>()
            .putInt("streak_count", streakCount);
      } catch (e) {
        print('Error updating coins: $e');
      }
    } else {
      await GetIt.instance
          .get<SharedPreferencesManager>()
          .putBool("daily_task_completed", true);
    }
  }

  void showEndDialog() {
    bool isSuccess = correctCount == totalQuestions;

    // Calculate bonus coins for completing all questions
    int bonusCoins = isSuccess ? 20 : 0;
    int totalEarnedCoins = earnedCoins + bonusCoins;

    // Update user's coin count
    updateUserCoins(totalEarnedCoins);

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess
                  ? 'Bạn đã hoàn thành tất cả câu hỏi một cách xuất sắc!'
                  : 'Bạn chưa trả lời đúng hết. Hãy thử lại để đạt điểm tối đa!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '+$totalEarnedCoins xu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            if (isSuccess && bonusCoins > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '(Bao gồm $bonusCoins xu thưởng hoàn thành)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
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
              Navigator.pop(
                  context, true); // Return true to refresh home screen
            },
            icon: const Icon(Icons.home),
            label: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => updateUserCoinCubit,
        )
      ],
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: isDailyTaskCompleted
                        ? _buildCompletionScreen()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Progress bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 16),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF05518B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
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
                                                Container(
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      color: const Color(
                                                          0xFF46D9BF)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const Positioned(
                                        right: 5,
                                        top: 3,
                                        child: FaIcon(
                                          FontAwesomeIcons.flagCheckered,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildHeaderQuestion(),
                              // Question content
                              Expanded(
                                child: isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : errorMessage != null
                                        ? _buildErrorData(errorMessage!)
                                        : questions.isEmpty
                                            ? _buildEmptyData()
                                            : _buildContentQuestion(),
                              )
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      text: 'Câu hỏi ${currentQuestionIndex + 1}',
                      style: const TextStyle(
                        fontFamily: 'LilitaOne',
                        color: ColorBase.primaryBackground,
                        fontSize: 30,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${questions.length}',
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
                onTap: isAnswered ? nextQuestion : null,
                child: Container(
                  width: 82,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isAnswered
                        ? const Color(0x21FFFFFF)
                        : const Color(0x10FFFFFF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
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
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(4, 0, 10, 0),
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
    if (currentQuestion == null) return const SizedBox();

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
          Column(
            children: [
              Text(
                currentQuestion?.title ?? "-",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              if (currentQuestion!.content != null)
                Text(
                  currentQuestion?.content??"-",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (currentQuestion?.imageUrl != null)
                Image.network(
                  currentQuestion?.imageUrl ?? "",
                  width: 200,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 100),
                ),
              const SizedBox(height: 20),
            ],
          ),
          ...List.generate(
            currentQuestion?.answers?.length ?? 0,
            (index) => AnswerCard(
              answer: currentQuestion?.answers?[index].content ?? "-",
              onTap: isAnswered
                  ? null
                  : () {
                      setState(() {
                        selectedAnswerIndex = index;
                        isAnswered = true;
                      });
                      checkAnswer(index);
                    },
              answerCardStatus: _getAnswerStatus(index),
            ),
          ),
          if (isAnswered) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF46D9BF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Câu tiếp theo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    // Get the next day's date for the message
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final nextDay = tomorrow.day;
    final month = tomorrow.month;

    // Format the date for display
    final monthNames = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];

    return Stack(children: [
      Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (streakCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Chuỗi: $streakCount ngày',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

              // Trophy icon with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF9C4),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Congratulatory text
              const Text(
                '🎉 Chúc mừng! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontFamily: 'LilitaOne',
                ),
              ),
              const SizedBox(height: 16),

              // Completion message
              const Text(
                'Bạn đã hoàn thành nhiệm vụ hằng ngày!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'LilitaOne',
                ),
              ),
              const SizedBox(height: 24),

              // Next day message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Quay lại vào ngày mai',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhiệm vụ mới sẽ được mở vào ngày $nextDay ${monthNames[month]}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Return to home button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home),
                label: const Text('Về trang chủ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF46D9BF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2, // straight up
          maxBlastForce: 5,
          minBlastForce: 2,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.1,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
            Colors.red,
          ],
        ),
      ),
    ]);
  }

  AnswerCardStatus _getAnswerStatus(int index) {
    if (!isAnswered) return AnswerCardStatus.normal;

    if (index == isRightIndex && index == selectedAnswerIndex) {
      return AnswerCardStatus.right;
    } else if (index != isRightIndex && index == selectedAnswerIndex) {
      return AnswerCardStatus.error;
    } else {
      return AnswerCardStatus.disabled;
    }
  }

  Widget _buildErrorData(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lỗi: $error',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: loadQuestions,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Không có câu hỏi nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Image.asset(
            "assets/images/kitten.png",
            height: 150,
            width: 180,
          ),
        ],
      ),
    );
  }
}
