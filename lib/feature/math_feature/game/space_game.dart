import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

// Data models for better structure
class GameLevel {
  final int level;
  final int questionCount;
  final int duration;

  const GameLevel({
    required this.level,
    required this.questionCount,
    required this.duration,
  });
}

class MathQuestion {
  final int operand1;
  final int operand2;
  final String operation;
  final int correctAnswer;
  final List<int> choices;

  MathQuestion({
    required this.operand1,
    required this.operand2,
    required this.operation,
    required this.correctAnswer,
    required this.choices,
  });
}

class GameState {
  final GameLevel currentLevel;
  final List<MathQuestion> questions;
  final int currentQuestionIndex;
  final int score;
  final double progress;
  final bool isComplete;
  final bool isCorrect;
  final int timeLeft;

  const GameState({
    required this.currentLevel,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.score = 0,
    this.progress = 0.0,
    this.isComplete = false,
    this.isCorrect = false,
    this.timeLeft = 30,
  });

  GameState copyWith({
    GameLevel? currentLevel,
    List<MathQuestion>? questions,
    int? currentQuestionIndex,
    int? score,
    double? progress,
    bool? isComplete,
    bool? isCorrect,
    int? timeLeft,
  }) {
    return GameState(
      currentLevel: currentLevel ?? this.currentLevel,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      progress: progress ?? this.progress,
      isComplete: isComplete ?? this.isComplete,
      isCorrect: isCorrect ?? this.isCorrect,
      timeLeft: timeLeft ?? this.timeLeft,
    );
  }

  MathQuestion get currentQuestion => questions[currentQuestionIndex];
  bool get hasMoreQuestions => currentQuestionIndex < questions.length - 1;
  bool get isLevelComplete => score == currentLevel.questionCount;
  bool get isGameComplete => currentLevel.level == 4 && isLevelComplete;
}

// Service for generating questions
class QuestionGenerator {
  static final Random _random = Random();

  static List<MathQuestion> generateQuestions(int count) {
    final questions = <MathQuestion>[];

    for (int i = 0; i < count; i++) {
      final operation = _random.nextBool() ? 'sum' : 'sub';
      late int operand1, operand2, correctAnswer;

      if (operation == 'sum') {
        do {
          operand1 = _random.nextInt(10);
          operand2 = _random.nextInt(10);
          correctAnswer = operand1 + operand2;
        } while (correctAnswer > 9);
      } else {
        operand1 = _random.nextInt(10);
        operand2 = _random.nextInt(operand1 + 1);
        correctAnswer = operand1 - operand2;
      }

      // Generate unique choices
      final choicesSet = <int>{correctAnswer};
      while (choicesSet.length < 4) {
        final wrongAnswer = _random.nextInt(10);
        choicesSet.add(wrongAnswer);
      }

      final choices = choicesSet.toList()..shuffle(_random);

      questions.add(MathQuestion(
        operand1: operand1,
        operand2: operand2,
        operation: operation,
        correctAnswer: correctAnswer,
        choices: choices,
      ));
    }

    return questions;
  }
}

// Game configuration
class GameConfig {
  static const List<GameLevel> levels = [
    GameLevel(level: 1, questionCount: 5, duration: 30),
    GameLevel(level: 2, questionCount: 10, duration: 25),
    GameLevel(level: 3, questionCount: 15, duration: 20),
    GameLevel(level: 4, questionCount: 20, duration: 15),
  ];

  static GameLevel getLevelConfig(int level) {
    return levels.firstWhere((l) => l.level == level,
        orElse: () => levels.first);
  }
}

class SpaceGameScreen extends StatefulWidget {
  const SpaceGameScreen({super.key});

  @override
  State<SpaceGameScreen> createState() => _SpaceGameScreenState();
}

class _SpaceGameScreenState extends State<SpaceGameScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _spaceshipController;
  late final AnimationController _celebrationController;
  late final AnimationController _timerController;

  // Animations
  late final Animation<double> _spaceshipAnimation;
  late final Animation<double> _timerAnimation;

  // Game state
  GameState _gameState = GameState(
    currentLevel: GameConfig.levels.first,
    questions: QuestionGenerator.generateQuestions(
        GameConfig.levels.first.questionCount),
  );

  // Timer
  Timer? _gameTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _initializeAnimations();
    _startNewLevel();
  }

  void _initializeScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializeAnimations() {
    _spaceshipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _gameState.currentLevel.duration),
    );

    _spaceshipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spaceshipController, curve: Curves.easeInOut),
    );

    _timerAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_timerController);

    // Add status listener for timer
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isDisposed) {
        _handleTimeOut();
      }
    });
  }

  void _startNewLevel() {
    _gameTimer?.cancel();

    if (!_isDisposed) {
      setState(() {
        _gameState = _gameState.copyWith(
          timeLeft: _gameState.currentLevel.duration,
        );
      });

      _timerController.duration =
          Duration(seconds: _gameState.currentLevel.duration);
      _timerController.reset();
      _timerController.forward();
      _startTimer();
    }
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_gameState.timeLeft > 0) {
        setState(() {
          _gameState = _gameState.copyWith(timeLeft: _gameState.timeLeft - 1);
        });
      } else {
        timer.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    if (_isDisposed) return;
    _handleAnswer(-1); // Invalid answer for timeout
  }

  void _handleAnswer(int selectedAnswer) {
    if (_isDisposed) return;

    _gameTimer?.cancel();

    final isCorrect =
        selectedAnswer == _gameState.currentQuestion.correctAnswer;

    setState(() {
      _gameState = _gameState.copyWith(
        isCorrect: isCorrect,
        score: isCorrect ? _gameState.score + 1 : _gameState.score,
        progress: isCorrect
            ? _gameState.progress +
                (1.0 / _gameState.currentLevel.questionCount)
            : _gameState.progress,
      );
    });

    if (isCorrect && !_isDisposed) {
      _spaceshipController.forward(from: 0);
    }

    // Move to next question or complete level
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isDisposed) return;

      if (_gameState.hasMoreQuestions) {
        _nextQuestion();
      } else {
        _completeLevel();
      }
    });
  }

  void _nextQuestion() {
    if (_isDisposed) return;

    setState(() {
      _gameState = _gameState.copyWith(
        currentQuestionIndex: _gameState.currentQuestionIndex + 1,
        isCorrect: false,
      );
    });

    _startNewLevel();
  }

  void _completeLevel() {
    if (_isDisposed) return;

    if (_gameState.isLevelComplete) {
      if (_gameState.isGameComplete) {
        _showCelebration();
      } else {
        _advanceToNextLevel();
      }
    } else {
      _showCelebration();
    }
  }

  void _advanceToNextLevel() {
    if (_isDisposed) return;

    final nextLevel =
        GameConfig.getLevelConfig(_gameState.currentLevel.level + 1);
    final newQuestions =
        QuestionGenerator.generateQuestions(nextLevel.questionCount);

    setState(() {
      _gameState = GameState(
        currentLevel: nextLevel,
        questions: newQuestions,
        currentQuestionIndex: 0,
        score: 0,
        progress: 0.0,
      );
    });

    _startNewLevel();
  }

  void _showCelebration() {
    if (_isDisposed) return;

    setState(() {
      _gameState = _gameState.copyWith(isComplete: true);
    });

    _celebrationController.forward();
  }

  void _resetGame() {
    if (_isDisposed) return;

    final firstLevel = GameConfig.levels.first;
    final newQuestions =
        QuestionGenerator.generateQuestions(firstLevel.questionCount);

    setState(() {
      _gameState = GameState(
        currentLevel: firstLevel,
        questions: newQuestions,
      );
    });

    _celebrationController.reset();
    _startNewLevel();
  }

  void _exitGame() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (mounted) {
      context.pop();
    }
  }

  Color _getTimerColor() {
    final ratio = _gameState.timeLeft / _gameState.currentLevel.duration;
    if (ratio > 0.6) return Colors.green;
    if (ratio > 0.3) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _gameTimer?.cancel();
    _spaceshipController.dispose();
    _celebrationController.dispose();
    _timerController.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AnimatedBackground(),
          if (_gameState.isComplete) ...[
            _CelebrationScreen(
              gameState: _gameState,
              celebrationAnimation: _celebrationController,
              onReset: _resetGame,
              onExit: _exitGame,
            ),
          ] else ...[
            _GameContent(
              gameState: _gameState,
              spaceshipAnimation: _spaceshipAnimation,
              timerAnimation: _timerAnimation,
              timerColor: _getTimerColor(),
              onAnswerSelected: _handleAnswer,
              onExit: _exitGame,
            ),
          ],
        ],
      ),
    );
  }
}

// Separate widgets for better performance and lifecycle management
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: const Stack(
        children: [
          // Reduced number of animated elements for better performance
          Positioned(
            bottom: 200,
            right: 200,
            child: _AnimatedStar(size: 25, duration: 14000),
          ),
          Positioned(
            bottom: 120,
            left: 180,
            child: _AnimatedStar(size: 22, duration: 12000),
          ),
          Positioned(
            top: 150,
            left: 60,
            child: _AnimatedStar(size: 18, duration: 18000),
          ),
          Positioned(
            top: 80,
            right: 100,
            child: _AnimatedStar(size: 20, duration: 16000),
          ),
        ],
      ),
    );
  }
}

class _GameContent extends StatelessWidget {
  final GameState gameState;
  final Animation<double> spaceshipAnimation;
  final Animation<double> timerAnimation;
  final Color timerColor;
  final Function(int) onAnswerSelected;
  final VoidCallback onExit;

  const _GameContent({
    required this.gameState,
    required this.spaceshipAnimation,
    required this.timerAnimation,
    required this.timerColor,
    required this.onAnswerSelected,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _EnergyBar(
            progress: gameState.progress,
            spaceshipAnimation: spaceshipAnimation,
            onExit: onExit,
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "🌟 Level ${gameState.currentLevel.level}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 20),
                _CustomCircularProgress(
                  timeLeft: gameState.timeLeft,
                  timerAnimation: timerAnimation,
                  timerColor: timerColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _QuestionDisplay(
            question: gameState.currentQuestion,
            onAnswerSelected: onAnswerSelected,
          ),
        ],
      ),
    );
  }
}

class _EnergyBar extends StatelessWidget {
  final double progress;
  final Animation<double> spaceshipAnimation;
  final VoidCallback onExit;

  const _EnergyBar({
    required this.progress,
    required this.spaceshipAnimation,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onExit,
            child: Container(
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
                ],
              ),
              child: Transform.rotate(
                angle: -pi / 2,
                child: const FaIcon(
                  FontAwesomeIcons.rocket,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 36),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: spaceshipAnimation,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.green,
                                      Colors.yellow,
                                      Colors.red
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -20,
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
                                    shaderCallback: const LinearGradient(
                                      colors: [
                                        Colors.blue,
                                        Colors.cyanAccent,
                                        Colors.white
                                      ],
                                    ).createShader,
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
}

class _CustomCircularProgress extends StatelessWidget {
  final int timeLeft;
  final Animation<double> timerAnimation;
  final Color timerColor;

  const _CustomCircularProgress({
    required this.timeLeft,
    required this.timerAnimation,
    required this.timerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            const Color(0xFF1A2240),
            const Color(0xFF3C3B92),
            const Color(0xFF5A47B6),
          ],
          radius: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: AnimatedBuilder(
              animation: timerAnimation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: timerAnimation.value,
                  strokeWidth: 10,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  backgroundColor: Colors.blueGrey.withOpacity(0.3),
                );
              },
            ),
          ),
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
    );
  }
}

class _QuestionDisplay extends StatelessWidget {
  final MathQuestion question;
  final Function(int) onAnswerSelected;

  const _QuestionDisplay({
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(question.operand1),
            const SizedBox(width: 12),
            Text(
              question.operation == 'sum' ? "+" : "-",
              style: const TextStyle(
                fontSize: 50,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            _buildIcon(question.operand2),
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: question.choices
              .map((value) => _buildOption(value, onAnswerSelected))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildIcon(int number) {
    return Image.asset(
      'assets/number/$number.png',
      width: 64,
      height: 64,
      fit: BoxFit.cover,
    );
  }

  Widget _buildOption(int value, Function(int) onTap) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildIcon(value),
        ),
      ),
    );
  }
}

class _CelebrationScreen extends StatelessWidget {
  final GameState gameState;
  final AnimationController celebrationAnimation;
  final VoidCallback onReset;
  final VoidCallback onExit;

  const _CelebrationScreen({
    required this.gameState,
    required this.celebrationAnimation,
    required this.onReset,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebrationAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: celebrationAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    gameState.isLevelComplete
                        ? FontAwesomeIcons.trophy
                        : FontAwesomeIcons.rocket,
                    color: gameState.isLevelComplete
                        ? Colors.amber
                        : Colors.lightBlueAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _getCelebrationMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _CustomButton(
                    text: gameState.isGameComplete ? "Chơi Lại" : "Thử Lại",
                    icon: FontAwesomeIcons.redo,
                    onTap: onReset,
                  ),
                  const SizedBox(height: 20),
                  _CustomButton(
                    text: "Thoát",
                    icon: FontAwesomeIcons.doorOpen,
                    onTap: onExit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCelebrationMessage() {
    if (gameState.isLevelComplete) {
      if (gameState.isGameComplete) {
        return "🎉 Chúc mừng! Bạn đã hoàn thành tất cả Level! 🎉";
      } else {
        return "⭐ Hoàn thành Level ${gameState.currentLevel.level}! Chuẩn bị sang Level ${gameState.currentLevel.level + 1}!";
      }
    } else {
      return "🚀 Cố gắng hơn nhé! Thử lại Level ${gameState.currentLevel.level}!";
    }
  }
}

class _CustomButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _CustomButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

// Optimized animated star widget
class _AnimatedStar extends StatefulWidget {
  final double size;
  final int duration;

  const _AnimatedStar({
    required this.size,
    required this.duration,
  });

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );

    // Add listener to check if widget is still mounted
    _controller.addListener(() {
      if (_isDisposed) return;
    });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
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
}
