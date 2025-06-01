// import 'dart:math';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
// import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
// import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
// import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
// import 'package:fun_edu/widget/menu/portal_master_layout.dart';

// class CompareNumberScreen extends StatefulWidget {
//   const CompareNumberScreen({super.key});

//   @override
//   State<CompareNumberScreen> createState() => _CompareNumberScreenState();
// }

// class _CompareNumberScreenState extends State<CompareNumberScreen> {
//   int? leftNumber;
//   int? rightNumber;
//   String? comparisonSign;
//   List<int> draggableNumbers = [];
//   final List<String> signs = ['>', '<', '='];
//   final FlutterTts flutterTts = FlutterTts();
//   bool isShowingDialog = false;

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     Future.delayed(const Duration(milliseconds: 500));
//     _setupTTS();
//     _generateNumbers();
//     _speakQuestion();
//   }

//   void _setupTTS() async {
//     await flutterTts.setLanguage('vi-VN');
//     await flutterTts.setSpeechRate(0.5);
//     await flutterTts.setVolume(1.0);
//     await flutterTts.setPitch(1.0);
//   }

//   void _speakQuestion() async {
//     String question;
//     if (leftNumber == null && rightNumber == null) {
//       question = "Hãy kéo số vào các ô để hoàn thành phép so sánh!";
//     } else if (leftNumber == null) {
//       question = "Hãy kéo số vào ô bên trái!";
//     } else if (rightNumber == null) {
//       question = "Hãy kéo số vào ô bên phải!";
//     } else if (comparisonSign == null) {
//       question = "Hãy chọn dấu phù hợp để hoàn thành phép so sánh!";
//     } else {
//       question = "Tuyệt vời! Bạn đã hoàn thành phép so sánh!";
//     }
//     await flutterTts.speak(question);
//   }

//   void _generateNumbers() {
//     final random = Random();
//     draggableNumbers = [];
//     Set<int> uniqueNumbers = {};
//     isShowingDialog = false;
//     leftNumber = random.nextInt(10);
//     rightNumber = random.nextInt(10);
//     comparisonSign = random.nextBool() ? null : _getCorrectSign();
//     bool isLeftMissing = random.nextBool();

//     if (comparisonSign == null) {
//       while (uniqueNumbers.length < 4) {
//         uniqueNumbers.add(random.nextInt(10));
//       }
//     } else {
//       if (comparisonSign == '=') {
//         int fixedValue = random.nextInt(10);
//         leftNumber = fixedValue;
//         rightNumber = fixedValue;
//         uniqueNumbers.add(fixedValue);
//         while (uniqueNumbers.length < 4) {
//           int wrong = random.nextInt(10);
//           if (wrong != fixedValue) uniqueNumbers.add(wrong);
//         }
//         if (isLeftMissing) {
//           leftNumber = null;
//         } else {
//           rightNumber = null;
//         }
//       } else {
//         bool isGreaterThan = comparisonSign == '>';
//         int knownNumber;

//         if (isLeftMissing) {
//           rightNumber = _generateKnownNumber(
//               isGreaterThan: isGreaterThan, isKnownRight: true);
//           leftNumber = null;
//           knownNumber = rightNumber!;
//         } else {
//           leftNumber = _generateKnownNumber(
//               isGreaterThan: isGreaterThan, isKnownRight: false);
//           rightNumber = null;
//           knownNumber = leftNumber!;
//         }

//         _generateMissingNumber(
//           knownNumber: knownNumber,
//           isMissingLeft: isLeftMissing,
//           isGreaterThan: isGreaterThan,
//           uniqueNumbers: uniqueNumbers,
//         );
//       }
//     }
//     draggableNumbers = uniqueNumbers.toList()..shuffle();
//     setState(() {});
//   }

//   int _generateKnownNumber(
//       {required bool isGreaterThan, required bool isKnownRight}) {
//     final random = Random();
//     if (isGreaterThan) {
//       return isKnownRight ? random.nextInt(7) : random.nextInt(7) + 3;
//     } else {
//       return isKnownRight ? random.nextInt(7) + 3 : random.nextInt(7);
//     }
//   }

//   void _generateMissingNumber({
//     required int knownNumber,
//     required bool isMissingLeft,
//     required bool isGreaterThan,
//     required Set<int> uniqueNumbers,
//   }) {
//     final random = Random();
//     List<int> correctCandidates = [];
//     List<int> wrongCandidates = [];

//     if (isMissingLeft) {
//       if (isGreaterThan) {
//         correctCandidates = [for (int i = knownNumber + 1; i < 10; i++) i];
//         wrongCandidates = [for (int i = 0; i <= knownNumber; i++) i];
//       } else {
//         correctCandidates = [for (int i = 0; i < knownNumber; i++) i];
//         wrongCandidates = [for (int i = knownNumber; i < 10; i++) i];
//       }
//     } else {
//       if (isGreaterThan) {
//         correctCandidates = [for (int i = 0; i < knownNumber; i++) i];
//         wrongCandidates = [for (int i = knownNumber; i < 10; i++) i];
//       } else {
//         correctCandidates = [for (int i = knownNumber + 1; i < 10; i++) i];
//         wrongCandidates = [for (int i = 0; i <= knownNumber; i++) i];
//       }
//     }

//     if (correctCandidates.isEmpty) correctCandidates = wrongCandidates;

//     int correct = correctCandidates[random.nextInt(correctCandidates.length)];
//     uniqueNumbers.add(correct);
//     wrongCandidates.remove(correct);
//     wrongCandidates.shuffle();

//     for (int wrong in wrongCandidates) {
//       uniqueNumbers.add(wrong);
//       if (uniqueNumbers.length >= 4) break;
//     }
//   }

//   String _getCorrectSign() {
//     if (leftNumber == null || rightNumber == null) return '?';
//     if (leftNumber! > rightNumber!) return '>';
//     if (leftNumber! < rightNumber!) return '<';
//     return '=';
//   }

//   bool _checkCorrectness() {
//     if (leftNumber == null || rightNumber == null || comparisonSign == null) {
//       return false;
//     }
//     if (comparisonSign == '>') return leftNumber! > rightNumber!;
//     if (comparisonSign == '<') return leftNumber! < rightNumber!;
//     if (comparisonSign == '=') return leftNumber == rightNumber;
//     return false;
//   }

//   Widget _buildAnimatedBackground() {
//     return Stack(
//       children: [
//         Positioned(
//             top: 40,
//             left: 10,
//             child: AnimatedCloud(
//                 size: 100,
//                 color: Colors.white.withOpacity(0.4),
//                 duration: 25000)),
//         Positioned(
//             top: 100,
//             right: 50,
//             child: AnimatedCloud(
//                 size: 130,
//                 color: Colors.white.withOpacity(0.5),
//                 duration: 30000)),
//         Positioned(
//             bottom: 150,
//             left: 40,
//             child: AnimatedCloud(
//                 size: 90,
//                 color: Colors.white.withOpacity(0.6),
//                 duration: 20000)),
//         const Positioned(
//             top: 300,
//             left: 40,
//             child: AnimatedButterfly(size: 40, duration: 16000)),
//         const Positioned(
//             bottom: 0,
//             left: 40,
//             child:
//                 AnimatedBalloon(color: Colors.red, size: 60, duration: 12000)),
//         const Positioned(
//             bottom: 0,
//             right: 40,
//             child:
//                 AnimatedBalloon(color: Colors.blue, size: 50, duration: 10000)),
//         const Positioned(
//             bottom: 200,
//             right: 200,
//             child: AnimatedStar(size: 25, duration: 14000)),
//         const Positioned(
//             bottom: 120,
//             left: 180,
//             child: AnimatedStar(size: 22, duration: 12000)),
//       ],
//     );
//   }

//   Widget _buildTopButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         IconButton(
//           icon: const Icon(FontAwesomeIcons.rotate),
//           onPressed: () {
//             _generateNumbers();
//             _speakQuestion();
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildComparisonSigns() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: signs.map((sign) {
//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               comparisonSign = sign;
//             });
//             if (_checkCorrectness()) {
//               _generateNumbers();
//               _speakQuestion();
//             } else {
//               comparisonSign = null;
//             }
//           },
//           child: Container(
//             margin: const EdgeInsets.all(8),
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.green,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               sign,
//               style: const TextStyle(fontSize: 36, color: Colors.white),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildNumberRow() {
//     return Wrap(
//       spacing: 16,
//       children: draggableNumbers.map((number) {
//         return Draggable<int>(
//           data: number,
//           feedback: _buildNumberWidget(number, true),
//           childWhenDragging: _buildNumberWidget(null, false),
//           child: _buildNumberWidget(number, false),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildNumberWidget(int? number, bool isDragging) {
//     return Container(
//       height: 70,
//       width: 70,
//       decoration: BoxDecoration(
//         color: number == null ? Colors.grey[300] : Colors.lightBlue,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       alignment: Alignment.center,
//       child: Text(
//         number?.toString() ?? '',
//         style: TextStyle(
//             fontSize: 32, color: isDragging ? Colors.white : Colors.black),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: kIsWeb ? PortalMasterLayout(body: _buildBody()) : _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     return Stack(
//       children: [
//         _buildAnimatedBackground(),
//         SafeArea(
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               _buildTopButtons(),
//               const SizedBox(height: 20),
//               _buildTopRow(),
//               const SizedBox(height: 30),
//               if (!isShowingDialog)
//                 comparisonSign == null
//                     ? _buildComparisonSigns()
//                     : _buildNumberRow(),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTopRow() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildNumberTile(leftNumber, index: 0),
//         Text(
//           comparisonSign ?? '?',
//           style: const TextStyle(fontSize: 50),
//         ),
//         _buildNumberTile(rightNumber, index: 1),
//       ],
//     );
//   }

//   Widget _buildNumberTile(int? number, {required int index}) {
//     return DragTarget<int>(
//       builder: (context, candidateData, rejectedData) {
//         return Container(
//           height: 100,
//           width: 100,
//           margin: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: number == null ? Colors.grey[300] : Colors.orange,
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(color: Colors.blueAccent, width: 3),
//           ),
//           child: Center(
//             child: Text(
//               number?.toString() ?? '?',
//               style: TextStyle(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: number == null ? Colors.black54 : Colors.white),
//             ),
//           ),
//         );
//       },
//       onWillAccept: (value) => number == null,
//       onAccept: (value) {
//         setState(() {
//           if (index == 0) leftNumber = value;
//           if (index == 1) rightNumber = value;
//         });

//         if (_checkCorrectness()) {
//           _speakQuestion();
//           _generateNumbers();
//         } else {
//           if (index == 0) leftNumber = null;
//           if (index == 1) rightNumber = null;
//         }
//       },
//     );
//   }
// }

////////////////////
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';

class CompareNumberScreen extends StatefulWidget {
  const CompareNumberScreen({super.key});

  @override
  State<CompareNumberScreen> createState() => _CompareNumberScreenState();
}

class _CompareNumberScreenState extends State<CompareNumberScreen> {
  int? leftNumber;
  int? rightNumber;
  String? comparisonSign;
  List<int> draggableNumbers = [];
  final List<String> signs = ['>', '<', '='];
  final FlutterTts flutterTts = FlutterTts();
  bool isShowingDialog = false;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Future.delayed(const Duration(milliseconds: 500));
    _setupTTS();
    _generateNumbers();
    _speakQuestion();
  }

  void _setupTTS() async {
    await flutterTts.setLanguage('vi-VN');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void _speakQuestion() async {
    String question;
    if (leftNumber == null && rightNumber == null) {
      question = "Hãy kéo số vào các ô để hoàn thành phép so sánh!";
    } else if (leftNumber == null) {
      question = "Hãy kéo số vào ô bên trái!";
    } else if (rightNumber == null) {
      question = "Hãy kéo số vào ô bên phải!";
    } else if (comparisonSign == null) {
      question = "Hãy chọn dấu phù hợp để hoàn thành phép so sánh!";
    } else {
      question = "Tuyệt vời! Bạn đã hoàn thành phép so sánh!";
    }
    await flutterTts.speak(question);
  }

  void _generateNumbers() {
    final random = Random();
    draggableNumbers = [];
    Set<int> uniqueNumbers = {};
    isShowingDialog = false;
    leftNumber = random.nextInt(10);
    rightNumber = random.nextInt(10);
    comparisonSign = random.nextBool() ? null : _getCorrectSign();
    bool isLeftMissing = random.nextBool();

    if (comparisonSign == null) {
      while (uniqueNumbers.length < 4) {
        uniqueNumbers.add(random.nextInt(10));
      }
    } else {
      if (comparisonSign == '=') {
        // Trường hợp dấu "="
        int fixedValue = random.nextInt(10);
        leftNumber = fixedValue;
        rightNumber = fixedValue;
        uniqueNumbers.add(fixedValue);
        while (uniqueNumbers.length < 4) {
          int wrong = random.nextInt(10);
          if (wrong != fixedValue) uniqueNumbers.add(wrong);
        }
        if (isLeftMissing) {
          leftNumber = null;
        } else {
          rightNumber = null;
        }
      } else {
        // Trường hợp dấu ">" hoặc "<"
        bool isGreaterThan = comparisonSign == '>';
        int knownNumber;

        if (isLeftMissing) {
          // left ? right → right là known
          rightNumber = _generateKnownNumber(
              isGreaterThan: isGreaterThan, isKnownRight: true);
          leftNumber = null;
          knownNumber = rightNumber!;
        } else {
          // left ? right → left là known
          leftNumber = _generateKnownNumber(
              isGreaterThan: isGreaterThan, isKnownRight: false);
          rightNumber = null;
          knownNumber = leftNumber!;
        }

        generateMissingNumber(
          knownNumber: knownNumber,
          isMissingLeft: isLeftMissing,
          isGreaterThan: isGreaterThan,
          uniqueNumbers: uniqueNumbers,
        );
      }
    }
    draggableNumbers = uniqueNumbers.toList()..shuffle();
    setState(() {});
  }

  int _generateKnownNumber(
      {required bool isGreaterThan, required bool isKnownRight}) {
    final random = Random();
    if (isGreaterThan) {
      // cần known < missing
      return isKnownRight
          ? random
              .nextInt(7) // right < left → right ∈ [0,6] ⇒ left ∈ [right+1,9]
          : random.nextInt(7) + 3; // left là known ≥ 3 ⇒ right ∈ [0, left-1]
    } else {
      // cần known > missing
      return isKnownRight
          ? random.nextInt(7) + 3 // right ≥ 3 ⇒ left ∈ [0, right-1]
          : random.nextInt(7); // left ∈ [0,6] ⇒ right ∈ [left+1, 9]
    }
  }

  void generateMissingNumber({
    required int knownNumber,
    required bool isMissingLeft,
    required bool isGreaterThan,
    required Set<int> uniqueNumbers,
  }) {
    final random = Random();
    List<int> correctCandidates = [];
    List<int> wrongCandidates = [];

    if (isMissingLeft) {
      if (isGreaterThan) {
        correctCandidates = [for (int i = knownNumber + 1; i < 10; i++) i];
        wrongCandidates = [for (int i = 0; i <= knownNumber; i++) i];
      } else {
        correctCandidates = [for (int i = 0; i < knownNumber; i++) i];
        wrongCandidates = [for (int i = knownNumber; i < 10; i++) i];
      }
    } else {
      if (isGreaterThan) {
        correctCandidates = [for (int i = 0; i < knownNumber; i++) i];
        wrongCandidates = [for (int i = knownNumber; i < 10; i++) i];
      } else {
        correctCandidates = [for (int i = knownNumber + 1; i < 10; i++) i];
        wrongCandidates = [for (int i = 0; i <= knownNumber; i++) i];
      }
    }

    if (correctCandidates.isEmpty) {
      correctCandidates = wrongCandidates;
    }

    int correct = correctCandidates[random.nextInt(correctCandidates.length)];
    uniqueNumbers.add(correct);

    wrongCandidates.remove(correct);
    wrongCandidates.shuffle();

    for (int wrong in wrongCandidates) {
      uniqueNumbers.add(wrong);
      if (uniqueNumbers.length >= 4) break;
    }

    // while (uniqueNumbers.length < 4) {
    //   uniqueNumbers.add(random.nextInt(10));
    // }
  }

  String _getCorrectSign() {
    if (leftNumber == null || rightNumber == null) return '?';
    if (leftNumber! > rightNumber!) return '>';
    if (leftNumber! < rightNumber!) return '<';
    return '=';
  }

  bool _checkCorrectness() {
    if (leftNumber == null || rightNumber == null || comparisonSign == null) {
      return false;
    }
    if (comparisonSign == '>') return leftNumber! > rightNumber!;
    if (comparisonSign == '<') return leftNumber! < rightNumber!;
    if (comparisonSign == '=') return leftNumber == rightNumber;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kIsWeb ? PortalMasterLayout(body: _buildBody()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildAnimatedBackground(),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTopButtons(),
              const SizedBox(height: 20),
              _buildTopRow(),
              const SizedBox(height: 30),
              if (!isShowingDialog)
                comparisonSign == null
                    ? _buildComparisonSigns()
                    : _buildNumberRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNumberTile(leftNumber, index: 0),
        _buildComparisonTile(),
        _buildNumberTile(rightNumber, index: 1),
      ],
    );
  }

  Widget _buildNumberTile(int? number, {required int index}) {
    return DragTarget<int>(
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 100,
          width: 100,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: number == null ? Colors.grey[300] : Colors.orange,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.blueAccent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number?.toString() ?? '?',
              style: TextStyle(
                fontSize: number == null ? 50 : 40,
                fontWeight: FontWeight.bold,
                color: number == null ? Colors.black54 : Colors.white,
              ),
            ),
          ),
        );
      },
      onWillAccept: (value) => number == null,
      onAccept: (value) {
        setState(() {
          if (index == 0) leftNumber = value;
          if (index == 1) rightNumber = value;
        });

        if (_checkCorrectness()) {
          _showCongratsDialog(context);
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
            Future.delayed(Duration(milliseconds: 500));
            setState(() {
              isShowingDialog = false;
            });
            _generateNumbers();
            _speakQuestion();
          });
        } else {
          _showWrongDialog(context);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
              Future.delayed(Duration(milliseconds: 500));
              setState(() {
                isShowingDialog = false;
              });
              _resetDraggedItems(
                  resetNumber: true, index: index); // Chỉ reset số sai
            }
          });
        }
      },
    );
  }

  Widget _buildComparisonTile() {
    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 100,
          width: 100,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: comparisonSign == null
                ? Colors.grey[300]
                : Colors.lightBlueAccent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.pinkAccent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              comparisonSign ?? '?',
              style: TextStyle(
                fontSize: comparisonSign == null ? 50 : 40,
                fontWeight: FontWeight.bold,
                color: comparisonSign == null ? Colors.black54 : Colors.white,
              ),
            ),
          ),
        );
      },
      onWillAccept: (value) => comparisonSign == null,
      onAccept: (value) {
        setState(() {
          comparisonSign = value;
        });
        Future.delayed(const Duration(milliseconds: 500), () {});
        if (_checkCorrectness()) {
          _showCongratsDialog(context);
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
            setState(() {
              isShowingDialog = true;
            });
            _generateNumbers();
            _speakQuestion();
          });
        } else {
          _showWrongDialog(context);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
              setState(() {
                isShowingDialog = true;
              });
              _resetDraggedItems(resetSignOnly: true); // Chỉ reset dấu sai
            }
          });
        }
      },
    );
  }

  Widget _buildComparisonSigns() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: signs.map((sign) {
        return Draggable<String>(
          data: sign,
          feedback: Material(
            color: Colors.transparent,
            child: _buildDraggableBox(sign, Colors.deepPurpleAccent),
          ),
          childWhenDragging: const SizedBox.shrink(),
          child: _buildDraggableBox(sign, Colors.deepPurpleAccent),
        );
      }).toList(),
    );
  }

  Widget _buildNumberRow() {
    final List<Color> colors = [
      Colors.redAccent,
      Colors.green,
      Colors.blue,
      Colors.purple
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(draggableNumbers.length, (index) {
        int number = draggableNumbers[index];
        Color color = colors[index % colors.length];
        return Draggable<int>(
          data: number,
          feedback: Material(
            color: Colors.transparent,
            child: _buildDraggableBox(number.toString(), color),
          ),
          childWhenDragging: const SizedBox.shrink(),
          child: _buildDraggableBox(number.toString(), color),
        );
      }),
    );
  }

  Widget _buildDraggableBox(String text, Color color) {
    return Container(
      height: 90,
      width: 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!kIsWeb)
            _buildNavButton(FontAwesomeIcons.house, "Trang Chủ", Colors.red,
                () => Navigator.pop(context)),
          Row(
            children: [
              _buildNavButton(
                  Icons.volume_up, "Nghe", Colors.pink, _speakQuestion),
              const SizedBox(width: 20),
              _buildNavButton(FontAwesomeIcons.arrowsRotate, "Đổi Câu",
                  Colors.blue, _generateNumbers),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.4), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FaIcon(icon, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2F5EA), Color(0xFF81E6D9), Color(0xFF7FDBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
              top: 40,
              left: 10,
              child: AnimatedCloud(
                  size: 100,
                  color: Colors.white.withOpacity(0.4),
                  duration: 25000)),
          Positioned(
              top: 100,
              right: 50,
              child: AnimatedCloud(
                  size: 130,
                  color: Colors.white.withOpacity(0.5),
                  duration: 30000)),
          Positioned(
              bottom: 150,
              left: 40,
              child: AnimatedCloud(
                  size: 90,
                  color: Colors.white.withOpacity(0.6),
                  duration: 20000)),
          const Positioned(
              top: 300,
              left: 40,
              child: AnimatedButterfly(size: 40, duration: 16000)),
          const Positioned(
              bottom: 0,
              left: 40,
              child: AnimatedBalloon(
                  color: Colors.red, size: 60, duration: 12000)),
          const Positioned(
              bottom: 0,
              right: 40,
              child: AnimatedBalloon(
                  color: Colors.blue, size: 50, duration: 10000)),
          const Positioned(
              bottom: 200,
              right: 200,
              child: AnimatedStar(size: 25, duration: 14000)),
          const Positioned(
              bottom: 120,
              left: 180,
              child: AnimatedStar(size: 22, duration: 12000)),
        ],
      ),
    );
  }

  void checkCompletion(BuildContext context) {
    if (_checkCorrectness()) {
      _showCongratsDialog(context);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
        _generateNumbers();
        _speakQuestion();
      });
    } else {
      _showWrongDialog(context);

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
        _resetDraggedItems();
      });
    }
  }

  void _resetDraggedItems({
    bool resetSignOnly = false,
    bool resetNumber = false,
    int? index,
  }) {
    setState(() {
      if (resetSignOnly) {
        // ❌ Chỉ reset dấu nếu sai
        if (comparisonSign != _getCorrectSign()) {
          comparisonSign = null;
          debugPrint("Resetting Comparison Sign.");
        }
      } else if (resetNumber && index != null) {
        // ❌ Chỉ reset số được kéo sai theo `index`
        if (index == 0 && leftNumber != null) {
          debugPrint("Resetting Left Number: $leftNumber");
          leftNumber = null;
        }
        if (index == 1 && rightNumber != null) {
          debugPrint("Resetting Right Number: $rightNumber");
          rightNumber = null;
        }
      } else {
        // ❌ Reset toàn bộ nếu cần
        if (comparisonSign != _getCorrectSign()) {
          comparisonSign = null;
          debugPrint("Resetting Comparison Sign.");
        }

        if (leftNumber != null && !_checkCorrectness()) {
          debugPrint("Resetting Left Number: $leftNumber");
          leftNumber = null;
        }

        if (rightNumber != null && !_checkCorrectness()) {
          debugPrint("Resetting Right Number: $rightNumber");
          rightNumber = null;
        }
      }
      isShowingDialog = false;
    });
  }

  void _showCongratsDialog(BuildContext context) async {
    setState(() {
      isShowingDialog = true;
    });
    Future.delayed(
      const Duration(milliseconds: 500),
    );
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/excellent.png',
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 16),
            const Text(
              "Chúc mừng! Bạn đã sắp xếp đúng!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWrongDialog(BuildContext context) async {
    setState(() {
      isShowingDialog = true;
    });
    Future.delayed(
      const Duration(milliseconds: 500),
    );
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/wrong.png',
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 16),
            const Text(
              "Cùng thử lại nhé!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Trả lại chế độ quay dọc khi thoát màn hình
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
