import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fun_edu/data/term/app_colors.dart';
import 'package:fun_edu/feature/even_old_game/widget/game_mode_selector.dart';
import 'package:fun_edu/feature/provider/game_provider.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/widget/dashed_border_painter.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class EvenOddGameScreen extends StatefulWidget {
  const EvenOddGameScreen({Key? key, required this.mode}) : super(key: key);
  final String mode;
  @override
  State<EvenOddGameScreen> createState() => _EvenOddGameScreenState();
}

class _EvenOddGameScreenState extends State<EvenOddGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _dragController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _timerController;
  late ConfettiController _confettiController;

  bool _gameStarted = false;
  String _gameMode = 'practice';
  int _currentNumber = 0;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  String? _result;
  int _timeLeft = 0;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

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
            _checkAnswer(false); // Wrong answer if time runs out
          }
        }
      });
    Future.microtask(() {
      if (mounted) {
        _startGame(widget.mode);
      }
    });
    _setupTTS();
    _playVoice();
  }

  void _setupTTS() async {
    await flutterTts.setLanguage('vi-VN');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.00);
  }

  void _playVoice() async {
    await flutterTts.speak("Kéo số vào ô chẵn hoặc lẻ");
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _dragController.dispose();
    _bounceController.dispose();
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
    _generateNewNumber();
  }

  void _generateNewNumber() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final level = gameProvider.level;
    setState(() {
      _currentNumber = gameProvider.generateRandomNumber();
      _dragOffset = Offset.zero;
      _result = null;
      if (_gameMode == 'challenge') {
        _timeLeft = math.max(10 - level, 5);
        _timerController.duration = Duration(seconds: _timeLeft);
        _timerController.forward(from: 0.0);
      }
    });

    // Bounce animation for new number
    _bounceController.forward(from: 0.0);
  }

  void _checkAnswer(bool isEvenAnswer) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // Stop timer
    if (_gameMode == 'challenge') {
      _timerController.stop();
    }

    bool isEven = gameProvider.isEven(_currentNumber);
    bool isCorrect = (isEven && isEvenAnswer) || (!isEven && !isEvenAnswer);

    gameProvider.checkEvenOddAnswer(_currentNumber, isEvenAnswer);

    setState(() {
      _result = isCorrect ? 'correct' : 'incorrect';
    });

    if (isCorrect) {
      _confettiController.play();
    }

    // Wait before showing next number
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _generateNewNumber();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: CustomAppbar.basic(
        isLeading: true,
        title: 'Phân Biệt Số Chẵn, Lẻ',
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

  Widget _buildModeSelector() {
    return GameModeSelector(
      onSelectMode: _startGame,
      practiceDescription: 'Không giới hạn thời gian',
      challengeDescription: 'Độ khó tăng dần',
    );
  }

  Widget _buildGameContent() {
    final gameProvider = Provider.of<GameProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Game stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBadge(
                  label: 'Điểm',
                  value: '${gameProvider.score}',
                  color: Colors.pink
                  //AppColors.secondary,
                  ),
              if (gameProvider.combo > 1)
                _buildStatBadge(
                  label: 'Combo',
                  value: 'x${gameProvider.combo}',
                  color: AppColors.accent,
                  icon: Icons.star_rounded,
                ),
              if (_gameMode == 'challenge')
                _buildStatBadge(
                  label: 'Thời gian',
                  value: '$_timeLeft',
                  color: AppColors.accent,
                  icon: Icons.timer,
                ),
              _buildStatBadge(
                  label: 'Chế độ',
                  value: _gameMode == 'practice' ? 'Luyện Tập' : 'Thử Thách',
                  color: Colors.blue
                  //AppColors.primary,
                  ),
            ],
          ),

          const SizedBox(height: 40),

          // Game area
          Expanded(
            child: Stack(
              children: [
                // Even container (left)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: _buildDropContainer(
                    label: 'CHẴN',
                    color: const Color(0xFF48BB78),
                    //Colors.green,
                    //AppColors.evenColor,
                    isHighlighted: _isDragging && _dragOffset.dx < -50,
                  ),
                ),

                // Odd container (right)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: _buildDropContainer(
                    label: 'LẺ',
                    color: Colors.pink,
                    //AppColors.oddColor,
                    isHighlighted: _isDragging && _dragOffset.dx > 50,
                  ),
                ),

                // Draggable number
                if (_result == null)
                  Center(
                    child: GestureDetector(
                      onPanStart: (_) {
                        setState(() {
                          _isDragging = true;
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _dragOffset += details.delta;
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _isDragging = false;

                          // Check if dragged to even container
                          if (_dragOffset.dx < -100) {
                            _checkAnswer(true);
                          }
                          // Check if dragged to odd container
                          else if (_dragOffset.dx > 100) {
                            _checkAnswer(false);
                          } else {
                            _dragOffset = Offset.zero;
                          }
                        });
                      },
                      child: Transform.translate(
                        offset: _dragOffset,
                        child: ScaleTransition(
                          scale: _bounceAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$_currentNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Result overlay
                if (_result != null)
                  Center(
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
                        _result == 'correct' ? 'Đúng rồi!' : 'Sai rồi!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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

          const SizedBox(height: 20),

          // Answer buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAnswerButton(
                label: 'Chẵn',
                color: const Color(0xFF48BB78),
                onTap: () => _checkAnswer(true),
              ),
              _buildAnswerButton(
                label: 'Lẻ',
                color: Colors.pink,
                onTap: () => _checkAnswer(false),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Kéo số vào ô tương ứng hoặc nhấn nút bên dưới để trả lời',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
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

  Widget _buildDropContainer({
    required String label,
    required Color color,
    required bool isHighlighted,
  }) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color.withOpacity(isHighlighted ? 0.8 : 0.9),
        strokeWidth: 4,
        dashWidth: 14,
        dashSpace: 4,
        borderRadius: 24,
      ),
      child: Container(
        // margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(isHighlighted ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kéo thả vào đây',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
