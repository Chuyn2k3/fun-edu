// import 'dart:math';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fun_edu/feature/number_feature/widget/tile_card.dart';
// import 'package:fun_edu/utils/base_scaffold.dart';
// import 'package:fun_edu/utils/custom_app_bar.dart';

// class SortNumber extends StatefulWidget {
//   const SortNumber({super.key});

//   @override
//   State<SortNumber> createState() => _SortNumberState();
// }

// class _SortNumberState extends State<SortNumber> {
//   final AudioPlayer player = AudioPlayer();
//   List<int> numbers = [];
//   List<int> sortedNumbers = [];
//   List<int?> placedNumbers = [];
//   bool isAscendingOrder = true;
//   final Set<int> usedNumbers = {}; // Các số do người dùng kéo vào
//   final Set<int> preFilledNumbers = {}; // Các số được điền sẵn từ đầu
//   final Set<int> preFilledIndexes = {}; // Các vị trí được điền sẵn từ đầu

//   // Khởi tạo trò chơi
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     _generateNumbers();
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//     ]);
//     super.dispose();
//   }

//   // Tạo dãy số và bố trí số điền sẵn hoặc trống ở hàng dưới
//   void _generateNumbers() {
//     final random = Random();
//     numbers = [];
//     usedNumbers.clear();
//     preFilledNumbers.clear();
//     preFilledIndexes.clear();

//     // Tạo dãy số ngẫu nhiên từ 0 đến 9, không trùng nhau
//     while (numbers.length < 6) {
//       int num = random.nextInt(10);
//       if (!numbers.contains(num)) numbers.add(num);
//     }

//     // Sắp xếp dãy số theo đúng thứ tự cần kiểm tra
//     sortedNumbers = List.from(numbers)..sort();
//     isAscendingOrder = random.nextBool();

//     if (!isAscendingOrder) {
//       sortedNumbers = sortedNumbers.reversed.toList();
//     }

//     // Tạo `placedNumbers` theo thứ tự `sortedNumbers`
//     placedNumbers = List.from(sortedNumbers);

//     // Chọn ngẫu nhiên 2-3 vị trí để trống
//     Set<int> emptyIndexes = {};
//     while (emptyIndexes.length < random.nextInt(3) + 2) {
//       emptyIndexes.add(random.nextInt(6));
//     }

//     // Di chuyển các số từ `placedNumbers` lên `numbers`
//     numbers.clear();
//     for (int index in emptyIndexes) {
//       numbers.add(placedNumbers[index]!);
//       placedNumbers[index] = null;
//     }

//     // Lưu các số và vị trí đã được điền sẵn
//     for (int i = 0; i < placedNumbers.length; i++) {
//       if (placedNumbers[i] != null) {
//         preFilledNumbers.add(placedNumbers[i]!);
//         preFilledIndexes.add(i);
//       }
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BaseScaffold(
//       appBar: CustomAppbar.basic(
//         onTap: () => Navigator.pop(context),
//         title: "Truy tìm số bị mất",
//         actions: [
//           IconButton(
//             onPressed: _generateNumbers,
//             icon: const Icon(Icons.replay_rounded,
//                 size: 30, color: Colors.redAccent),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 16),
//             Text(
//               "Sắp xếp theo thứ tự: ${isAscendingOrder ? 'Tăng dần 🔼' : 'Giảm dần 🔽'}",
//               style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blueAccent),
//             ),
//             const SizedBox(height: 16),
//             Expanded(child: _buildDraggableNumbers()),
//             const SizedBox(height: 16),
//             Expanded(child: _buildDropTargets()),
//           ],
//         ),
//       ),
//     );
//   }

//   // Xây dựng hàng trên với các số kéo được
//   Widget _buildDraggableNumbers() {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: numbers.map((number) {
//           if (usedNumbers.contains(number)) {
//             return const SizedBox.shrink(); // Ẩn số đã được kéo vào
//           }

//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Draggable<int>(
//               data: number,
//               feedback: SizedBox(
//                 height: 150,
//                 width: 100,
//                 child: TileCard(
//                   title: number.toString(),
//                   isActive: true,
//                   textColor: Colors.blueAccent,
//                   backgroundColor: Colors.yellow[300]!,
//                   fontSizeBase: 60,
//                   fontSizeActive: 70,
//                   onTap: () {},
//                 ),
//               ),
//               childWhenDragging: const SizedBox.shrink(),
//               child: SizedBox(
//                 height: 150,
//                 width: 100,
//                 child: TileCard(
//                   title: number.toString(),
//                   isActive: true,
//                   textColor: Colors.blueAccent,
//                   backgroundColor: Colors.yellow[300]!,
//                   fontSizeBase: 60,
//                   fontSizeActive: 70,
//                   onTap: () {},
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // Xây dựng các ô thả xuống hàng dưới
//   // Xây dựng các ô thả xuống hàng dưới
//   Widget _buildDropTargets() {
//     var width = MediaQuery.of(context).size.width;
//     return Row(
//       children: [
//         SizedBox(width: width * 0.1),
//         Expanded(
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: List.generate(
//               6,
//               (index) {
//                 return Expanded(
//                   child: Row(
//                     children: [
//                       DragTarget<int>(
//                         builder: (context, candidateData, rejectedData) {
//                           return Container(
//                             height: 120,
//                             width: 80,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(15),
//                               color: Colors.white,
//                               border: Border.all(
//                                   color: Colors.lightBlueAccent, width: 2),
//                               boxShadow: const [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   blurRadius: 4,
//                                   offset: Offset(2, 2),
//                                 ),
//                               ],
//                             ),
//                             child: placedNumbers[index] != null
//                                 ? TileCard(
//                                     title: placedNumbers[index].toString(),
//                                     isActive: true,
//                                     onTap: () {},
//                                     textColor: Colors.blueAccent,
//                                     backgroundColor: Colors.greenAccent,
//                                     fontSizeBase: 60,
//                                     fontSizeActive: 70,
//                                   )
//                                 : const Center(
//                                     child: Text(
//                                       "?",
//                                       style: TextStyle(fontSize: 80),
//                                     ),
//                                   ),
//                           );
//                         },
//                         onWillAccept: (value) =>
//                             placedNumbers[index] ==
//                             null, // Chỉ chấp nhận số khi ô trống
//                         onAccept: (number) {
//                           setState(() {
//                             placedNumbers[index] = number;
//                             usedNumbers.add(number);
//                           });
//                           _checkCompletion(context);
//                         },
//                       ),
//                       if (index < 5)
//                         const Expanded(
//                           child: Icon(
//                             Icons.arrow_forward,
//                             size: 50,
//                             color: Colors.pinkAccent,
//                           ),
//                         ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Kiểm tra hoàn thành trò chơi
//   void _checkCompletion(BuildContext context) async {
//     if (placedNumbers.contains(null)) return;

//     List<int> currentNumbers = placedNumbers.cast<int>();

//     // Tạo thứ tự đúng theo chế độ Tăng dần hoặc Giảm dần
//     List<int> correctOrder = List.from(currentNumbers)..sort();
//     if (!isAscendingOrder) correctOrder = correctOrder.reversed.toList();

//     bool isCorrect = true;

//     for (int i = 0; i < placedNumbers.length; i++) {
//       if (placedNumbers[i] != correctOrder[i]) {
//         if (preFilledIndexes.contains(i)) {
//           // Nếu vị trí này là số điền sẵn, tiếp tục kiểm tra các số khác
//           continue;
//         } else {
//           // Nếu vị trí này không phải là số điền sẵn và bị sai, đánh dấu sai
//           isCorrect = false;
//           break;
//         }
//       }
//     }

//     if (isCorrect) {
//       _showCongratsDialog(context);
//       Future.delayed(
//         const Duration(seconds: 1),
//         () {
//           Navigator.pop(context);
//         },
//       );
//       _generateNumbers();
//     } else {
//       _showWrongDialog(context);
//       Future.delayed(
//         const Duration(seconds: 1),
//         () {
//           Navigator.pop(context);
//           setState(
//             () {
//               for (int i = 0; i < placedNumbers.length; i++) {
//                 int? number = placedNumbers[i];
//                 if (number != null &&
//                     usedNumbers.contains(number) &&
//                     !preFilledIndexes.contains(i)) {
//                   placedNumbers[i] = null;
//                 }
//               }
//               usedNumbers.clear();
//             },
//           );
//         },
//       );
//     }
//   }

//   void _showCongratsDialog(BuildContext context) async {
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               'assets/images/excellent.png',
//               height: 150,
//               width: 150,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Chúc mừng! Bạn đã sắp xếp đúng!",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showWrongDialog(BuildContext context) async {
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               'assets/images/wrong.png',
//               height: 150,
//               width: 150,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Cùng thử lại nhé!",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
///////////////////////
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';

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
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.2);
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
                _buildQuestionSection(),
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

  // Widget _buildNavButton() {
  //   return Positioned(
  //     top: 30,
  //     left: 20,
  //     child: GestureDetector(
  //       onTap: () => Navigator.pop(context),
  //       child: Container(
  //         padding: const EdgeInsets.all(12),
  //         decoration: const BoxDecoration(
  //           shape: BoxShape.circle,
  //           color: Colors.red,
  //         ),
  //         child: const FaIcon(FontAwesomeIcons.house, color: Colors.white),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildNavButton(FontAwesomeIcons.house, "Về Trang Chủ", Colors.red,
              () => Navigator.pop(context)),
          Spacer(),
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

    return Draggable<int>(
      data: number,
      feedback: _buildStyledNumber(number),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildStyledNumber(number),
      ),
      child: _buildStyledNumber(number),
    );
  }

  Widget _buildStyledNumber(int number) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(20),
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
              DragTarget<int>(
                builder: (context, candidateData, rejectedData) {
                  bool isAccepted = candidateData.isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 120,
                    width: 100,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAccepted ? Colors.greenAccent : Colors.white,
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
                },
                onWillAccept: (value) => placedNumbers[index] == null,
                onAccept: (number) {
                  setState(() {
                    placedNumbers[index] = number;
                    usedNumbers.add(number);
                  });
                  _checkCompletion(context);
                },
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
          Navigator.pop(context);
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
          Navigator.pop(context);
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
