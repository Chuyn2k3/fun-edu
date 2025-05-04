import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/data/term/app_colors.dart';
import 'package:fun_edu/data/term/app_config.dart';
import 'package:fun_edu/feature/even_old_game/widget/game_mode_selector.dart';
import 'package:fun_edu/feature/provider/game_provider.dart';
import 'package:fun_edu/model/game.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class CountShapesGameScreen extends StatefulWidget {
  const CountShapesGameScreen({Key? key, required this.mode}) : super(key: key);
  final String mode;
  @override
  State<CountShapesGameScreen> createState() => _CountShapesGameScreenState();
}

class _CountShapesGameScreenState extends State<CountShapesGameScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _timerController;

  bool _gameStarted = false;
  String _gameMode = 'practice';
  List<GameShape> _shapes = [];
  ShapeType _targetShapeType = ShapeType.circle;
  Color? _targetColor;
  int _correctAnswer = 0;
  List<int> _options = [];
  String? _result;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (_gameMode == 'challenge') {
          setState(() {
            _timeLeft = (10 * (1 - _timerController.value)).ceil();
          });

          if (_timerController.isCompleted) {
            _checkAnswer(-1); // Wrong answer if time runs out
          }
        }
      });
    Future.microtask(() {
      if (mounted) {
        _startGame(widget.mode);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _confettiController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _startGame(String mode) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.resetGame();

    setState(() {
      _gameStarted = true;
      _gameMode = mode;
    });

    _generateNewLevel();
  }

  void _generateNewLevel() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final level = gameProvider.level;

    // Generate shapes
    final shapes = gameProvider.generateShapes();

    // Determine target shape and color
    final targetShape = shapes.first.type;
    final targetColor = level > 3 ? shapes.first.color : null;

    // Count correct answer
    final correctCount = shapes
        .where((shape) =>
            shape.type == targetShape &&
            (targetColor == null || shape.color == targetColor))
        .length;

    // Generate answer options
    List<int> options = [correctCount];
    while (options.length < 4) {
      final option = math.max(0, correctCount + (math.Random().nextInt(7) - 3));
      if (!options.contains(option)) {
        options.add(option);
      }
    }

    setState(() {
      _shapes = shapes;
      _targetShapeType = targetShape;
      _targetColor = targetColor;
      _correctAnswer = correctCount;
      _options = options..shuffle();
      _result = null;

      // Reset and start timer for challenge mode
      if (_gameMode == 'challenge') {
        _timeLeft = math.max(10 - level, 5);
        _timerController.duration = Duration(seconds: _timeLeft);
        _timerController.forward(from: 0.0);
      }
    });
  }

  void _checkAnswer(int answer) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // Stop timer
    if (_gameMode == 'challenge') {
      _timerController.stop();
    }

    bool isCorrect = answer == _correctAnswer;

    gameProvider.checkCountingAnswer(answer, _correctAnswer);

    setState(() {
      _result = isCorrect ? 'correct' : 'incorrect';
    });

    if (isCorrect) {
      _confettiController.play();
    }

    // Wait before showing next level
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _generateNewLevel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        isLeading: true,
        title: 'Đuổi Hình Bắt Số',
        styleTitle: const TextStyle(
          color: Colors.pink,
          fontSize: 18,
        ),
        onTap: () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          Navigator.pop(context);
        },
      ),
      body: _buildGameContent(),
    );
  }

  Widget _buildGameContent() {
    final gameProvider = Provider.of<GameProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Game stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBadge(
                  label: 'Điểm',
                  value: '${gameProvider.score}',
                  color: AppColors.primary,
                ),
                _buildStatBadge(
                  label: 'Cấp độ',
                  value: '${gameProvider.level}',
                  color: AppColors.secondary,
                ),
                if (_gameMode == 'challenge')
                  _buildStatBadge(
                    label: 'Thời gian',
                    value: '$_timeLeft',
                    color: AppColors.accent,
                    icon: Icons.timer,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Instruction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Hãy đếm số lượng ${_targetColor != null ? '${_targetColor!.vietnameseName} ' : ''}${_targetShapeType.vietnameseName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Shapes area
            Stack(
              children: [
                Container(
                  height: context.screenSize.height * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Shapes
                        ..._shapes.map((shape) => Positioned(
                              left: shape.x * MediaQuery.of(context).size.width,
                              top: shape.y *
                                  MediaQuery.of(context).size.height *
                                  0.4,
                              child: Transform.rotate(
                                angle: shape.rotation,
                                child: SizedBox(
                                  width: shape.size,
                                  height: shape.size,
                                  child: _buildShapeWidget(shape),
                                ),
                              ),
                            )),

                        // Result overlay
                        if (_result != null)
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _result == 'correct'
                                      ? AppColors.evenColor.withOpacity(0.9)
                                      : AppColors.oddColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _result == 'correct'
                                      ? 'Đúng rồi!'
                                      : 'Sai rồi!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Confetti
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirection: math.pi / 2,
                            maxBlastForce: 5,
                            minBlastForce: 1,
                            emissionFrequency: 0.05,
                            numberOfParticles: 20,
                            gravity: 0.1,
                            colors: const [
                              Colors.green,
                              Colors.blue,
                              Colors.pink,
                              Colors.orange,
                              Colors.purple,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Answer options
            Wrap(
              //runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _options
                  .map(
                    (option) => _buildAnswerButton(
                      label: '$option',
                      onTap: () => _checkAnswer(option),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeWidget(GameShape shape) {
    switch (shape.type) {
      case ShapeType.circle:
        return Container(
          decoration: BoxDecoration(
            color: shape.color,
            shape: BoxShape.circle,
          ),
        );
      case ShapeType.square:
        return Container(
          decoration: BoxDecoration(
            color: shape.color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      case ShapeType.triangle:
        return CustomPaint(
          painter: TrianglePainter(color: shape.color),
          size: Size.square(shape.size),
        );
    }
  }

  Widget _buildAnswerButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
