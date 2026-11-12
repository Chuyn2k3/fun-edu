import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning/lesson_item.dart';
import '../../learning/today_lesson_provider.dart';
import '../../math/math_level.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/primary_button.dart';
import '../math/math_session_screen.dart';
import '../writing/writing_screen.dart';

/// Runs today's lesson: a [WritingScreen] or [MathSessionScreen] per item,
/// then the done screen.
class LessonFlowScreen extends ConsumerStatefulWidget {
  const LessonFlowScreen({super.key});

  @override
  ConsumerState<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends ConsumerState<LessonFlowScreen> {
  // Frozen at first load: recording progress invalidates todayLessonProvider,
  // and the lesson in progress must not change under the child.
  List<LessonItem>? _items;
  int _index = 0;
  bool _busy = false;
  bool _loadFailed = false;
  // Set when saving a finished item failed; the finished screen is replaced
  // by a retry prompt that re-runs only the save, not the session.
  bool _saveFailed = false;
  Future<void> Function()? _pendingRecord;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    // Await the fresh value: after an invalidate the provider may still expose
    // the previous (stale) list while reloading.
    ref.read(todayLessonProvider.future).then((items) {
      if (mounted) setState(() => _items = items);
    }, onError: (Object e, StackTrace st) {
      debugPrint('today lesson failed: $e\n$st');
      if (mounted) setState(() => _loadFailed = true);
    });
  }

  void _home() => context.go('/');

  /// Records one finished item, then advances or finishes the lesson.
  Future<void> _completeItem(Future<void> Function() record) async {
    if (_busy) return;
    _busy = true;
    final repo = ref.read(progressRepositoryProvider);
    final items = _items!;
    try {
      // A retry must not record the item twice if only a later step failed.
      if (!_recorded) {
        await record();
        _recorded = true;
      }
      final last = _index == items.length - 1;
      if (!last) {
        ref.invalidate(homeSummaryProvider);
        ref.invalidate(todayLessonProvider);
        if (!mounted) return;
        setState(() {
          _index++;
          _saveFailed = false;
          _pendingRecord = null;
          _recorded = false;
        });
        return;
      }
      final stars = await repo.recordLessonCompleted(
        itemsCompleted: items.length,
      );
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(todayLessonProvider);
      if (!mounted) return;
      context.go('/lesson/done', extra: stars);
    } catch (e, st) {
      debugPrint('lesson progress failed: $e\n$st');
      if (mounted) {
        setState(() {
          _saveFailed = true;
          _pendingRecord = record;
        });
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _onGlyphCompleted(String id, int failedStrokes) =>
      _completeItem(() => ref
          .read(progressRepositoryProvider)
          .recordGlyphCompleted(id, failedStrokes: failedStrokes));

  Future<void> _onMathCompleted(int firstTryCorrect, int total) =>
      _completeItem(() async {
        await ref.read(levelRepositoryProvider).recordMathSession(
              firstTryCorrect: firstTryCorrect,
              total: total,
            );
        ref.invalidate(mathLevelIndexProvider);
      });

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _loadFailed
            ? _Message(onHome: _home, text: 'Chưa có bài nào')
            : const Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _Message(onHome: _home, text: 'Chưa có bài nào'),
      );
    }
    if (_saveFailed) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _Message(
          onHome: _home,
          text: 'Không lưu được kết quả',
          onRetry: () => _completeItem(_pendingRecord!),
        ),
      );
    }
    final item = items[_index];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: switch (item) {
        WritingItem(:final glyphId) => _writing(glyphId, items.length),
        MathItem(:final levelIndex) => MathSessionScreen(
            key: ValueKey('math-$_index'),
            level: mathLevels[levelIndex.clamp(0, mathLevels.length - 1)],
            step: _index + 1,
            totalSteps: items.length,
            onCompleted: _onMathCompleted,
          ),
      },
    );
  }

  Widget _writing(String id, int total) {
    final glyph = ref.watch(glyphProvider(id));
    return glyph.when(
      data: (g) => WritingScreen(
        key: ValueKey(id),
        glyph: g,
        step: _index + 1,
        totalSteps: total,
        onCompleted: (failed) => _onGlyphCompleted(id, failed),
      ),
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: _Message(onHome: _home, text: 'Chưa có bài nào'),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onHome, this.onRetry});

  final String text;
  final VoidCallback onHome;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              if (onRetry != null) ...[
                PrimaryButton(label: 'Thử lại', onPressed: onRetry),
                const SizedBox(height: 12),
              ],
              PrimaryButton(label: 'Về trang chính', onPressed: onHome),
            ],
          ),
        ),
      ),
    );
  }
}
