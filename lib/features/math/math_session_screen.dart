import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../math/math_level.dart';
import '../../math/math_question.dart';
import '../../math/question_generator.dart';
import '../../progress/progress_repository.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/info_pill.dart';
import '../../ui/widgets/speech_bubble.dart';
import 'exercise/choice_answers.dart';
import 'exercise/compare_groups.dart';
import 'exercise/drag_number_match.dart';
import 'exercise/object_grid.dart';
import 'exercise/tap_count_board.dart';

const _contentMaxWidth = 560.0;
const _nextDelay = Duration(milliseconds: 900);
const _completeDelay = Duration(milliseconds: 1200);

/// The illustration grid only helps small numbers; beyond this it is skipped.
const _maxIllustratedObjects = 10;

/// Math screen: runs [questionCount] questions of [level] with Chíp Chíp
/// feedback after each answer.
class MathSessionScreen extends ConsumerStatefulWidget {
  const MathSessionScreen({
    required this.level,
    required this.onCompleted,
    this.step,
    this.totalSteps,
    this.questionCount = 5,
    this.random,
    super.key,
  });

  final MathLevel level;

  /// Called once, 1.2 s after the last answer, with the number of questions
  /// answered correctly without a prior wrong pick, and the total.
  final void Function(int firstTryCorrect, int total) onCompleted;
  final int? step;
  final int? totalSteps;
  final int questionCount;

  /// Seeds question generation; tests pass one for determinism.
  final Random? random;

  @override
  ConsumerState<MathSessionScreen> createState() => _MathSessionScreenState();
}

class _MathSessionScreenState extends ConsumerState<MathSessionScreen> {
  late final List<MathQuestion> _questions = generateQuestions(
    widget.level,
    widget.random ?? Random(),
    count: widget.questionCount,
  );
  Timer? _timer;
  int _index = 0;
  int _firstTry = 0;
  bool _missed = false;
  bool _finished = false;
  String _chip = AppImages.chipMain;
  String _message = 'Mình cùng làm Toán nhé!';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onAnswered(bool correct) {
    if (_finished) return;
    if (!correct) {
      setState(() {
        _missed = true;
        _chip = AppImages.chipEncourage;
        _message = 'Thử lại nhé!';
      });
      return;
    }
    if (!_missed) _firstTry++;
    setState(() {
      _chip = AppImages.chipJoy;
      _message = 'Đúng rồi!';
    });
    _timer?.cancel();
    _timer = Timer(_nextDelay, _advance);
  }

  void _advance() {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _missed = false;
      });
      return;
    }
    setState(() {
      _finished = true;
      _chip = AppImages.chipThumb;
      _message = 'Bé giỏi quá!';
    });
    _timer = Timer(
      _completeDelay,
      () => widget.onCompleted(_firstTry, _questions.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stars = ref.watch(homeSummaryProvider).valueOrNull?.totalStars ?? 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _Header(
                    title: 'Toán · ${widget.level.title}',
                    step: widget.step,
                    totalSteps: widget.totalSteps,
                    stars: stars,
                  ),
                  Text(
                    'Câu ${_index + 1}/${_questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _questionCard()),
                  const SizedBox(height: 8),
                  _ChipRow(image: _chip, message: _message),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionCard() {
    final q = _questions[_index];
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (q is! ArithmeticQuestion)
                  Text(
                    q.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                const SizedBox(height: 12),
                // The key resets exercise state even when consecutive
                // questions are value-equal.
                _exercise(q, ValueKey(_index)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exercise(MathQuestion q, Key key) => switch (q) {
        CountQuestion() =>
          TapCountBoard(key: key, q: q, onAnswered: _onAnswered),
        CompareQuestion() =>
          CompareGroups(key: key, q: q, onAnswered: _onAnswered),
        MatchQuestion() =>
          DragNumberMatch(key: key, q: q, onAnswered: _onAnswered),
        ArithmeticQuestion() => Column(
            key: key,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  q.prompt,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (q.a <= _maxIllustratedObjects) ...[
                const SizedBox(height: 12),
                ObjectGrid(count: q.a),
              ],
              const SizedBox(height: 16),
              ChoiceAnswers(
                choices: q.choices,
                answer: q.answer,
                onAnswered: _onAnswered,
              ),
            ],
          ),
      };
}

// Header, progress bar and chip row mirror writing_screen.dart.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.step,
    required this.totalSteps,
    required this.stars,
  });

  final String title;
  final int? step;
  final int? totalSteps;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final showProgress = step != null && totalSteps != null && totalSteps! > 0;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Semantics(
            label: 'Quay lại',
            button: true,
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => Navigator.of(context).maybePop(),
              radius: 32,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    boxShadow: [AppShadows.card],
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 36,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          if (showProgress) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: _ProgressBar(step: step!, total: totalSteps!),
            ),
          ],
          const SizedBox(width: 8),
          InfoPill(
            leading: Image.asset(
              AppImages.icStar,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            label: '$stars',
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$step/$total',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: SizedBox(
              width: 48,
              height: 8,
              child: LinearProgressIndicator(
                value: (step / total).clamp(0.0, 1.0),
                backgroundColor: AppColors.dot,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$step/$total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.image, required this.message});

  final String image;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(image, width: 88, height: 88, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SpeechBubble(text: message),
            ),
          ),
        ],
      ),
    );
  }
}
