import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph.dart';
import '../../stroke/glyph_session.dart';
import '../../stroke/grader.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/info_pill.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../trace/trace_pad.dart';
import 'ruled_paper.dart';

const _contentMaxWidth = 560.0;
const _completeDelay = Duration(milliseconds: 1200);
const _flashDuration = Duration(milliseconds: 1500);
const _flashCount = 3;
const _badgeSize = 32.0;

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
  late final GlyphSession _session = GlyphSession(widget.glyph);
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: _flashDuration,
  );
  final List<Stroke> _inked = [];
  Timer? _completeTimer;
  bool _completed = false;
  String _chip = AppImages.chipMain;
  late String _message = 'Bé tô nét số 1 nhé!';

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
    unawaited(
      ref
          .read(databaseProvider)
          .logAttempt(
            glyphId: widget.glyph.id,
            strokeIndex: index,
            ok: result.ok,
            error: result.error?.name,
            deviation: result.deviation,
            drawn: drawn,
          )
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
        return;
      }
      _inked.add(drawn);
      _flash.reset();
      if (_session.isComplete) {
        _completed = true;
        _chip = AppImages.chipThumb;
        _message = 'Bé viết ${widget.glyph.label} đẹp lắm!';
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Giọng đọc sắp có')));
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
      _message = 'Bé tô nét số 1 nhé!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = ref.watch(homeSummaryProvider).valueOrNull?.totalStars ?? 0;
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
                  _Header(
                    title: 'Viết ${widget.glyph.label}',
                    step: widget.step,
                    totalSteps: widget.totalSteps,
                    stars: stars,
                  ),
                  Expanded(child: _paperCard()),
                  const SizedBox(height: 8),
                  _ChipRow(image: _chip, message: _message),
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

  Widget _paperCard() {
    final strokes = widget.glyph.strokes;
    final next = _session.isComplete ? null : strokes[_session.currentIndex];
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, c) {
          final side = c.biggest.shortestSide;
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: Stack(
                children: [
                  const Positioned.fill(child: RuledPaper()),
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
                      left: next.points.first.x * side - _badgeSize / 2,
                      top: next.points.first.y * side - _badgeSize / 2,
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.step,
    required this.totalSteps,
    required this.stars,
  });

  final String title;
  final int? step;
  final int? totalSteps;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final showProgress = step != null && totalSteps != null && totalSteps! > 0;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Semantics(
            label: 'Quay lại',
            button: true,
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => Navigator.of(context).maybePop(),
              radius: 32,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    boxShadow: [AppShadows.card],
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 36,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          if (showProgress) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: _ProgressBar(step: step!, total: totalSteps!),
            ),
          ],
          const SizedBox(width: 8),
          InfoPill(
            leading: Image.asset(
              AppImages.icStar,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            label: '$stars',
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$step/$total',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: SizedBox(
              width: 48,
              height: 8,
              child: LinearProgressIndicator(
                value: (step / total).clamp(0.0, 1.0),
                backgroundColor: AppColors.dot,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$step/$total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
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

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.image, required this.message});

  final String image;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(image, width: 88, height: 88, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SpeechBubble(text: message),
            ),
          ),
        ],
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
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          boxShadow: const [AppShadows.card],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.tile),
          onTap: onTap,
          child: Center(
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
        ),
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
    if (t <= 0 || t >= 1 || stroke.points.length < 2) return;
    final side = size.shortestSide;
    final path = Path();
    for (var i = 0; i < stroke.points.length; i++) {
      final p = stroke.points[i];
      i == 0
          ? path.moveTo(p.x * side, p.y * side)
          : path.lineTo(p.x * side, p.y * side);
    }
    final pulse = math.sin(t * _flashCount * math.pi).abs();
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent.withOpacity(pulse)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = side * 0.05,
    );
  }

  @override
  bool shouldRepaint(_FlashPainter old) => old.t != t || old.stroke != stroke;
}
