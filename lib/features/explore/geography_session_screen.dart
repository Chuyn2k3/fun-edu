import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../explore/geography_generator.dart';
import '../../explore/explore_island.dart';
import '../../explore/geography_level.dart';
import '../../explore/geography_question.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/session_header.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../voice/speaker.dart';
import '../../voice/speech_wait.dart';

const _contentMaxWidth = 560.0;
const _tabletPortraitMaxWidth = 720.0;
const _phoneChipSize = 88.0;
const _tabletChipSize = 140.0;
const _minPhoneTile = 96.0;
const _minTabletTile = 140.0;
const _maxTile = 220.0;
const _phoneFocus = 168.0;
const _tabletFocus = 240.0;
const _gap = 12.0;

/// Estimated time for Chíp to read [spoken] (name + fact) with the slow
/// device voice: about 320 ms per Vietnamese syllable, 1.6–8 s. Used as the
/// upper bound of the wait; the screen moves on as soon as the voice ends.
Duration geographyAnswerPause(String spoken) {
  final syllables = spoken.trim().split(RegExp(r'\s+')).length;
  final ms = (syllables * 320 + 400).clamp(1600, 8000);
  return Duration(milliseconds: ms);
}

/// Shortest stay on a right answer, even when the voice is off.
const _minPause = Duration(milliseconds: 1600);

/// Extra time on the last question before the round closes.
const _completeExtra = Duration(milliseconds: 200);

/// One geography round: Chíp asks, the kid taps one of three pictures.
/// The geography name of the shared session screen.
typedef GeographySessionScreen = ExploreSessionScreen;

/// One explore round: Chíp asks, the kid taps one of three pictures (or, for
/// a pair, the picture that goes with the one shown).
class ExploreSessionScreen extends ConsumerStatefulWidget {
  const ExploreSessionScreen({
    this.island = geographyIsland,
    required this.level,
    required this.onCompleted,
    this.questionCount = 5,
    this.random,
    super.key,
  });

  final ExploreIsland island;
  final GeographyLevel level;
  final void Function(int firstTryCorrect, int total) onCompleted;
  final int questionCount;
  final Random? random;

  @override
  ConsumerState<ExploreSessionScreen> createState() =>
      _ExploreSessionScreenState();
}

class _ExploreSessionScreenState
    extends ConsumerState<ExploreSessionScreen> {
  late final List<GeographyQuestion> _questions = generateGeographyQuestions(
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

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _speakCurrent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _precache(1));
  }


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

  void _speakCurrent() => _speaker.speak(_questions[_index].speech);

  /// The speaker button: the question, or after a right answer the name
  /// and fact Chíp is reading (never the question already answered).
  void _replay() {
    if (_answered) {
      _speaker.speak(_questions[_index].praise);
    } else {
      _speakCurrent();
    }
  }

  /// Decodes the pictures of question [i] ahead of time; a broken picture
  /// is ignored here and shown as a name tile on screen.
  void _precache(int i) {
    if (!mounted || i >= _questions.length) return;
    for (final c in _questions[i].choices) {
      precacheImage(AssetImage(c.image), context, onError: (_, __) {});
    }
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
    final a = q.answer;
    setState(() {
      _answered = true;
      _wrongPick = null;
      _chip = AppImages.chipJoy;
      _message = q.kind == GeoQuestionKind.pairPick
          ? '${a.name}! ${q.fact}'
          : '${a.name}! ${a.fact}';
    });
    final spoken = q.praise;
    final speech = _speaker.speak(spoken);
    // Never more than the estimated reading time plus a margin, in case
    // the voice never reports the end.
    final cap = geographyAnswerPause(spoken) + const Duration(seconds: 3);
    _pending?.cancel();
    if (_index == _questions.length - 1) {
      _finished = true;
      _wait(speech, _minPause + _completeExtra, atMost: cap + _completeExtra, () {
        if (mounted) widget.onCompleted(_firstTry, _questions.length);
      });
      return;
    }
    _wait(speech, _minPause, atMost: cap, () {
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
      _precache(_index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final tablet = context.isTablet;
    final landscape = context.formFactor == FormFactor.tabletLandscape;

    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SessionHeader(
        title: widget.level.title,
        step: _index + 1,
        totalSteps: _questions.length,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/subject/dia-ly');
          }
        },
      ),
    );

    final chipSize = tablet && !landscape ? _tabletChipSize : _phoneChipSize;
    final chipRow = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(_chip, width: chipSize, height: chipSize),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SpeechBubble(text: _message),
          ),
        ),
        const SizedBox(width: 8),
        _SpeakerButton(
            tablet: tablet, subject: widget.island.subject, onTap: _replay),
      ],
    );

    final subject = widget.island.subject;
    final focusItem = q.focus;
    final Widget? focus = focusItem == null
        ? null
        : Center(
            child: _FocusPicture(
              key: const ValueKey('geo-focus'),
              item: focusItem,
              subject: subject,
              size: tablet ? _tabletFocus : _phoneFocus,
            ),
          );

    Widget tile(int i, double size) => _PictureTile(
          key: ValueKey('geo-choice-$i'),
          subject: subject,
          item: q.choices[i],
          size: size,
          correctShown: _answered && i == q.correctIndex,
          wrongShown: !_answered && _wrongPick == i,
          enabled: !_answered,
          onTap: () => _onPick(i),
        );

    final minTile = tablet ? _minTabletTile : _minPhoneTile;
    final Widget content;
    if (landscape) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    chipRow,
                    if (focus != null) ...[const SizedBox(height: 20), focus],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: LayoutBuilder(builder: (context, c) {
                final size = min(c.maxWidth, (c.maxHeight - 2 * _gap) / 3)
                    .clamp(minTile, _maxTile)
                    .toDouble();
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(height: _gap),
                        tile(i, size),
                      ],
                    ],
                  ),
                );
              }),
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
            child: LayoutBuilder(builder: (context, c) {
              final size = ((c.maxWidth - 2 * _gap) / 3)
                  .clamp(minTile, _maxTile)
                  .toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  chipRow,
                  if (focus != null) ...[const SizedBox(height: 20), focus],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: _gap,
                    runSpacing: _gap,
                    children: [for (var i = 0; i < 3; i++) tile(i, size)],
                  ),
                ],
              );
            }),
          ),
        ),
      );
    }

    final body = Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Column(
            children: [header, Expanded(child: content)],
          ),
        ),
      ),
    );
    return tablet ? TabletTextScale(child: body) : body;
  }
}

class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({
    required this.tablet,
    required this.subject,
    required this.onTap,
  });

  final bool tablet;
  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = tablet ? TabletSizes.kidTarget : 64.0;
    return Pressable(
      key: const ValueKey('geo-speaker'),
      onTap: onTap,
      semanticsLabel: 'Nghe lại câu hỏi',
      builder: (pressed) => Container(
        width: size,
        height: size,
        decoration: raisedDecoration(
          accent: subject.color,
          tint: subject.tint,
          radius: size / 2,
          pressed: pressed,
        ),
        child: Icon(Icons.volume_up_rounded,
            size: tablet ? 40 : 32, color: subject.color),
      ),
    );
  }
}

class _PictureTile extends StatelessWidget {
  const _PictureTile({
    super.key,
    required this.subject,
    required this.item,
    required this.size,
    required this.correctShown,
    required this.wrongShown,
    required this.enabled,
    required this.onTap,
  });

  final Subject subject;
  final GeoItem item;
  final double size;
  final bool correctShown;
  final bool wrongShown;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = correctShown
        ? GameColors.correctRing
        : wrongShown
            ? AppColors.primary
            : subject.color;
    final tint = wrongShown ? Subject.viet.tint : subject.tint;
    return Pressable(
      onTap: enabled ? onTap : null,
      semanticsLabel: item.name,
      builder: (pressed) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: raisedDecoration(
          accent: accent,
          tint: tint,
          radius: AppRadii.tile,
          pressed: pressed,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              item.image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _NameTile(item.name, subject: subject),
            ),
            if (correctShown)
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.check_circle_rounded,
                    color: GameColors.correctRing, size: 32),
              ),
          ],
        ),
      ),
    );
  }
}

/// Stand-in when a picture fails to load: the kid can still pick it.
class _NameTile extends StatelessWidget {
  const _NameTile(this.name, {required this.subject});

  final String name;
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: subject.tint,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: subject.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The picture a pair question asks about, big above the choices.
class _FocusPicture extends StatelessWidget {
  const _FocusPicture({
    super.key,
    required this.item,
    required this.subject,
    required this.size,
  });

  final GeoItem item;
  final Subject subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.name,
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(10),
        decoration: raisedDecoration(
          accent: subject.color,
          tint: subject.tint,
          radius: AppRadii.card,
        ),
        child: Image.asset(
          item.image,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _NameTile(item.name, subject: subject),
        ),
      ),
    );
  }
}
