import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../explore/geography_level.dart';
import '../../game/data/game_repository.dart';
import '../../game/engine/question_source.dart';
import '../../game/engine/race_question.dart';
import '../../game/travel/trip.dart';
import '../../game/travel/trip_board_painter.dart';
import '../../game/travel/trip_progress.dart';
import '../../learning/writing_ladder.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../../voice/speaker.dart';
import 'answer_keys.dart';
import 'race_controller.dart' show raceRandomProvider, spokenNameFromId;
import 'race_question_card.dart';
import 'race_screen.dart' show spokenRaceQuestion;

/// The question on screen, for tests.
@visibleForTesting
RaceQuestion? debugTravelQuestion;

/// Time per step while Chíp hops along the board.
const tripHopStep = Duration(milliseconds: 250);

/// Width of one step on the board.
const _cell = 56.0;

/// "Chíp du lịch": answer questions, Chíp walks the trip, stops give
/// postcards. Progress is written on every right answer, so leaving at any
/// time loses nothing.
class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

enum _Phase { loading, done, asking, moving, postcard, summary }

class _TravelScreenState extends ConsumerState<TravelScreen> {
  _Phase _phase = _Phase.loading;
  List<RaceQuestion> _questions = const [];
  int _index = 0;
  bool _missed = false;
  int? _wrongKey;
  int _wrongSeq = 0;
  int? _correctKey;
  int _step = 0;
  int _roundStars = 0;
  final List<GeoItem> _roundStops = [];
  GeoItem? _postcard;
  Completer<void>? _continue;
  late final Speaker _speaker;
  final _scroll = ScrollController();
  bool _disposed = false;

  RaceQuestion? get _current =>
      _questions.isEmpty ? null : _questions[_index];

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _start();
  }

  @override
  void dispose() {
    _disposed = true;
    debugTravelQuestion = null;
    _speaker.stop();
    _scroll.dispose();
    super.dispose();
  }

  Future<GameRepository> get _repo => ref.read(gameRepositoryProvider.future);

  Future<void> _start() async {
    if (_phase != _Phase.loading) {
      setState(() => _phase = _Phase.loading);
      debugTravelQuestion = null;
    }
    final repo = await _repo;
    final levels = await ref.read(levelRepositoryProvider.future);
    final progress = await ref.read(progressRepositoryProvider.future);
    final mathLevel = await levels.levelOf('toan') ?? 0;
    final writingStart = await levels.levelOf('viet') ?? 0;
    final stats = await progress.glyphStats();
    final speech = <String, String>{};
    final ids = {
      ...writingLadder.where((id) => id.startsWith('chu-')),
      ...firstLetterGroup,
      ...toneIds,
    };
    // Names come from the glyph files; a slow read never holds the round
    // up: after 2 s the missing ones use the built-in names.
    for (final id in ids) {
      speech[id] = spokenNameFromId(id);
    }
    try {
      await Future.wait(ids.map((id) async {
        try {
          speech[id] = (await ref.read(glyphProvider(id).future)).spokenName;
        } catch (_) {}
      })).timeout(const Duration(seconds: 2));
    } on TimeoutException catch (_) {}
    final step = await repo.tripStep();
    if (_disposed) return;
    final questions = buildTripQuestions(
      mathLevelIndex: mathLevel,
      glyphStats: stats,
      writingStartIndex: writingStart,
      speechByGlyph: speech,
      rng: ref.read(raceRandomProvider),
    );
    setState(() {
      _step = step;
      _questions = questions;
      _index = 0;
      _missed = false;
      _wrongKey = null;
      _correctKey = null;
      _roundStars = 0;
      _roundStops.clear();
      _phase = step >= tripLength ? _Phase.done : _Phase.asking;
    });
    debugTravelQuestion = questions.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(jump: true));
    if (_phase == _Phase.done) {
      _speaker.speak('Chíp đã đi khắp nơi rồi! '
          'Cảm ơn bạn nhỏ đã đi cùng Chíp!');
    } else {
      _speakQuestion();
    }
  }

  void _speakQuestion() {
    final q = _current;
    if (q != null) _speaker.speak(spokenRaceQuestion(q));
  }

  /// Keeps Chíp about a third from the left of the board.
  void _follow({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final target = (_xOf(_step) - view / 3)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if (jump) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target,
          duration: tripHopStep, curve: Curves.easeOut);
    }
  }

  Future<void> _onKey(int i) async {
    final q = _current;
    if (q == null || _phase != _Phase.asking || _correctKey != null) return;
    if (i != q.correctIndex) {
      setState(() {
        _missed = true;
        _wrongKey = i;
        _wrongSeq++;
      });
      _speaker.speak('Thử lại nhé!');
      return;
    }
    final firstTry = !_missed;
    setState(() {
      _correctKey = i;
      _wrongKey = null;
      _phase = _Phase.moving;
    });
    final repo = await _repo;
    if (firstTry) {
      await repo.addTripStar();
      _roundStars++;
    }
    final advance = await repo.advanceTrip(tripStepsFor(firstTry: firstTry));
    ref.read(gameDataRevisionProvider.notifier).state++;
    if (_disposed) return;
    await _walk(advance);
    if (_disposed) return;
    _next();
  }

  /// Hops from [a.from] to [a.to], pausing on each stop for its postcard.
  Future<void> _walk(TripAdvance a) async {
    final db = ref.read(databaseProvider);
    for (final hop in tripHops(a.from, a.to - a.from)) {
      for (var s = 0; s < hop; s++) {
        await Future<void>.delayed(tripHopStep);
        if (_disposed) return;
        setState(() => _step++);
        _follow();
      }
      final reached = tripNewStops(_step - hop, _step);
      for (final stop in reached) {
        _roundStops.add(stop);
        final kid = (await _repo).kidId;
        if (kid != null) await markTripShown(db, kid, _step);
        if (_disposed) return;
        final done = Completer<void>();
        setState(() {
          _postcard = stop;
          _continue = done;
          _phase = _Phase.postcard;
        });
        _speaker.speak('Chíp tới ${stop.speech} rồi! ${stop.fact}');
        await done.future;
        if (_disposed) return;
        setState(() {
          _postcard = null;
          _phase = _Phase.moving;
        });
      }
    }
  }

  void _onContinue() {
    final c = _continue;
    _continue = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  void _next() {
    if (_index == _questions.length - 1) {
      setState(() => _phase = _Phase.summary);
      _speaker.speak(_roundStops.isEmpty
          ? 'Giỏi quá! Mình đi tiếp lần sau nhé!'
          : 'Giỏi quá! Bé có thêm ${_roundStops.length} bưu thiếp!');
      return;
    }
    setState(() {
      _index++;
      _missed = false;
      _wrongKey = null;
      _correctKey = null;
      _phase = _Phase.asking;
    });
    debugTravelQuestion = _current;
    _speakQuestion();
  }

  void _leave() {
    _onContinue();
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final landscape = context.formFactor == FormFactor.tabletLandscape;
    final q = _current;

    final header = _Header(
      postcards: tripPostcards(_step),
      onBack: _leave,
      tablet: tablet,
    );

    final board = _Board(step: _step, scroll: _scroll, tablet: tablet);

    final Widget answers = q == null
        ? const SizedBox.shrink()
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RaceQuestionCard(
                key: ValueKey('trip-q-$_index'),
                question: q,
                onListen: _speakQuestion,
              ),
              SizedBox(height: tablet ? 16 : 10),
              SizedBox(
                height: tablet ? (landscape ? 200 : 100) : 76,
                child: AnswerKeys(
                  labelOf: (i, ink) => raceKeyLabel(q, i, ink, tablet),
                  semanticsOf: (i) => raceKeySemantics(q, i),
                  onPressed: _phase == _Phase.asking ? _onKey : null,
                  wrongKey: _wrongKey,
                  wrongSeq: _wrongSeq,
                  correctKey: _correctKey,
                  vertical: landscape,
                  gap: tablet ? 16 : 12,
                ),
              ),
            ],
          );

    final desk = Container(
      padding: EdgeInsets.all(tablet ? 20 : 14),
      decoration: raisedDecoration(radius: AppRadii.card),
      child: SingleChildScrollView(child: answers),
    );

    final Widget body = landscape
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: board),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: Center(child: desk)),
            ],
          )
        : LayoutBuilder(
            builder: (context, c) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: c.maxHeight * 0.45, child: board),
                const SizedBox(height: 12),
                Expanded(child: Align(alignment: Alignment.topCenter, child: desk)),
              ],
            ),
          );

    final overlay = switch (_phase) {
      _Phase.postcard when _postcard != null => _PostcardOverlay(
          stop: _postcard!, tablet: tablet, onContinue: _onContinue),
      _Phase.summary => _SummaryOverlay(
          stars: _roundStars,
          stops: _roundStops,
          tablet: tablet,
          onAgain: _start,
          onHome: _leave,
        ),
      _Phase.done => _DoneOverlay(
          tablet: tablet,
          onPlay: () {
            setState(() => _phase = _Phase.asking);
            _speakQuestion();
          },
        ),
      _ => null,
    };

    final scaffold = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    tablet ? 24 : 12, 8, tablet ? 24 : 12, tablet ? 24 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 8),
                    Expanded(
                      child: _phase == _Phase.loading
                          ? const SizedBox.shrink()
                          : body,
                    ),
                  ],
                ),
              ),
              if (overlay != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.text.withOpacity(0.35),
                    child: Center(child: overlay),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tablet ? TabletTextScale(child: scaffold) : scaffold;
  }
}

double _xOf(int step) => _cell * (step + 1);

double _yOf(int step, double height) =>
    height * 0.55 + sin(step * 0.45) * height * 0.18;

class _Header extends StatelessWidget {
  const _Header({
    required this.postcards,
    required this.onBack,
    required this.tablet,
  });

  final int postcards;
  final VoidCallback onBack;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final size = tablet ? TabletSizes.kidTarget : 64.0;
    return Row(
      children: [
        Pressable(
          key: const ValueKey('trip-back'),
          onTap: onBack,
          semanticsLabel: 'Quay lại',
          builder: (pressed) => Container(
            width: size,
            height: size,
            decoration: raisedDecoration(radius: size / 2, pressed: pressed),
            child: Icon(Icons.chevron_left_rounded,
                size: tablet ? 44 : 36, color: AppColors.text),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Chíp du lịch',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: raisedDecoration(
            radius: AppRadii.pill,
            accent: Subject.diaLy.color,
            tint: Subject.diaLy.tint,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_rounded,
                  size: tablet ? 26 : 22, color: Subject.diaLy.color),
              const SizedBox(width: 6),
              Text(
                '$postcards/${tripStops.length}',
                style: TextStyle(
                  fontSize: tablet ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  color: Subject.diaLy.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The trip board: path and dots painted, stop stamps and Chíp as widgets
/// (so a broken picture falls back to its name).
class _Board extends StatelessWidget {
  const _Board({required this.step, required this.scroll, required this.tablet});

  final int step;
  final ScrollController scroll;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Subject.diaLy.tint,
          border: Border.all(color: AppColors.dot, width: 2),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight;
          final stamp = (h * 0.36).clamp(56.0, tablet ? 120.0 : 96.0);
          final chip = (h * 0.32).clamp(48.0, tablet ? 110.0 : 84.0);
          final width = _xOf(tripLength) + _cell * 2;
          return SingleChildScrollView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: width,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: TripBoardPainter(
                          length: tripLength,
                          stopEvery: tripStepsPerStop,
                          reached: step,
                          pointAt: (s) => Offset(_xOf(s), _yOf(s, h)),
                          path: AppColors.dot,
                          walked: Subject.diaLy.color,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _xOf(0) - chip * 0.4,
                    top: _yOf(0, h) - chip * 0.4,
                    child: Image.asset(AppImages.icKhamPha,
                        width: chip * 0.8, height: chip * 0.8),
                  ),
                  for (var i = 0; i < tripStops.length; i++)
                    Positioned(
                      left: _xOf(tripStopStep(i)) - stamp / 2,
                      top: (_yOf(tripStopStep(i), h) - stamp / 2)
                          .clamp(0.0, h - stamp),
                      child: TripStamp(
                        stop: tripStops[i],
                        size: stamp,
                        reached: tripStopStep(i) <= step,
                      ),
                    ),
                  AnimatedPositioned(
                    duration: tripHopStep,
                    curve: Curves.easeOut,
                    left: _xOf(step) - chip / 2,
                    top: (_yOf(step, h) - chip * 0.95).clamp(0.0, h - chip),
                    child: IgnorePointer(
                      child: Image.asset(AppImages.chipJoy,
                          width: chip, height: chip),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A round postcard stamp on the board; faded with "?" until reached.
class TripStamp extends StatelessWidget {
  const TripStamp({
    super.key,
    required this.stop,
    required this.size,
    required this.reached,
  });

  final GeoItem stop;
  final double size;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final art = Image.asset(
      stop.image,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => TripNameTile(stop.name, size: size),
    );
    return Semantics(
      label: reached ? stop.name : 'Trạm chưa tới',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: reached ? Subject.diaLy.color : AppColors.dot,
            width: 3,
          ),
        ),
        child: reached
            ? ClipOval(child: art)
            : Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: 0.25, child: ClipOval(child: art)),
                  Text(
                    '?',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Stand-in for a picture that fails to load: the stop's name.
class TripNameTile extends StatelessWidget {
  const TripNameTile(this.name, {super.key, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      color: Subject.diaLy.tint,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Subject.diaLy.color,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.tablet, required this.child});

  final bool tablet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: tablet ? 520 : 360),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.all(tablet ? 28 : 20),
        decoration: raisedDecoration(radius: AppRadii.card),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.tablet,
    this.primary = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool tablet;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticsLabel: label,
      builder: (pressed) => Container(
        constraints:
            BoxConstraints(minHeight: tablet ? TabletSizes.kidTarget : 64),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: primary
            ? raisedDecoration(
                radius: AppRadii.pill,
                accent: AppColors.primary,
                tint: AppColors.primary,
                pressed: pressed,
              )
            : raisedDecoration(radius: AppRadii.pill, pressed: pressed),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: tablet ? 24 : 20,
            fontWeight: FontWeight.w900,
            color: primary ? AppColors.card : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _PostcardOverlay extends StatelessWidget {
  const _PostcardOverlay({
    required this.stop,
    required this.tablet,
    required this.onContinue,
  });

  final GeoItem stop;
  final bool tablet;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final art = tablet ? 260.0 : 180.0;
    return _Card(
      key: const ValueKey('trip-postcard'),
      tablet: tablet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bưu thiếp mới!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tablet ? 22 : 18,
              fontWeight: FontWeight.w800,
              color: Subject.diaLy.color,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Image.asset(
              stop.image,
              width: art,
              height: art,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => TripNameTile(stop.name, size: art),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stop.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tablet ? 30 : 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stop.fact,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tablet ? 20 : 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          _BigButton(
            key: const ValueKey('trip-continue'),
            label: 'Đi tiếp',
            onTap: onContinue,
            tablet: tablet,
          ),
        ],
      ),
    );
  }
}

class _SummaryOverlay extends StatelessWidget {
  const _SummaryOverlay({
    required this.stars,
    required this.stops,
    required this.tablet,
    required this.onAgain,
    required this.onHome,
  });

  final int stars;
  final List<GeoItem> stops;
  final bool tablet;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final thumb = tablet ? 88.0 : 64.0;
    return _Card(
      key: const ValueKey('trip-summary'),
      tablet: tablet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(AppImages.chipJoy,
              height: tablet ? 120 : 88, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            'Hết chặng rồi!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tablet ? 30 : 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppImages.icStar, width: 32, height: 32),
              const SizedBox(width: 6),
              Text(
                '+$stars',
                style: TextStyle(
                  fontSize: tablet ? 28 : 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          if (stops.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in stops)
                  TripStamp(stop: s, size: thumb, reached: true),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _BigButton(
            key: const ValueKey('trip-again'),
            label: 'Chơi tiếp',
            onTap: onAgain,
            tablet: tablet,
          ),
          const SizedBox(height: 10),
          _BigButton(
            key: const ValueKey('trip-home'),
            label: 'Về Góc Chơi',
            onTap: onHome,
            tablet: tablet,
            primary: false,
          ),
        ],
      ),
    );
  }
}

class _DoneOverlay extends StatelessWidget {
  const _DoneOverlay({required this.tablet, required this.onPlay});

  final bool tablet;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return _Card(
      key: const ValueKey('trip-done'),
      tablet: tablet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(AppImages.chipJoy,
              height: tablet ? 140 : 100, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            'Hoàn thành chuyến du lịch!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tablet ? 30 : 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bé đã có đủ ${tripStops.length} bưu thiếp. Chơi tiếp để nhận sao nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tablet ? 20 : 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          _BigButton(
            key: const ValueKey('trip-done-play'),
            label: 'Chơi tiếp',
            onTap: onPlay,
            tablet: tablet,
          ),
        ],
      ),
    );
  }
}
