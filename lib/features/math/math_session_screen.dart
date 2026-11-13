import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../math/math_level.dart';
import '../../math/math_question.dart';
import '../../math/question_generator.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/chip_says.dart';
import '../../ui/widgets/session_header.dart';
import '../../voice/speaker.dart';
import '../../voice/voice_lines.dart';
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
  late final Speaker _speaker;

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _speakQuestion();
  }

  void _speakQuestion() => _speaker.speak(spokenQuestion(_questions[_index]));

  @override
  void dispose() {
    _speaker.stop();
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
      _speakQuestion();
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
                  SessionHeader(
                    title: 'Toán · ${widget.level.title}',
                    step: widget.step,
                    totalSteps: widget.totalSteps,
                    onBack: () => Navigator.of(context).maybePop(),
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
                  // The first question is read on opening, so Chíp stays quiet then.
                  ChipSays(image: _chip, text: _message, speakFirst: false),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          q.prompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      _listenButton(),
                    ],
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

  /// Small speaker button that re-reads the current question.
  Widget _listenButton() => Semantics(
        button: true,
        label: 'Nghe câu hỏi',
        excludeSemantics: true,
        child: IconButton(
          onPressed: _speakQuestion,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
        ),
      );

  /// Pictures for an arithmetic question, empty when there would be more
  /// than [_maxIllustratedObjects]. Addition shows both groups; subtraction
  /// shows `a` objects with the last `b` dimmed (the ones taken away).
  List<Widget> _illustration(ArithmeticQuestion q) {
    final total = q.plus ? q.a + q.b : q.a;
    if (total > _maxIllustratedObjects) return const [];
    return [
      const SizedBox(height: 12),
      if (q.plus) ...[
        ObjectGrid(count: q.a),
        const Text(
          '+',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        ObjectGrid(count: q.b),
      ] else
        ObjectGrid(
          count: q.a,
          faded: {for (var i = q.a - q.b; i < q.a; i++) i},
        ),
    ];
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
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
                  ),
                  _listenButton(),
                ],
              ),
              ..._illustration(q),
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
