import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning/today_lesson_provider.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/primary_button.dart';
import '../writing/writing_screen.dart';

/// Runs today's lesson: one [WritingScreen] per glyph, then the done screen.
class LessonFlowScreen extends ConsumerStatefulWidget {
  const LessonFlowScreen({super.key});

  @override
  ConsumerState<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends ConsumerState<LessonFlowScreen> {
  // Frozen at first load: recording progress invalidates todayLessonProvider,
  // and the lesson in progress must not change under the child.
  List<String>? _ids;
  int _index = 0;
  bool _busy = false;

  void _home() => context.go('/');

  Future<void> _onGlyphCompleted(String id, int failedStrokes) async {
    if (_busy) return;
    _busy = true;
    final repo = ref.read(progressRepositoryProvider);
    final ids = _ids!;
    try {
      await repo.recordGlyphCompleted(id, failedStrokes: failedStrokes);
      final last = _index == ids.length - 1;
      if (!last) {
        ref.invalidate(homeSummaryProvider);
        ref.invalidate(todayLessonProvider);
        if (!mounted) return;
        setState(() => _index++);
        return;
      }
      final stars = await repo.recordLessonCompleted(
        glyphsCompleted: ids.length,
      );
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(todayLessonProvider);
      if (!mounted) return;
      context.go('/lesson/done', extra: stars);
    } catch (e, st) {
      debugPrint('lesson progress failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lưu được kết quả')),
        );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(todayLessonProvider);
    _ids ??= lesson.valueOrNull;
    final ids = _ids;
    if (ids == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: lesson.hasError
            ? _Message(onHome: _home, text: 'Chưa có bài nào')
            : const Center(child: CircularProgressIndicator()),
      );
    }
    if (ids.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _Message(onHome: _home, text: 'Chưa có bài nào'),
      );
    }
    final id = ids[_index];
    final glyph = ref.watch(glyphProvider(id));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: glyph.when(
        data: (g) => WritingScreen(
          key: ValueKey(id),
          glyph: g,
          step: _index + 1,
          totalSteps: ids.length,
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
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onHome});

  final String text;
  final VoidCallback onHome;

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
              PrimaryButton(label: 'Về trang chính', onPressed: onHome),
            ],
          ),
        ),
      ),
    );
  }
}
