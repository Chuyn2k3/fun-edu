import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../profile/kid_repository.dart';
import '../../stroke/glyph.dart';
import '../../stroke/glyph_repository.dart';
import '../../stroke/glyph_session.dart';
import '../../stroke/grader.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/chip_says.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/session_header.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../voice/speaker.dart';
import '../trace/trace_pad.dart';
import 'ruled_paper.dart';

const _contentMaxWidth = 560.0;
const _completeDelay = Duration(milliseconds: 1200);
const _flashDuration = Duration(milliseconds: 1500);
const _flashCount = 3;
const _badgeSize = 32.0;
const _cardPadding = 12.0;

String _errorMessage(StrokeError error) => switch (error) {
      StrokeError.tooShort => 'Vẽ dài thêm chút nữa nhé',
      StrokeError.wrongDirection => 'Bé vẽ ngược chiều rồi',
      StrokeError.offPath => 'Đi theo đường chấm nhé',
      StrokeError.wrongOrder => 'Nét này vẽ sau nhé',
    };

/// Writing screen: the child traces [glyph] on ruled paper and Chíp Chíp
/// reacts to each graded stroke.
class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({
    required this.glyph,
    required this.onCompleted,
    this.step,
    this.totalSteps,
    super.key,
  });

  final Glyph glyph;

  /// Called once, 1.2 s after the last stroke, with the number of failed
  /// strokes in this attempt.
  final void Function(int failedStrokes) onCompleted;
  final int? step;
  final int? totalSteps;

  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen>
    with SingleTickerProviderStateMixin {
  /// The glyph in writing-window coordinates: guide, grading, hints and the
  /// ô li paper all use it (old glyphs without a ruling are unchanged).
  late final Glyph _glyph = widget.glyph.inWindow();
  late final GlyphSession _session = GlyphSession(_glyph);
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: _flashDuration,
  );
  final List<Stroke> _inked = [];
  Timer? _completeTimer;
  bool _completed = false;
  String _chip = AppImages.chipMain;
  late String _message = _opening;

  /// Faint reference letter (the "a" under a tone mark), in this glyph's
  /// window; null when there is none or it is still loading.
  List<Stroke>? _context;
  Glyph? _contextSource;

  /// First line; letters are named the way the teacher says them.
  String get _opening => widget.glyph.speech == null
      ? 'Bé tô nét số 1 nhé!'
      : 'Mình viết ${widget.glyph.spokenName} nhé! Bé tô nét số 1.';

  /// Watches the context glyph and maps it into this glyph's window. Called
  /// from [build] (not from a layout callback).
  List<Stroke>? _watchContext() {
    final id = widget.glyph.context;
    if (id == null) return null;
    final ctx = ref.watch(glyphProvider(id)).valueOrNull;
    if (ctx == null) return null;
    if (!identical(ctx, _contextSource)) {
      _contextSource = ctx;
      // Both glyphs share the 12-ô-li frame; place it in *this* window.
      _context = Glyph(
        id: ctx.id,
        label: ctx.label,
        strokes: ctx.strokes,
        ruling: widget.glyph.ruling ?? ctx.ruling,
      ).inWindow().strokes;
    }
    return _context;
  }

  /// Keeps Chíp's line (and its voice) across tablet rotations.
  final _chipKey = GlobalKey();

  @override
  void dispose() {
    _completeTimer?.cancel();
    _flash.dispose();
    super.dispose();
  }

  void _onStrokeEnd(Stroke drawn) {
    if (_completed || _session.isComplete) return;
    final index = _session.currentIndex;
    final result = _session.submit(drawn);
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final kidIdFuture = ref.read(currentKidIdProvider.future);
    unawaited(
      (() async {
        final kidId = await kidIdFuture;
        if (kidId == null) return;
        await db.logAttempt(
          kidId: kidId,
          glyphId: widget.glyph.id,
          strokeIndex: index,
          ok: result.ok,
          error: result.error?.name,
          deviation: result.deviation,
          drawn: drawn,
        );
      })()
          .catchError((Object e, StackTrace st) {
        debugPrint('logAttempt failed: $e\n$st');
        messenger.showSnackBar(
          const SnackBar(content: Text('Không lưu được kết quả')),
        );
      }),
    );
    setState(() {
      if (!result.ok) {
        _chip = AppImages.chipEncourage;
        _message = _errorMessage(result.error!);
        // Replay the model stroke so a child who cannot read the bubble
        // still sees what to trace.
        _flash.forward(from: 0);
        return;
      }
      _inked.add(drawn);
      _flash.reset();
      if (_session.isComplete) {
        _completed = true;
        _chip = AppImages.chipThumb;
        _message = 'Bé viết ${widget.glyph.spokenName} đẹp lắm!';
        final failed = _session.history.where((r) => !r.ok).length;
        _completeTimer =
            Timer(_completeDelay, () => widget.onCompleted(failed));
      } else {
        _chip = AppImages.chipJoy;
        _message = 'Giỏi quá! Giờ tô nét ${_session.currentIndex + 1} nhé.';
      }
    });
  }

  void _listen() {
    ref.read(speakerProvider).speak(_message);
  }

  void _showSample() {
    if (_completed) return;
    _flash.forward(from: 0);
  }

  void _clear() {
    if (_completed) return;
    _completeTimer?.cancel();
    _flash.reset();
    _session.reset();
    setState(() {
      _inked.clear();
      _chip = AppImages.chipMain;
      _message = _opening;
    });
  }

  @override
  Widget build(BuildContext context) {
    _watchContext();
    final formFactor = context.formFactor;
    if (formFactor != FormFactor.phone) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: TabletTextScale(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: formFactor == FormFactor.tabletLandscape
                        ? _landscape()
                        : _portrait(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
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
                    title: 'Viết ${widget.glyph.label}',
                    step: widget.step,
                    totalSteps: widget.totalSteps,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(child: _paperCard()),
                  const SizedBox(height: 8),
                  // Same key as the tablet layouts: switching between them
                  // (split view) keeps the state, so Chíp does not re-speak.
                  ChipSays(key: _chipKey, image: _chip, text: _message),
                  const SizedBox(height: 8),
                  _ActionRow(
                    onListen: _listen,
                    onSample: _showSample,
                    onClear: _clear,
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

  Widget _header() => SessionHeader(
        title: 'Viết ${widget.glyph.label}',
        step: widget.step,
        totalSteps: widget.totalSteps,
        onBack: () => Navigator.of(context).maybePop(),
      );

  /// Pad on the left as a square as tall as the space under the header;
  /// Chíp, the three actions and the stroke progress in a column on the right.
  Widget _landscape() {
    return LayoutBuilder(builder: (context, c) {
      const gap = 32.0;
      final column = (c.maxWidth * 0.3).clamp(300.0, 380.0);
      final side = math.min(c.maxHeight, c.maxWidth - column - gap);
      // Short landscape windows (small Android tablets) use phone-size
      // buttons so the column still fits.
      final button = c.maxHeight < 600 ? 64.0 : TabletSizes.kidTarget;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: side, height: side, child: _paperCard()),
          const SizedBox(width: gap),
          SizedBox(
            width: column,
            height: c.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // Chíp and the actions at the top, stroke progress at the
              // bottom; the card shrinks first when the column is short.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: ChipSays(
                          key: _chipKey,
                          image: _chip,
                          text: _message,
                          layout: _chipCard,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final (i, b) in _actions.indexed) ...[
                        if (i > 0) const SizedBox(height: 14),
                        _ActionButton(label: b.$1, onTap: b.$2, height: button),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _StrokeProgress(
                  done: _session.currentIndex,
                  total: _glyph.strokes.length,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// Pad centred; under it Chíp (160) with the line and the three actions.
  Widget _portrait() {
    return LayoutBuilder(builder: (context, c) {
      final size = MediaQuery.sizeOf(context);
      final pad = math.max(
        0.0,
        math.min(
          math.min(size.width - 96, size.height - 360),
          math.min(c.maxWidth, c.maxHeight - 200 - AppDepth.lip) -
              _cardPadding * 2,
        ),
      );
      return Column(
        children: [
          SizedBox(
            width: pad + _cardPadding * 2,
            // The card's bottom lip is a border, which pads the content.
            height: pad + _cardPadding * 2 + AppDepth.lip,
            child: _paperCard(),
          ),
          const SizedBox(height: 20),
          ChipSays(
            key: _chipKey,
            image: _chip,
            text: _message,
            layout: (context, image, text) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  image,
                  key: const ValueKey('writing-chip-image'),
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpeechBubble(text: text),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final (i, b) in _actions.indexed) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                label: b.$1,
                                onTap: b.$2,
                                height: TabletSizes.kidTarget,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  List<(String, VoidCallback)> get _actions => [
        ('Xem mẫu', _showSample),
        ('Nghe', _listen),
        ('Xóa', _clear),
      ];

  Widget _chipCard(BuildContext context, String image, String text) {
    return Container(
      key: const ValueKey('writing-chip-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: raisedDecoration(
        accent: Subject.viet.color,
        tint: Subject.viet.tint,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SizedBox(
              height: 240,
              child: Image.asset(
                image,
                key: const ValueKey('writing-chip-image'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.25,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paperCard() {
    final strokes = _glyph.strokes;
    final next = _session.isComplete ? null : strokes[_session.currentIndex];
    final contextStrokes = _context;
    // A dot stroke is its own start point: keep the badge off the dot.
    final badgeShift =
        next != null && next.points.length == 1 ? _badgeSize * 0.9 : 0.0;
    return AppCard(
      padding: const EdgeInsets.all(_cardPadding),
      child: LayoutBuilder(
        builder: (context, c) {
          final side = c.biggest.shortestSide;
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: Stack(
                children: [
                  Positioned.fill(child: RuledPaper(ruling: _glyph.ruling)),
                  if (contextStrokes != null)
                    Positioned.fill(
                      child: FaintLetter(
                        key: const ValueKey('glyph-context'),
                        strokes: contextStrokes,
                      ),
                    ),
                  if (next != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _flash,
                          builder: (_, __) => CustomPaint(
                            painter: _FlashPainter(next, _flash.value),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: TracePad(
                      crayon: true,
                      onStrokeEnd: _onStrokeEnd,
                      guide: strokes,
                      inked: List.of(_inked),
                    ),
                  ),
                  if (next != null && next.points.isNotEmpty)
                    Positioned(
                      left: next.points.first.x * side -
                          _badgeSize / 2 -
                          badgeShift,
                      top: next.points.first.y * side -
                          _badgeSize / 2 -
                          badgeShift,
                      child: IgnorePointer(
                        child: _NumberBadge(_session.currentIndex + 1),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _badgeSize,
      height: _badgeSize,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.text,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: AppColors.card,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onListen,
    required this.onSample,
    required this.onClear,
  });

  final VoidCallback onListen;
  final VoidCallback onSample;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionButton(label: 'Nghe', onTap: onListen)),
        const SizedBox(width: 10),
        Expanded(child: _ActionButton(label: 'Xem mẫu', onTap: onSample)),
        const SizedBox(width: 10),
        Expanded(child: _ActionButton(label: 'Xóa', onTap: onClear)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (pressed) => Container(
        height: height,
        alignment: Alignment.center,
        decoration: raisedDecoration(
          accent: Subject.viet.color,
          tint: Subject.viet.tint,
          radius: AppRadii.tile,
          pressed: pressed,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Nét 1/2" with one dot per stroke, filled for finished strokes.
class _StrokeProgress extends StatelessWidget {
  const _StrokeProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final current = math.min(done + 1, total);
    return Semantics(
      label: 'Nét $current/$total',
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            'Nét $current/$total',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 10),
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? AppColors.accent : AppColors.card,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Flashes the next stroke in orange: three pulses over the animation.
class _FlashPainter extends CustomPainter {
  _FlashPainter(this.stroke, this.t);

  final Stroke stroke;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1 || stroke.points.isEmpty) return;
    final side = size.shortestSide;
    final pulse = math.sin(t * _flashCount * math.pi).abs();
    final color = AppColors.accent.withOpacity(pulse);
    if (stroke.points.length == 1) {
      // A dot (the dot of "i", dấu nặng): pulse a filled circle.
      final p = stroke.points.single;
      canvas.drawCircle(
        Offset(p.x * side, p.y * side),
        side * 0.035,
        Paint()..color = color,
      );
      return;
    }
    final path = Path();
    for (var i = 0; i < stroke.points.length; i++) {
      final p = stroke.points[i];
      i == 0
          ? path.moveTo(p.x * side, p.y * side)
          : path.lineTo(p.x * side, p.y * side);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = side * 0.05,
    );
  }

  @override
  bool shouldRepaint(_FlashPainter old) => old.t != t || old.stroke != stroke;
}
