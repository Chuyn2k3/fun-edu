import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../math/math_level.dart';
import '../../math/math_question.dart';
import '../../math/question_generator.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/chip_says.dart';
import '../../ui/widgets/session_header.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../voice/speaker.dart';
import '../../voice/voice_lines.dart';
import 'exercise/choice_answers.dart';
import 'exercise/compare_groups.dart';
import 'exercise/drag_number_match.dart';
import 'exercise/object_grid.dart';
import 'exercise/tap_count_board.dart';

const _contentMaxWidth = 560.0;
const _tabletPortraitMaxWidth = 720.0;
const _phoneAnswerHeight = 72.0;
const _tabletAnswerHeight = 96.0;
const _matchTileSize = 80.0;
const _tabletChipSize = 140.0;
const _questionFlex = 3;
const _answersFlex = 2;
const _columnGap = 24.0;
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

  /// Keeps Chíp's line across tablet rotations.
  final _chipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _speakQuestion();
  }

  void _speakQuestion() => _speaker.speak(spokenQuestion(_questions[_index]));

  @override
  void dispose() {
    // Assumes in-place swaps: a route replacement could clip the next
    // screen's first line.
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
    return switch (context.formFactor) {
      FormFactor.phone => _stacked(),
      FormFactor.tabletPortrait => TabletTextScale(
          child: _stacked(
            maxWidth: _tabletPortraitMaxWidth,
            answerHeight: _tabletAnswerHeight,
            chipKey: _chipKey,
          ),
        ),
      FormFactor.tabletLandscape => TabletTextScale(child: _landscape()),
    };
  }

  /// Phone layout (also tablet portrait, wider and with bigger answers):
  /// the question card above Chíp.
  Widget _stacked({
    double maxWidth = _contentMaxWidth,
    double answerHeight = _phoneAnswerHeight,
    Key? chipKey,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _header(),
                  _counter(),
                  const SizedBox(height: 8),
                  Expanded(child: _questionCard(answerHeight)),
                  const SizedBox(height: 8),
                  // The first question is read on opening, so Chíp stays quiet then.
                  ChipSays(
                    key: chipKey,
                    image: _chip,
                    text: _message,
                    speakFirst: false,
                    layout: chipKey == null ? null : _tabletChip,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tablet landscape: the question card on the left; on the right the
  /// answers start level with the card's top and Chíp sits right under
  /// them.
  Widget _landscape() {
    final q = _questions[_index];
    Widget arrange(Widget question, Widget answers) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: _questionFlex,
              child: AppCard(
                key: const ValueKey('math-question-area'),
                padding: const EdgeInsets.all(20),
                child: _scrollCentered(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (q is! ArithmeticQuestion) _promptRow(q),
                      const SizedBox(height: 12),
                      question,
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: _columnGap),
            Expanded(
              flex: _answersFlex,
              child: SingleChildScrollView(
                key: const ValueKey('math-answers-column'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    answers,
                    const SizedBox(height: 24),
                    ChipSays(
                      key: _chipKey,
                      image: _chip,
                      text: _message,
                      speakFirst: false,
                      layout: _tabletChip,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
          child: Column(
            children: [
              _header(),
              // The counter is centred over the question card.
              Row(
                children: [
                  Expanded(
                    flex: _questionFlex,
                    child: Center(child: _counter()),
                  ),
                  const SizedBox(width: _columnGap),
                  const Spacer(flex: _answersFlex),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: _exercise(
                    q,
                    null,
                    answerHeight: _tabletAnswerHeight,
                    arrange: arrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => SessionHeader(
        title: 'Toán · ${widget.level.title}',
        step: widget.step,
        totalSteps: widget.totalSteps,
        onBack: () => Navigator.of(context).maybePop(),
      );

  Widget _counter() => Text(
        'Câu ${_index + 1}/${_questions.length}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
        ),
      );

  /// [child] centred vertically, scrolling when taller than the space.
  Widget _scrollCentered(Widget child) => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Center(child: child),
          ),
        ),
      );

  Widget _promptRow(MathQuestion q) => Row(
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
      );

  Widget _questionCard(double answerHeight) {
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
                if (q is! ArithmeticQuestion) _promptRow(q),
                const SizedBox(height: 12),
                // The key resets exercise state even when consecutive
                // questions are value-equal.
                _exercise(q, ValueKey(_index), answerHeight: answerHeight),
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
          constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
          iconSize: context.isTablet ? 40 : null,
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

  Widget _exercise(
    MathQuestion q,
    Key? key, {
    required double answerHeight,
    SplitArrange? arrange,
  }) =>
      switch (q) {
        CountQuestion() => TapCountBoard(
            key: key,
            q: q,
            onAnswered: _onAnswered,
            answerHeight: answerHeight,
            arrange: arrange,
          ),
        CompareQuestion() => CompareGroups(
            key: key,
            q: q,
            onAnswered: _onAnswered,
            arrange: arrange,
          ),
        MatchQuestion() => DragNumberMatch(
            key: key,
            q: q,
            onAnswered: _onAnswered,
            tileSize: max(_matchTileSize, answerHeight),
            arrange: arrange,
          ),
        ArithmeticQuestion() when arrange != null => arrange(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [_arithmeticPrompt(q), ..._illustration(q)],
            ),
            ChoiceAnswers(
              choices: q.choices,
              answer: q.answer,
              onAnswered: _onAnswered,
              tileHeight: answerHeight,
              vertical: true,
            ),
          ),
        ArithmeticQuestion() => Column(
            key: key,
            children: [
              _arithmeticPrompt(q),
              ..._illustration(q),
              const SizedBox(height: 16),
              ChoiceAnswers(
                choices: q.choices,
                answer: q.answer,
                onAnswered: _onAnswered,
                tileHeight: answerHeight,
              ),
            ],
          ),
      };

  Widget _arithmeticPrompt(ArithmeticQuestion q) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                q.prompt,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: context.isTablet ? 64 : 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          _listenButton(),
        ],
      );
}

/// Chíp at tablet size: a 140 pt image beside the speech bubble.
Widget _tabletChip(BuildContext context, String image, String text) {
  return SizedBox(
    height: _tabletChipSize,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(
          image,
          width: _tabletChipSize,
          height: _tabletChipSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SpeechBubble(text: text),
          ),
        ),
      ],
    ),
  );
}
