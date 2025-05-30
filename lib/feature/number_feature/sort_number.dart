import 'dart:math';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
import 'package:go_router/go_router.dart';

class SortNumber extends StatefulWidget {
  const SortNumber({super.key});

  @override
  State<SortNumber> createState() => _SortNumberState();
}

class _SortNumberState extends State<SortNumber> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer player = AudioPlayer();
  List<int> numbers = [];
  List<int> sortedNumbers = [];
  List<int?> placedNumbers = [];
  bool isAscendingOrder = true;
  final Set<int> usedNumbers = {};
  final Set<int> preFilledIndexes = {};
  int? selectedDropIndex;

  @override
  void initState() {
    super.initState();
    // Thiết lập quay ngang và chế độ fullscreen immersiveSticky
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Future.delayed(const Duration(milliseconds: 500));
    _generateNumbers();
    _speakInstruction();
  }

  Future<void> _playSound(String fileName) async {
    await player.setSource(AssetSource('audio/$fileName.wav'));
    await player.resume();
  }

  Future<void> _speakInstruction() async {
    await flutterTts.setLanguage('vi-VN');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    String direction = isAscendingOrder ? 'tăng dần' : 'giảm dần';
    await flutterTts.speak('Hãy sắp xếp theo thứ tự $direction.');
  }

  void _generateNumbers() {
    final random = Random();
    numbers = [];
    usedNumbers.clear();
    preFilledIndexes.clear();

    while (numbers.length < 6) {
      int num = random.nextInt(10);
      if (!numbers.contains(num)) numbers.add(num);
    }

    sortedNumbers = List.from(numbers)..sort();
    isAscendingOrder = random.nextBool();

    if (!isAscendingOrder) sortedNumbers = sortedNumbers.reversed.toList();

    placedNumbers = List.filled(6, null);
    Set<int> emptyIndexes = {};
    while (emptyIndexes.length < random.nextInt(3) + 2) {
      emptyIndexes.add(random.nextInt(6));
    }

    for (int index in emptyIndexes) {
      placedNumbers[index] = sortedNumbers[index];
      preFilledIndexes.add(index);
    }

    numbers =
        sortedNumbers.where((num) => !placedNumbers.contains(num)).toList();
    setState(() {});
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
                Expanded(child: _buildGameBoard()),
              ],
            ),
          ),
        ],
      ),
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
          // Moving Clouds
          Positioned(
            top: 40,
            left: 10,
            child: AnimatedCloud(
              size: 100,
              color: Colors.white.withOpacity(0.4),
              duration: 25000,
            ),
          ),
          Positioned(
            top: 100,
            right: 50,
            child: AnimatedCloud(
              size: 130,
              color: Colors.white.withOpacity(0.5),
              duration: 30000,
            ),
          ),
          Positioned(
            bottom: 150,
            left: 40,
            child: AnimatedCloud(
              size: 90,
              color: Colors.white.withOpacity(0.6),
              duration: 20000,
            ),
          ),

          // Flying Butterflies
          const Positioned(
            top: 300,
            left: 40,
            child: AnimatedButterfly(size: 40, duration: 16000),
          ),

          // Floating Balloons (Spread out more)
          const Positioned(
            bottom: 0,
            left: 40,
            child:
                AnimatedBalloon(color: Colors.red, size: 60, duration: 12000),
          ),
          const Positioned(
            bottom: 0,
            right: 40,
            child:
                AnimatedBalloon(color: Colors.blue, size: 50, duration: 10000),
          ),

          // Sparkling Particles (More scattered)

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
        ],
      ),
    );
  }

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildNavButton(FontAwesomeIcons.house, "Về Trang Chủ", Colors.red,
              () => context.pop(context)),
          const SizedBox(
            width: 12,
          ),
          _buildQuestionSection(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildNavButton(
                    Icons.volume_up, "Nghe", Colors.pink, _speakInstruction),
                const SizedBox(width: 20),
                _buildNavButton(FontAwesomeIcons.arrowsRotate, "Đổi Câu Hỏi",
                    Colors.blue, _generateNumbers),
              ],
            ),
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
                  blurRadius: 12,
                  spreadRadius: 2,
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

  Widget _buildQuestionSection() {
    return Text(
      "Sắp xếp theo thứ tự: ${isAscendingOrder ? 'Tăng dần 🔼' : 'Giảm dần 🔽'}",
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
  }

  Widget _buildGameBoard() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(child: _buildDraggableNumbers()),
          Expanded(child: _buildDropTargets()),
        ],
      ),
    );
  }

  Widget _buildDraggableNumbers() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: numbers.map((number) => _buildDraggable(number)).toList(),
      ),
    );
  }

  Widget _buildDraggable(int number) {
    if (usedNumbers.contains(number)) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (selectedDropIndex != null &&
            placedNumbers[selectedDropIndex!] == null) {
          setState(() {
            placedNumbers[selectedDropIndex!] = number;
            usedNumbers.add(number);
            selectedDropIndex = null;
          });
          _checkCompletion(context);
        }
      },
      child: Draggable<int>(
        data: number,
        feedback: _buildStyledNumber(number),
        childWhenDragging: Opacity(
          opacity: 0.4,
          child: _buildStyledNumber(number),
        ),
        child: _buildStyledNumber(number),
      ),
    );
  }

  Widget _buildStyledNumber(int number) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.yellow.shade300,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildDropTargets() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          return Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!preFilledIndexes.contains(index) &&
                      placedNumbers[index] == null) {
                    setState(() {
                      selectedDropIndex =
                          selectedDropIndex == index ? null : index;
                    });
                  }
                },
                child: DragTarget<int>(
                  builder: (context, candidateData, rejectedData) {
                    bool isAccepted = candidateData.isNotEmpty;
                    bool isSelected = selectedDropIndex == index;
                    return SizedBox(
                      width: 100,
                      height: 130,
                      child: LayoutBuilder(builder: (context, constraints) {
                        double cellSize = constraints.maxWidth;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: cellSize,
                          width: cellSize,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAccepted
                                ? Colors.greenAccent
                                : isSelected
                                    ? Colors.greenAccent
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                          child: placedNumbers[index] != null
                              ? _buildStyledNumber(placedNumbers[index]!)
                              : const Center(
                                  child: Text(
                                    "?",
                                    style: TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        );
                      }),
                    );
                  },
                  onWillAccept: (value) => placedNumbers[index] == null,
                  onAccept: (number) {
                    setState(() {
                      placedNumbers[index] = number;
                      usedNumbers.add(number);
                      selectedDropIndex = null;
                    });
                    _checkCompletion(context);
                  },
                ),
              ),
              if (index < 5)
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 50,
                  color: Colors.pinkAccent,
                ),
            ],
          );
        }),
      ),
    );
  }

  //   // Kiểm tra hoàn thành trò chơi
  void _checkCompletion(BuildContext context) async {
    if (placedNumbers.contains(null)) return;

    List<int> currentNumbers = placedNumbers.cast<int>();

    // Tạo thứ tự đúng theo chế độ Tăng dần hoặc Giảm dần
    List<int> correctOrder = List.from(currentNumbers)..sort();
    if (!isAscendingOrder) correctOrder = correctOrder.reversed.toList();

    bool isCorrect = true;

    for (int i = 0; i < placedNumbers.length; i++) {
      if (placedNumbers[i] != correctOrder[i]) {
        if (preFilledIndexes.contains(i)) {
          // Nếu vị trí này là số điền sẵn, tiếp tục kiểm tra các số khác
          continue;
        } else {
          // Nếu vị trí này không phải là số điền sẵn và bị sai, đánh dấu sai
          isCorrect = false;
          break;
        }
      }
    }

    if (isCorrect) {
      await _playSound('correct-choice');
      if (!mounted) return;
      _showCongratsDialog(context);
      Future.delayed(
        const Duration(seconds: 1),
        () {
          context.pop(context);
        },
      );
      _generateNumbers();
    } else {
      await _playSound('wrong-choice');
      if (!mounted) return;
      _showWrongDialog(context);
      Future.delayed(
        const Duration(seconds: 1),
        () {
          context.pop(context);
          setState(
            () {
              for (int i = 0; i < placedNumbers.length; i++) {
                int? number = placedNumbers[i];
                if (number != null &&
                    usedNumbers.contains(number) &&
                    !preFilledIndexes.contains(i)) {
                  placedNumbers[i] = null;
                }
              }
              usedNumbers.clear();
            },
          );
        },
      );
    }
  }

  void _showCongratsDialog(BuildContext context) async {
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
