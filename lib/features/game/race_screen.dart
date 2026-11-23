import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/engine/race.dart';
import '../../game/engine/race_question.dart';
import '../../game/scene/online_race_painter.dart'
    show roomRocketForIndex, safeOnlineAvatar;
import '../../game/scene/race_scene.dart';
import '../../math/math_question.dart';
import '../../online/room/room_controller.dart';
import '../../profile/avatars.dart';
import '../../profile/kid_repository.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import '../../voice/voice_lines.dart';
import '../online_race/room_widgets.dart' show StickerImageTile, roomStickerArt;
import 'answer_keys.dart';
import 'glyph_view.dart';
import 'race_controller.dart';
import 'race_rival.dart';
import 'race_standings_strip.dart';

part 'race_answer_desk.dart';
part 'race_hud.dart';
part 'race_online_extras.dart';

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
String spokenRaceIntro(RaceQuestion q) =>
    q.comet ? '$voiceComet ${spokenRaceQuestion(q)}' : spokenRaceQuestion(q);

/// "Đua với Chíp": the space scene on top (left on a landscape tablet) and
/// the warm toy cockpit AnswerDesk below (right on landscape tablet).
class RaceScreen extends ConsumerStatefulWidget {
  const RaceScreen({
    super.key,
    required this.subject,
    this.retryAfterLoss = false,
    this.rival,
    this.inputLocked = false,
  });

  final RaceSubject subject;
  final bool retryAfterLoss;

  /// Online room: race this friend instead of Chíp.
  final RaceRival? rival;

  /// True while self-reconnecting in an online race: scene stays visible but
  /// answer keys ignore taps until reconnected.
  final bool inputLocked;

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
  final _sceneKey = GlobalKey<RaceSceneState>();
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
  bool _speakingQuestion = false;
  int _speakToken = 0;
  int _lastHandledStickerSeq = -1;
  int _cheerStage = 1;
  bool _cheeredThisStage = false;
  final List<DateTime> _teaseTimestamps = [];

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
    _speakToken++;
    _speakingQuestion = false;
    _speaker.stop();
    super.dispose();
  }

  Future<void> _speakQuestion(String line) async {
    final token = ++_speakToken;
    _speakingQuestion = true;
    try {
      await _speaker.speak(line);
    } finally {
      if (_speakToken == token) {
        _speakingQuestion = false;
      }
    }
  }

  void _onIncomingSticker(RoomSticker? s) {
    if (s == null || s.seq == _lastHandledStickerSeq) return;
    _lastHandledStickerSeq = s.seq;

    final race = ref.read(raceControllerProvider);
    if (race.phase != RacePhase.racing) return;

    final teaseOn = ref.read(teaseStickersProvider).valueOrNull ?? true;
    if (isTeaseSticker(s.id) && !teaseOn) {
      return;
    }

    final room = ref.read(roomControllerProvider);
    final scene = _sceneKey.currentState;
    final phrase = quickPhraseTexts[s.id];

    scene?.playSticker(
      IncomingStickerEvent(
        seq: s.seq,
        fromId: s.from,
        stickerId: s.id,
        toId: s.to,
        bubbleText: phrase,
      ),
    );

    if (phrase != null && !_speakingQuestion && !race.paused) {
      unawaited(_speaker.speak(phrase));
    }

    if (isTeaseSticker(s.id) && teaseOn && s.from != room.you) {
      if (_cheerStage != race.stage) {
        _cheerStage = race.stage;
        _cheeredThisStage = false;
        _teaseTimestamps.clear();
      }
      final now = ref.read(stickerClockProvider)();
      _teaseTimestamps.add(now);
      _teaseTimestamps.removeWhere(
        (t) => now.difference(t) > const Duration(seconds: 10),
      );
      if (!_cheeredThisStage && _teaseTimestamps.length >= 3) {
        _cheeredThisStage = true;
        scene?.playCheerUp();
      }
    }
  }

  void _onState(RaceState? prev, RaceState next) {
    final q = next.current;
    final leavingGate = (prev?.starGateActive ?? false) && !next.starGateActive;
    final shown = !next.starGateActive &&
        (prev?.phase != RacePhase.racing ||
            prev?.questionIndex != next.questionIndex ||
            leavingGate);
    if (next.phase == RacePhase.racing && q != null && shown) {
      unawaited(_speakQuestion(spokenRaceIntro(q)));
    }
    if (prev != null && next.wrongSeq > prev.wrongSeq) {
      _speaker.speak(_tryAgain);
      setState(() => _showTryAgain = true);
      _bubble?.cancel();
      _bubble = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _showTryAgain = false);
      });
    }
    if (next.comboStreak == 2 && (prev?.comboStreak ?? 0) < 2) {
      _speaker.speak(voiceNitroFast);
    }
    if (next.correctKey != null &&
        prev?.correctKey == null &&
        next.phase == RacePhase.racing) {
      _next?.cancel();
      _next = Timer(_rightAnswerPause, _controller.showNext);
    }
    if (next.phase == RacePhase.finishing && prev?.phase == RacePhase.racing) {
      _finishingSince = DateTime.now();
      _clock.stop();
      _speakToken++;
      _speakingQuestion = false;
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
    if (q != null) unawaited(_speakQuestion(spokenRaceQuestion(q)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RaceState>(raceControllerProvider, _onState);
    if (widget.rival != null) {
      ref.listen<RoomSticker?>(
        roomControllerProvider.select((s) => s.sticker),
        (_, next) => _onIncomingSticker(next),
      );
    }
    final paused = ref.watch(raceControllerProvider.select((s) => s.paused));
    final form = context.formFactor;
    final tablet = context.isTablet;
    final landscape = form == FormFactor.tabletLandscape;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final isOnline = widget.rival != null;
    final double bottomInset = landscape
        ? 0.0
        : isOnline
            ? (tablet ? 400.0 : 328.0 + safeBottom)
            : (tablet ? 310.0 : 256.0 + safeBottom);

    final scene = Consumer(
      builder: (context, ref, _) {
        final kids = ref.watch(kidsProvider).valueOrNull ?? const [];
        final currentKidId = ref.watch(currentKidIdProvider).valueOrNull;
        final currentKid =
            kids.where((k) => k.id == currentKidId).firstOrNull ??
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
                comboStreak: s.comboStreak,
                starGateStage: s.starGateStage,
              ))),
          bottomInset: bottomInset,
          kidAvatar: currentKid?.avatar,
          rival: ref.watch(raceControllerProvider.select((s) => s.rival)),
        );
      },
    );

    final topBar = RepaintBoundary(
      child: Consumer(
        builder: (context, ref, _) {
          final bar = _topBar(ref.watch(raceControllerProvider.select((s) => (
                phase: s.phase,
                questionIndex: s.questionIndex,
                count: s.questions.length,
                online: s.online,
                stage: s.stage,
                inSprint: s.inSprint,
                kidSteps: s.kidSteps,
              ))));
          // Online rooms of 3-4: everyone's progress under the top bar.
          final rival =
              ref.watch(raceControllerProvider.select((s) => s.rival));
          final standings = rival?.standings;
          final showStandings = RaceStandingsStrip.shows(standings);
          final showRivalWaiting =
              !showStandings && (rival?.rivalAway ?? false) && rival != null;
          if (!showStandings && !showRivalWaiting) return bar;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              bar,
              if (showStandings)
                Align(
                  alignment: Alignment.centerLeft,
                  child: RaceStandingsStrip(standings: standings!),
                )
              else if (showRivalWaiting)
                Align(
                  alignment: Alignment.centerRight,
                  child: _RivalWaitingBadge(
                    avatar: rival.avatar,
                    name: rival.name,
                  ),
                ),
            ],
          );
        },
      ),
    );

    final desk = RepaintBoundary(
      child: IgnorePointer(
        ignoring: widget.inputLocked,
        child: Opacity(
          opacity: widget.inputLocked ? 0.55 : 1.0,
          child: AnswerDesk(
            onKey: (i) {
              if (!widget.inputLocked) _controller.answer(i);
            },
            onListen: _speakAgain,
          ),
        ),
      ),
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
      int comboStreak,
      int? starGateStage,
    }) s, {
    required double bottomInset,
    String? kidAvatar,
    RivalView? rival,
  }) {
    final isOnline = rival != null;
    final targetSteps = isOnline ? onlineRaceLength : raceLength;
    List<OnlineRacer>? onlineRacers;
    if (isOnline) {
      final active = <OnlineRacer>[];
      for (var i = 0; i < rival.standings.length; i++) {
        final r = rival.standings[i];
        if (r.left) continue;
        final fallbackAvatar =
            r.isYou && kidAvatar != null ? kidAvatar : r.avatar;
        active.add(OnlineRacer(
          id: r.id.isNotEmpty ? r.id : 'p$i',
          name: r.name,
          avatar: safeOnlineAvatar(fallbackAvatar, i),
          rocket: roomRocketForIndex(i),
          steps: r.isYou ? math.max(r.steps, s.kidSteps) : r.steps,
          rank: r.rank,
          me: r.isYou,
          away: r.away,
        ));
      }
      if (active.isEmpty) {
        active.addAll([
          OnlineRacer(
            id: 'me',
            name: 'Bé',
            avatar: safeOnlineAvatar(kidAvatar ?? '', 0),
            rocket: roomRocketForIndex(0),
            steps: s.kidSteps,
            me: true,
          ),
          OnlineRacer(
            id: 'rival',
            name: rival.name,
            avatar: safeOnlineAvatar(rival.avatar, 1),
            rocket: roomRocketForIndex(1),
            steps: s.chipSteps,
            away: rival.rivalAway,
          ),
        ]);
      }
      onlineRacers = active;
    }

    return RaceScene(
      key: _sceneKey,
      kidSteps: s.kidSteps,
      chipSteps: s.chipSteps,
      kidRocket: s.rocket,
      kidTrail: s.trail,
      boosting: s.boosting,
      won: s.phase != RacePhase.racing &&
          s.phase != RacePhase.loading &&
          s.kidSteps >= targetSteps,
      kidAvatar: kidAvatar,
      rivalRocket: rival?.rocket,
      rivalAvatar: rival?.avatar,
      rivalName: rival?.name,
      rivalAway: rival?.rivalAway ?? false,
      onlineRacers: onlineRacers,
      raceSteps: targetSteps,
      comboStreak: s.comboStreak,
      superSpeed: s.comboStreak >= 3,
      starGateStage: s.starGateStage,
      stallSeq: s.wrongSeq,
      bottomInset: bottomInset,
    );
  }

  Widget _topBar(
      ({
        RacePhase phase,
        int questionIndex,
        int count,
        bool online,
        int stage,
        bool inSprint,
        int kidSteps,
      }) s) {
    final tablet = context.isTablet;
    final onlineQ = (s.questionIndex + 1).clamp(1, onlineRaceLength);
    final hudLabel = s.phase == RacePhase.loading
        ? 'Chuẩn bị…'
        : (s.online
            ? 'Chặng ${s.stage} · Câu $onlineQ/$onlineRaceLength'
            : 'Câu ${s.questionIndex + 1}/${s.count}');
    final showSprint = s.online &&
        s.phase != RacePhase.loading &&
        (s.stage == 3 || s.inSprint);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 28 : 16,
        vertical: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HudButton(
                size: tablet ? 80 : 54,
                onTap: s.phase == RacePhase.racing
                    ? () => _controller.setPaused(true)
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSprint) ...[
                      Flexible(
                        child: Container(
                          key: const ValueKey('sprint-badge'),
                          padding: EdgeInsets.symmetric(
                            horizontal: tablet ? 14 : 10,
                            vertical: tablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: GameColors.sprintBadgeBg,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            boxShadow: const [
                              BoxShadow(
                                color: GameColors.hudShadow,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Nước rút!',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: tablet ? 18 : 13,
                                fontWeight: FontWeight.w900,
                                color: GameColors.sprintBadgeInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tablet ? 20 : 12,
                          vertical: tablet ? 10 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          boxShadow: const [
                            BoxShadow(
                              color: GameColors.hudEdge,
                              offset: Offset(0, 4),
                            ),
                            BoxShadow(
                              color: GameColors.hudShadow,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                AppImages.icStar,
                                width: tablet ? 26 : 20,
                                height: tablet ? 26 : 20,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hudLabel,
                                style: TextStyle(
                                  fontSize: tablet ? 22 : 15,
                                  fontWeight: FontWeight.w900,
                                  color: GameColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (s.online) ...[
            const SizedBox(height: 8),
            _StageProgressBar(
              kidSteps: s.kidSteps,
              stage: s.stage,
              inSprint: s.inSprint,
              tablet: tablet,
            ),
          ],
        ],
      ),
    );
  }
}
