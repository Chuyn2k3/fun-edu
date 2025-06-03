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
  int currentLevel = 1;

  // Cơ chế điểm đạt mới
  final Map<int, int> levelQuestions = {1: 5, 2: 8, 3: 12, 4: 15};

  final Map<int, double> levelPassRates = {
    1: 0.60, // 60% = 3/5 câu đúng
    2: 0.65, // 65% = 5-6/8 câu đúng
    3: 0.70, // 70% = 8-9/12 câu đúng
    4: 0.75, // 75% = 11-12/15 câu đúng
  };

  final Map<int, int> levelDurations = {1: 30, 2: 25, 3: 22, 4: 20};

  bool isMarked = false;
  bool isCorrect = false;
  bool isComplete = false;
  bool isProcessing = false;
  int starsEarned = 0;

  // Nullable controllers để tránh late initialization error
  AnimationController? _spaceshipController;
  Animation<double>? _spaceshipAnimation;
  AnimationController? _celebrationController;
  AnimationController? _starController;
  Animation<double>? _starAnimation;
  final CountDownController _controller = CountDownController();

  AnimationController? _animationController;
  Animation<double>? _animation;
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

    _initializeControllers();
    _generateQuestions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNewQuestion();
    });
  }

  void _initializeControllers() {
    _spaceshipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _spaceshipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spaceshipController!, curve: Curves.easeInOut),
    );

    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController!, curve: Curves.elasticOut),
    );

    _initializeTimerController();
  }

  void _initializeTimerController() {
    _animationController?.dispose();

    int duration = levelDurations[currentLevel] ?? 30;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: duration),
    );

    _animation = Tween<double>(begin: 1, end: 0).animate(_animationController!)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          !isMarked &&
          !isProcessing &&
          mounted) {
        _handleTimeout();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (smallStars.isEmpty) {
      _initializeSmallStars();
    }
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

  void _startNewQuestion() {
    if (!mounted) return;

    setState(() {
      isMarked = false;
      isProcessing = false;
    });

    _startTimer();
  }

  void _startTimer() {
    if (!mounted) return;

    timer?.cancel();
    timeLeft = levelDurations[currentLevel] ?? 30;

    _animationController?.reset();
    _animationController?.forward();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        if (!isMarked && !isProcessing) {
          _handleTimeout();
        }
      }
    });
  }

  void _handleTimeout() {
    if (isProcessing || !mounted) return;
    _changeQuestion('TimeOut');
  }

  void _generateQuestions() {
    questions.clear();
    answers.clear();
    mcq.clear();

    int numOfQuestions = levelQuestions[currentLevel] ?? 10;
    final rand = Random();

    for (var i = 0; i < numOfQuestions; i++) {
      String randomOperator;
      int val1, val2, correctAnswer;

      // Tăng độ khó theo level với phép nhân được giới hạn
      switch (currentLevel) {
        case 1:
          // Level 1: Chỉ phép cộng 0-5
          randomOperator = 'sum';
          do {
            val1 = rand.nextInt(6);
            val2 = rand.nextInt(6);
            correctAnswer = val1 + val2;
          } while (correctAnswer > 9);
          break;

        case 2:
          // Level 2: Phép cộng/trừ 0-10
          randomOperator = rand.nextBool() ? 'sum' : 'sub';
          if (randomOperator == 'sum') {
            do {
              val1 = rand.nextInt(8);
              val2 = rand.nextInt(8);
              correctAnswer = val1 + val2;
            } while (correctAnswer > 9);
          } else {
            val1 = rand.nextInt(10);
            val2 = rand.nextInt(val1 + 1);
            correctAnswer = val1 - val2;
          }
          break;

        case 3:
          // Level 3: Phép cộng/trừ + nhân đơn giản (kết quả ≤ 9)
          List<String> operators = ['sum', 'sub', 'mul'];
          randomOperator = operators[rand.nextInt(operators.length)];

          if (randomOperator == 'sum') {
            do {
              val1 = rand.nextInt(8);
              val2 = rand.nextInt(8);
              correctAnswer = val1 + val2;
            } while (correctAnswer > 9);
          } else if (randomOperator == 'sub') {
            val1 = rand.nextInt(10);
            val2 = rand.nextInt(val1 + 1);
            correctAnswer = val1 - val2;
          } else {
            // Phép nhân: chỉ tạo các phép tính có kết quả ≤ 9
            List<List<int>> validMultiplications = [
              [1, 1],
              [1, 2],
              [1, 3],
              [1, 4],
              [1, 5],
              [1, 6],
              [1, 7],
              [1, 8],
              [1, 9],
              [2, 2],
              [2, 3],
              [2, 4],
              [3, 3]
            ];
            var selectedPair =
                validMultiplications[rand.nextInt(validMultiplications.length)];
            val1 = selectedPair[0];
            val2 = selectedPair[1];
            correctAnswer = val1 * val2;
          }
          break;

        case 4:
          // Level 4: Tất cả phép tính với phép nhân được giới hạn
          List<String> operators = ['sum', 'sub', 'mul'];
          randomOperator = operators[rand.nextInt(operators.length)];

          if (randomOperator == 'sum') {
            do {
              val1 = rand.nextInt(8);
              val2 = rand.nextInt(8);
              correctAnswer = val1 + val2;
            } while (correctAnswer > 9);
          } else if (randomOperator == 'sub') {
            val1 = rand.nextInt(10);
            val2 = rand.nextInt(val1 + 1);
            correctAnswer = val1 - val2;
          } else {
            // Phép nhân: mở rộng thêm một số phép tính
            List<List<int>> validMultiplications = [
              [1, 1],
              [1, 2],
              [1, 3],
              [1, 4],
              [1, 5],
              [1, 6],
              [1, 7],
              [1, 8],
              [1, 9],
              [2, 2],
              [2, 3],
              [2, 4],
              [3, 3],
              [3, 2],
              [3, 1],
              [4, 2],
              [4, 1],
              [5, 1],
              [6, 1],
              [7, 1],
              [8, 1],
              [9, 1]
            ];
            var selectedPair =
                validMultiplications[rand.nextInt(validMultiplications.length)];
            val1 = selectedPair[0];
            val2 = selectedPair[1];
            correctAnswer = val1 * val2;
          }
          break;

        default:
          randomOperator = rand.nextBool() ? 'sum' : 'sub';
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
      }

      answers.add(correctAnswer);
      questions.add([val1, val2, randomOperator]);

      // Tạo đáp án sai trong khoảng 0-9
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

  // Tính số sao dựa trên tỷ lệ đúng
  int _calculateStars(double accuracy) {
    if (accuracy >= 1.0) return 3; // 100% = 3 sao
    if (accuracy >= 0.8) return 2; // 80-99% = 2 sao
    if (accuracy >= (levelPassRates[currentLevel] ?? 0.6))
      return 1; // Đạt tỷ lệ tối thiểu = 1 sao
    return 0; // Không đạt
  }

  void _changeQuestion(String answer) {
    if (isProcessing || !mounted) return;

    setState(() {
      isProcessing = true;
      isMarked = true;
    });

    timer?.cancel();
    _animationController?.stop();

    userAnswer.add(answer);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (j + 1 >= questions.length) {
        double accuracy = score / (levelQuestions[currentLevel] ?? 10);
        double requiredRate = levelPassRates[currentLevel] ?? 0.6;
        starsEarned = _calculateStars(accuracy);

        if (accuracy >= requiredRate) {
          if (currentLevel == 4) {
            setState(() {
              isComplete = true;
            });
            _celebrationController?.forward();
            _starController?.forward();
          } else {
            _nextLevel();
          }
        } else {
          setState(() {
            isComplete = true;
          });
          _celebrationController?.forward();
        }
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextLevel() {
    if (!mounted) return;

    setState(() {
      currentLevel++;
      score = 0;
      progress = 0.0;
      userAnswer.clear();
      j = 0;
    });

    _generateQuestions();
    _initializeTimerController();
    _startNewQuestion();
    _controller.restart(duration: (levelDurations[currentLevel] ?? 30));
  }

  void _nextQuestion() {
    if (!mounted) return;

    setState(() {
      j++;
    });

    _initializeTimerController();
    _startNewQuestion();
    _controller.restart(duration: (levelDurations[currentLevel] ?? 30));
  }

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
      onTap: isProcessing
          ? null
          : () {
              if (isMarked || isProcessing || !mounted) return;

              setState(() {
                isCorrect = value == answers[j];
                if (isCorrect) {
                  score++;
                  progress += 1 / (levelQuestions[currentLevel] ?? 10);
                  _spaceshipController?.forward(from: 0);
                }
              });

              _changeQuestion(value.toString());
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: isProcessing
                ? [Colors.grey, Colors.grey.shade400]
                : [Color(0xFF6A11CB), Color(0xFF2575FC)],
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

  Widget _buildScoreDisplay() {
    double currentAccuracy = j > 0 ? score / j : 0.0;
    double requiredRate = levelPassRates[currentLevel] ?? 0.6;
    int totalQuestions = levelQuestions[currentLevel] ?? 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.purple.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                '$score/$totalQuestions',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Điểm',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${(currentAccuracy * 100).toInt()}%',
                style: TextStyle(
                  color: currentAccuracy >= requiredRate
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Hiện tại',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${(requiredRate * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Cần đạt',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  int predictedStars = _calculateStars(currentAccuracy);
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: index < predictedStars
                        ? Colors.amber
                        : Colors.white.withOpacity(0.3),
                  );
                }),
              ),
              Text(
                'Sao dự kiến',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
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
        children: [
          if (!kIsWeb)
            GestureDetector(
              onTap: () {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
                Navigator.pop(context);
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
                    if (_spaceshipAnimation != null)
                      AnimatedBuilder(
                        animation: _spaceshipAnimation!,
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
                                        Colors.red,
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
    if (questions.isEmpty || j >= questions.length) {
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
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      children: [
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
                      _buildScoreDisplay(),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildIcons(questions[j][0]),
                          const SizedBox(width: 12),
                          Text(
                            _getOperatorSymbol(questions[j][2]),
                            style: const TextStyle(
                              fontSize: 50,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildIcons(questions[j][1]),
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

  String _getOperatorSymbol(String operator) {
    switch (operator) {
      case 'sum':
        return '+';
      case 'sub':
        return '-';
      case 'mul':
        return '×';
      case 'div':
        return '÷';
      default:
        return '+';
    }
  }

  Widget _buildCelebrationScreen() {
    double accuracy = score / (levelQuestions[currentLevel] ?? 10);
    double requiredRate = levelPassRates[currentLevel] ?? 0.6;
    bool passed = accuracy >= requiredRate;

    return AnimatedBuilder(
      animation: _celebrationController ?? AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Opacity(
          opacity: _celebrationController?.value ?? 1.0,
          child: Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    passed
                        ? (currentLevel == 4 && passed
                            ? FontAwesomeIcons.trophy
                            : FontAwesomeIcons.rocket)
                        : FontAwesomeIcons.redo,
                    color: passed
                        ? (currentLevel == 4 && passed
                            ? Colors.amber
                            : Colors.lightBlueAccent)
                        : Colors.orange,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  if (passed) ...[
                    AnimatedBuilder(
                      animation: _starAnimation ?? AlwaysStoppedAnimation(1.0),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _starAnimation?.value ?? 1.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return AnimatedContainer(
                                duration:
                                    Duration(milliseconds: 200 * (index + 1)),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.star,
                                  size: 40,
                                  color: index < starsEarned
                                      ? Colors.amber
                                      : Colors.white.withOpacity(0.3),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$starsEarned/3 Sao',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.purple.withOpacity(0.2),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Level $currentLevel - Kết Quả',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$score/${levelQuestions[currentLevel]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Điểm',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${(accuracy * 100).toInt()}%',
                                  style: TextStyle(
                                    color: passed ? Colors.green : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Đạt được',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${(requiredRate * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Yêu cầu',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    passed
                        ? (currentLevel == 4
                            ? "🎉 Chúc mừng! Bạn đã hoàn thành tất cả Level! 🎉"
                            : "⭐ Hoàn thành Level $currentLevel! Chuẩn bị sang Level ${currentLevel + 1}!")
                        : "🚀 Cần ${(requiredRate * 100).toInt()}% để qua level! Thử lại nhé!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildCustomButton(
                    text: passed && currentLevel == 4 ? "Chơi Lại" : "Thử Lại",
                    icon: FontAwesomeIcons.redo,
                    onTap: () {
                      _resetGame(passed && currentLevel == 4);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (!kIsWeb)
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
                        Navigator.pop(context);
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

  void _resetGame(bool resetToLevel1) {
    timer?.cancel();
    _animationController?.stop();

    setState(() {
      if (resetToLevel1) {
        currentLevel = 1;
      }
      score = 0;
      progress = 0.0;
      userAnswer.clear();
      j = 0;
      starsEarned = 0;
      isComplete = false;
      isProcessing = false;
      isMarked = false;
    });

    _generateQuestions();
    _initializeTimerController();
    _celebrationController?.reset();
    _starController?.reset();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNewQuestion();
    });
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
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                value: _animation?.value ?? 1.0,
                strokeWidth: 10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  valueColorCountdown(),
                ),
                backgroundColor: Colors.blueGrey.withOpacity(0.3),
              ),
            ),
            RotationTransition(
              turns: AlwaysStoppedAnimation((_animation?.value ?? 1.0) /
                  (levelDurations[currentLevel] ?? 30)),
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
    timer?.cancel();
    _spaceshipController?.dispose();
    _celebrationController?.dispose();
    _starController?.dispose();
    _animationController?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
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
      child: Stack(
        children: [
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
          ...smallStars,
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
          const Positioned(
            top: 50,
            right: -100,
            child: AnimatedMeteor(
              size: 100,
              duration: 30000,
              image: 'assets/images/meteor.png',
            ),
          ),
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

// Các widget animation giữ nguyên
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
          offset: Offset(value * 400, value * 200),
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
          offset: Offset(
              _controller.value * 400 - 200, _controller.value * 150 - 75),
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
