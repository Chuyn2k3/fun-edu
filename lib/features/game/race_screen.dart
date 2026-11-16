import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/engine/race.dart';
import '../../game/engine/race_question.dart';
import '../../game/scene/race_scene.dart';
import '../../math/math_question.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import '../../voice/voice_lines.dart';
import 'answer_keys.dart';
import 'glyph_view.dart';
import 'race_controller.dart';

const _tryAgain = 'Thử lại nhé!';
const _cometLine = 'Câu sao chổi! Đúng là bay vọt 2 nấc';

/// What Chíp reads when [q] appears.
String spokenRaceQuestion(RaceQuestion q) => switch (q) {
      MathRaceQuestion(question: final ArithmeticQuestion a) =>
        spokenQuestion(a),
      MathRaceQuestion() => 'Có bao nhiêu ngôi sao?',
      LetterRaceQuestion() || ToneRaceQuestion() => q.spoken,
    };

/// "Đua với Chíp": the space scene on top (left on a landscape tablet) and
/// the warm question area with three chunky keys below (right).
class RaceScreen extends ConsumerStatefulWidget {
  const RaceScreen({
    super.key,
    required this.subject,
    this.retryAfterLoss = false,
  });

  final RaceSubject subject;
  final bool retryAfterLoss;

  @override
  ConsumerState<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends ConsumerState<RaceScreen> {
  /// Race time moves in these steps, only while the race is visible.
  static const _clockStep = Duration(milliseconds: 100);
  static const _rightAnswerPause = Duration(milliseconds: 380);

  late final Speaker _speaker;
  late final RaceController _controller;
  final _sceneKey = GlobalKey();
  Timer? _clock;
  Timer? _next;
  Timer? _bubble;
  Timer? _leave;
  ValueListenable<bool>? _tickerMode;
  bool _showTryAgain = false;
  DateTime? _finishingSince;

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _controller = ref.read(raceControllerProvider.notifier);
    Future.microtask(() {
      if (mounted) {
        _controller.start(widget.subject,
            retryAfterLoss: widget.retryAfterLoss);
      }
    });
    _clock = Timer.periodic(_clockStep, (_) => _onClock());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The screen-time guard turns tickers off while its sleep screen
    // covers the app: the race clock stops with them.
    _tickerMode = TickerMode.getNotifier(context);
  }

  bool get _visible {
    final life = WidgetsBinding.instance.lifecycleState;
    final resumed = life == null || life == AppLifecycleState.resumed;
    return resumed && (_tickerMode?.value ?? true);
  }

  void _onClock() {
    if (!mounted || !_visible) return;
    _controller.advance(_clockStep);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _next?.cancel();
    _bubble?.cancel();
    _leave?.cancel();
    _speaker.stop();
    super.dispose();
  }

  void _onState(RaceState? prev, RaceState next) {
    final q = next.current;
    final shown = prev?.phase != RacePhase.racing ||
        prev?.questionIndex != next.questionIndex;
    if (next.phase == RacePhase.racing && q != null && shown) {
      _speaker.speak(spokenRaceQuestion(q));
    }
    if (prev != null && next.wrongSeq > prev.wrongSeq) {
      _speaker.speak(_tryAgain);
      setState(() => _showTryAgain = true);
      _bubble?.cancel();
      _bubble = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _showTryAgain = false);
      });
    }
    if (next.correctKey != null &&
        prev?.correctKey == null &&
        next.phase == RacePhase.racing) {
      _next?.cancel();
      _next = Timer(_rightAnswerPause, _controller.showNext);
    }
    if (next.phase == RacePhase.finishing && prev?.phase == RacePhase.racing) {
      _finishingSince = DateTime.now();
      _speaker.stop();
      if (_showTryAgain) setState(() => _showTryAgain = false);
    }
    if (next.phase == RacePhase.done && prev?.phase != RacePhase.done) {
      _goToResult(next.result!);
    }
  }

  /// Lets the rockets settle at the line before the result opens.
  void _goToResult(RaceResultArgs result) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final hold = Duration(milliseconds: reduce ? 600 : 1400);
    final since = _finishingSince ?? DateTime.now();
    final waited = DateTime.now().difference(since);
    final rest = hold - waited;
    _leave = Timer(rest.isNegative ? Duration.zero : rest, () {
      if (mounted) context.go('/game/result', extra: result);
    });
  }

  void _speakAgain() {
    final q = ref.read(raceControllerProvider).current;
    if (q != null) _speaker.speak(spokenRaceQuestion(q));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RaceState>(raceControllerProvider, _onState);
    final s = ref.watch(raceControllerProvider);
    final form = context.formFactor;
    final scene = _sceneArea(s);
    final panel = _QuestionPanel(
      state: s,
      onKey: (i) => _controller.answer(i),
      onListen: _speakAgain,
    );
    final size = MediaQuery.sizeOf(context);
    final Widget body = switch (form) {
      FormFactor.tabletLandscape => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: scene),
            Expanded(flex: 2, child: panel),
          ],
        ),
      FormFactor.tabletPortrait => Column(
          children: [
            SizedBox(height: size.height * 0.55, child: scene),
            Expanded(child: panel),
          ],
        ),
      FormFactor.phone => Column(
          children: [
            SizedBox(
              height: (size.height * 0.54).clamp(300.0, 520.0),
              child: scene,
            ),
            Expanded(child: panel),
          ],
        ),
    };
    return Scaffold(
      backgroundColor: GameColors.panelTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          body,
          if (s.paused)
            _PauseOverlay(
              onResume: () => _controller.setPaused(false),
              onLeave: () => context.go('/game'),
            ),
        ],
      ),
    );
  }

  Widget _sceneArea(RaceState s) {
    final tablet = context.isTablet;
    return Stack(
      fit: StackFit.expand,
      children: [
        RaceScene(
          key: _sceneKey,
          kidSteps: s.kidSteps,
          chipSteps: s.chipSteps,
          kidRocket: s.rocket,
          kidTrail: s.trail,
          boosting: s.boosting,
          won: s.phase != RacePhase.racing &&
              s.phase != RacePhase.loading &&
              s.kidSteps >= raceLength,
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HudButton(
                  size: tablet ? 80 : 64,
                  onTap: s.phase == RacePhase.racing
                      ? () => _controller.setPaused(true)
                      : null,
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(top: tablet ? 14 : 8),
                  child: _HudPill(
                    text: s.phase == RacePhase.loading
                        ? 'Chuẩn bị…'
                        : 'Câu ${s.questionIndex + 1}/${s.questions.length}',
                    fontSize: tablet ? 24 : 18,
                  ),
                ),
                const Spacer(),
                SizedBox(width: tablet ? 80 : 64),
              ],
            ),
          ),
        ),
        if (_showTryAgain)
          Positioned(
            right: 12,
            top: MediaQuery.paddingOf(context).top + (tablet ? 120 : 92),
            child: const _TryAgainBubble(),
          ),
      ],
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticsLabel: 'Tạm dừng',
      builder: (pressed) => Container(
        width: size,
        height: size,
        decoration: raisedKeyDecoration(
          top: AppColors.card,
          body: AppColors.card,
          edge: GameColors.hudEdge,
          radius: 20,
          lip: 6,
          pressed: pressed,
        ),
        child:
            Icon(Icons.pause_rounded, size: size * 0.5, color: GameColors.ink),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.45),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [
          BoxShadow(color: GameColors.hudEdge, offset: Offset(0, 5)),
          BoxShadow(
              color: GameColors.hudShadow,
              blurRadius: 16,
              offset: Offset(0, 10)),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: GameColors.ink,
        ),
      ),
    );
  }
}

class _TryAgainBubble extends StatelessWidget {
  const _TryAgainBubble();

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(color: GameColors.hudEdge, offset: Offset(0, 5)),
          BoxShadow(
              color: GameColors.hudShadow,
              blurRadius: 16,
              offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppImages.chipEncourage,
              width: tablet ? 64 : 48, height: tablet ? 64 : 48),
          const SizedBox(width: 6),
          Text(
            _tryAgain,
            style: TextStyle(
              fontSize: tablet ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: GameColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// The warm lower (or right) half: comet banner, question card, keys.
class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.state,
    required this.onKey,
    required this.onListen,
  });

  final RaceState state;
  final ValueChanged<int> onKey;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final landscape = context.formFactor == FormFactor.tabletLandscape;
    final q = state.current;
    final enabled = state.phase == RacePhase.racing &&
        !state.paused &&
        state.correctKey == null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.panelTop, GameColors.panelBottom],
        ),
      ),
      child: SafeArea(
        top: landscape,
        left: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(tablet ? 28 : 16, tablet ? 20 : 12,
              tablet ? 28 : 16, tablet ? 28 : 14),
          child: q == null
              ? const SizedBox.expand()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (landscape) const Spacer(),
                    SizedBox(
                      height: tablet ? 48 : 34,
                      child: q.comet ? const _CometBanner() : null,
                    ),
                    SizedBox(height: tablet ? 12 : 8),
                    _QuestionCard(
                      key: ValueKey('q-${state.questionIndex}'),
                      question: q,
                      onListen: onListen,
                    ),
                    SizedBox(height: tablet ? 22 : 14),
                    Flexible(
                      flex: landscape ? 0 : 1,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (tablet ? 80.0 : 64.0) + 10,
                          maxHeight: tablet ? 300 : 190,
                        ),
                        child: SizedBox(
                          height: landscape ? 300 : null,
                          child: AnswerKeys(
                            labelOf: (i, ink) => _keyLabel(q, i, ink, tablet),
                            semanticsOf: (i) => _keySemantics(q, i),
                            onPressed: enabled ? onKey : null,
                            wrongKey: state.wrongKey,
                            wrongSeq: state.wrongSeq,
                            correctKey: state.correctKey,
                            gap: tablet ? 18 : 12,
                          ),
                        ),
                      ),
                    ),
                    if (landscape) const Spacer(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _keyLabel(RaceQuestion q, int i, Color ink, bool tablet) {
    switch (q) {
      case MathRaceQuestion():
        return Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            child: Text(
              '${q.choices[i]}',
              style: TextStyle(
                fontSize: tablet ? 64 : 46,
                fontWeight: FontWeight.w900,
                color: ink,
                height: 1.1,
              ),
            ),
          ),
        );
      case LetterRaceQuestion():
        return _GlyphKey(ids: q.choiceGlyphIds, index: i, ink: ink);
      case ToneRaceQuestion():
        return _GlyphKey(ids: q.choiceMarkIds, index: i, ink: ink);
    }
  }

  String _keySemantics(RaceQuestion q, int i) => switch (q) {
        MathRaceQuestion() => '${q.choices[i]}',
        LetterRaceQuestion() => q.choiceGlyphIds[i],
        ToneRaceQuestion() => toneLabels[q.choiceMarkIds[i]] ?? '',
      };
}

/// One glyph key: drawn at the scale shared by the question's three glyphs.
class _GlyphKey extends ConsumerWidget {
  const _GlyphKey({required this.ids, required this.index, required this.ink});

  final List<String> ids;
  final int index;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var tallest = 0.0;
    for (final id in ids) {
      final g = ref.watch(glyphProvider(id)).valueOrNull;
      if (g != null) tallest = math.max(tallest, glyphHeightCells(g));
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GlyphView(
        ids[index],
        color: ink,
        heightCells: tallest == 0 ? null : tallest,
      ),
    );
  }
}

class _CometBanner extends StatelessWidget {
  const _CometBanner();

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AppImages.comet, height: tablet ? 44 : 32),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _cometLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tablet ? 22 : 15,
              fontWeight: FontWeight.w900,
              color: GameColors.cometInk,
            ),
          ),
        ),
      ],
    );
  }
}

/// The white question card: a sum, stars to count, or (Tiếng Việt) a big
/// speaker button to hear the letter or tone mark again.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard(
      {super.key, required this.question, required this.onListen});

  final RaceQuestion question;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final q = question;
    final Widget child = switch (q) {
      MathRaceQuestion(question: final ArithmeticQuestion a) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  a.prompt,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: tablet ? 60 : 44,
                    fontWeight: FontWeight.w900,
                    color: GameColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ListenButton(onTap: onListen, size: tablet ? 80 : 64),
          ],
        ),
      MathRaceQuestion(question: final CountQuestion c) =>
        _countCard(c.n, tablet),
      MathRaceQuestion(question: final MatchQuestion m) =>
        _countCard(m.n, tablet),
      MathRaceQuestion() => const SizedBox.shrink(),
      LetterRaceQuestion() => _listenCard('Chíp đọc chữ nào?', tablet),
      ToneRaceQuestion() => _listenCard('Chíp đọc dấu nào?', tablet),
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: tablet ? 18 : 12, vertical: tablet ? 14 : 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.card, GameColors.questionCardTint],
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          const BoxShadow(
              color: GameColors.questionCardEdge, offset: Offset(0, 9)),
          BoxShadow(
            color: GameColors.keyOrangeEdge.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _countCard(int n, bool tablet) {
    final star = tablet ? 46.0 : 30.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Có bao nhiêu ngôi sao?',
                style: TextStyle(
                  fontSize: tablet ? 26 : 19,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                // Five stars a row, so 10 reads as two rows of five.
                constraints: BoxConstraints(maxWidth: star * 5 + 4 * 4),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    for (var i = 0; i < n; i++)
                      Image.asset(AppImages.icStar, width: star, height: star),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ListenButton(onTap: onListen, size: tablet ? 80 : 64),
      ],
    );
  }

  Widget _listenCard(String hint, bool tablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ListenButton(onTap: onListen, size: tablet ? 104 : 80, big: true),
        SizedBox(width: tablet ? 20 : 14),
        Flexible(
          child: Text(
            hint,
            style: TextStyle(
              fontSize: tablet ? 30 : 22,
              fontWeight: FontWeight.w900,
              color: GameColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton(
      {required this.onTap, required this.size, this.big = false});

  final VoidCallback onTap;
  final double size;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final face = big ? size : size * 0.8;
    return Pressable(
      key: ValueKey(big ? 'listen-big' : 'listen'),
      onTap: onTap,
      semanticsLabel: 'Nghe câu hỏi',
      builder: (pressed) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: face,
            height: face,
            decoration: raisedKeyDecoration(
              top: GameColors.listenFill,
              body: GameColors.listenFill,
              edge: GameColors.listenEdge,
              radius: face / 2,
              lip: big ? 6 : 4,
              pressed: pressed,
            ),
            child: Icon(Icons.volume_up_rounded,
                size: face * 0.5, color: GameColors.listenInk),
          ),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onLeave});

  final VoidCallback onResume;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return ColoredBox(
      color: GameColors.skyTop.withOpacity(0.7),
      child: Center(
        child: Container(
          width: tablet ? 440 : 320,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: raisedDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AppImages.chipMain, height: tablet ? 140 : 110),
              const SizedBox(height: 8),
              Text(
                'Tạm dừng',
                style: TextStyle(
                  fontSize: tablet ? 34 : 28,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
              const SizedBox(height: 18),
              BigGameButton(label: 'Đua tiếp', onTap: onResume),
              const SizedBox(height: 14),
              BigGameButton(
                  label: 'Về Góc Chơi', onTap: onLeave, primary: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width game button: orange "go" key, or a white one.
class BigGameButton extends StatelessWidget {
  const BigGameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final h = primary ? (tablet ? 96.0 : 76.0) : (tablet ? 80.0 : 64.0);
    return Pressable(
      onTap: onTap,
      semanticsLabel: label,
      builder: (pressed) => Container(
        height: h,
        alignment: Alignment.center,
        decoration: primary
            ? raisedKeyDecoration(
                top: GameColors.goTop,
                body: GameColors.go,
                edge: GameColors.goEdge,
                pressed: pressed,
                lip: 8,
              )
            : raisedKeyDecoration(
                top: AppColors.card,
                body: GameColors.questionCardTint,
                edge: GameColors.questionCardEdge,
                pressed: pressed,
                lip: 7,
              ),
        child: ExcludeSemantics(
          child: Text(
            label,
            style: TextStyle(
              fontSize: primary ? (tablet ? 34 : 28) : (tablet ? 26 : 21),
              fontWeight: FontWeight.w900,
              color: primary ? GameColors.goInk : GameColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
