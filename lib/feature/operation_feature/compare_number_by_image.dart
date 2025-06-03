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

// class CompareImageScreen extends StatefulWidget {
//   const CompareImageScreen({Key? key}) : super(key: key);

//   @override
//   State<CompareImageScreen> createState() => _CompareImageScreenState();
// }

// class _CompareImageScreenState extends State<CompareImageScreen> {
//   final FlutterTts flutterTts = FlutterTts();
//   final List<String> exampleImages = [
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

//   int leftNumber = 1;
//   int rightNumber = 1;
//   String? comparisonSign;
//   final List<String> signs = ['>', '<', '='];
//   bool isShowingDialog = false;

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     _generateImages();
//     _setupTTS();
//   }

//   void _setupTTS() async {
//     await flutterTts.setLanguage('vi-VN');
//     await flutterTts.setSpeechRate(0.5);
//     await flutterTts.setVolume(1.0);
//     await flutterTts.setPitch(1.0);
//   }

//   void _generateImages() {
//     final random = Random();
//     leftNumber = random.nextInt(9) + 1;
//     rightNumber = random.nextInt(9) + 1;
//     comparisonSign = null;
//     isShowingDialog = false;
//     setState(() {});
//   }

//   bool _checkCorrectness() {
//     if (comparisonSign == null) {
//       return false;
//     }
//     if (comparisonSign == '>') return leftNumber > rightNumber;
//     if (comparisonSign == '<') return leftNumber < rightNumber;
//     if (comparisonSign == '=') return leftNumber == rightNumber;
//     return false;
//   }

//   void _resetDraggedItems() {
//     setState(() {
//       comparisonSign = null;
//       isShowingDialog = false;
//     });
//   }

//   void _speak(String text) async {
//     await flutterTts.speak(text);
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
//         SingleChildScrollView(
//           child: SafeArea(
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),
//                 _buildTopButtons(),
//                 const SizedBox(height: 20),
//                 _buildComparisonRow(),
//                 const SizedBox(height: 20),
//                 if (comparisonSign == null) _buildComparisonSigns(),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAnimatedBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFB2F5EA), Color(0xFF81E6D9), Color(0xFF7FDBFF)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Stack(
//         children: [
//           Positioned(
//               top: 40,
//               left: 10,
//               child: AnimatedCloud(
//                   size: 100,
//                   color: Colors.white.withOpacity(0.4),
//                   duration: 25000)),
//           Positioned(
//               top: 100,
//               right: 50,
//               child: AnimatedCloud(
//                   size: 130,
//                   color: Colors.white.withOpacity(0.5),
//                   duration: 30000)),
//           Positioned(
//               bottom: 150,
//               left: 40,
//               child: AnimatedCloud(
//                   size: 90,
//                   color: Colors.white.withOpacity(0.6),
//                   duration: 20000)),
//           const Positioned(
//               top: 300,
//               left: 40,
//               child: AnimatedButterfly(size: 40, duration: 16000)),
//           const Positioned(
//               bottom: 0,
//               left: 40,
//               child: AnimatedBalloon(
//                   color: Colors.red, size: 60, duration: 12000)),
//           const Positioned(
//               bottom: 0,
//               right: 40,
//               child: AnimatedBalloon(
//                   color: Colors.blue, size: 50, duration: 10000)),
//           const Positioned(
//               bottom: 200,
//               right: 200,
//               child: AnimatedStar(size: 25, duration: 14000)),
//           const Positioned(
//               bottom: 120,
//               left: 180,
//               child: AnimatedStar(size: 22, duration: 12000)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopButtons() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           if (!kIsWeb)
//             _buildNavButton(FontAwesomeIcons.house, "Trang Chủ", Colors.red,
//                 () => Navigator.pop(context)),
//           Row(
//             children: [
//               _buildNavButton(Icons.volume_up, "Nghe", Colors.pink,
//                   () => _speak("Hãy chọn dấu phù hợp")),
//               const SizedBox(width: 20),
//               _buildNavButton(FontAwesomeIcons.arrowsRotate, "Đổi Câu",
//                   Colors.blue, _generateImages),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavButton(
//       IconData icon, String text, Color color, VoidCallback onTap) {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [color.withOpacity(0.4), color],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: FaIcon(icon, size: 30, color: Colors.white),
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
//       ],
//     );
//   }

//   Widget _buildComparisonRow() {
//     String imagePath = exampleImages[Random().nextInt(exampleImages.length)];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildImageBox(
//           leftNumber,
//           imagePath,
//         ),
//         _buildComparisonTile(),
//         _buildImageBox(
//           rightNumber,
//           imagePath,
//         ),
//       ],
//     );
//   }

//   Widget _buildImageBox(
//     int number,
//     String imagePath,
//   ) {
//     //String imagePath = exampleImages[Random().nextInt(exampleImages.length)];
//     return Container(
//       height: 150,
//       width: 150,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.blueAccent, width: 3),
//       ),
//       child: GridView.builder(
//         itemCount: number,
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           crossAxisSpacing: 5,
//           mainAxisSpacing: 5,
//         ),
//         itemBuilder: (context, index) =>
//             Image.asset(imagePath, fit: BoxFit.contain),
//       ),
//     );
//   }

//   Widget _buildComparisonTile() {
//     return DragTarget<String>(
//       builder: (context, candidateData, rejectedData) {
//         return Container(
//           height: 100,
//           width: 100,
//           decoration: BoxDecoration(
//             color: comparisonSign == null
//                 ? Colors.grey[300]
//                 : Colors.lightBlueAccent,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.pinkAccent, width: 3),
//           ),
//           child: Center(
//             child: Text(
//               comparisonSign ?? '?',
//               style: TextStyle(
//                 fontSize: 50,
//                 fontWeight: FontWeight.bold,
//                 color: comparisonSign == null ? Colors.black54 : Colors.white,
//               ),
//             ),
//           ),
//         );
//       },
//       onWillAccept: (value) => comparisonSign == null,
//       onAccept: (value) {
//         setState(() => comparisonSign = value);
//         checkCompletion(context);
//       },
//     );
//   }

//   Widget _buildComparisonSigns() {
//     final List<Color> colors = [
//       Colors.redAccent,
//       Colors.green,
//       Colors.blue,
//       Colors.purple
//     ];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: signs.map((sign) {
//         return Draggable<String>(
//           data: sign,
//           feedback: Material(
//             color: Colors.transparent,
//             child: _buildSignBox(sign, colors[Random().nextInt(colors.length)]),
//           ),
//           childWhenDragging: const SizedBox.shrink(),
//           child: _buildSignBox(sign, colors[Random().nextInt(colors.length)]),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildSignBox(String sign, Color color) {
//     return Container(
//       height: 90,
//       width: 90,
//       margin: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(2, 2),
//           ),
//         ],
//       ),
//       child: Center(
//         child: Text(
//           sign,
//           style: const TextStyle(
//             fontSize: 40,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }

//   void _showCongratsDialog(BuildContext context) async {
//     setState(() => isShowingDialog = true);

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
//               "Chúc mừng! Bạn đã chọn đúng!",
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );

//     _speak("Tuyệt vời! Bạn đã chọn đúng!");
//   }

//   void _showWrongDialog(BuildContext context) async {
//     setState(() => isShowingDialog = true);

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
//               "Sai rồi! Thử lại nhé!",
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );

//     _speak("Ôi không! Bạn chọn sai rồi. Thử lại nào!");
//   }

//   void checkCompletion(BuildContext context) {
//     if (_checkCorrectness()) {
//       _showCongratsDialog(context);
//       Future.delayed(const Duration(seconds: 1), () {
//         Navigator.pop(context);
//         _generateImages();
//       });
//     } else {
//       _showWrongDialog(context);

//       Future.delayed(const Duration(seconds: 1), () {
//         Navigator.pop(context);
//         _resetDraggedItems();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//     super.dispose();
//   }
// }

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';

class EnhancedCompareGameScreen extends StatefulWidget {
  const EnhancedCompareGameScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedCompareGameScreen> createState() =>
      _EnhancedCompareGameScreenState();
}

class _EnhancedCompareGameScreenState extends State<EnhancedCompareGameScreen>
    with TickerProviderStateMixin {
  // Game Assets
  final List<String> gameImages = [
    "assets/image_math/apple.png",
    "assets/image_math/banana.png",
    "assets/image_math/strawberry.png",
    "assets/image_math/happy-face.png",
    "assets/image_math/panda.png",
    "assets/image_math/corgi.png",
  ];

  final List<GameTheme> themes = [
    GameTheme(
      name: "Vườn Trái Cây",
      colors: [
        Color(0xFF667eea), // Tím nhạt
        Color(0xFF764ba2), // Tím đậm
        Color(0xFFf093fb), // Hồng nhạt
        Color(0xFFf5576c), // Đỏ nhạt
      ],
      accentColor: Color(0xFFFFEB3B),
      mascot: "🍎",
      icon: Icons.eco,
    ),
    GameTheme(
      name: "Đại Dương",
      colors: [
        Color(0xFF4facfe), // Xanh dương nhạt
        Color(0xFF00f2fe), // Cyan
        Color(0xFF43e97b), // Xanh lá nhạt
        Color(0xFF38f9d7), // Xanh mint
      ],
      accentColor: Color(0xFF00BCD4),
      mascot: "🐬",
      icon: Icons.water,
    ),
    GameTheme(
      name: "Vũ Trụ",
      colors: [
        Color(0xFF8360c3), // Tím space
        Color(0xFF2ebf91), // Xanh mint
        Color(0xFF667eea), // Xanh tím
        Color(0xFF764ba2), // Tím đậm
      ],
      accentColor: Color(0xFFE040FB),
      mascot: "🚀",
      icon: Icons.rocket_launch,
    ),
  ];

  // Game State
  int currentLevel = 1;
  int currentTheme = 0;
  int leftCount = 1;
  int rightCount = 1;
  String? selectedOperator;
  int totalScore = 0;
  int currentStreak = 0;
  int bestStreak = 0;
  int timeRemaining = 30;
  int questionsAnswered = 0;
  bool isGameActive = false;
  bool isProcessingAnswer = false;
  String currentImagePath = "";

  // Animation Controllers
  late AnimationController _numberAnimController;
  late AnimationController _successAnimController;
  late AnimationController _timerAnimController;
  late AnimationController _mascotAnimController;
  late AnimationController _backgroundAnimController;

  // Animations
  late Animation<double> _numberCountAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _timerProgressAnimation;
  late Animation<double> _mascotBounceAnimation;
  late Animation<double> _backgroundAnimation;

  Timer? _gameTimer;
  List<ConfettiParticle> _confettiParticles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupGame();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializeAnimations() {
    _numberAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _successAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _timerAnimController = AnimationController(
      duration: Duration(seconds: _getLevelTimeLimit()),
      vsync: this,
    );

    _mascotAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _backgroundAnimController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Setup animations
    _numberCountAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _numberAnimController, curve: Curves.easeOutQuad),
    );

    _successScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successAnimController, curve: Curves.elasticOut),
    );

    _timerProgressAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _timerAnimController, curve: Curves.linear),
    );

    _mascotBounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mascotAnimController, curve: Curves.elasticOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundAnimController, curve: Curves.linear),
    );
  }

  void _setupGame() {
    setState(() {
      isGameActive = true;
      isProcessingAnswer = false;
      selectedOperator = null;
      timeRemaining = _getLevelTimeLimit();
    });
    _generateNewQuestion();
    _startTimer();
  }

  int _getLevelTimeLimit() {
    switch (currentLevel) {
      case 1:
        return 30;
      case 2:
        return 25;
      case 3:
        return 20;
      default:
        return 15;
    }
  }

  int _getLevelMaxNumber() {
    switch (currentLevel) {
      case 1:
        return 3;
      case 2:
        return 5;
      case 3:
        return 7;
      default:
        return 9;
    }
  }

  void _generateNewQuestion() {
    final random = Random();
    final maxNum = _getLevelMaxNumber();

    setState(() {
      leftCount = random.nextInt(maxNum) + 1;
      rightCount = random.nextInt(maxNum) + 1;
      currentImagePath = gameImages[random.nextInt(gameImages.length)];
      selectedOperator = null;
      isProcessingAnswer = false;
    });

    // Ensure some variety in higher levels
    if (currentLevel > 2 && leftCount == rightCount && random.nextBool()) {
      rightCount = rightCount == maxNum ? rightCount - 1 : rightCount + 1;
    }

    _numberAnimController.forward(from: 0);
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _timerAnimController.forward(from: 0);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() {
          timeRemaining--;
        });
      } else {
        timer.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    if (!isProcessingAnswer) {
      _showResultDialog(false, "Hết thời gian!", "Thử nhanh hơn lần sau nhé!");
    }
  }

  void _handleOperatorSelection(String operator) {
    if (!isGameActive || isProcessingAnswer) return;

    setState(() {
      selectedOperator = operator;
      isProcessingAnswer = true;
      isGameActive = false;
    });

    _gameTimer?.cancel();
    _timerAnimController.stop();

    // Check answer after a short delay for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkAnswer(operator);
    });
  }

  void _checkAnswer(String operator) {
    bool isCorrect = false;

    switch (operator) {
      case '>':
        isCorrect = leftCount > rightCount;
        break;
      case '<':
        isCorrect = leftCount < rightCount;
        break;
      case '=':
        isCorrect = leftCount == rightCount;
        break;
    }

    if (isCorrect) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  void _handleCorrectAnswer() {
    setState(() {
      totalScore += _calculateScore();
      currentStreak++;
      questionsAnswered++;
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
    });

    _createConfetti();
    _successAnimController.forward(from: 0);
    _mascotAnimController.forward(from: 0);

    _showResultDialog(
        true, "Chính xác! 🎉", "Bạn được ${_calculateScore()} điểm!");
  }

  void _handleWrongAnswer() {
    setState(() {
      currentStreak = 0;
      questionsAnswered++;
    });

    String correctAnswer = leftCount > rightCount
        ? '>'
        : leftCount < rightCount
            ? '<'
            : '=';

    _showResultDialog(false, "Chưa đúng! 😅",
        "Đáp án đúng là: $leftCount $correctAnswer $rightCount");
  }

  int _calculateScore() {
    int baseScore = 10;
    int timeBonus = timeRemaining;
    int streakBonus = currentStreak * 5;
    int levelBonus = currentLevel * 5;
    return baseScore + timeBonus + streakBonus + levelBonus;
  }

  void _createConfetti() {
    _confettiParticles.clear();
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < 30; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: screenWidth / 2,
        y: screenHeight / 2,
        vx: (random.nextDouble() - 0.5) * 300,
        vy: (random.nextDouble() - 0.5) * 300,
        color: [
          Colors.yellow,
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.pink,
          Colors.purple,
          Colors.orange
        ][random.nextInt(7)],
        size: random.nextDouble() * 10 + 5,
      ));
    }
  }

  void _showResultDialog(bool isCorrect, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(
        isCorrect: isCorrect,
        title: title,
        message: message,
        score: totalScore,
        streak: currentStreak,
        onContinue: () {
          Navigator.of(context).pop();
          _continueGame();
        },
      ),
    );
  }

  void _continueGame() {
    // Check for level up
    if (questionsAnswered >= 5 && totalScore >= currentLevel * 50) {
      _levelUp();
    } else {
      _setupGame();
    }
  }

  void _levelUp() {
    setState(() {
      currentLevel++;
      if (currentLevel > 4) {
        currentLevel = 1;
        currentTheme = (currentTheme + 1) % themes.length;
      }
      questionsAnswered = 0;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpDialog(
        level: currentLevel,
        theme: themes[currentTheme].name,
        onContinue: () {
          Navigator.of(context).pop();
          _setupGame();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: kIsWeb ? PortalMasterLayout(body: _buildBody()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themes[currentTheme].colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                0.0 + _backgroundAnimation.value * 0.1,
                0.3 + _backgroundAnimation.value * 0.1,
                0.7 + _backgroundAnimation.value * 0.1,
                1.0,
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5 + _backgroundAnimation.value * 0.5,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  _buildAnimatedBackground(),
                  _buildGeometricShapes(),
                  _buildConfetti(),
                  Column(
                    children: [
                      _buildTopBar(),
                      Expanded(child: _buildGameArea()),
                      if (selectedOperator == null && isGameActive)
                        _buildOperatorButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                  _buildMascot(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Floating bubbles
        ...List.generate(12, (index) {
          return AnimatedFloatingBubble(
            delay: index * 300,
            size: 20.0 + (index % 4) * 15,
            color: themes[currentTheme].accentColor.withOpacity(0.1),
          );
        }),
        // Floating icons
        ...List.generate(8, (index) {
          return AnimatedFloatingIcon(
            delay: index * 500,
            icon: [
              Icons.star,
              Icons.favorite,
              Icons.circle,
              Icons.diamond,
              themes[currentTheme].icon,
            ][index % 5],
            color: themes[currentTheme].accentColor,
          );
        }),
      ],
    );
  }

  Widget _buildGeometricShapes() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Large circle
            Positioned(
              top: -100 + _backgroundAnimation.value * 50,
              right: -100 + _backgroundAnimation.value * 30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Medium circle
            Positioned(
              bottom: -50 + _backgroundAnimation.value * 40,
              left: -50 + _backgroundAnimation.value * 25,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      themes[currentTheme].accentColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Triangular shapes
            Positioned(
              top: 100 + _backgroundAnimation.value * 20,
              left: 50 + _backgroundAnimation.value * 15,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 2 * pi,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _successAnimController,
      builder: (context, child) {
        return CustomPaint(
          painter:
              ConfettiPainter(_confettiParticles, _successAnimController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
              "Level", currentLevel.toString(), Icons.star, Colors.amber),
          _buildTimerCard(),
          _buildStatCard(
              "Điểm", totalScore.toString(), Icons.score, Colors.green),
          _buildStatCard("Streak", currentStreak.toString(),
              Icons.local_fire_department, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _timerProgressAnimation,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _timerProgressAnimation.value,
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      timeRemaining > 10 ? Colors.green : Colors.red,
                    ),
                    backgroundColor: Colors.grey.withOpacity(0.3),
                  );
                },
              ),
              Text(
                timeRemaining.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: timeRemaining > 10 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Thời gian",
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildGameArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNumberCard(leftCount, true),
          _buildComparisonArea(),
          _buildNumberCard(rightCount, false),
        ],
      ),
    );
  }

  Widget _buildNumberCard(int count, bool isLeft) {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themes[currentTheme].colors.first.withOpacity(0.1),
                  themes[currentTheme].colors[1].withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: AnimatedBuilder(
              animation: _numberCountAnimation,
              builder: (context, child) {
                int displayCount =
                    (_numberCountAnimation.value * count).round();
                return Text(
                  displayCount.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: themes[currentTheme].colors.first,
                  ),
                );
              },
            ),
          ),
          // Images grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedBuilder(
                animation: _numberCountAnimation,
                builder: (context, child) {
                  int displayCount =
                      (_numberCountAnimation.value * count).round();
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemBuilder: (context, index) {
                      return AnimatedScale(
                        scale: _numberCountAnimation.value,
                        duration: Duration(milliseconds: 200 + (index * 50)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              currentImagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: themes[currentTheme]
                                      .colors
                                      .first
                                      .withOpacity(0.3),
                                  child: Icon(
                                    Icons.image,
                                    color: themes[currentTheme].colors.first,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonArea() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: selectedOperator == null
            ? Colors.white.withOpacity(0.95)
            : themes[currentTheme].colors.first,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: selectedOperator == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 30,
                    color: themes[currentTheme].colors.first.withOpacity(0.7),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themes[currentTheme].colors.first.withOpacity(0.7),
                    ),
                  ),
                ],
              )
            : AnimatedScale(
                scale: 1.2,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  selectedOperator!,
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOperatorButtons() {
    final operators = ['>', '<', '='];
    final colors = [
      Color(0xFFFF6B6B), // Đỏ coral
      Color(0xFF4ECDC4), // Xanh mint
      Color(0xFF45B7D1), // Xanh dương
    ];
    final labels = ['Lớn hơn', 'Nhỏ hơn', 'Bằng nhau'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: operators.asMap().entries.map((entry) {
          int index = entry.key;
          String operator = entry.value;

          return GestureDetector(
            onTap: () => _handleOperatorSelection(operator),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors[index],
                    colors[index].withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors[index].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    operator,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMascot() {
    return Positioned(
      top: 120,
      right: 20,
      child: AnimatedBuilder(
        animation: _mascotBounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_mascotBounceAnimation.value * 15),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    themes[currentTheme].mascot,
                    style: const TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Level $currentLevel",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themes[currentTheme].colors.first,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _numberAnimController.dispose();
    _successAnimController.dispose();
    _timerAnimController.dispose();
    _mascotAnimController.dispose();
    _backgroundAnimController.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}

// Supporting Classes
class GameTheme {
  final String name;
  final List<Color> colors;
  final Color accentColor;
  final String mascot;
  final IconData icon;

  GameTheme({
    required this.name,
    required this.colors,
    required this.accentColor,
    required this.mascot,
    required this.icon,
  });
}

class ConfettiParticle {
  double x, y, vx, vy;
  Color color;
  double size;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      paint.color = particle.color.withOpacity(1 - progress);

      double currentX = particle.x + particle.vx * progress;
      double currentY = particle.y +
          particle.vy * progress +
          (50 * progress * progress); // Add gravity

      // Draw star-shaped confetti
      if (Random().nextBool()) {
        _drawStar(canvas, Offset(currentX, currentY),
            particle.size * (1 - progress * 0.5), paint);
      } else {
        canvas.drawCircle(
          Offset(currentX, currentY),
          particle.size * (1 - progress * 0.5),
          paint,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final double halfRadius = radius / 2;
    final double degreesPerStep = _degToRad(360 / 5);
    final double halfDegreesPerStep = degreesPerStep / 2;

    path.moveTo(center.dx, center.dy - radius);

    for (int i = 0; i < 5; i++) {
      path.lineTo(
          center.dx + halfRadius * sin(_degToRad(36) + degreesPerStep * i),
          center.dy - halfRadius * cos(_degToRad(36) + degreesPerStep * i));
      path.lineTo(
          center.dx + radius * sin(halfDegreesPerStep + degreesPerStep * i),
          center.dy - radius * cos(halfDegreesPerStep + degreesPerStep * i));
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedFloatingIcon extends StatefulWidget {
  final int delay;
  final IconData icon;
  final Color color;

  const AnimatedFloatingIcon({
    Key? key,
    required this.delay,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  State<AnimatedFloatingIcon> createState() => _AnimatedFloatingIconState();
}

class _AnimatedFloatingIconState extends State<AnimatedFloatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 4000 + widget.delay),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin:
          Offset(Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1),
      end: Offset(Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: 50 + _animation.value.dx * 100,
          top: 100 + _animation.value.dy * 100,
          child: Icon(
            widget.icon,
            color: widget.color.withOpacity(0.3),
            size: 20,
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

class AnimatedFloatingBubble extends StatefulWidget {
  final int delay;
  final double size;
  final Color color;

  const AnimatedFloatingBubble({
    Key? key,
    required this.delay,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  State<AnimatedFloatingBubble> createState() => _AnimatedFloatingBubbleState();
}

class _AnimatedFloatingBubbleState extends State<AnimatedFloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 6000 + widget.delay),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin:
          Offset(Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1),
      end: Offset(Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: 100 + _animation.value.dx * 150,
          top: 150 + _animation.value.dy * 200,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withOpacity(0.3),
                    widget.color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
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

class ResultDialog extends StatelessWidget {
  final bool isCorrect;
  final String title;
  final String message;
  final int score;
  final int streak;
  final VoidCallback onContinue;

  const ResultDialog({
    Key? key,
    required this.isCorrect,
    required this.title,
    required this.message,
    required this.score,
    required this.streak,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: isCorrect
                ? [Color(0xFF4ECDC4), Color(0xFF44A08D)] // Xanh mint gradient
                : [Color(0xFFFF6B6B), Color(0xFFEE5A52)], // Đỏ coral gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.info_outline,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCorrect) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.score, color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          score.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Tổng điểm",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          streak.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Streak",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    isCorrect ? Color(0xFF44A08D) : Color(0xFFEE5A52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Tiếp tục",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelUpDialog extends StatelessWidget {
  final int level;
  final String theme;
  final VoidCallback onContinue;

  const LevelUpDialog({
    Key? key,
    required this.level,
    required this.theme,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)], // Vàng gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              "🎉 LEVEL UP! 🎉",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Chúc mừng! Bạn đã lên Level $level",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Chủ đề: $theme",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFFFB300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Bắt đầu Level mới!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
