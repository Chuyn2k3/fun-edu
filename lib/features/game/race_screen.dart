import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/engine/race.dart';
import '../../game/engine/race_question.dart';
import '../../game/scene/race_scene.dart';
import '../../math/math_question.dart';
import '../../profile/kid_repository.dart';
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
import 'race_rival.dart';

const _tryAgain = 'Thử lại nhé!';

/// How many times the question card was built (tests check that Chíp's
/// steps do not rebuild it).
@visibleForTesting
int debugQuestionCardBuilds = 0;

/// What Chíp reads when [q] appears.
String spokenRaceQuestion(RaceQuestion q) => switch (q) {
      MathRaceQuestion(question: final ArithmeticQuestion a) =>
        spokenQuestion(a),
      MathRaceQuestion() => 'Có bao nhiêu ngôi sao?',
      LetterRaceQuestion() || ToneRaceQuestion() => q.spoken,
    };

/// What Chíp says when [q] first appears: a comet question announces itself
/// and then still reads the question, so the kid can always answer it.
String spokenRaceIntro(RaceQuestion q) => q.comet
    ? '$voiceComet ${spokenRaceQuestion(q)}'
    : spokenRaceQuestion(q);

/// "Đua với Chíp": the space scene on top (left on a landscape tablet) and
/// the warm toy cockpit AnswerDesk below (right on landscape tablet).
class RaceScreen extends ConsumerStatefulWidget {
  const RaceScreen({
    super.key,
    required this.subject,
    this.retryAfterLoss = false,
    this.rival,
  });

  final RaceSubject subject;
  final bool retryAfterLoss;

  /// Online room: race this friend instead of Chíp.
  final RaceRival? rival;

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
            retryAfterLoss: widget.retryAfterLoss, rival: widget.rival);
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
      _speaker.speak(spokenRaceIntro(q));
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
        if (_comboStreak == 2) {
          _speaker.speak(voiceNitroFast);
        }
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
      if (!mounted) return;
      // Online: the room's ranking screen (it waits for the others).
      if (result.online) {
        context.go('/game/room/result', extra: result);
      } else {
        context.go('/game/result', extra: result);
      }
    });
  }

  void _speakAgain() {
    final q = ref.read(raceControllerProvider).current;
    // The listen button repeats the question itself, comet or not.
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
        : (tablet ? 310.0 : 256.0 + safeBottom);

    final scene = Consumer(
      builder: (context, ref, _) {
        final kids = ref.watch(kidsProvider).valueOrNull ?? const [];
        final currentKidId = ref.watch(currentKidIdProvider).valueOrNull;
        final currentKid = kids.where((k) => k.id == currentKidId).firstOrNull ??
            kids.firstOrNull;
        return _sceneOnly(
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
          kidAvatar: currentKid?.avatar,
          rival: ref.watch(raceControllerProvider.select((s) => s.rival)),
        );
      },
    );

    final topBar = Consumer(
      builder: (context, ref, _) =>
          _topBar(ref.watch(raceControllerProvider.select((s) => (
                phase: s.phase,
                questionIndex: s.questionIndex,
                count: s.questions.length,
              )))),
    );

    final desk = AnswerDesk(
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
              flex: 6, // 60% scene
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
                      right: 16,
                      top: MediaQuery.paddingOf(context).top + 100,
                      child: const _TryAgainBubble(),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4, // 40% desk
              child: SafeArea(
                left: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 20),
                  child: desk,
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
                top: MediaQuery.paddingOf(context).top + (tablet ? 110 : 86),
                child: const _TryAgainBubble(),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: desk,
            ),
          ],
        ),
    };

    final loading = ref.watch(
        raceControllerProvider.select((s) => s.phase == RacePhase.loading));
    return PopScope(
      canPop: loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.setPaused(true);
      },
      child: Scaffold(
        backgroundColor: GameColors.spaceTop,
        body: Stack(
          fit: StackFit.expand,
          children: [
            body,
            if (paused)
              _PauseOverlay(
                onResume: () => _controller.setPaused(false),
                onLeave: () {
                  widget.rival?.leave();
                  context.go('/game');
                },
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
    String? kidAvatar,
    RivalView? rival,
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
      kidAvatar: kidAvatar,
      rivalRocket: rival?.rocket,
      rivalAvatar: rival?.avatar,
      rivalName: rival?.name,
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
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 28 : 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HudButton(
            size: tablet ? 80 : 54,
            onTap: s.phase == RacePhase.racing
                ? () => _controller.setPaused(true)
                : null,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 20 : 14,
              vertical: tablet ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: const [
                BoxShadow(color: GameColors.hudEdge, offset: Offset(0, 4)),
                BoxShadow(
                  color: GameColors.hudShadow,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.icStar,
                  width: tablet ? 26 : 20,
                  height: tablet ? 26 : 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  s.phase == RacePhase.loading
                      ? 'Chuẩn bị…'
                      : 'Câu ${s.questionIndex + 1}/${s.count}',
                  style: TextStyle(
                    fontSize: tablet ? 22 : 16,
                    fontWeight: FontWeight.w900,
                    color: GameColors.ink,
                  ),
                ),
              ],
            ),
          ),
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
          lip: 5,
          pressed: pressed,
        ),
        child:
            Icon(Icons.pause_rounded, size: size * 0.5, color: GameColors.ink),
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

/// The warm cream toy cockpit console at the bottom of the race screen.
/// Replaces FloatingCockpitHUD, eliminating BackdropFilter and dark neon glass.
class AnswerDesk extends ConsumerWidget {
  const AnswerDesk({
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

    return Container(
      decoration: const BoxDecoration(
        color: GameColors.cockpitBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: GameColors.cockpitShadow,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          border: Border(
            top: BorderSide(
              color: GameColors.star.withOpacity(0.95),
              width: 3.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: landscape ? 32 : (tablet ? 32 : 16),
              vertical: tablet ? 18 : 14,
            ),
            child: q == null
                ? _CockpitPlaceholder(tablet: tablet, landscape: landscape)
                : Column(
                    mainAxisSize:
                        landscape ? MainAxisSize.max : MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (landscape) const Spacer(),

                      // Top instrument bar: Speed Gauge (left) & Co-pilot Chíp (right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Toy Speed / Energy Gauge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: tablet ? 12 : 8,
                              vertical: tablet ? 5 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: GameColors.gaugeBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: GameColors.gaugeBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isNitro
                                      ? Icons.bolt_rounded
                                      : Icons.speed_rounded,
                                  size: tablet ? 20 : 16,
                                  color: GameColors.gaugeIcon,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isNitro
                                      ? 'BỨT TỐC x$comboStreak!'
                                      : 'NĂNG LƯỢNG',
                                  style: TextStyle(
                                    fontSize: tablet ? 14 : 11,
                                    fontWeight: FontWeight.w900,
                                    color: GameColors.gaugeText,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right: Co-pilot Chíp reaction / speech bubble
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: tablet ? 10 : 8,
                                  vertical: tablet ? 5 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: GameColors.hudShadow,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  isNitro
                                      ? 'Nhanh quá!'
                                      : (q.comet ? 'Sao chổi!' : 'Cố lên!'),
                                  style: TextStyle(
                                    fontSize: tablet ? 14 : 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: tablet ? 42 : 32,
                                height: tablet ? 42 : 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: GameColors.coPilotBg,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    isNitro
                                        ? AppImages.chipSurprise
                                        : AppImages.chipJoy,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: tablet ? 14 : 10),

                      // Central Question Card (with perched comet if comet question)
                      _QuestionCard(
                        key: ValueKey('q-${state.questionIndex}'),
                        question: q,
                        onListen: onListen,
                      ),
                      SizedBox(height: tablet ? 16 : 10),

                      // 3 Chunky 3D Arcade Keys
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (tablet ? 80.0 : 64.0) + 10,
                          maxHeight: tablet ? 280 : 160,
                        ),
                        child: SizedBox(
                          height: landscape ? 240 : (tablet ? 100 : 76),
                          child: AnswerKeys(
                            labelOf: (i, ink) => _keyLabel(q, i, ink, tablet),
                            semanticsOf: (i) => _keySemantics(q, i),
                            onPressed: enabled ? onKey : null,
                            wrongKey: state.wrongKey,
                            wrongSeq: state.wrongSeq,
                            correctKey: state.correctKey,
                            gap: tablet ? 16 : 12,
                          ),
                        ),
                      ),
                      if (landscape) const Spacer(),
                    ],
                  ),
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

class _CockpitPlaceholder extends StatelessWidget {
  const _CockpitPlaceholder({required this.tablet, required this.landscape});

  final bool tablet;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final keyHeight = tablet ? 88.0 : 66.0;
    return Column(
      mainAxisSize: landscape ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (landscape) const Spacer(),
        // Top instrument row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? 12 : 8,
                vertical: tablet ? 5 : 4,
              ),
              decoration: BoxDecoration(
                color: GameColors.gaugeBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GameColors.gaugeBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: tablet ? 20 : 16,
                    color: GameColors.gaugeIcon,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'NĂNG LƯỢNG',
                    style: TextStyle(
                      fontSize: tablet ? 14 : 11,
                      fontWeight: FontWeight.w900,
                      color: GameColors.gaugeText,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tablet ? 10 : 8,
                    vertical: tablet ? 5 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: GameColors.hudShadow,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Cố lên!',
                    style: TextStyle(
                      fontSize: tablet ? 14 : 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: tablet ? 42 : 32,
                  height: tablet ? 42 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GameColors.coPilotBg,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppImages.chipJoy,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: tablet ? 12 : 8),

        // Placeholder question card
        Container(
          width: double.infinity,
          height: tablet ? 104 : 80,
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 20 : 14,
            vertical: tablet ? 14 : 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: GameColors.questionCardEdge,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: GameColors.questionCardEdge,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.rocketOrange,
                  width: tablet ? 32 : 24,
                  height: tablet ? 32 : 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Sẵn sàng xuất phát!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: tablet ? 20 : 15,
                      fontWeight: FontWeight.w900,
                      color: GameColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tablet ? 14 : 10),

        // 3 inactive placeholder keys
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: tablet ? 14 : 10),
              Expanded(
                child: Container(
                  height: keyHeight,
                  decoration: raisedKeyDecoration(
                    top: GameColors.keyOrangeTop.withOpacity(0.5),
                    body: GameColors.keyOrange.withOpacity(0.5),
                    edge: GameColors.keyOrangeEdge.withOpacity(0.5),
                    radius: tablet ? 26 : 20,
                    lip: tablet ? 9 : 7,
                    pressed: false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

typedef FloatingCockpitHUD = AnswerDesk;

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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: tablet ? 20 : 14, vertical: tablet ? 14 : 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: q.comet ? GameColors.cometRim : GameColors.questionCardEdge,
              width: q.comet ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: q.comet
                    ? GameColors.stoneLuckyGlow.withOpacity(0.35)
                    : GameColors.questionCardEdge,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: GameColors.keyOrangeEdge.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        if (q.comet)
          Positioned(
            left: -10,
            top: -12,
            child: Image.asset(
              AppImages.comet,
              width: tablet ? 42 : 32,
              height: tablet ? 42 : 32,
              fit: BoxFit.contain,
            ),
          ),
      ],
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
                constraints: BoxConstraints(maxWidth: star * 5 + 4 * 4),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < n; i++)
                      Image.asset(
                        AppImages.icStar,
                        width: star,
                        height: star,
                        fit: BoxFit.contain,
                      ),
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

  Widget _listenCard(String prompt, bool tablet) {
    return Row(
      children: [
        Expanded(
          child: Text(
            prompt,
            style: TextStyle(
              fontSize: tablet ? 26 : 19,
              fontWeight: FontWeight.w900,
              color: GameColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ListenButton(onTap: onListen, size: tablet ? 80 : 64, big: true),
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
    final face = big ? size * 0.9 : size * 0.72;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Pressable(
          key: ValueKey(big ? 'listen-big' : 'listen'),
          onTap: onTap,
          semanticsLabel: 'Nghe câu hỏi',
          builder: (pressed) => Container(
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
