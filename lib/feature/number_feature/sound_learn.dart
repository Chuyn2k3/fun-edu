// import 'package:flutter/material.dart';
// import 'package:fun_edu/data/term/constants.dart';
// import 'package:fun_edu/model/model_nums.dart';
// import 'package:fun_edu/utils/base_scaffold.dart';
// import 'package:fun_edu/utils/custom_app_bar.dart';

// class SoundLearnScreen extends StatefulWidget {
//   const SoundLearnScreen({super.key});

//   @override
//   State<SoundLearnScreen> createState() => _SoundLearnScreenState();
// }

// class _SoundLearnScreenState extends State<SoundLearnScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return BaseScaffold(
//       appBar: CustomAppbar.basic(
//         onTap: () {
//           Navigator.pop(context);
//         },
//         title: "Chữ số",
//       ),
//       body: Center(
//         child: buildModels(),
//       ),
//     );
//   }
// Widget buildModels() {
//   return Padding(
//     padding: const EdgeInsets.all(8.0),
//     child: ListView.builder(
//       padding: EdgeInsets.zero,
//       itemCount: numsList.length,
//       itemBuilder: (context, index) {
//         return ModelStyle(
//           cardModel: CustomCardModel(
//             title: numsList[index].title,
//             subImage: numsList[index].subImage,
//             image: numsList[index].image,
//             color: numsList[index].color,
//           ),
//         );
//       },
//     ),
//   );
// }
// }
//////////////////////////////////////////
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animated_widgets/animated_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/term/constants.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_butterfly.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_clound.dart';
import 'package:fun_edu/feature/number_feature/widget/animate_star.dart';
import 'package:fun_edu/feature/number_feature/widget/animated_balloon.dart';
import 'package:fun_edu/model/model_nums.dart';
import 'package:fun_edu/widget/responsive.dart';

class SoundLearnScreen extends StatefulWidget {
  const SoundLearnScreen({super.key});

  @override
  State<SoundLearnScreen> createState() => _SoundLearnScreenState();
}

class _SoundLearnScreenState extends State<SoundLearnScreen> {
  final FlutterTts flutterTts = FlutterTts();
  bool flag = false;
  int currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _speak(numsList[currentIndex].title);
  }

  void _speak(String text) async {
    await flutterTts.setLanguage('vi-VN');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  void _nextNumber() {
    if (currentIndex < numsList.length - 1) {
      setState(() {
        currentIndex++;
        _speak(numsList[currentIndex].title);
      });
    }
  }

  void _previousNumber() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _speak(numsList[currentIndex].title);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentNum = numsList[currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _buildTopButtons(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(
                      width: kIsWeb ? 64 : 8,
                    ),
                    _buildNavButton(Icons.chevron_left, "Lùi Lại", Colors.blue,
                        _previousNumber),
                    // const SizedBox(
                    //   width: kIsWeb ? 64 : 8,
                    // ),
                    Row(
                      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNumberDisplay(currentNum),
                        const SizedBox(
                          width: kIsWeb ? 64 : 12,
                        ),
                        StatefulBuilder(builder: (context, setState) {
                          return ShakeAnimatedWidget(
                            enabled: flag,
                            duration: const Duration(milliseconds: 1000),
                            shakeAngle: Rotation.deg(z: 10),
                            child: GestureDetector(
                              onTap: () async {
                                if (!flag) {
                                  setState(() => flag = true);
                                  _speak(currentNum.title);

                                  // Wait for the animation to complete
                                  try {
                                    // Đợi animation hoàn thành trước khi thay đổi flag
                                    await Future.delayed(
                                        const Duration(milliseconds: 1000));
                                  } catch (e) {
                                    // Nếu widget bị huỷ giữa chừng, bỏ qua lỗi
                                    return;
                                  }

                                  if (mounted) {
                                    setState(() => flag = false);
                                  }
                                }
                              },
                              child: Image.asset(
                                currentNum.subImage,
                                height: 70,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    // const SizedBox(
                    //   width: kIsWeb ? 64 : 8,
                    // ),
                    _buildNavButton(Icons.chevron_right, "Tiến Lên",
                        Colors.green, _nextNumber),
                    const SizedBox(
                      width: kIsWeb ? 64 : 8,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTitle(currentNum),
                const SizedBox(height: 20),
                Expanded(child: _buildExamples(currentNum)),
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

  Widget _buildNavButton(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
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
            child: FaIcon(icon, size: 28, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(Icons.home, "Quay Lại", Colors.red, () {
            Navigator.pop(context);
          }),
          // _buildNavButton(
          //     Icons.chevron_left, "Lùi Lại", Colors.blue, _previousNumber),
          _buildNavButton(Icons.volume_up, "Nghe", Colors.pink,
              () => _speak(numsList[currentIndex].title)),
          // _buildNavButton(
          //     Icons.chevron_right, "Tiến Lên", Colors.green, _nextNumber),
        ],
      ),
    );
  }

  Widget _buildNumberDisplay(CustomCardModel currentNum) {
    return StatefulBuilder(
      builder: (context, setState) {
        return ShakeAnimatedWidget(
          enabled: flag,
          duration: const Duration(milliseconds: 1000),
          shakeAngle: Rotation.deg(z: 10),
          child: GestureDetector(
            onTap: () async {
              if (!flag) {
                setState(() => flag = true);
                _speak(currentNum.title);

                // Wait for the animation to complete
                try {
                  // Đợi animation hoàn thành trước khi thay đổi flag
                  await Future.delayed(const Duration(milliseconds: 1000));
                } catch (e) {
                  // Nếu widget bị huỷ giữa chừng, bỏ qua lỗi
                  return;
                }

                if (mounted) {
                  setState(() => flag = false);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                currentNum.image,
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(CustomCardModel currentNum) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentNum.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        currentNum.title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExamples(CustomCardModel currentNum) {
    int count = _extractNumber(currentNum.title);
    String emoji = _getEmoji(currentNum.title);
    List<String> exampleImages = [
      "assets/image_math/apple.png",
      "assets/image_math/banana.png",
      "assets/image_math/corgi.png",
      "assets/image_math/happy-face.png",
      "assets/image_math/monster.png",
      "assets/image_math/panda.png",
      "assets/image_math/pine-tree.png",
      "assets/image_math/strawberry.png",
      "assets/image_math/table.png",
    ];
    final imageindexRamdom = Random().nextInt(exampleImages.length);
    List<String> randomImages = List.generate(
      count,
      (_) => exampleImages[imageindexRamdom],
    );
    var size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // StatefulBuilder(builder: (context, setState) {
            //   return ShakeAnimatedWidget(
            //     enabled: flag,
            //     duration: const Duration(milliseconds: 1000),
            //     shakeAngle: Rotation.deg(z: 10),
            //     child: GestureDetector(
            //       onTap: () async {
            //         if (!flag) {
            //           setState(() => flag = true);
            //           _speak(currentNum.title);

            //           // Wait for the animation to complete
            //           try {
            //             // Đợi animation hoàn thành trước khi thay đổi flag
            //             await Future.delayed(
            //                 const Duration(milliseconds: 1000));
            //           } catch (e) {
            //             // Nếu widget bị huỷ giữa chừng, bỏ qua lỗi
            //             return;
            //           }

            //           if (mounted) {
            //             setState(() => flag = false);
            //           }
            //         }
            //       },
            //       child: Image.asset(
            //         currentNum.subImage,
            //         height: 80,
            //         fit: BoxFit.contain,
            //       ),
            //     ),
            //   );
            // }),
            const SizedBox(height: 8),
            // const Text(
            //   "Ví dụ bằng Emoji: ",
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.blueAccent,
            //   ),
            // ),
            const SizedBox(height: 8),
            SizedBox(
              width: size.width,
              child: Center(
                child: Wrap(
                  children: List.generate(
                    count,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Image Example
            // const Text(
            //   "Ví dụ bằng Hình ảnh: ",
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.green,
            //   ),
            // ),
            const SizedBox(height: 8),
            SizedBox(
              width: size.width,
              child: Center(
                child: Wrap(
                  children: randomImages.map((imagePath) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Image.asset(
                        imagePath,
                        width: 70,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _extractNumber(String title) {
    final numbers = {
      "Số Không": 0,
      "Số Một": 1,
      "Số Hai": 2,
      "Số Ba": 3,
      "Số Bốn": 4,
      "Số Năm": 5,
      "Số Sáu": 6,
      "Số Bảy": 7,
      "Số Tám": 8,
      "Số Chín": 9,
    };
    return numbers[title] ?? 0;
  }

  String _getEmoji(String title) {
    final emojis = {
      "Số Không": "🍀",
      "Số Một": "🍎",
      "Số Hai": "🍊",
      "Số Ba": "🍌",
      "Số Bốn": "🍒",
      "Số Năm": "🍇",
      "Số Sáu": "🍉",
      "Số Bảy": "🍓",
      "Số Tám": "🍍",
      "Số Chín": "🥥",
    };
    return emojis[title] ?? "🍎";
  }
}
