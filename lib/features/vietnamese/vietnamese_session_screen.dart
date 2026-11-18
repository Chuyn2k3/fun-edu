import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/session_header.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../vietnamese/vietnamese_generator.dart';
import '../../vietnamese/vietnamese_level.dart';
import '../../vietnamese/vietnamese_question.dart';
import '../../voice/speaker.dart';

const _contentMaxWidth = 560.0;
const _tabletPortraitMaxWidth = 720.0;
const _phoneAnswerHeight = 72.0;
const _tabletAnswerHeight = 96.0;
const _tabletChipSize = 140.0;
const _columnGap = 24.0;
const _nextDelay = Duration(milliseconds: 900);
const _completeDelay = Duration(milliseconds: 1200);

/// Vietnamese practice screen: runs [questionCount] questions of [level] with
/// Chíp Chíp voice & visual feedback after each pick.
class VietnameseSessionScreen extends ConsumerStatefulWidget {
  const VietnameseSessionScreen({
    required this.level,
    required this.onCompleted,
    this.step,
    this.totalSteps,
    this.questionCount = 5,
    this.random,
    super.key,
  });

  final VietnameseLevel level;

  /// Called once after the final answer with the count of first-try correct
  /// answers and total questions.
  final void Function(int firstTryCorrect, int total) onCompleted;
  final int? step;
  final int? totalSteps;
  final int questionCount;
  final Random? random;

  @override
  ConsumerState<VietnameseSessionScreen> createState() =>
      _VietnameseSessionScreenState();
}

class _VietnameseSessionScreenState
    extends ConsumerState<VietnameseSessionScreen> {
  late final List<VietnameseQuestion> _questions = generateVietnameseQuestions(
    widget.level,
    widget.random ?? Random(),
    count: widget.questionCount,
  );
  Timer? _timer;
  int _index = 0;
  int _firstTry = 0;
  bool _missed = false;
  bool _answered = false;
  bool _finished = false;
  int? _wrongPick;
  String _chip = AppImages.chipMain;
  late String _message = _questions[0].prompt;
  late final Speaker _speaker;
  final _chipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _speakCurrent();
  }

  void _speakCurrent() => _speaker.speak(_questions[_index].speech);

  @override
  void dispose() {
    _speaker.stop();
    _timer?.cancel();
    super.dispose();
  }

  void _onPick(int i) {
    if (_finished || _answered) return;
    final q = _questions[_index];
    if (i != q.correctIndex) {
      setState(() {
        _missed = true;
        _wrongPick = i;
        _chip = AppImages.chipEncourage;
        _message = 'Thử lại nhé! Nghe Chíp đọc lại nào!';
      });
      _speakCurrent();
      return;
    }

    if (!_missed) _firstTry++;
    setState(() {
      _answered = true;
      _wrongPick = null;
      _chip = AppImages.chipJoy;
      _message = 'Đúng rồi!';
    });
    _speaker.speak(q.celebrationSpeech);
    _timer?.cancel();
    final last = _index == _questions.length - 1;
    if (last) {
      _finished = true;
      _timer = Timer(_completeDelay, () {
        if (mounted) widget.onCompleted(_firstTry, _questions.length);
      });
      return;
    }
    _timer = Timer(_nextDelay, () {
      if (!mounted) return;
      setState(() {
        _index++;
        _missed = false;
        _answered = false;
        _wrongPick = null;
        _chip = AppImages.chipMain;
        _message = _questions[_index].prompt;
      });
      _speakCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final tablet = context.isTablet;
    final landscape =
        tablet && MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SessionHeader(
        title: widget.level.title,
        step: widget.step ?? (_index + 1),
        totalSteps: widget.totalSteps ?? _questions.length,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    );

    final chipRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(
          _chip,
          width: tablet && !landscape ? _tabletChipSize : 88,
          height: tablet && !landscape ? _tabletChipSize : 88,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SpeechBubble(key: _chipKey, text: _message),
          ),
        ),
      ],
    );

    final questionCard = AppCard(
      padding: EdgeInsets.all(tablet ? 24 : 20),
      child: _QuestionBoard(
        question: q,
        answered: _answered,
        tablet: tablet,
        onReplay: _speakCurrent,
      ),
    );

    final answers = _AnswerColumn(
      choices: q.choices,
      correctIndex: q.correctIndex,
      answered: _answered,
      wrongPick: _wrongPick,
      tablet: tablet,
      onPick: _onPick,
    );

    final Widget content;
    if (landscape) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    chipRow,
                    const SizedBox(height: 16),
                    questionCard,
                  ],
                ),
              ),
            ),
            const SizedBox(width: _columnGap),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(child: answers),
            ),
          ],
        ),
      );
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: tablet ? _tabletPortraitMaxWidth : _contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                chipRow,
                const SizedBox(height: 16),
                questionCard,
                const SizedBox(height: 18),
                answers,
              ],
            ),
          ),
        ),
      );
    }

    final body = Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Column(
            children: [
              header,
              _QuestionDots(
                current: _index,
                total: _questions.length,
                answered: _answered,
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );

    return tablet ? TabletTextScale(child: body) : body;
  }
}

class _QuestionDots extends StatelessWidget {
  const _QuestionDots({
    required this.current,
    required this.total,
    required this.answered,
  });

  final int current;
  final int total;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              width: i == current ? 24 : 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i < current || (i == current && answered)
                    ? Subject.tiengViet.color
                    : i == current
                        ? AppColors.primary
                        : AppColors.dot,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionBoard extends StatelessWidget {
  const _QuestionBoard({
    required this.question,
    required this.answered,
    required this.tablet,
    required this.onReplay,
  });

  final VietnameseQuestion question;
  final bool answered;
  final bool tablet;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final listenSize = tablet ? TabletSizes.kidTarget : 68.0;
    final listenButton = Pressable(
      onTap: onReplay,
      semanticsLabel: 'Nghe lại câu hỏi',
      builder: (pressed) => Container(
        width: listenSize,
        height: listenSize,
        decoration: raisedDecoration(
          accent: Subject.tiengViet.color,
          tint: Subject.tiengViet.tint,
          radius: listenSize / 2,
          pressed: pressed,
        ),
        child: Icon(
          Icons.volume_up_rounded,
          size: tablet ? 40 : 34,
          color: Subject.tiengViet.color,
        ),
      ),
    );

    return switch (question.displayKind) {
      VietnameseDisplayKind.listenPick => Column(
          children: [
            listenButton,
            const SizedBox(height: 14),
            Text(
              answered ? question.correctChoice : 'Chạm loa để nghe lại nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: answered ? (tablet ? 40 : 34) : (tablet ? 18 : 16),
                fontWeight: FontWeight.w900,
                color: answered ? Subject.tiengViet.color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      VietnameseDisplayKind.equationBuild => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                listenButton,
                const SizedBox(width: 14),
                Text(
                  question.equationResult ?? '',
                  style: TextStyle(
                    fontSize: tablet ? 40 : 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _EquationBox(
                  text: question.equationLeft ??
                      (answered ? question.correctChoice : '?'),
                  isBlank: question.equationLeft == null,
                  filled: answered,
                  tablet: tablet,
                ),
                Text(
                  '+',
                  style: TextStyle(
                    fontSize: tablet ? 30 : 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                  ),
                ),
                _EquationBox(
                  text: question.equationRight ??
                      (answered ? question.correctChoice : '?'),
                  isBlank: question.equationRight == null,
                  filled: answered,
                  tablet: tablet,
                ),
                Text(
                  '=',
                  style: TextStyle(
                    fontSize: tablet ? 30 : 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                  ),
                ),
                _EquationBox(
                  text: question.equationResult ?? '',
                  isBlank: false,
                  filled: answered,
                  highlight: true,
                  tablet: tablet,
                ),
              ],
            ),
          ],
        ),
      VietnameseDisplayKind.phraseFill => Column(
          children: [
            listenButton,
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((question.phraseBefore ?? '').isNotEmpty)
                  Text(
                    question.phraseBefore!,
                    style: TextStyle(
                      fontSize: tablet ? 28 : 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                _EquationBox(
                  text: answered ? question.correctChoice : '___',
                  isBlank: true,
                  filled: answered,
                  tablet: tablet,
                ),
                if ((question.phraseAfter ?? '').isNotEmpty)
                  Text(
                    question.phraseAfter!,
                    style: TextStyle(
                      fontSize: tablet ? 28 : 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
              ],
            ),
          ],
        ),
    };
  }
}

class _EquationBox extends StatelessWidget {
  const _EquationBox({
    required this.text,
    required this.isBlank,
    required this.filled,
    required this.tablet,
    this.highlight = false,
  });

  final String text;
  final bool isBlank;
  final bool filled;
  final bool tablet;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? Subject.tiengViet.tint
        : (isBlank && filled)
            ? Subject.tiengViet.color
            : isBlank
                ? AppColors.background
                : AppColors.card;
    final border = isBlank
        ? (filled ? Subject.tiengViet.color : AppColors.primary)
        : AppColors.dot;
    final fg = (isBlank && filled)
        ? AppColors.card
        : highlight
            ? Subject.tiengViet.color
            : isBlank
                ? AppColors.primary
                : AppColors.text;

    return Container(
      constraints: BoxConstraints(
        minWidth: tablet ? 74 : 58,
        minHeight: tablet ? 64 : 52,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: border, width: isBlank ? 2.5 : 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: tablet ? 30 : 25,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerColumn extends StatelessWidget {
  const _AnswerColumn({
    required this.choices,
    required this.correctIndex,
    required this.answered,
    required this.wrongPick,
    required this.tablet,
    required this.onPick,
  });

  final List<String> choices;
  final int correctIndex;
  final bool answered;
  final int? wrongPick;
  final bool tablet;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final height = tablet ? _tabletAnswerHeight : _phoneAnswerHeight;
    final shortChoices = choices.every((c) => c.length <= 4);
    if (shortChoices) {
      return Row(
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _ChoiceTile(
                key: ValueKey('vn-choice-$i'),
                label: choices[i],
                height: height,
                tablet: tablet,
                isCorrectShown: answered && i == correctIndex,
                isWrongShown: !answered && wrongPick == i,
                enabled: !answered,
                onTap: () => onPick(i),
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < choices.length; i++) ...[
          _ChoiceTile(
            key: ValueKey('vn-choice-$i'),
            label: choices[i],
            height: height,
            tablet: tablet,
            isCorrectShown: answered && i == correctIndex,
            isWrongShown: !answered && wrongPick == i,
            enabled: !answered,
            onTap: () => onPick(i),
          ),
          if (i < choices.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.height,
    required this.tablet,
    required this.isCorrectShown,
    required this.isWrongShown,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final double height;
  final bool tablet;
  final bool isCorrectShown;
  final bool isWrongShown;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isCorrectShown ? AppColors.card : AppColors.text;
    final deco = isCorrectShown
        ? BoxDecoration(
            color: GameColors.correctRing,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            boxShadow: [
              BoxShadow(
                color: GameColors.correctRing.withOpacity(0.32),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : raisedDecoration(
            accent: isWrongShown ? AppColors.primary : Subject.tiengViet.color,
            tint: isWrongShown ? Subject.viet.tint : Subject.tiengViet.tint,
            radius: AppRadii.tile,
            pressed: false,
          );

    return Pressable(
      onTap: enabled ? onTap : null,
      semanticsLabel: label,
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        alignment: Alignment.center,
        decoration: isCorrectShown
            ? deco
            : raisedDecoration(
                accent:
                    isWrongShown ? AppColors.primary : Subject.tiengViet.color,
                tint: isWrongShown ? Subject.viet.tint : Subject.tiengViet.tint,
                radius: AppRadii.tile,
                pressed: pressed,
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: label.length <= 3
                      ? (tablet ? 36 : 30)
                      : (tablet ? 26 : 22),
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ),
            if (isCorrectShown) ...[
              const SizedBox(width: 10),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.card,
                size: 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
