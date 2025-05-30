import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/core/repositories/question_repository.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/feature/user/cubit/coin/update_user_coin_cubit.dart';
import 'package:fun_edu/model/question_model.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';
import 'package:fun_edu/providers/questions.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:fun_edu/widget/answer_card.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:styled_divider/styled_divider.dart';

// Separate state management for better performance
class DailyTaskState {
  final bool isLoading;
  final bool isAnswered;
  final bool isDailyTaskCompleted;
  final String? errorMessage;
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final int selectedAnswerIndex;
  final int correctCount;
  final int earnedCoins;
  final int streakCount;
  final double progress;

  const DailyTaskState({
    this.isLoading = true,
    this.isAnswered = false,
    this.isDailyTaskCompleted = false,
    this.errorMessage,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedAnswerIndex = -1,
    this.correctCount = 0,
    this.earnedCoins = 0,
    this.streakCount = 0,
    this.progress = 0.0,
  });

  DailyTaskState copyWith({
    bool? isLoading,
    bool? isAnswered,
    bool? isDailyTaskCompleted,
    String? errorMessage,
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    int? selectedAnswerIndex,
    int? correctCount,
    int? earnedCoins,
    int? streakCount,
    double? progress,
  }) {
    return DailyTaskState(
      isLoading: isLoading ?? this.isLoading,
      isAnswered: isAnswered ?? this.isAnswered,
      isDailyTaskCompleted: isDailyTaskCompleted ?? this.isDailyTaskCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswerIndex: selectedAnswerIndex ?? this.selectedAnswerIndex,
      correctCount: correctCount ?? this.correctCount,
      earnedCoins: earnedCoins ?? this.earnedCoins,
      streakCount: streakCount ?? this.streakCount,
      progress: progress ?? this.progress,
    );
  }

  QuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;
}

// Separate business logic into a controller
class DailyTaskController {
  static const int totalQuestions = 10;
  static const int coinsPerCorrectAnswer = 5;
  static const int bonusCoinsForCompletion = 20;

  final QuestionRepository _questionRepository;
  final SharedPreferencesManager _prefsManager;

  DailyTaskController(this._questionRepository, this._prefsManager);

  Future<bool> checkAndResetDailyTasks() async {
    try {
      final lastCompletionDate =
          _prefsManager.getString("last_daily_task_date");
      final currentDate = DateTime.now().toIso8601String().split('T')[0];

      if (lastCompletionDate != currentDate) {
        final yesterday = DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0];

        final maintainStreak = lastCompletionDate == yesterday;

        await _prefsManager.putString("last_daily_task_date", currentDate);
        await _prefsManager.putBool("daily_task_completed", false);

        if (!maintainStreak) {
          await _prefsManager.putInt("streak_count", 0);
        }

        return false; // Task not completed today
      }

      return _prefsManager.getBool("daily_task_completed") ?? false;
    } catch (e) {
      debugPrint('Error checking daily tasks: $e');
      return false;
    }
  }

  Future<List<QuestionModel>> loadQuestions() async {
    final result = await _questionRepository.getQuestionDaily();
    final questions = result.data?.content ?? [];

    return questions.length > totalQuestions
        ? questions.take(totalQuestions).toList()
        : questions;
  }

  int getCorrectAnswerIndex(QuestionModel question) {
    final answers = question.answers;
    if (answers == null || answers.isEmpty) return -1;
    return answers.indexWhere((e) => e.isCorrect ?? false);
  }

  Future<void> updateUserCoins(String? deviceId, int currentCoins,
      int earnedCoins, UpdateUserCoinCubit cubit) async {
    if (deviceId?.isNotEmpty == true) {
      final request = UserInfoByDeviceIdModel(
        deviceId: deviceId,
        coin: currentCoins + earnedCoins,
      );
      cubit.updateUserCoin(request: request);
    }

    await _prefsManager.putBool("daily_task_completed", true);
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    await _prefsManager.putString("last_daily_task_date", currentDate);

    final currentStreak = _prefsManager.getInt("streak_count") ?? 0;
    await _prefsManager.putInt("streak_count", currentStreak + 1);
  }

  int getCurrentStreak() => _prefsManager.getInt("streak_count") ?? 0;
}

class DailyTaskScreen extends StatefulWidget {
  const DailyTaskScreen({
    Key? key,
    required this.userCoin,
  }) : super(key: key);

  final int userCoin;

  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen>
    with SingleTickerProviderStateMixin {
  // Controllers and managers
  late final AnimationController _animationController;
  late final ConfettiController _confettiController;
  late final DailyTaskController _taskController;
  late final UpdateUserCoinCubit _updateUserCoinCubit;

  // State
  DailyTaskState _state = const DailyTaskState();
  String? _deviceId;

  // Getters for cleaner code
  bool get _isLastQuestion =>
      _state.currentQuestionIndex >= _state.questions.length - 1;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _taskController = DailyTaskController(
      serviceLocator<QuestionRepository>(),
      GetIt.instance.get<SharedPreferencesManager>(),
    );

    _updateUserCoinCubit = UpdateUserCoinCubit();
    _deviceId =
        GetIt.instance.get<SharedPreferencesManager>().getString("deviceId");
  }

  Future<void> _initializeData() async {
    try {
      final isDailyTaskCompleted =
          await _taskController.checkAndResetDailyTasks();
      final streakCount = _taskController.getCurrentStreak();

      setState(() {
        _state = _state.copyWith(
          isDailyTaskCompleted: isDailyTaskCompleted,
          streakCount: streakCount,
        );
      });

      if (isDailyTaskCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _confettiController.play();
        });
      } else {
        await _loadQuestions();
      }
    } catch (e) {
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      });
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _state = _state.copyWith(isLoading: true, errorMessage: null);
    });

    try {
      final questions = await _taskController.loadQuestions();
      setState(() {
        _state = _state.copyWith(
          questions: questions,
          isLoading: false,
        );
      });
    } catch (e) {
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      });
    }
  }

  void _selectAnswer(int selectedIndex) {
    if (_state.isAnswered || _state.currentQuestion == null) return;

    final correctIndex =
        _taskController.getCorrectAnswerIndex(_state.currentQuestion!);
    final isCorrect = selectedIndex == correctIndex;

    setState(() {
      _state = _state.copyWith(
        selectedAnswerIndex: selectedIndex,
        isAnswered: true,
        correctCount: isCorrect ? _state.correctCount + 1 : _state.correctCount,
        earnedCoins: isCorrect
            ? _state.earnedCoins + DailyTaskController.coinsPerCorrectAnswer
            : _state.earnedCoins,
        progress: _state.progress + (1 / DailyTaskController.totalQuestions),
      );
    });

    if (isCorrect) {
      _animationController.forward(from: 0);
    }
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      _showEndDialog();
    } else {
      setState(() {
        _state = _state.copyWith(
          currentQuestionIndex: _state.currentQuestionIndex + 1,
          selectedAnswerIndex: -1,
          isAnswered: false,
        );
      });
    }
  }

  Future<void> _showEndDialog() async {
    final isSuccess = _state.correctCount == DailyTaskController.totalQuestions;
    final bonusCoins =
        isSuccess ? DailyTaskController.bonusCoinsForCompletion : 0;
    final totalEarnedCoins = _state.earnedCoins + bonusCoins;

    await _taskController.updateUserCoins(
      _deviceId,
      widget.userCoin,
      totalEarnedCoins,
      _updateUserCoinCubit,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EndGameDialog(
        isSuccess: isSuccess,
        totalEarnedCoins: totalEarnedCoins,
        bonusCoins: bonusCoins,
        onHomePressed: () {
          context.pop(context);
          Navigator.pop(context, true);
        },
      ),
    );
  }

  AnswerCardStatus _getAnswerStatus(int index) {
    if (!_state.isAnswered) return AnswerCardStatus.normal;

    final correctIndex =
        _taskController.getCorrectAnswerIndex(_state.currentQuestion!);

    if (index == correctIndex && index == _state.selectedAnswerIndex) {
      return AnswerCardStatus.right;
    } else if (index != correctIndex && index == _state.selectedAnswerIndex) {
      return AnswerCardStatus.error;
    } else {
      return AnswerCardStatus.disabled;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _updateUserCoinCubit),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            _BackgroundWidget(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppBarWidget(onBackPressed: () => context.pop(context)),
                  Expanded(
                    child: _state.isDailyTaskCompleted
                        ? _CompletionScreen(
                            streakCount: _state.streakCount,
                            confettiController: _confettiController,
                            onHomePressed: () => context.pop(context),
                          )
                        : _QuizContent(
                            state: _state,
                            animationController: _animationController,
                            onAnswerSelected: _selectAnswer,
                            onNextQuestion: _nextQuestion,
                            onRetry: _loadQuestions,
                            getAnswerStatus: _getAnswerStatus,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate widgets for better performance and readability
class _BackgroundWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage('assets/images/Background_1.png'),
        ),
      ),
    );
  }
}

class _AppBarWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _AppBarWidget({required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onBackPressed,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: ColorBase.primaryBackground,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Thử thách hằng ngày',
            style: TextStyle(
              fontFamily: 'LilitaOne',
              color: ColorBase.primaryBackground,
              fontSize: 24,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizContent extends StatelessWidget {
  final DailyTaskState state;
  final AnimationController animationController;
  final Function(int) onAnswerSelected;
  final VoidCallback onNextQuestion;
  final VoidCallback onRetry;
  final AnswerCardStatus Function(int) getAnswerStatus;

  const _QuizContent({
    required this.state,
    required this.animationController,
    required this.onAnswerSelected,
    required this.onNextQuestion,
    required this.onRetry,
    required this.getAnswerStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _ErrorWidget(
        errorMessage: state.errorMessage!,
        onRetry: onRetry,
      );
    }

    if (state.questions.isEmpty) {
      return _EmptyDataWidget();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProgressBar(
          progress: state.progress,
          animationController: animationController,
        ),
        _QuestionHeader(
          currentIndex: state.currentQuestionIndex,
          totalQuestions: state.questions.length,
          isAnswered: state.isAnswered,
          onNextQuestion: onNextQuestion,
        ),
        Expanded(
          child: _QuestionContent(
            question: state.currentQuestion!,
            selectedAnswerIndex: state.selectedAnswerIndex,
            isAnswered: state.isAnswered,
            onAnswerSelected: onAnswerSelected,
            onNextQuestion: onNextQuestion,
            getAnswerStatus: getAnswerStatus,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final AnimationController animationController;

  const _ProgressBar({
    required this.progress,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF05518B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF46D9BF),
                    ),
                  ),
                );
              },
            ),
            const Positioned(
              right: 5,
              top: 3,
              child: FaIcon(
                FontAwesomeIcons.flagCheckered,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool isAnswered;
  final VoidCallback onNextQuestion;

  const _QuestionHeader({
    required this.currentIndex,
    required this.totalQuestions,
    required this.isAnswered,
    required this.onNextQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Câu hỏi ${currentIndex + 1}',
                      style: const TextStyle(
                        fontFamily: 'LilitaOne',
                        color: ColorBase.primaryBackground,
                        fontSize: 30,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' / $totalQuestions',
                      style: const TextStyle(
                        color: ColorBase.primaryBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: isAnswered ? onNextQuestion : null,
                child: Container(
                  width: 82,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isAnswered
                        ? const Color(0x21FFFFFF)
                        : const Color(0x10FFFFFF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tiếp tục',
                        style: TextStyle(
                          fontFamily: 'LilitaOne',
                          color: ColorBase.primaryBackground,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(4, 0, 10, 0),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: ColorBase.primaryBackground,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const StyledDivider(
          height: 1,
          thickness: 2,
          indent: 16,
          endIndent: 16,
          color: ColorBase.primaryBackground,
          lineStyle: DividerLineStyle.dashed,
        ),
      ],
    );
  }
}

class _QuestionContent extends StatelessWidget {
  final QuestionModel question;
  final int selectedAnswerIndex;
  final bool isAnswered;
  final Function(int) onAnswerSelected;
  final VoidCallback onNextQuestion;
  final AnswerCardStatus Function(int) getAnswerStatus;

  const _QuestionContent({
    required this.question,
    required this.selectedAnswerIndex,
    required this.isAnswered,
    required this.onAnswerSelected,
    required this.onNextQuestion,
    required this.getAnswerStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _QuestionDisplay(question: question),
          const SizedBox(height: 20),
          ...List.generate(
            question.answers?.length ?? 0,
            (index) => AnswerCard(
              answer: question.answers?[index].content ?? "-",
              onTap: isAnswered ? null : () => onAnswerSelected(index),
              answerCardStatus: getAnswerStatus(index),
            ),
          ),
          if (isAnswered) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onNextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF46D9BF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Câu tiếp theo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionDisplay extends StatelessWidget {
  final QuestionModel question;

  const _QuestionDisplay({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          question.title ?? "-",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 16),
        if (question.content != null)
          Text(
            question.content ?? "-",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          )
        else if (question.imageUrl != null)
          Image.network(
            question.imageUrl!,
            width: 200,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, size: 100),
          ),
      ],
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  final int streakCount;
  final ConfettiController confettiController;
  final VoidCallback onHomePressed;

  const _CompletionScreen({
    required this.streakCount,
    required this.confettiController,
    required this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final monthNames = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];

    return Stack(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (streakCount > 0) _StreakDisplay(streakCount: streakCount),
                _TrophyAnimation(),
                const SizedBox(height: 24),
                const Text(
                  '🎉 Chúc mừng! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontFamily: 'LilitaOne',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn đã hoàn thành nhiệm vụ hằng ngày!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'LilitaOne',
                  ),
                ),
                const SizedBox(height: 24),
                _NextDayMessage(
                  nextDay: tomorrow.day,
                  monthName: monthNames[tomorrow.month],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onHomePressed,
                  icon: const Icon(Icons.home),
                  label: const Text('Về trang chủ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46D9BF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.red,
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakDisplay extends StatelessWidget {
  final int streakCount;

  const _StreakDisplay({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          Text(
            'Chuỗi: $streakCount ngày',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF9C4),
            ),
            child: const Center(
              child: Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.amber,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NextDayMessage extends StatelessWidget {
  final int nextDay;
  final String monthName;

  const _NextDayMessage({
    required this.nextDay,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Quay lại vào ngày mai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nhiệm vụ mới sẽ được mở vào ngày $nextDay $monthName',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lỗi: $errorMessage',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Không có câu hỏi nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Image.asset(
            "assets/images/kitten.png",
            height: 150,
            width: 180,
          ),
        ],
      ),
    );
  }
}

class _EndGameDialog extends StatelessWidget {
  final bool isSuccess;
  final int totalEarnedCoins;
  final int bonusCoins;
  final VoidCallback onHomePressed;

  const _EndGameDialog({
    required this.isSuccess,
    required this.totalEarnedCoins,
    required this.bonusCoins,
    required this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSuccess ? '🎉 Chúc mừng!' : '😅 Thử lại nhé!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Icon(
            isSuccess ? Icons.emoji_events : Icons.refresh,
            color: isSuccess ? Colors.green : Colors.orange,
            size: 50,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isSuccess
                ? 'Bạn đã hoàn thành tất cả câu hỏi một cách xuất sắc!'
                : 'Bạn chưa trả lời đúng hết. Hãy thử lại để đạt điểm tối đa!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '+$totalEarnedCoins xu',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          if (isSuccess && bonusCoins > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '(Bao gồm $bonusCoins xu thưởng hoàn thành)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSuccess ? Colors.green : Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onHomePressed,
          icon: const Icon(Icons.home),
          label: const Text('Về trang chủ'),
        ),
      ],
    );
  }
}
