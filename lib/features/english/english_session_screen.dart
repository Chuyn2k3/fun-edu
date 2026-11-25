import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../english/english_generator.dart';
import '../../english/english_level.dart';
import '../../english/english_question.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/session_header.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../voice/speaker.dart';
import '../../voice/speech_wait.dart';

const _contentMaxWidth = 560.0;
const _tabletPortraitMaxWidth = 720.0;
const _phoneAnswerHeight = 72.0;
const _tabletAnswerHeight = 96.0;
const _tabletChipSize = 140.0;
const _columnGap = 24.0;
const _nextDelay = Duration(milliseconds: 950);
const _completeDelay = Duration(milliseconds: 1200);

/// English practice screen: runs [questionCount] questions of [level] with
/// `en-US` audio playback and Chíp Chíp feedback.
class EnglishSessionScreen extends ConsumerStatefulWidget {
  const EnglishSessionScreen({
    required this.level,
    required this.onCompleted,
    this.step,
    this.totalSteps,
    this.questionCount = 5,
    this.random,
    super.key,
  });

  final EnglishLevel level;
  final void Function(int firstTryCorrect, int total) onCompleted;
  final int? step;
  final int? totalSteps;
  final int questionCount;
  final Random? random;

  @override
  ConsumerState<EnglishSessionScreen> createState() =>
      _EnglishSessionScreenState();
}

class _EnglishSessionScreenState extends ConsumerState<EnglishSessionScreen> {
  late final List<EnglishQuestion> _questions = generateEnglishQuestions(
    widget.level,
    widget.random ?? Random(),
    count: widget.questionCount,
  );
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

  void _speakCurrent() =>
      _speaker.speakInLanguage(_questions[_index].englishSpeech, 'en-US');


  /// The pending move to the next question, if any.
  SpeechWait? _pending;

  /// Runs [then] once Chíp has finished [speech] (at least [atLeast]).
  void _wait(Future<void> speech, Duration atLeast, VoidCallback then,
      {Duration atMost = const Duration(seconds: 8)}) {
    _pending?.cancel();
    final wait = _pending =
        SpeechWait(speech, atLeast: atLeast, atMost: atMost);
    wait.done.then((_) {
      if (mounted && identical(wait, _pending)) then();
    });
  }

  @override
  void dispose() {
    _speaker.stop();
    _pending?.cancel();
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
      _message = 'Đúng rồi! ${q.englishSpeech} — ${q.vietnameseMeaning}';
    });
    final speech = _speaker.speakInLanguage(q.englishSpeech, 'en-US');
    _pending?.cancel();
    final last = _index == _questions.length - 1;
    if (last) {
      _finished = true;
      _wait(speech, _completeDelay, () {
        if (mounted) widget.onCompleted(_firstTry, _questions.length);
      });
      return;
    }
    _wait(speech, _nextDelay, () {
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
    final landscape = tablet &&
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

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
      child: _EnglishBoard(
        question: q,
        answered: _answered,
        tablet: tablet,
        onReplay: _speakCurrent,
      ),
    );

    final answers = _EnglishAnswers(
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
                    ? Subject.tiengAnh.color
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

class _EnglishBoard extends StatelessWidget {
  const _EnglishBoard({
    required this.question,
    required this.answered,
    required this.tablet,
    required this.onReplay,
  });

  final EnglishQuestion question;
  final bool answered;
  final bool tablet;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final listenSize = tablet ? TabletSizes.kidTarget : 68.0;
    final listenButton = Pressable(
      onTap: onReplay,
      semanticsLabel: 'Nghe lại tiếng Anh',
      builder: (pressed) => Container(
        width: listenSize,
        height: listenSize,
        decoration: raisedDecoration(
          accent: Subject.tiengAnh.color,
          tint: Subject.tiengAnh.tint,
          radius: listenSize / 2,
          pressed: pressed,
        ),
        child: Icon(
          Icons.volume_up_rounded,
          size: tablet ? 40 : 34,
          color: Subject.tiengAnh.color,
        ),
      ),
    );

    final meaningPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Subject.tiengAnh.tint,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        question.vietnameseMeaning,
        style: TextStyle(
          fontSize: tablet ? 19 : 16,
          fontWeight: FontWeight.w800,
          color: Subject.tiengAnh.color,
        ),
      ),
    );

    return switch (question.displayKind) {
      EnglishDisplayKind.listenPick => Column(
          children: [
            listenButton,
            const SizedBox(height: 14),
            if (question.id.startsWith('en-vocab-')) ...[
              meaningPill,
              const SizedBox(height: 8),
            ],
            Text(
              answered ? question.correctChoice : 'Chạm loa để nghe tiếng Anh!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: answered ? (tablet ? 38 : 32) : (tablet ? 17 : 15),
                fontWeight: FontWeight.w900,
                color: answered ? Subject.tiengAnh.color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      EnglishDisplayKind.countPick => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                listenButton,
                const SizedBox(width: 16),
                Text(
                  '${question.countValue ?? 1}',
                  style: TextStyle(
                    fontSize: tablet ? 48 : 42,
                    fontWeight: FontWeight.w900,
                    color: Subject.tiengAnh.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < (question.countValue ?? 1); i++)
                  Container(
                    width: tablet ? 28 : 22,
                    height: tablet ? 28 : 22,
                    decoration: BoxDecoration(
                      color: Subject.tiengAnh.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      EnglishDisplayKind.colorPick => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                listenButton,
                const SizedBox(width: 18),
                Container(
                  width: tablet ? 84 : 72,
                  height: tablet ? 84 : 72,
                  decoration: BoxDecoration(
                    color: question.swatchColor ?? EnglishSwatchColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.text.withOpacity(0.18),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.text.withOpacity(0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            meaningPill,
          ],
        ),
      EnglishDisplayKind.phonicsBuild => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                listenButton,
                const SizedBox(width: 14),
                meaningPill,
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                _SlotBox(
                  text: answered ? question.correctChoice : '?',
                  filled: answered,
                  tablet: tablet,
                ),
                Text(
                  question.phonicsTail ?? '',
                  style: TextStyle(
                    fontSize: tablet ? 38 : 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      EnglishDisplayKind.phraseFill => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                listenButton,
                const SizedBox(width: 12),
                Flexible(child: meaningPill),
              ],
            ),
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
                _SlotBox(
                  text: answered ? question.correctChoice : '___',
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

class _SlotBox extends StatelessWidget {
  const _SlotBox({
    required this.text,
    required this.filled,
    required this.tablet,
  });

  final String text;
  final bool filled;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: tablet ? 68 : 54,
        minHeight: tablet ? 60 : 50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Subject.tiengAnh.color : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(
          color: filled ? Subject.tiengAnh.color : AppColors.primary,
          width: 2.5,
        ),
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
              color: filled ? AppColors.card : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnglishAnswers extends StatelessWidget {
  const _EnglishAnswers({
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
    final shortChoices = choices.every((c) => c.length <= 3);
    if (shortChoices) {
      return Row(
        children: [
          for (var i = 0; i < choices.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _ChoiceTile(
                key: ValueKey('en-choice-$i'),
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
            key: ValueKey('en-choice-$i'),
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
    final correctDeco = BoxDecoration(
      color: GameColors.correctRing,
      borderRadius: BorderRadius.circular(AppRadii.tile),
      boxShadow: [
        BoxShadow(
          color: GameColors.correctRing.withOpacity(0.32),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Pressable(
      onTap: enabled ? onTap : null,
      semanticsLabel: label,
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        alignment: Alignment.center,
        decoration: isCorrectShown
            ? correctDeco
            : raisedDecoration(
                accent:
                    isWrongShown ? AppColors.primary : Subject.tiengAnh.color,
                tint: isWrongShown ? Subject.viet.tint : Subject.tiengAnh.tint,
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
                      ? (tablet ? 34 : 28)
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
