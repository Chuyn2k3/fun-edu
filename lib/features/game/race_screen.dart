import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

/// How many times the question card was built (tests check that Chíp's
/// steps do not rebuild it).
@visibleForTesting
int debugQuestionCardBuilds = 0;
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

class _RaceScreenState extends ConsumerState<RaceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Longest step race time takes in one frame, so a stall never jumps.
  static const _maxStep = Duration(milliseconds: 250);
  static const _rightAnswerPause = Duration(milliseconds: 380);

  late final Speaker _speaker;
  late final RaceController _controller;
  final _sceneKey = GlobalKey();
  late final Ticker _clock = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  /// Set when the race becomes visible again: the next frame only resyncs,
  /// so hidden time (sleep screen, background) never counts.
  bool _resync = true;
  Timer? _next;
  Timer? _bubble;
  Timer? _leave;
  ValueListenable<bool>? _tickerMode;
  bool _showTryAgain = false;
  DateTime? _finishingSince;
  int _comboStreak = 0;
  bool _triedCurrent = false;
  bool get _isNitroActive => _comboStreak >= 2;

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
    WidgetsBinding.instance.addObserver(this);
    _clock.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The screen-time guard turns tickers off while its sleep screen
    // covers the app: the race clock stops with them.
    final mode = TickerMode.getNotifier(context);
    if (mode != _tickerMode) {
      _tickerMode?.removeListener(_onTickerMode);
      _tickerMode = mode..addListener(_onTickerMode);
    }
  }

  void _onTickerMode() => _resync = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _resync = true;

  bool get _visible {
    final life = WidgetsBinding.instance.lifecycleState;
    final resumed = life == null || life == AppLifecycleState.resumed;
    return resumed && (_tickerMode?.value ?? true);
  }

  /// Race time is the frame clock's elapsed time, counted only while the
  /// race is visible and not paused, at most [_maxStep] per frame.
  void _onTick(Duration elapsed) {
    final dt = elapsed - _lastTick;
    _lastTick = elapsed;
    if (_resync || !mounted || !_visible) {
      _resync = !_visible;
      return;
    }
    if (dt <= Duration.zero) return;
    _controller.advance(dt > _maxStep ? _maxStep : dt);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerMode?.removeListener(_onTickerMode);
    _clock.dispose();
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
      _triedCurrent = false;
      _speaker.speak(spokenRaceQuestion(q));
    }
    if (prev?.phase != RacePhase.racing && next.phase == RacePhase.racing) {
      _comboStreak = 0;
      _triedCurrent = false;
    }
    if (prev != null && next.wrongSeq > prev.wrongSeq) {
      _triedCurrent = true;
      if (_comboStreak != 0) setState(() => _comboStreak = 0);
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
      if (!_triedCurrent) {
        setState(() => _comboStreak++);
      }
      _next?.cancel();
      _next = Timer(_rightAnswerPause, _controller.showNext);
    }
    if (next.phase == RacePhase.finishing && prev?.phase == RacePhase.racing) {
      _finishingSince = DateTime.now();
      _clock.stop();
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
    final paused = ref.watch(raceControllerProvider.select((s) => s.paused));
    final form = context.formFactor;
    final tablet = context.isTablet;
    final landscape = form == FormFactor.tabletLandscape;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final double bottomInset = landscape
        ? 0.0
        : (tablet ? 310.0 : 216.0 + safeBottom);

    final scene = Consumer(
      builder: (context, ref, _) =>
          _sceneOnly(
            ref.watch(raceControllerProvider.select((s) => (
                  kidSteps: s.kidSteps,
                  chipSteps: s.chipSteps,
                  boosting: s.boosting,
                  phase: s.phase,
                  rocket: s.rocket,
                  trail: s.trail,
                  wrongSeq: s.wrongSeq,
                ))),
            bottomInset: bottomInset,
          ),
    );
    final topBar = Consumer(
      builder: (context, ref, _) =>
          _topBar(ref.watch(raceControllerProvider.select((s) => (
                phase: s.phase,
                questionIndex: s.questionIndex,
                count: s.questions.length,
              )))),
    );
    final hud = FloatingCockpitHUD(
      comboStreak: _comboStreak,
      nitroActive: _isNitroActive,
      onKey: (i) => _controller.answer(i),
      onListen: _speakAgain,
    );
    final Widget body = switch (form) {
      FormFactor.tabletLandscape => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: scene),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      right: false,
                      child: topBar,
                    ),
                  ),
                  if (_showTryAgain)
                    Positioned(
                      right: 12,
                      top: MediaQuery.paddingOf(context).top + 120,
                      child: const _TryAgainBubble(),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SafeArea(
                left: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 20, 20),
                  child: hud,
                ),
              ),
            ),
          ],
        ),
      FormFactor.tabletPortrait || FormFactor.phone => Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: scene),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: topBar,
              ),
            ),
            if (_showTryAgain)
              Positioned(
                right: 12,
                top: MediaQuery.paddingOf(context).top + (tablet ? 120 : 92),
                child: const _TryAgainBubble(),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tablet ? 24 : 12,
                    0,
                    tablet ? 24 : 12,
                    tablet ? 16 : 8,
                  ),
                  child: hud,
                ),
              ),
            ),
          ],
        ),
    };
    // Android back / iOS edge swipe opens the pause overlay instead of
    // silently abandoning the race; its "Về Góc Chơi" is the explicit exit.
    // Only a race still loading can be left this way.
    final loading = ref.watch(
        raceControllerProvider.select((s) => s.phase == RacePhase.loading));
    return PopScope(
      canPop: loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.setPaused(true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0826),
        body: Stack(
          fit: StackFit.expand,
          children: [
            body,
            if (paused)
              _PauseOverlay(
                onResume: () => _controller.setPaused(false),
                onLeave: () => context.go('/game'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sceneOnly(
      ({
        int kidSteps,
        int chipSteps,
        bool boosting,
        RacePhase phase,
        String rocket,
        String trail,
        int wrongSeq,
      }) s, {
      required double bottomInset,
  }) {
    return RaceScene(
      key: _sceneKey,
      kidSteps: s.kidSteps,
      chipSteps: s.chipSteps,
      kidRocket: s.rocket,
      kidTrail: s.trail,
      boosting: s.boosting,
      won: s.phase != RacePhase.racing &&
          s.phase != RacePhase.loading &&
          s.kidSteps >= raceLength,
      stallSeq: s.wrongSeq,
      bottomInset: bottomInset,
    );
  }

  Widget _topBar(
      ({
        RacePhase phase,
        int questionIndex,
        int count,
      }) s) {
    final tablet = context.isTablet;
    return Padding(
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
                  : 'Câu ${s.questionIndex + 1}/${s.count}',
              fontSize: tablet ? 24 : 18,
            ),
          ),
          const Spacer(),
          SizedBox(width: tablet ? 80 : 64),
        ],
      ),
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

/// Floating cockpit HUD with dark translucent space glass styling,
/// Nitro streak indicator, question card, and chunky answer keys.
class FloatingCockpitHUD extends ConsumerWidget {
  const FloatingCockpitHUD({
    super.key,
    required this.onKey,
    required this.onListen,
    this.comboStreak = 0,
    this.nitroActive = false,
  });

  final ValueChanged<int> onKey;
  final VoidCallback onListen;
  final int comboStreak;
  final bool nitroActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only what the panel shows: Chíp's steps never rebuild it.
    final state = ref.watch(raceControllerProvider.select((s) => (
          phase: s.phase,
          questions: s.questions,
          questionIndex: s.questionIndex,
          wrongKey: s.wrongKey,
          wrongSeq: s.wrongSeq,
          correctKey: s.correctKey,
          paused: s.paused,
        )));
    final tablet = context.isTablet;
    final landscape = context.formFactor == FormFactor.tabletLandscape;
    final q =
        state.questions.isEmpty ? null : state.questions[state.questionIndex];
    final enabled = state.phase == RacePhase.racing &&
        !state.paused &&
        state.correctKey == null;

    final isNitro = nitroActive || comboStreak >= 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tablet ? 28 : 22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xEE160D35),
                Color(0xF5261858),
              ],
            ),
            borderRadius: BorderRadius.circular(tablet ? 28 : 22),
            border: Border.all(
              color: const Color(0x559C7DFF),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6608031C),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            tablet ? 24 : 14,
            tablet ? 16 : 10,
            tablet ? 24 : 14,
            tablet ? 18 : 12,
          ),
          child: q == null
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: landscape ? MainAxisSize.max : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (landscape) const Spacer(),
                    if (isNitro || q.comet) ...[
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isNitro) _NitroBadge(comboStreak: comboStreak),
                            if (isNitro && q.comet) const SizedBox(height: 6),
                            if (q.comet) const _CometBanner(),
                          ],
                        ),
                      ),
                      SizedBox(height: tablet ? 10 : 6),
                    ],
                    _QuestionCard(
                      key: ValueKey('q-${state.questionIndex}'),
                      question: q,
                      onListen: onListen,
                    ),
                    SizedBox(height: tablet ? 16 : 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (tablet ? 80.0 : 64.0) + 10,
                        maxHeight: tablet ? 280 : 160,
                      ),
                      child: SizedBox(
                        height: landscape ? 260 : (tablet ? 100 : 78),
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

class _NitroBadge extends StatelessWidget {
  const _NitroBadge({required this.comboStreak});

  final int comboStreak;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final fontSize = tablet ? 18.0 : 14.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 14 : 10,
        vertical: tablet ? 5 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5722),
            Color(0xFFFFB300),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88FF6D00),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            color: const Color(0xFFFFF6C7),
            size: fontSize * 1.3,
          ),
          const SizedBox(width: 4),
          Text(
            'NITRO x$comboStreak!',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: const [
                Shadow(
                  color: Color(0x99000000),
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 12 : 8,
        vertical: tablet ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0x33FFA000),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: const Color(0x88FFD54F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppImages.comet, height: tablet ? 28 : 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _cometLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: tablet ? 18 : 13,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFE082),
              ),
            ),
          ),
        ],
      ),
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
    debugQuestionCardBuilds++;
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
          horizontal: tablet ? 18 : 12, vertical: tablet ? 12 : 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.card, GameColors.questionCardTint],
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          const BoxShadow(
              color: GameColors.questionCardEdge, offset: Offset(0, 5)),
          BoxShadow(
            color: GameColors.keyOrangeEdge.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
