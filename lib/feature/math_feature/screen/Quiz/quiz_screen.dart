// import 'dart:async';
// import 'dart:math';

// import 'package:circular_countdown_timer/circular_countdown_timer.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fun_edu/feature/math_feature/customWidget/QuizButtonIcon.dart';
// import 'package:fun_edu/utils/base_scaffold.dart';
// import 'package:fun_edu/utils/colorConst.dart';
// import 'package:fun_edu/utils/custom_app_bar.dart';
// import 'answer_screen.dart';

// class QuizScreen extends StatefulWidget {
//   const QuizScreen({
//     required this.duration,
//     this.operator = 'sum',
//     super.key,
//     this.numOfQuestions = '5',
//     this.range1 = '5',
//     this.range2 = '5',
//   });
//   final String operator;
//   final String numOfQuestions;
//   final String range1;
//   final int duration;

//   final String range2;

//   @override
//   State<QuizScreen> createState() => _QuizScreenState();
// }

// class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
//   List<dynamic> questions = [];
//   List<dynamic> answers = [];
//   bool isMarked = false;
//   List<List<dynamic>> mcq = [];
//   List<dynamic> userAnswer = [];
//   List<dynamic> ansData = [];
//   List<dynamic> ans = [];
//   var j = 0;
//   final CountDownController _controller = CountDownController();

//   //
//   late AnimationController _animationController;

//   late Animation<double> _animation;
//   Timer? timer;
//   int timeLeft = 30;
//   final listImage = [
//     "assets/image_math/apple.png",
//     "assets/image_math/banana.png",
//     "assets/image_math/corgi.png",
//     "assets/image_math/happy-face.png",
//     "assets/image_math/monster.png",
//     "assets/image_math/panda.png",
//     "assets/image_math/pine-tree.png",
//     "assets/image_math/strawberry.png",
//     "assets/image_math/table.png",
//   ];
//   Icon getOperation(String operator) {
//     if (operator == "sum") {
//       return const Icon(
//         FontAwesomeIcons.plus,
//         size: 24,
//       );
//     } else if (operator == "minus") {
//       return const Icon(
//         FontAwesomeIcons.minus,
//         size: 24,
//       );
//     }
//     return const Icon(
//       FontAwesomeIcons.plus,
//       size: 24,
//     );
//   }

//   Widget questionBuild(int val1, int val2, int ramImageIndex, String operator) {
//     final imageList1 = List.generate(val1, (index) {
//       return listImage[ramImageIndex];
//     });
//     final imageList2 = List.generate(val2, (index) {
//       return listImage[ramImageIndex];
//     });
//     return Row(
//       children: [
//         Expanded(
//           flex: 3,
//           child: Directionality(
//             textDirection: TextDirection.rtl, // Đảo ngược hướng hiển thị
//             child: Wrap(
//               spacing: 4,
//               runSpacing: 4,
//               children: imageList1
//                   .map((e) => Image.asset(
//                         e,
//                         width: 48,
//                         height: 48,
//                         fit: BoxFit.contain,
//                       ))
//                   .toList(),
//             ),
//           ),
//         ),
//         SizedBox(
//           width: 4,
//         ),
//         getOperation(operator),
//         SizedBox(
//           width: 4,
//         ),
//         Expanded(
//           flex: 2,
//           child: Wrap(
//             spacing: 4,
//             runSpacing: 4,
//             children: imageList2
//                 .map((e) => Image.asset(
//                       e,
//                       width: 48,
//                       height: 48,
//                       fit: BoxFit.contain,
//                     ))
//                 .toList(),
//           ),
//         ),
//         SizedBox(
//           width: 100, // Tăng chiều rộng từ 30 lên 50
//           child: FittedBox(
//             fit: BoxFit.scaleDown,
//             child: Row(
//               children: [
//                 Text(
//                   '=  ? ',
//                   style: TextStyle(
//                       fontSize:
//                           26), // Bạn có thể bỏ dòng này nếu muốn tự động co giãn
//                 ),
//                 Image.asset(
//                   listImage[ramImageIndex],
//                   width: 48,
//                   height: 48,
//                   fit: BoxFit.cover,
//                 )
//               ],
//             ),
//           ),
//         ),
//         Spacer(
//           flex: 1,
//         )
//         // Expanded(
//         //   child: Image.asset(
//         //     listImage[ramImageIndex],
//         //     // width: 48,
//         //     // height: 48,
//         //     fit: BoxFit.fill,
//         //   ),
//         // )
//       ],
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     for (var i = 1; i < int.parse(widget.numOfQuestions) + 1; i++) {
//       ans = [];
//       final val1 = Random().nextInt(int.parse(widget.range1)) + 1;
//       final val2 = Random().nextInt(int.parse(widget.range2)) + 1;
//       final ramImageIndex = Random().nextInt(9);
//       if (widget.operator == 'sum') {
//         questions.add(questionBuild(val1, val2, ramImageIndex, "sum"));
//         answers.add(val1 + val2);
//         ansData = [
//           val1 + val2,
//           val1 + val2 + Random().nextInt(10) + 1,
//           val1 + val2 - Random().nextInt(10) - 1,
//           val1 + val2 + Random().nextInt(16) + 1,
//         ];
//       } else if (widget.operator == 'minus') {
//         questions.add(questionBuild(val1, val2, ramImageIndex, "minus"));
//         answers.add(val1 - val2);
//         ansData = [
//           val1 - val2,
//           val1 - val2 + Random().nextInt(10) + 1,
//           val1 - val2 - Random().nextInt(10) - 1,
//           val1 - val2 + Random().nextInt(16) + 1,
//         ];
//       } else if (widget.operator == 'multiplication') {
//         questions.add('$val1  *  $val2 =  ? ');
//         answers.add(val1 * val2);
//         ansData = [
//           val1 * val2,
//           val1 * val2 + Random().nextInt(10) + 1,
//           val1 * val2 - Random().nextInt(10) - 1,
//           val1 * val2 + Random().nextInt(16) + 1,
//         ];
//       } else {
//         questions.add('$val1  /  $val2 =  ? ');
//         answers.add((val1 / val2).toStringAsFixed(2));
//         ansData = [
//           (val1 / val2).toStringAsFixed(2),
//           (val1 / val2 + Random().nextInt(10) + 1).toStringAsFixed(2),
//           (val1 / val2 - Random().nextInt(10) - 1).toStringAsFixed(2),
//           (val1 / val2 + Random().nextInt(16) + 1).toStringAsFixed(2),
//         ];
//       }
//       for (var j = 0; j < 4; j++) {
//         final rNum = Random().nextInt(ansData.length).round();
//         ans.add(ansData[rNum]);
//         ansData.removeAt(rNum);
//       }
//       mcq.add(ans);
//     }

//     //
//     _animationController =
//         AnimationController(vsync: this, duration: Duration(seconds: 30));
//     _animation = Tween<double>(begin: 30, end: 0).animate(_animationController)
//       ..addListener(() {
//         setState(() {});
//       });
//     _animationController.addStatusListener((status) {
//       if (status == AnimationStatus.completed && !isMarked) {
//         _changeQuestion('TimeOut');
//       }
//     });

//     _animationController.forward();
//     startTimer();
//   }

//   void startTimer() {
//     timer?.cancel();
//     timeLeft = (levelDurations[currentLevel] ??30);
//     _animationController.reset();
//     _animationController.forward();
//     timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (timeLeft > 0) {
//         setState(() {
//           timeLeft--;
//         });
//       } else {
//         timer.cancel();
//         if (!isMarked) {
//           _changeQuestion('TimeOut');
//         }
//       }
//     });
//   }

//   void _changeQuestion(ans) {
//     userAnswer.add(ans);
//     if (j + 1 >= questions.length) {
//       int score = 0;
//       for (var i = 0; i < answers.length; i++) {
//         if (userAnswer[i].toString() == answers[i].toString()) {
//           score++;
//         }
//       }
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => AnswerScreen(
//             maxScore: int.parse(widget.numOfQuestions),
//             score: score,
//             answers: answers,
//             questions: questions,
//             userAnswer: userAnswer,
//           ),
//         ),
//       );
//     } else {
//       setState(() {
//         ++j;
//         isMarked = false;
//       });
//       _animationController =
//           AnimationController(vsync: this, duration: Duration(seconds: 30));
//       _animation =
//           Tween<double>(begin: 30, end: 0).animate(_animationController)
//             ..addListener(() {
//               setState(() {});
//             });
//       startTimer();
//       _controller.restart(duration: (levelDurations[currentLevel] ??30));
//     }
//   }

//   Color valueColorCountdown() {
//     if (timeLeft > (levelDurations[currentLevel] ??30) * 0.6) {
//       return Colors.green;
//     } else if (timeLeft <= (levelDurations[currentLevel] ??30) * 0.6 ||
//         timeLeft <= (levelDurations[currentLevel] ??30) * 0.3) {
//       return Colors.orange;
//     } else {
//       return Colors.red;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     return BaseScaffold(
//       appBar: CustomAppbar.basic(
//         onTap: () => Navigator.pop(context),
//         flexibleSpace: Column(
//           children: [
//             SizedBox(
//               height: 24,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.quiz,
//                         color: Colors.black,
//                         size: 20,
//                       ),
//                       const SizedBox(
//                         width: 8,
//                       ),
//                       Text(
//                         "${j + 1}/${widget.numOfQuestions}",
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     Container(
//                       height: 60,
//                       width: 60,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                       child: CircularProgressIndicator(
//                         value: _animation.value / (levelDurations[currentLevel] ??30),
//                         //color: Colors.amber,
//                         //backgroundColor: Colors.black,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                             valueColorCountdown()),
//                         strokeWidth: 5,
//                       ),
//                     ),
//                     Text("${_animation.value.floor()}")
//                   ],
//                 )
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           // Row(
//           //   mainAxisAlignment: MainAxisAlignment.spaceAround,
//           //   children: [
//           //     Container(
//           //       padding: const EdgeInsets.symmetric(
//           //         horizontal: 16,
//           //         vertical: 12,
//           //       ),
//           //       decoration: BoxDecoration(
//           //         color: Colors.white,
//           //         borderRadius: BorderRadius.circular(20),
//           //       ),
//           //       child: Row(
//           //         children: [
//           //           const Icon(
//           //             Icons.quiz,
//           //             color: Colors.black,
//           //             size: 20,
//           //           ),
//           //           const SizedBox(
//           //             width: 8,
//           //           ),
//           //           Text(
//           //             "${j + 1}/${widget.numOfQuestions}",
//           //             style: const TextStyle(
//           //               color: Colors.black,
//           //               fontSize: 16,
//           //               fontWeight: FontWeight.bold,
//           //             ),
//           //           ),
//           //         ],
//           //       ),
//           //     ),
//           //     Stack(
//           //       alignment: Alignment.center,
//           //       children: [
//           //         Container(
//           //           height: 60,
//           //           width: 60,
//           //           decoration: BoxDecoration(
//           //             color: Colors.white,
//           //             shape: BoxShape.circle,
//           //           ),
//           //           child: CircularProgressIndicator(
//           //             value: _animation.value / (levelDurations[currentLevel] ??30),
//           //             //color: Colors.amber,
//           //             //backgroundColor: Colors.black,
//           //             valueColor:
//           //                 AlwaysStoppedAnimation<Color>(valueColorCountdown()),
//           //             strokeWidth: 5,
//           //           ),
//           //         ),
//           //         Text("${_animation.value.floor()}")
//           //       ],
//           //     )
//           //   ],
//           // ),
//         ],
//       ),
//       //backgroundColor: Colors.white,
//       body: LayoutBuilder(builder: (context, constraint) {
//         return SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//                 minHeight: constraint.maxHeight, minWidth: constraint.minWidth),
//             child: IntrinsicHeight(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   // Row(
//                   //   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   //   children: [
//                   //     Container(
//                   //       padding: const EdgeInsets.symmetric(
//                   //         horizontal: 16,
//                   //         vertical: 12,
//                   //       ),
//                   //       decoration: BoxDecoration(
//                   //         color: Colors.white,
//                   //         borderRadius: BorderRadius.circular(20),
//                   //       ),
//                   //       child: Row(
//                   //         children: [
//                   //           const Icon(
//                   //             Icons.quiz,
//                   //             color: Colors.black,
//                   //             size: 20,
//                   //           ),
//                   //           const SizedBox(
//                   //             width: 8,
//                   //           ),
//                   //           Text(
//                   //             "${j + 1}/${widget.numOfQuestions}",
//                   //             style: const TextStyle(
//                   //               color: Colors.black,
//                   //               fontSize: 16,
//                   //               fontWeight: FontWeight.bold,
//                   //             ),
//                   //           ),
//                   //         ],
//                   //       ),
//                   //     ),
//                   //     Stack(
//                   //       alignment: Alignment.center,
//                   //       children: [
//                   //         Container(
//                   //           height: 60,
//                   //           width: 60,
//                   //           decoration: BoxDecoration(
//                   //             color: Colors.white,
//                   //             shape: BoxShape.circle,
//                   //           ),
//                   //           child: CircularProgressIndicator(
//                   //             value: _animation.value / (levelDurations[currentLevel] ??30),
//                   //             //color: Colors.amber,
//                   //             //backgroundColor: Colors.black,
//                   //             valueColor: AlwaysStoppedAnimation<Color>(
//                   //                 valueColorCountdown()),
//                   //             strokeWidth: 5,
//                   //           ),
//                   //         ),
//                   //         Text("${_animation.value.floor()}")
//                   //       ],
//                   //     )
//                   //   ],
//                   // ),
//                   // CircularCountDownTimer(
//                   //     duration: (levelDurations[currentLevel] ??30),
//                   //     controller: _controller,
//                   //     width: MediaQuery.of(context).size.width > 500
//                   //         ? MediaQuery.of(context).size.width / 10
//                   //         : MediaQuery.of(context).size.width / 6,
//                   //     height: MediaQuery.of(context).size.height / 2,
//                   //     ringColor: Colors.grey[300] ?? Colors.grey,
//                   //     fillColor: baseColor,
//                   //     backgroundColor: Colors.white,
//                   //     strokeWidth: 20.0,
//                   //     textStyle: const TextStyle(
//                   //         fontSize: 33.0,
//                   //         color: baseColorLight,
//                   //         fontWeight: FontWeight.bold),
//                   //     textFormat: CountdownTextFormat.SS,
//                   //     isReverse: true,
//                   //     onStart: () {},
//                   //     onComplete: () {
//                   //       if (!isMarked) {
//                   //         _changeQuestion('TimeOut');
//                   //       }
//                   //     }),
//                   // Text(questions[j].toString(),
//                   //     style: TextStyle(
//                   //         color: baseColor,
//                   //         fontSize:
//                   //             MediaQuery.of(context).size.width > 500 ? 45 : 20,
//                   //         fontWeight: FontWeight.bold)),
//                   questions[j],
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: <Widget>[
//                       GestureDetector(
//                           onTap: () {
//                             _changeQuestion(mcq[j][0].toString());
//                           },
//                           child: QuizButtonIcon(option: mcq[j][0].toString())),
//                       GestureDetector(
//                           onTap: () {
//                             _changeQuestion(mcq[j][1].toString());
//                           },
//                           child: QuizButtonIcon(option: mcq[j][1].toString())),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: <Widget>[
//                       GestureDetector(
//                           onTap: () {
//                             _changeQuestion(mcq[j][2].toString());
//                           },
//                           child: QuizButtonIcon(option: mcq[j][2].toString())),
//                       GestureDetector(
//                           onTap: () {
//                             _changeQuestion(mcq[j][3].toString());
//                           },
//                           child: QuizButtonIcon(option: mcq[j][3].toString())),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }),
//     );
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//     super.dispose();
//   }
// }
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:fun_edu/utils/base_scaffold.dart';
// import 'answer_screen.dart';

// class QuizScreen extends StatefulWidget {
//   const QuizScreen({
//     required this.duration,
//     this.operator = 'sum',
//     super.key,
//     this.numOfQuestions = '5',
//     this.range1 = '5',
//     this.range2 = '5',
//   });

//   final String operator;
//   final String numOfQuestions;
//   final String range1;
//   final int duration;
//   final String range2;

//   @override
//   State<QuizScreen> createState() => _QuizScreenState();
// }

// class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
//   List<dynamic> questions = [];
//   List<dynamic> answers = [];
//   List<dynamic> userAnswer = [];
//   List<List<dynamic>> mcq = [];
//   int j = 0;
//   int score = 0;
//   int energy = 100; // Thanh năng lượng

//   bool isCorrect = false;
//   late AnimationController _animationController;
//   late AnimationController _spaceshipController;
//   final AudioPlayer player = AudioPlayer();

//   final List<IconData> planetIcons = [
//     FontAwesomeIcons.rocket,
//     FontAwesomeIcons.star,
//     FontAwesomeIcons.ghost,
//     FontAwesomeIcons.robot,
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _generateQuestions();
//     _startTimerAnimation();
//     _spaceshipController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//   }

//   void _generateQuestions() {
//     for (var i = 0; i < int.parse(widget.numOfQuestions); i++) {
//       final val1 = Random().nextInt(int.parse(widget.range1)) + 1;
//       final val2 = Random().nextInt(int.parse(widget.range2)) + 1;

//       int correctAnswer = widget.operator == 'sum' ? val1 + val2 : val1 - val2;
//       answers.add(correctAnswer);

//       questions.add('$val1 ${widget.operator == 'sum' ? "+" : "-"} $val2 = ?');

//       List<int> answerOptions = [
//         correctAnswer,
//         correctAnswer + Random().nextInt(3) + 1,
//         correctAnswer - Random().nextInt(3) - 1,
//         correctAnswer + Random().nextInt(5) + 2,
//       ]..shuffle();

//       mcq.add(answerOptions);
//     }
//   }

//   void _startTimerAnimation() {
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(seconds: (levelDurations[currentLevel] ??30)),
//     );
//     _animationController.forward();
//     _animationController.addListener(() {
//       setState(() {});
//       if (_animationController.isCompleted) _changeQuestion("TimeOut");
//     });
//   }

//   void _changeQuestion(String answer) {
//     userAnswer.add(answer);

//     if (j + 1 >= questions.length || energy <= 0) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => AnswerScreen(
//             maxScore: int.parse(widget.numOfQuestions),
//             score: score,
//             answers: answers,
//             questions: questions,
//             userAnswer: userAnswer,
//           ),
//         ),
//       );
//     } else {
//       setState(() {
//         j++;
//         _animationController.reset();
//         _startTimerAnimation();
//       });
//     }
//   }

//   Widget _buildPlanet(int index, int value) {
//     return GestureDetector(
//       onTap: () async {
//         isCorrect = value == answers[j];
//         if (isCorrect) {
//           score++;
//           //player.play(AssetSource('sounds/correct.mp3'));
//           _spaceshipController.forward(from: 0);
//         } else {
//           energy -= 20; // Giảm năng lượng khi sai
//          // player.play(AssetSource('sounds/wrong.mp3'));
//           _spaceshipController.reverse();
//         }
//         await Future.delayed(const Duration(milliseconds: 600));
//         _changeQuestion(value.toString());
//       },
//       child: Container(
//         margin: const EdgeInsets.all(8),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.primaries[index % Colors.primaries.length],
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
//         ),
//         child: FaIcon(
//           planetIcons[index % planetIcons.length],
//           color: Colors.white,
//           size: 30,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BaseScaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.lightBlueAccent, Colors.deepPurple],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Stack(
//           children: [
//             Positioned(
//               top: 60,
//               left: 20,
//               child: Text(
//                 questions[j],
//                 style: const TextStyle(
//                   fontSize: 28,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 40,
//               right: 20,
//               child: Container(
//                 width: 150,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: FractionallySizedBox(
//                   alignment: Alignment.centerLeft,
//                   widthFactor: energy / 100,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.green,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             AnimatedBuilder(
//               animation: _spaceshipController,
//               builder: (context, child) {
//                 return Positioned(
//                   bottom: 80 + _spaceshipController.value * 300,
//                   left: MediaQuery.of(context).size.width / 2 - 50,
//                   child: FaIcon(
//                     FontAwesomeIcons.spaceShuttle,
//                     color: isCorrect ? Colors.yellow : Colors.white,
//                     size: 80,
//                   ),
//                 );
//               },
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: List.generate(mcq[j].length, (index) {
//                   return _buildPlanet(index, mcq[j][index]);
//                 }),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _spaceshipController.dispose();
//     player.dispose();
//     super.dispose();
//   }
import 'dart:async';
import 'dart:math';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'answer_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  List<dynamic> questions = [];
  List<dynamic> answers = [];
  List<dynamic> userAnswer = [];
  List<List<dynamic>> mcq = [];
  int j = 0;
  int score = 0;
  double progress = 0.0;
  int currentLevel = 1; // Level hiện tại
  final Map<int, int> levelQuestions = {
    1: 5,
    2: 10,
    3: 15,
    4: 20
  }; // Số câu hỏi mỗi level
  final Map<int, int> levelDurations = {
    1: 30,
    2: 25,
    3: 20,
    4: 15
  }; // Thời gian tương ứng cho mỗi level
  bool isMarked = false;
  bool isCorrect = false;
  bool isComplete = false;
  late AnimationController _spaceshipController;
  late Animation<double> _spaceshipAnimation;
  late AnimationController _celebrationController;
  final CountDownController _controller = CountDownController();

  //
  late AnimationController _animationController;

  late Animation<double> _animation;
  Timer? timer;
  int timeLeft = 30;
  Color valueColorCountdown() {
    if (timeLeft > (levelDurations[currentLevel] ?? 30) * 0.6) {
      return Colors.green;
    } else if (timeLeft <= (levelDurations[currentLevel] ?? 30) * 0.6 ||
        timeLeft <= (levelDurations[currentLevel] ?? 30) * 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  List<Widget> smallStars = [];
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Future.delayed(const Duration(milliseconds: 500));
    _generateQuestions();
    //_initializeSmallStars();
    _spaceshipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _spaceshipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spaceshipController, curve: Curves.easeInOut),
    );
    int duration =
        levelDurations[currentLevel] ?? 30; // Thời gian theo từng level

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: duration),
    );
    _animation = Tween<double>(begin: 1, end: 0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !isMarked) {
        _changeQuestion('TimeOut');
      }
    });

    _animationController.forward();
    startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSmallStars(); // Gọi hàm tạo ngôi sao nhỏ khi MediaQuery đã sẵn sàng
  }

  void _initializeSmallStars() {
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    smallStars = List.generate(120, (index) {
      return AnimatedSmallStar(
        size: random.nextDouble() * 2 + 4,
        duration: random.nextInt(5000) + 3000,
        position: Offset(
          random.nextDouble() * screenWidth,
          random.nextDouble() * screenHeight,
        ),
      );
    });
  }

  void startTimer() {
    timer?.cancel();
    timeLeft = (levelDurations[currentLevel] ?? 30);
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

  void _generateQuestions() {
    questions.clear();
    answers.clear();
    mcq.clear();

    int numOfQuestions = levelQuestions[currentLevel] ?? 10;
    for (var i = 0; i < numOfQuestions; i++) {
      String randomOperator = Random().nextBool() ? 'sum' : 'sub';
      int val1, val2, correctAnswer;

      if (randomOperator == 'sum') {
        // Tạo phép cộng đảm bảo tổng không vượt quá 9
        do {
          val1 = Random().nextInt(10); // Random từ 0 đến 9
          val2 = Random().nextInt(10); // Random từ 0 đến 9
          correctAnswer = val1 + val2;
        } while (correctAnswer > 9); // Chỉ chấp nhận khi tổng <= 9
      } else {
        // Tạo phép trừ đảm bảo không có kết quả âm
        val1 = Random().nextInt(10); // Random từ 0 đến 9
        val2 = Random()
            .nextInt(val1 + 1); // Random từ 0 đến val1 (đảm bảo không âm)
        correctAnswer = val1 - val2;
      }

      answers.add(correctAnswer);
      questions.add([val1, val2, randomOperator]);

      // Tạo 4 đáp án (bao gồm đáp án đúng và 3 đáp án sai)
      List<int> answerOptions = [
        correctAnswer,
        (correctAnswer + Random().nextInt(3) + 1) % 10,
        (correctAnswer - Random().nextInt(3) - 1).abs(),
        (correctAnswer + Random().nextInt(5) + 2) % 10,
      ]..shuffle();

      mcq.add(answerOptions);
    }
  }

  void _changeQuestion(String answer) {
    userAnswer.add(answer);

    if (j + 1 >= questions.length) {
      if (score == levelQuestions[currentLevel]) {
        if (currentLevel == 4) {
          // Đã hoàn thành tất cả các level
          setState(() {
            isComplete = true;
          });
          _celebrationController.forward();
        } else {
          // Chuyển qua level tiếp theo
          setState(() {
            currentLevel++;
            score = 0;
            progress = 0.0;
            userAnswer.clear();
            j = 0;
            _generateQuestions();
            _controller.restart(
                duration:
                    levelDurations[currentLevel]); // Cập nhật thời gian mới
          });
        }
      } else {
        // Thất bại ở level hiện tại
        setState(() {
          isComplete = true; // Thất bại và hiển thị thông báo cố gắng lại
        });
        _celebrationController.forward();
      }
    } else {
      setState(() {
        j++;
        isMarked = false;
      });
      int duration =
          levelDurations[currentLevel] ?? 30; // Thời gian theo từng level

      _animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: duration),
      );

      _animation = Tween<double>(begin: 1, end: 0).animate(_animationController)
        ..addListener(() {
          setState(() {});
        });
      startTimer();
      _controller.restart(duration: (levelDurations[currentLevel] ?? 30));
    }
  }

// Hàm hiển thị số lượng biểu tượng của câu hỏi
  Widget _buildIcons(int number) {
    return Image.asset(
      'assets/number/$number.png',
      width: 64,
      height: 64,
      fit: BoxFit.cover,
    );
  }

  Widget _buildOption(int value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isCorrect = value == answers[j];
          if (isCorrect) {
            score++;
            progress += 1 / (levelQuestions[currentLevel] ?? 10);
            _spaceshipController.forward(from: 0);
          }
          _changeQuestion(value.toString());
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC)
            ], // Gradient xanh-tím đẹp hơn
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.4), // Border trắng nhẹ bao quanh
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 14,
              spreadRadius: 3,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedScale(
            scale: isCorrect ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildIcons(value),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyBar() {
    double barWidth = MediaQuery.of(context).size.width * 0.65;

    return Padding(
      padding: const EdgeInsets.only(
        top: 4,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🌌 Nút Back
          GestureDetector(
            onTap: () {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              Navigator.pop(context); // Trở lại màn hình chính
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(right: 32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF9013FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle:
                    -pi / 2, // Xoay tên lửa nằm ngang (ngược chiều kim đồng hồ)
                child: const FaIcon(
                  FontAwesomeIcons.rocket,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          // ⚡ Thanh năng lượng
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 36),
              child: Container(
                width: barWidth,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Thanh năng lượng đầy màu
                    AnimatedBuilder(
                      animation: _spaceshipAnimation,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 🌌 Thanh năng lượng
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.green,
                                      Colors.yellow,
                                      Colors.red,
                                    ],
                                  ),
                                ),
                              ),

                              // 🚀 Tên lửa (Đặt trong Stack với Positioned)
                              Positioned(
                                right: -20, // Đẩy tên lửa ra ngoài một chút
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.lightBlueAccent
                                            .withOpacity(0.6),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return const LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.cyanAccent,
                                          Colors.white,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: const FaIcon(
                                      FontAwesomeIcons.shuttleSpace,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // 🌍 Trái đất
                    Positioned(
                      right: -15,
                      top: -28,
                      child: Image.asset(
                        "assets/images/earth.png",
                        width: 96,
                        height: 96,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          // Nền động dễ thương
          _buildAnimatedBackground(),
          if (isComplete) ...[
            _buildCelebrationScreen(),
          ] else ...[
            SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      //crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildEnergyBar(),
                        const SizedBox(height: 8),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "🌟 Level $currentLevel",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 20),
                              _buildCustomCircularProgress(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Câu hỏi nằm ngang
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildIcons(questions[j][0]), // Số đầu tiên
                            const SizedBox(width: 12),
                            Text(
                              questions[j][2] == 'sum' ? "+" : "-",
                              style: const TextStyle(
                                fontSize: 50,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildIcons(questions[j][1]), // Số thứ hai
                            const SizedBox(width: 12),
                            const Text(
                              "= ?",
                              style: TextStyle(
                                fontSize: 50,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Hàng đáp án bên dưới
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: mcq[j]
                              .map((value) => _buildOption(value))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCelebrationScreen() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Opacity(
          opacity: _celebrationController.value,
          child: Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    progress >= 1.0
                        ? FontAwesomeIcons.trophy
                        : FontAwesomeIcons.rocket,
                    color:
                        progress >= 1.0 ? Colors.amber : Colors.lightBlueAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    (score == levelQuestions[currentLevel])
                        ? (currentLevel == 4
                            ? "🎉 Chúc mừng! Bạn đã hoàn thành tất cả Level! 🎉"
                            : "⭐ Hoàn thành Level $currentLevel! Chuẩn bị sang Level ${currentLevel + 1}!")
                        : "🚀 Cố gắng hơn nhé! Thử lại Level $currentLevel!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 🔄 Nút Chơi Lại hoặc Tiếp Tục
                  _buildCustomButton(
                    text: (score == levelQuestions[currentLevel] &&
                            currentLevel == 4)
                        ? "Chơi Lại"
                        : "Thử Lại",
                    icon: FontAwesomeIcons.redo,
                    onTap: () {
                      setState(() {
                        if (score == levelQuestions[currentLevel] &&
                            currentLevel == 4) {
                          currentLevel =
                              1; // Reset lại tất cả nếu hoàn thành hết
                        }
                        score = 0;
                        progress = 0.0;
                        userAnswer.clear();
                        j = 0;
                        _generateQuestions();
                        isComplete = false;
                      });
                      _celebrationController.reset();
                    },
                  ),
                  const SizedBox(height: 20),

                  // ❌ Nút Thoát
                  _buildCustomButton(
                    text: "Thoát",
                    icon: FontAwesomeIcons.doorOpen,
                    onTap: () {
                      SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.edgeToEdge);
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.portraitDown,
                      ]);
                      Navigator.pop(context); // Quay lại màn hình chính
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF9013FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCircularProgress() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.black.withOpacity(0.6),
              Color(0xFF1A2240),
              Color(0xFF3C3B92),
              Color(0xFF5A47B6),
            ],
            radius: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🌌 Vòng sáng bên ngoài
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.blueAccent.withOpacity(0.2),
                    Colors.cyanAccent.withOpacity(0.1),
                  ],
                  radius: 0.8,
                ),
              ),
            ),

            // 🔥 Vòng tròn đếm ngược
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  valueColorCountdown(),
                ),
                backgroundColor: Colors.blueGrey.withOpacity(0.3),
              ),
            ),

            // 🌠 Hiệu ứng ánh sáng xoay nhẹ
            RotationTransition(
              turns: AlwaysStoppedAnimation(
                  _animation.value / (levelDurations[currentLevel] ?? 30)),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      Colors.blueAccent.withOpacity(0.3),
                      Colors.cyanAccent.withOpacity(0.4),
                      Colors.purpleAccent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.6, 0.9, 1.0],
                  ),
                ),
              ),
            ),

            // ⏳ Text hiển thị thời gian còn lại
            Text(
              '${timeLeft}s',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _spaceshipController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A2240), // Xanh đen dịu (Không quá tối - làm nền chính)
            Color(0xFF1E2755), // Xanh đen ánh tím (Tạo chiều sâu vừa phải)
            Color(0xFF3C3B92), // Xanh tím mờ (Ánh sáng vũ trụ dịu nhẹ)
            Color(0xFF5A47B6), // Tím xanh nhạt (Tinh vân sáng hơn)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // 🌌 Nền Gradient đẹp hơn
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A2240),
                  Color(0xFF1E2755),
                  Color(0xFF3C3B92),
                  Color(0xFF5A47B6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🌟 Ngôi sao lấp lánh lớn
          const Positioned(
            bottom: 200,
            right: 200,
            child: AnimatedStar(size: 25, duration: 14000),
          ),
          const Positioned(
            bottom: 120,
            left: 180,
            child: AnimatedStar(size: 22, duration: 12000),
          ),
          const Positioned(
            top: 150,
            left: 60,
            child: AnimatedStar(size: 18, duration: 18000),
          ),
          const Positioned(
            top: 80,
            right: 100,
            child: AnimatedStar(size: 20, duration: 16000),
          ),

          // 🌌 Thêm rất nhiều ngôi sao nhỏ
          ...smallStars,

          // 🌑 Hành tinh di chuyển
          const Positioned(
            top: 100,
            left: -100,
            child: AnimatedPlanet(
              size: 180,
              duration: 40000,
              image: 'assets/images/galaxy.png',
            ),
          ),
          const Positioned(
            bottom: 150,
            right: -120,
            child: AnimatedPlanet(
              size: 220,
              duration: 35000,
              image: 'assets/images/universe.png',
            ),
          ),

          // ☄️ Thiên thạch bay chậm
          const Positioned(
            top: 50,
            right: -100,
            child: AnimatedMeteor(
              size: 100,
              duration: 30000,
              image: 'assets/images/meteor.png',
            ),
          ),

          // 🌠 Sao băng
          const Positioned(
            top: 20,
            left: 50,
            child: AnimatedShootingStar(
              size: 30,
              duration: 12000,
              color: Colors.white,
            ),
          ),
          const Positioned(
            top: 100,
            right: 30,
            child: AnimatedShootingStar(
              size: 25,
              duration: 14000,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedStar extends StatefulWidget {
  final double size;
  final int duration;

  const AnimatedStar({
    Key? key,
    required this.size,
    required this.duration,
  }) : super(key: key);

  @override
  _AnimatedStarState createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Icon(
        Icons.star,
        size: widget.size,
        color: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedPlanet extends StatelessWidget {
  final double size;
  final int duration;
  final String image;

  const AnimatedPlanet({
    Key? key,
    required this.size,
    required this.duration,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: duration),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * 300, 0),
          child: Image.asset(
            image,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class AnimatedMeteor extends StatelessWidget {
  final double size;
  final int duration;
  final String image;

  const AnimatedMeteor({
    Key? key,
    required this.size,
    required this.duration,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: Duration(milliseconds: duration),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * 400, value * 200), // Di chuyển chéo
          child: Image.asset(
            image,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class AnimatedShootingStar extends StatefulWidget {
  final double size;
  final int duration;
  final Color color;

  const AnimatedShootingStar({
    Key? key,
    required this.size,
    required this.duration,
    required this.color,
  }) : super(key: key);

  @override
  _AnimatedShootingStarState createState() => _AnimatedShootingStarState();
}

class _AnimatedShootingStarState extends State<AnimatedShootingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    )..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_controller.value * 400 - 200,
              _controller.value * 150 - 75), // Di chuyển chéo
          child: Icon(
            Icons.star,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedSmallStar extends StatefulWidget {
  final double size;
  final int duration;
  final Offset position;

  const AnimatedSmallStar({
    Key? key,
    required this.size,
    required this.duration,
    required this.position,
  }) : super(key: key);

  @override
  _AnimatedSmallStarState createState() => _AnimatedSmallStarState();
}

class _AnimatedSmallStarState extends State<AnimatedSmallStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _controller,
        child: Icon(
          Icons.circle,
          size: widget.size,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
