// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:fun_edu/widget/menu/portal_master_layout.dart';
// import 'package:go_router/go_router.dart';

// // Data models for better structure
// class GameLevel {
//   final int level;
//   final int questionCount;
//   final int duration;

//   const GameLevel({
//     required this.level,
//     required this.questionCount,
//     required this.duration,
//   });
// }

// class MathQuestion {
//   final int operand1;
//   final int operand2;
//   final String operation;
//   final int correctAnswer;
//   final List<int> choices;

//   MathQuestion({
//     required this.operand1,
//     required this.operand2,
//     required this.operation,
//     required this.correctAnswer,
//     required this.choices,
//   });
// }

// class GameState {
//   final GameLevel currentLevel;
//   final List<MathQuestion> questions;
//   final int currentQuestionIndex;
//   final int score;
//   final double progress;
//   final bool isComplete;
//   final bool isCorrect;
//   final int timeLeft;

//   const GameState({
//     required this.currentLevel,
//     this.questions = const [],
//     this.currentQuestionIndex = 0,
//     this.score = 0,
//     this.progress = 0.0,
//     this.isComplete = false,
//     this.isCorrect = false,
//     this.timeLeft = 30,
//   });

//   GameState copyWith({
//     GameLevel? currentLevel,
//     List<MathQuestion>? questions,
//     int? currentQuestionIndex,
//     int? score,
//     double? progress,
//     bool? isComplete,
//     bool? isCorrect,
//     int? timeLeft,
//   }) {
//     return GameState(
//       currentLevel: currentLevel ?? this.currentLevel,
//       questions: questions ?? this.questions,
//       currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
//       score: score ?? this.score,
//       progress: progress ?? this.progress,
//       isComplete: isComplete ?? this.isComplete,
//       isCorrect: isCorrect ?? this.isCorrect,
//       timeLeft: timeLeft ?? this.timeLeft,
//     );
//   }

//   MathQuestion get currentQuestion => questions[currentQuestionIndex];
//   bool get hasMoreQuestions => currentQuestionIndex < questions.length - 1;
//   bool get isLevelComplete => score == currentLevel.questionCount;
//   bool get isGameComplete => currentLevel.level == 4 && isLevelComplete;
// }

// // Service for generating questions
// class QuestionGenerator {
//   static final Random _random = Random();

//   static List<MathQuestion> generateQuestions(int count) {
//     final questions = <MathQuestion>[];

//     for (int i = 0; i < count; i++) {
//       final operation = _random.nextBool() ? 'sum' : 'sub';
//       late int operand1, operand2, correctAnswer;

//       if (operation == 'sum') {
//         do {
//           operand1 = _random.nextInt(10);
//           operand2 = _random.nextInt(10);
//           correctAnswer = operand1 + operand2;
//         } while (correctAnswer > 9);
//       } else {
//         operand1 = _random.nextInt(10);
//         operand2 = _random.nextInt(operand1 + 1);
//         correctAnswer = operand1 - operand2;
//       }

//       // Generate unique choices
//       final choicesSet = <int>{correctAnswer};
//       while (choicesSet.length < 4) {
//         final wrongAnswer = _random.nextInt(10);
//         choicesSet.add(wrongAnswer);
//       }

//       final choices = choicesSet.toList()..shuffle(_random);

//       questions.add(MathQuestion(
//         operand1: operand1,
//         operand2: operand2,
//         operation: operation,
//         correctAnswer: correctAnswer,
//         choices: choices,
//       ));
//     }

//     return questions;
//   }
// }

// // Game configuration
// class GameConfig {
//   static const List<GameLevel> levels = [
//     GameLevel(level: 1, questionCount: 5, duration: 30),
//     GameLevel(level: 2, questionCount: 10, duration: 25),
//     GameLevel(level: 3, questionCount: 15, duration: 20),
//     GameLevel(level: 4, questionCount: 20, duration: 15),
//   ];

//   static GameLevel getLevelConfig(int level) {
//     return levels.firstWhere((l) => l.level == level,
//         orElse: () => levels.first);
//   }
// }

// class SpaceGameScreen extends StatefulWidget {
//   const SpaceGameScreen({super.key});

//   @override
//   State<SpaceGameScreen> createState() => _SpaceGameScreenState();
// }

// class _SpaceGameScreenState extends State<SpaceGameScreen>
//     with TickerProviderStateMixin {
//   // Animation controllers
//   late final AnimationController _spaceshipController;
//   late final AnimationController _celebrationController;
//   late final AnimationController _timerController;

//   // Animations
//   late final Animation<double> _spaceshipAnimation;
//   late final Animation<double> _timerAnimation;

//   // Game state
//   GameState _gameState = GameState(
//     currentLevel: GameConfig.levels.first,
//     questions: QuestionGenerator.generateQuestions(
//         GameConfig.levels.first.questionCount),
//   );

//   // Timer
//   Timer? _gameTimer;
//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeScreen();
//     _initializeAnimations();
//     _startNewLevel();
//   }

//   void _initializeScreen() {
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//   }

//   void _initializeAnimations() {
//     _spaceshipController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );

//     _celebrationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );

//     _timerController = AnimationController(
//       vsync: this,
//       duration: Duration(seconds: _gameState.currentLevel.duration),
//     );

//     _spaceshipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _spaceshipController, curve: Curves.easeInOut),
//     );

//     _timerAnimation =
//         Tween<double>(begin: 1.0, end: 0.0).animate(_timerController);

//     // Add status listener for timer
//     _timerController.addStatusListener((status) {
//       if (status == AnimationStatus.completed && !_isDisposed) {
//         _handleTimeOut();
//       }
//     });
//   }

//   void _startNewLevel() {
//     _gameTimer?.cancel();

//     if (!_isDisposed) {
//       setState(() {
//         _gameState = _gameState.copyWith(
//           timeLeft: _gameState.currentLevel.duration,
//         );
//       });

//       _timerController.duration =
//           Duration(seconds: _gameState.currentLevel.duration);
//       _timerController.reset();
//       _timerController.forward();
//       _startTimer();
//     }
//   }

//   void _startTimer() {
//     _gameTimer?.cancel();
//     _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_isDisposed) {
//         timer.cancel();
//         return;
//       }

//       if (_gameState.timeLeft > 0) {
//         setState(() {
//           _gameState = _gameState.copyWith(timeLeft: _gameState.timeLeft - 1);
//         });
//       } else {
//         timer.cancel();
//         _handleTimeOut();
//       }
//     });
//   }

//   void _handleTimeOut() {
//     if (_isDisposed) return;
//     _handleAnswer(-1); // Invalid answer for timeout
//   }

//   void _handleAnswer(int selectedAnswer) {
//     if (_isDisposed) return;

//     _gameTimer?.cancel();

//     final isCorrect =
//         selectedAnswer == _gameState.currentQuestion.correctAnswer;

//     setState(() {
//       _gameState = _gameState.copyWith(
//         isCorrect: isCorrect,
//         score: isCorrect ? _gameState.score + 1 : _gameState.score,
//         progress: isCorrect
//             ? _gameState.progress +
//                 (1.0 / _gameState.currentLevel.questionCount)
//             : _gameState.progress,
//       );
//     });

//     if (isCorrect && !_isDisposed) {
//       _spaceshipController.forward(from: 0);
//     }

//     // Move to next question or complete level
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (_isDisposed) return;

//       if (_gameState.hasMoreQuestions) {
//         _nextQuestion();
//       } else {
//         _completeLevel();
//       }
//     });
//   }

//   void _nextQuestion() {
//     if (_isDisposed) return;

//     setState(() {
//       _gameState = _gameState.copyWith(
//         currentQuestionIndex: _gameState.currentQuestionIndex + 1,
//         isCorrect: false,
//       );
//     });

//     _startNewLevel();
//   }

//   void _completeLevel() {
//     if (_isDisposed) return;

//     if (_gameState.isLevelComplete) {
//       if (_gameState.isGameComplete) {
//         _showCelebration();
//       } else {
//         _advanceToNextLevel();
//       }
//     } else {
//       _showCelebration();
//     }
//   }

//   void _advanceToNextLevel() {
//     if (_isDisposed) return;

//     final nextLevel =
//         GameConfig.getLevelConfig(_gameState.currentLevel.level + 1);
//     final newQuestions =
//         QuestionGenerator.generateQuestions(nextLevel.questionCount);

//     setState(() {
//       _gameState = GameState(
//         currentLevel: nextLevel,
//         questions: newQuestions,
//         currentQuestionIndex: 0,
//         score: 0,
//         progress: 0.0,
//       );
//     });

//     _startNewLevel();
//   }

//   void _showCelebration() {
//     if (_isDisposed) return;

//     setState(() {
//       _gameState = _gameState.copyWith(isComplete: true);
//     });

//     _celebrationController.forward();
//   }

//   void _resetGame() {
//     if (_isDisposed) return;

//     final firstLevel = GameConfig.levels.first;
//     final newQuestions =
//         QuestionGenerator.generateQuestions(firstLevel.questionCount);

//     setState(() {
//       _gameState = GameState(
//         currentLevel: firstLevel,
//         questions: newQuestions,
//       );
//     });

//     _celebrationController.reset();
//     _startNewLevel();
//   }

//   void _exitGame() {
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//     if (mounted) {
//       context.pop();
//     }
//   }

//   Color _getTimerColor() {
//     final ratio = _gameState.timeLeft / _gameState.currentLevel.duration;
//     if (ratio > 0.6) return Colors.green;
//     if (ratio > 0.3) return Colors.orange;
//     return Colors.red;
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     _gameTimer?.cancel();
//     _spaceshipController.dispose();
//     _celebrationController.dispose();
//     _timerController.dispose();

//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);

//     super.dispose();
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
//         const _AnimatedBackground(),
//         if (_gameState.isComplete) ...[
//           _CelebrationScreen(
//             gameState: _gameState,
//             celebrationAnimation: _celebrationController,
//             onReset: _resetGame,
//             onExit: _exitGame,
//           ),
//         ] else ...[
//           _GameContent(
//             gameState: _gameState,
//             spaceshipAnimation: _spaceshipAnimation,
//             timerAnimation: _timerAnimation,
//             timerColor: _getTimerColor(),
//             onAnswerSelected: _handleAnswer,
//             onExit: _exitGame,
//           ),
//         ],
//       ],
//     );
//   }
// }

// // Separate widgets for better performance and lifecycle management
// class _AnimatedBackground extends StatelessWidget {
//   const _AnimatedBackground();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFF1A2240),
//             Color(0xFF1E2755),
//             Color(0xFF3C3B92),
//             Color(0xFF5A47B6),
//           ],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: const Stack(
//         children: [
//           // Reduced number of animated elements for better performance
//           Positioned(
//             bottom: 200,
//             right: 200,
//             child: _AnimatedStar(size: 25, duration: 14000),
//           ),
//           Positioned(
//             bottom: 120,
//             left: 180,
//             child: _AnimatedStar(size: 22, duration: 12000),
//           ),
//           Positioned(
//             top: 150,
//             left: 60,
//             child: _AnimatedStar(size: 18, duration: 18000),
//           ),
//           Positioned(
//             top: 80,
//             right: 100,
//             child: _AnimatedStar(size: 20, duration: 16000),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _GameContent extends StatelessWidget {
//   final GameState gameState;
//   final Animation<double> spaceshipAnimation;
//   final Animation<double> timerAnimation;
//   final Color timerColor;
//   final Function(int) onAnswerSelected;
//   final VoidCallback onExit;

//   const _GameContent({
//     required this.gameState,
//     required this.spaceshipAnimation,
//     required this.timerAnimation,
//     required this.timerColor,
//     required this.onAnswerSelected,
//     required this.onExit,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           _EnergyBar(
//             progress: gameState.progress,
//             spaceshipAnimation: spaceshipAnimation,
//             onExit: onExit,
//           ),
//           const SizedBox(height: 8),
//           Center(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "🌟 Level ${gameState.currentLevel.level}",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 _CustomCircularProgress(
//                   timeLeft: gameState.timeLeft,
//                   timerAnimation: timerAnimation,
//                   timerColor: timerColor,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           _QuestionDisplay(
//             question: gameState.currentQuestion,
//             onAnswerSelected: onAnswerSelected,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _EnergyBar extends StatelessWidget {
//   final double progress;
//   final Animation<double> spaceshipAnimation;
//   final VoidCallback onExit;

//   const _EnergyBar({
//     required this.progress,
//     required this.spaceshipAnimation,
//     required this.onExit,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 8),
//       child: Row(
//         children: [
//           if (!kIsWeb)
//             GestureDetector(
//               onTap: onExit,
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 margin: const EdgeInsets.only(right: 32),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF4A90E2), Color(0xFF9013FE)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.blue.withOpacity(0.6),
//                       blurRadius: 12,
//                       spreadRadius: 1,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Transform.rotate(
//                   angle: -pi / 2,
//                   child: const FaIcon(
//                     FontAwesomeIcons.rocket,
//                     color: Colors.white,
//                     size: 28,
//                   ),
//                 ),
//               ),
//             ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 36),
//               child: Container(
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.white, width: 2),
//                 ),
//                 child: Stack(
//                   clipBehavior: Clip.none,
//                   children: [
//                     AnimatedBuilder(
//                       animation: spaceshipAnimation,
//                       builder: (context, child) {
//                         return FractionallySizedBox(
//                           alignment: Alignment.centerLeft,
//                           widthFactor: progress,
//                           child: Stack(
//                             clipBehavior: Clip.none,
//                             children: [
//                               Container(
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(20),
//                                   gradient: const LinearGradient(
//                                     colors: [
//                                       Colors.green,
//                                       Colors.yellow,
//                                       Colors.red
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 right: -20,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.lightBlueAccent
//                                             .withOpacity(0.6),
//                                         blurRadius: 15,
//                                         spreadRadius: 2,
//                                       ),
//                                     ],
//                                   ),
//                                   child: ShaderMask(
//                                     shaderCallback: const LinearGradient(
//                                       colors: [
//                                         Colors.blue,
//                                         Colors.cyanAccent,
//                                         Colors.white
//                                       ],
//                                     ).createShader,
//                                     child: const FaIcon(
//                                       FontAwesomeIcons.shuttleSpace,
//                                       size: 30,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                     Positioned(
//                       right: -15,
//                       top: -28,
//                       child: Image.asset(
//                         "assets/images/earth.png",
//                         width: 96,
//                         height: 96,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CustomCircularProgress extends StatelessWidget {
//   final int timeLeft;
//   final Animation<double> timerAnimation;
//   final Color timerColor;

//   const _CustomCircularProgress({
//     required this.timeLeft,
//     required this.timerAnimation,
//     required this.timerColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 80,
//       height: 80,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: RadialGradient(
//           colors: [
//             Colors.black.withOpacity(0.6),
//             const Color(0xFF1A2240),
//             const Color(0xFF3C3B92),
//             const Color(0xFF5A47B6),
//           ],
//           radius: 1.0,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blueAccent.withOpacity(0.5),
//             blurRadius: 20,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           SizedBox(
//             height: 60,
//             width: 60,
//             child: AnimatedBuilder(
//               animation: timerAnimation,
//               builder: (context, child) {
//                 return CircularProgressIndicator(
//                   value: timerAnimation.value,
//                   strokeWidth: 10,
//                   valueColor: AlwaysStoppedAnimation<Color>(timerColor),
//                   backgroundColor: Colors.blueGrey.withOpacity(0.3),
//                 );
//               },
//             ),
//           ),
//           Text(
//             '${timeLeft}s',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _QuestionDisplay extends StatelessWidget {
//   final MathQuestion question;
//   final Function(int) onAnswerSelected;

//   const _QuestionDisplay({
//     required this.question,
//     required this.onAnswerSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             _buildIcon(question.operand1),
//             const SizedBox(width: 12),
//             Text(
//               question.operation == 'sum' ? "+" : "-",
//               style: const TextStyle(
//                 fontSize: 50,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(width: 12),
//             _buildIcon(question.operand2),
//             const SizedBox(width: 12),
//             const Text(
//               "= ?",
//               style: TextStyle(
//                 fontSize: 50,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         Wrap(
//           alignment: WrapAlignment.center,
//           spacing: 16,
//           runSpacing: 16,
//           children: question.choices
//               .map((value) => _buildOption(value, onAnswerSelected))
//               .toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildIcon(int number) {
//     return Image.asset(
//       'assets/number/$number.png',
//       width: 64,
//       height: 64,
//       fit: BoxFit.cover,
//     );
//   }

//   Widget _buildOption(int value, Function(int) onTap) {
//     return GestureDetector(
//       onTap: () => onTap(value),
//       child: Container(
//         margin: const EdgeInsets.all(8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           gradient: const LinearGradient(
//             colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.4),
//             width: 2,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.blue.withOpacity(0.5),
//               blurRadius: 12,
//               spreadRadius: 2,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: _buildIcon(value),
//         ),
//       ),
//     );
//   }
// }

// class _CelebrationScreen extends StatelessWidget {
//   final GameState gameState;
//   final AnimationController celebrationAnimation;
//   final VoidCallback onReset;
//   final VoidCallback onExit;

//   const _CelebrationScreen({
//     required this.gameState,
//     required this.celebrationAnimation,
//     required this.onReset,
//     required this.onExit,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: celebrationAnimation,
//       builder: (context, child) {
//         return Opacity(
//           opacity: celebrationAnimation.value,
//           child: Container(
//             color: Colors.black.withOpacity(0.85),
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     gameState.isLevelComplete
//                         ? FontAwesomeIcons.trophy
//                         : FontAwesomeIcons.rocket,
//                     color: gameState.isLevelComplete
//                         ? Colors.amber
//                         : Colors.lightBlueAccent,
//                     size: 80,
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _getCelebrationMessage(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 40),
//                   _CustomButton(
//                     text: gameState.isGameComplete ? "Chơi Lại" : "Thử Lại",
//                     icon: FontAwesomeIcons.redo,
//                     onTap: onReset,
//                   ),
//                   const SizedBox(height: 20),
//                   _CustomButton(
//                     text: "Thoát",
//                     icon: FontAwesomeIcons.doorOpen,
//                     onTap: onExit,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   String _getCelebrationMessage() {
//     if (gameState.isLevelComplete) {
//       if (gameState.isGameComplete) {
//         return "🎉 Chúc mừng! Bạn đã hoàn thành tất cả Level! 🎉";
//       } else {
//         return "⭐ Hoàn thành Level ${gameState.currentLevel.level}! Chuẩn bị sang Level ${gameState.currentLevel.level + 1}!";
//       }
//     } else {
//       return "🚀 Cố gắng hơn nhé! Thử lại Level ${gameState.currentLevel.level}!";
//     }
//   }
// }

// class _CustomButton extends StatelessWidget {
//   final String text;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _CustomButton({
//     required this.text,
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           gradient: const LinearGradient(
//             colors: [Color(0xFF4A90E2), Color(0xFF9013FE)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.blueAccent.withOpacity(0.4),
//               blurRadius: 15,
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             FaIcon(icon, color: Colors.white, size: 20),
//             const SizedBox(width: 10),
//             Text(
//               text,
//               style: const TextStyle(
//                 color: Colors.white,
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

// // Optimized animated star widget
// class _AnimatedStar extends StatefulWidget {
//   final double size;
//   final int duration;

//   const _AnimatedStar({
//     required this.size,
//     required this.duration,
//   });

//   @override
//   State<_AnimatedStar> createState() => _AnimatedStarState();
// }

// class _AnimatedStarState extends State<_AnimatedStar>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: widget.duration),
//     );

//     // Add listener to check if widget is still mounted
//     _controller.addListener(() {
//       if (_isDisposed) return;
//     });

//     _controller.repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _controller,
//       child: Icon(
//         Icons.star,
//         size: widget.size,
//         color: Colors.white,
//       ),
//     );
//   }
// }
/////////////////////////////

import 'dart:async';
import 'dart:math';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';

class SpaceGameScreen extends StatefulWidget {
  const SpaceGameScreen({
    super.key,
  });

  @override
  State<SpaceGameScreen> createState() => _SpaceGameScreenState();
}

class _SpaceGameScreenState extends State<SpaceGameScreen>
    with TickerProviderStateMixin {
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
    final rand = Random();

    for (var i = 0; i < numOfQuestions; i++) {
      String randomOperator = rand.nextBool() ? 'sum' : 'sub';
      int val1, val2, correctAnswer;

      if (randomOperator == 'sum') {
        do {
          val1 = rand.nextInt(10);
          val2 = rand.nextInt(10);
          correctAnswer = val1 + val2;
        } while (correctAnswer > 9);
      } else {
        val1 = rand.nextInt(10);
        val2 = rand.nextInt(val1 + 1);
        correctAnswer = val1 - val2;
      }

      answers.add(correctAnswer);
      questions.add([val1, val2, randomOperator]);

      // Đáp án đúng + 3 đáp án sai (không trùng)
      Set<int> answerSet = {correctAnswer};
      while (answerSet.length < 4) {
        int wrongAnswer = rand.nextInt(10);
        if (wrongAnswer != correctAnswer) {
          answerSet.add(wrongAnswer);
        }
      }

      List<int> answerOptions = answerSet.toList()..shuffle();
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
          int duration =
              levelDurations[currentLevel] ?? 30; // Thời gian theo từng level

          _animationController = AnimationController(
            vsync: this,
            duration: Duration(seconds: duration),
          );

          _animation =
              Tween<double>(begin: 1, end: 0).animate(_animationController)
                ..addListener(() {
                  setState(() {});
                });
          startTimer();
          _controller.restart(duration: (levelDurations[currentLevel] ?? 30));
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
          if (!kIsWeb)
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
                  angle: -pi /
                      2, // Xoay tên lửa nằm ngang (ngược chiều kim đồng hồ)
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
      body: kIsWeb ? PortalMasterLayout(body: _buildBody()) : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
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
                        children:
                            mcq[j].map((value) => _buildOption(value)).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
