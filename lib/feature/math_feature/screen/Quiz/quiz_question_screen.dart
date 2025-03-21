import 'package:design_system_sl/design_system_sl.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/app_colors.dart';
import 'package:fun_edu/helper/pref.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/colorConst.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/utils/extension.dart';
import 'package:fun_edu/widget/MainScreenCard.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'quiz_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({
    super.key,
    this.icon = Icons.add,
    this.operator = 'sum',
  });
  final IconData icon;
  final String operator;

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ques = TextEditingController();

  final TextEditingController _range1 = TextEditingController();

  final TextEditingController _range2 = TextEditingController();
  var time = 30;
  final List<int> lists = [5, 10, 15, 20, 25, 30];
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        isLeading: true,
        title: "Phép tính",
        styleTitle: TextStyle(color: Theme.of(context).lightTextColor),
        onTap: () => Navigator.pop(context),
      ),
      body: Center(
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: SingleChildScrollView(
            physics: const ScrollPhysics(parent: ScrollPhysics()),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: widget.icon,
                  child: Icon(
                    widget.icon,
                    size: 70,
                    color: baseColor,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MainScreenCard(
                          ques: _ques,
                          icon: widget.icon,
                          max: 3,
                          label: 'Số câu hỏi',
                          maxValue: 100,
                          hint: '20'),
                      MainScreenCard(
                          ques: _range1,
                          icon: widget.icon,
                          max: 5,
                          label: 'Giá trị tối đa toán tử thứ nhất',
                          hint: '20'),
                      MainScreenCard(
                          ques: _range2,
                          icon: widget.icon,
                          max: 5,
                          label: 'Giá trị tối đa toán tử thứ hai',
                          hint: '55'),
                    ],
                  ),
                ),
                const Row(
                  children: [
                    Text('Thời gian', style: TextStyle(fontSize: 16)),
                    SizedBox(
                      width: 8,
                    ),
                    Icon(Icons.watch_later_outlined),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Container(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: DropdownSearch<int>(
                    items: lists,
                    popupProps: PopupProps.menu(
                        showSearchBox: false,
                        searchFieldProps: TextFieldProps(
                            style: PrimaryFont.medium(13)
                                .copyWith(color: AppColors.greyColor)),
                        itemBuilder: (context, item, _) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("${item}s",
                                style: PrimaryFont.medium(13)
                                    .copyWith(color: AppColors.greyColor)),
                          );
                        }),
                    clearButtonProps: const ClearButtonProps(isVisible: false),
                    //  selectedItem: lists.first,
                    dropdownBuilder: (context, item) {
                      return Text(
                        item != null ? "${item}s" : "10s",
                        style: PrimaryFont.medium(13)
                            .copyWith(color: AppColors.greyColor),
                      );
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        suffixIconColor:
                            Pref.isDarkMode ? Colors.black : Colors.white,
                        contentPadding:
                            const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        border: InputBorder.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        time = value ?? 10;
                      });
                    },
                  ),
                ),
                // ExpansionTile(
                //   title: const Text('Time'),
                //   childrenPadding: const EdgeInsets.fromLTRB(30, 2, 30, 10),
                //   leading: const Icon(Icons.watch_later_rounded),
                //   trailing: Text('${time.toString()}s'),
                //   children: [
                //     ListTile(
                //       title: const Text('5s'),
                //       onTap: () {
                //         setState(() {
                //           time = 5;
                //         });
                //       },
                //     ),
                //     ListTile(
                //       title: const Text('10s'),
                //       onTap: () {
                //         setState(() {
                //           time = 10;
                //         });
                //       },
                //     ),
                //     ListTile(
                //       title: const Text('15s'),
                //       onTap: () {
                //         setState(() {
                //           time = 15;
                //         });
                //       },
                //     ),
                //     ListTile(
                //       title: const Text('20s'),
                //       onTap: () {
                //         setState(() {
                //           time = 20;
                //         });
                //       },
                //     ),
                //   ],
                // ),
                const SizedBox(
                  height: 30,
                ),
                MaterialButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => QuizScreen(
                               )),
                      );
                    }
                  },
                  elevation: 20,
                  color: baseColor,
                  child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Tạo Quiz',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w600))),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
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
//     timeLeft = widget.duration;
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
//       _controller.restart(duration: widget.duration);
//     }
//   }

//   Color valueColorCountdown() {
//     if (timeLeft > widget.duration * 0.6) {
//       return Colors.green;
//     } else if (timeLeft <= widget.duration * 0.6 ||
//         timeLeft <= widget.duration * 0.3) {
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
//                         value: _animation.value / widget.duration,
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
//           //             value: _animation.value / widget.duration,
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
//                   //             value: _animation.value / widget.duration,
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
//                   //     duration: widget.duration,
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