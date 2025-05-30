import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';

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
        bool isGreaterThan = comparisonSign == '>';
        int knownNumber;

        if (isLeftMissing) {
          rightNumber = _generateKnownNumber(
              isGreaterThan: isGreaterThan, isKnownRight: true);
          leftNumber = null;
          knownNumber = rightNumber!;
        } else {
          leftNumber = _generateKnownNumber(
              isGreaterThan: isGreaterThan, isKnownRight: false);
          rightNumber = null;
          knownNumber = leftNumber!;
        }

        _generateMissingNumber(
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
      return isKnownRight ? random.nextInt(7) : random.nextInt(7) + 3;
    } else {
      return isKnownRight ? random.nextInt(7) + 3 : random.nextInt(7);
    }
  }

  void _generateMissingNumber({
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

    if (correctCandidates.isEmpty) correctCandidates = wrongCandidates;

    int correct = correctCandidates[random.nextInt(correctCandidates.length)];
    uniqueNumbers.add(correct);
    wrongCandidates.remove(correct);
    wrongCandidates.shuffle();

    for (int wrong in wrongCandidates) {
      uniqueNumbers.add(wrong);
      if (uniqueNumbers.length >= 4) break;
    }
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

  Widget _buildAnimatedBackground() {
    return Stack(
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
            child:
                AnimatedBalloon(color: Colors.red, size: 60, duration: 12000)),
        const Positioned(
            bottom: 0,
            right: 40,
            child:
                AnimatedBalloon(color: Colors.blue, size: 50, duration: 10000)),
        const Positioned(
            bottom: 200,
            right: 200,
            child: AnimatedStar(size: 25, duration: 14000)),
        const Positioned(
            bottom: 120,
            left: 180,
            child: AnimatedStar(size: 22, duration: 12000)),
      ],
    );
  }

  Widget _buildTopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(FontAwesomeIcons.rotate),
          onPressed: () {
            _generateNumbers();
            _speakQuestion();
          },
        ),
      ],
    );
  }

  Widget _buildComparisonSigns() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: signs.map((sign) {
        return GestureDetector(
          onTap: () {
            setState(() {
              comparisonSign = sign;
            });
            if (_checkCorrectness()) {
              _generateNumbers();
              _speakQuestion();
            } else {
              comparisonSign = null;
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sign,
              style: const TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberRow() {
    return Wrap(
      spacing: 16,
      children: draggableNumbers.map((number) {
        return Draggable<int>(
          data: number,
          feedback: _buildNumberWidget(number, true),
          childWhenDragging: _buildNumberWidget(null, false),
          child: _buildNumberWidget(number, false),
        );
      }).toList(),
    );
  }

  Widget _buildNumberWidget(int? number, bool isDragging) {
    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color: number == null ? Colors.grey[300] : Colors.lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        number?.toString() ?? '',
        style: TextStyle(
            fontSize: 32, color: isDragging ? Colors.white : Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNumberTile(leftNumber, index: 0),
        Text(
          comparisonSign ?? '?',
          style: const TextStyle(fontSize: 50),
        ),
        _buildNumberTile(rightNumber, index: 1),
      ],
    );
  }

  Widget _buildNumberTile(int? number, {required int index}) {
    return DragTarget<int>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 100,
          width: 100,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: number == null ? Colors.grey[300] : Colors.orange,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.blueAccent, width: 3),
          ),
          child: Center(
            child: Text(
              number?.toString() ?? '?',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: number == null ? Colors.black54 : Colors.white),
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
          _speakQuestion();
          _generateNumbers();
        } else {
          if (index == 0) leftNumber = null;
          if (index == 1) rightNumber = null;
        }
      },
    );
  }
}
