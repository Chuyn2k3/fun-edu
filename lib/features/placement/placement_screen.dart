import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning/today_lesson_provider.dart';
import '../../learning/writing_ladder.dart';
import '../../math/math_level.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/primary_button.dart';
import '../../voice/speaker.dart';
import '../math/math_session_screen.dart';
import '../writing/writing_screen.dart';

const _contentMaxWidth = 560.0;

/// Glyphs tried in order (ladder positions 0, 5 and 9).
const placementGlyphs = ['net-ngang', 'so-0', 'so-4'];

/// Math levels tried in order.
const placementMathLevels = [0, 2, 4, 6];

const _questionCount = 3;
const _maxFailedStrokes = 2;
const _minCorrect = 2;

typedef PlacementWritingBuilder = Widget Function(
  Glyph glyph,
  int step,
  int totalSteps,
  void Function(int failedStrokes) onDone,
);

typedef PlacementMathBuilder = Widget Function(
  MathLevel level,
  int step,
  int totalSteps,
  void Function(int firstTryCorrect, int total) onDone,
);

Widget _defaultWriting(
  Glyph glyph,
  int step,
  int totalSteps,
  void Function(int) onDone,
) =>
    WritingScreen(
      key: ValueKey('placement-${glyph.id}'),
      glyph: glyph,
      step: step,
      totalSteps: totalSteps,
      onCompleted: onDone,
    );

Widget _defaultMath(
  MathLevel level,
  int step,
  int totalSteps,
  void Function(int, int) onDone,
) =>
    MathSessionScreen(
      key: ValueKey('placement-${level.id}'),
      level: level,
      step: step,
      totalSteps: totalSteps,
      questionCount: _questionCount,
      onCompleted: onDone,
    );

enum _Phase { welcome, writing, math, finish }

/// First-launch placement: a short writing and math try-out that picks the
/// starting level of both subjects. Nothing is stored until the very end.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({
    this.writingBuilder = _defaultWriting,
    this.mathBuilder = _defaultMath,
    super.key,
  });

  /// Seams so tests can drive the flow without tracing or answering.
  final PlacementWritingBuilder writingBuilder;
  final PlacementMathBuilder mathBuilder;

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  _Phase _phase = _Phase.welcome;
  int _step = 0;
  int _writingStart = 0;
  int _mathStart = 0;
  bool _saving = false;
  bool _saved = false;

  void _reset() => setState(() {
        _phase = _Phase.welcome;
        _step = 0;
        _writingStart = 0;
        _mathStart = 0;
      });

  void _start() => setState(() {
        _phase = _Phase.writing;
        _step = 0;
      });

  void _onGlyphDone(int failedStrokes) {
    if (_phase != _Phase.writing) return;
    if (failedStrokes > _maxFailedStrokes) return _startMath();
    _writingStart = writingLadder.indexOf(placementGlyphs[_step]);
    if (_step + 1 < placementGlyphs.length) {
      setState(() => _step++);
    } else {
      _startMath();
    }
  }

  void _startMath() => setState(() {
        _phase = _Phase.math;
        _step = 0;
      });

  void _onMathDone(int firstTryCorrect, int total) {
    if (_phase != _Phase.math) return;
    if (firstTryCorrect < _minCorrect) return _finish();
    _mathStart = placementMathLevels[_step];
    if (_step + 1 < placementMathLevels.length) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _finish() {
    setState(() => _phase = _Phase.finish);
    _save();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(levelRepositoryProvider);
      await repo.setLevel('viet', _writingStart);
      await repo.setLevel('toan', _mathStart);
      ref.invalidate(isPlacedProvider);
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(todayLessonProvider);
      ref.invalidate(mathLevelIndexProvider);
      if (mounted) setState(() => _saved = true);
    } catch (e, st) {
      debugPrint('placement save failed: $e\n$st');
      messenger.showSnackBar(
        const SnackBar(content: Text('Không lưu được kết quả')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (_phase) {
      _Phase.welcome => _Message(
          key: const ValueKey('welcome'),
          chip: AppImages.chipMain,
          title: 'Chào bé! Mình là Chíp Chíp',
          subtitle: 'Mình chơi thử một chút nhé!',
          button: PrimaryButton(label: 'Bắt đầu', onPressed: _start),
        ),
      _Phase.writing => _writing(),
      _Phase.math => widget.mathBuilder(
          mathLevels[placementMathLevels[_step]],
          _step + 1,
          placementMathLevels.length,
          _onMathDone,
        ),
      _Phase.finish => _Message(
          key: const ValueKey('finish'),
          chip: AppImages.chipThumb,
          title: 'Xong rồi! Mình cùng học nhé!',
          button: _saved
              ? PrimaryButton(
                  label: 'Vào học',
                  onPressed: () => context.go('/'),
                )
              : PrimaryButton(
                  label: 'Thử lại',
                  onPressed: _saving ? null : _save,
                ),
        ),
    };
    // Back during the try-out starts over; nothing was stored yet.
    return PopScope(
      canPop: _phase == _Phase.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _phase != _Phase.finish) _reset();
      },
      child: child,
    );
  }

  Widget _writing() {
    final id = placementGlyphs[_step];
    final glyph = ref.watch(glyphProvider(id));
    return glyph.when(
      data: (g) => widget.writingBuilder(
        g,
        _step + 1,
        placementGlyphs.length,
        _onGlyphDone,
      ),
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      // A missing glyph must not trap the child: skip to the math step.
      error: (_, __) => _Message(
        chip: AppImages.chipMain,
        title: 'Mình sang phần Toán nhé!',
        button: PrimaryButton(label: 'Tiếp tục', onPressed: _startMath),
      ),
    );
  }
}

class _Message extends ConsumerStatefulWidget {
  const _Message({
    required this.chip,
    required this.title,
    required this.button,
    this.subtitle,
    super.key,
  });

  final String chip;
  final String title;
  final String? subtitle;
  final Widget button;

  @override
  ConsumerState<_Message> createState() => _MessageState();
}

class _MessageState extends ConsumerState<_Message> {
  late final Speaker _speaker;

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(speakerProvider);
    _speaker.speak(widget.title);
  }

  @override
  void didUpdateWidget(_Message old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title) _speaker.speak(widget.title);
  }

  @override
  void dispose() {
    // Assumes in-place swaps keep the new line; a route replacement would
    // clip it (old element unmounts after the new one speaks).
    _speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chip = widget.chip;
    final title = widget.title;
    final subtitle = widget.subtitle;
    final button = widget.button;
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight - 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExcludeSemantics(
                          child: Image.asset(chip,
                              width: 200, height: 200, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        button,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
