import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning/today_lesson_provider.dart';
import '../../math/math_level.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../math/math_session_screen.dart';
import 'map_layout.dart';

const _contentMaxWidth = 560.0;

/// Toán subject map: the 9 math levels; done and current ones are tappable.
class MathMapScreen extends ConsumerStatefulWidget {
  const MathMapScreen({super.key});

  @override
  ConsumerState<MathMapScreen> createState() => _MathMapScreenState();
}

class _MathMapScreenState extends ConsumerState<MathMapScreen> {
  // True while a practice route is pushed; ignores further taps (double-tap).
  bool _navigating = false;

  Future<void> _openPractice(int index) async {
    if (_navigating) return;
    _navigating = true;
    try {
      await context.push('/practice-math/$index');
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(mathLevelIndexProvider);
    final current = level.valueOrNull;
    final tablet = context.isTablet;
    final body = Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tablet ? tabletMapMaxWidth : _contentMaxWidth,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: tablet ? 96 : 72,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Semantics(
                          label: 'Quay lại',
                          button: true,
                          excludeSemantics: true,
                          child: InkResponse(
                            onTap: () => context.go('/'),
                            radius: 32,
                            child: Container(
                              width: tablet ? TabletSizes.kidTarget : 64,
                              height: tablet ? TabletSizes.kidTarget : 64,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: tablet ? 64 : 48,
                                height: tablet ? 64 : 48,
                                decoration:
                                    raisedDecoration(radius: tablet ? 32 : 24),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: tablet ? 44 : 36,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Toán',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: current == null
                        ? const Center(child: CircularProgressIndicator())
                        : tablet
                            ? LayoutBuilder(
                                // 3x3 in both orientations; tile height comes
                                // from the free height so nine levels fill the
                                // screen without scrolling.
                                builder: (context, c) {
                                  const pad =
                                      EdgeInsets.fromLTRB(16, 8, 16, 24);
                                  const gap = 16.0;
                                  const cols = 3;
                                  final rows =
                                      (mathLevels.length / cols).ceil();
                                  final tileW = (c.maxWidth -
                                          pad.horizontal -
                                          gap * (cols - 1)) /
                                      cols;
                                  final tileH = (c.maxHeight -
                                          pad.vertical -
                                          gap * (rows - 1)) /
                                      rows;
                                  return GridView.builder(
                                    padding: pad,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: gap,
                                      crossAxisSpacing: gap,
                                      childAspectRatio:
                                          tileW / tileH.clamp(120.0, 400.0),
                                    ),
                                    itemCount: mathLevels.length,
                                    itemBuilder: (context, i) => _LevelTile(
                                      index: i,
                                      title: mathLevels[i].title,
                                      current: current,
                                      tablet: true,
                                      onTap: i <= current
                                          ? () => _openPractice(i)
                                          : null,
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: mathLevels.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) => _LevelTile(
                                  index: i,
                                  title: mathLevels[i].title,
                                  current: current,
                                  onTap: i <= current
                                      ? () => _openPractice(i)
                                      : null,
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return tablet ? TabletTextScale(child: body) : body;
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.index,
    required this.title,
    required this.current,
    required this.onTap,
    this.tablet = false,
  });

  /// Tablet grid cell: a square card with the content stacked.
  final bool tablet;

  final int index;
  final String title;
  final int current;
  final VoidCallback? onTap;

  Widget _tabletContent({
    required bool done,
    required bool isCurrent,
    required bool locked,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                if (isCurrent)
                  const Text(
                    'Đang học',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (done)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.check_circle_rounded,
                key: ValueKey('done-$index'),
                size: 32,
                color: Subject.toan.color,
              ),
            ),
          if (locked)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.lock_rounded,
                key: ValueKey('locked-$index'),
                size: 30,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final isCurrent = index == current;
    final locked = index > current;
    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Pressable(
        onTap: onTap,
        builder: (pressed) {
          final raised = raisedDecoration(
            accent: Subject.toan.color,
            tint: Subject.toan.tint,
            radius: AppRadii.tile,
            pressed: pressed,
          );
          return Container(
            // The current lesson gets a solid orange lip.
            decoration: isCurrent
                ? raised.copyWith(
                    border: Border(
                      bottom: BorderSide(
                        width: pressed ? AppDepth.pressedLip : AppDepth.lip,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : raised,
            child: tablet
                ? _tabletContent(
                    done: done, isCurrent: isCurrent, locked: locked)
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 72),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                  ),
                                ),
                                if (isCurrent)
                                  const Text(
                                    'Đang học',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (done)
                            Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('done-$index'),
                              size: 28,
                              color: Subject.toan.color,
                            ),
                          if (locked)
                            Icon(
                              Icons.lock_rounded,
                              key: ValueKey('locked-$index'),
                              size: 26,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Single-level practice: only the current level moves the child's level.
class PracticeMathScreen extends ConsumerStatefulWidget {
  const PracticeMathScreen(this.levelIndex, {super.key});

  final int levelIndex;

  @override
  ConsumerState<PracticeMathScreen> createState() => _PracticeMathScreenState();
}

class _PracticeMathScreenState extends ConsumerState<PracticeMathScreen> {
  bool _busy = false;

  Future<void> _onCompleted(int firstTryCorrect, int total) async {
    if (_busy) return;
    _busy = true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = await ref.read(levelRepositoryProvider.future);
      final current = await repo.levelOf('toan') ?? 0;
      if (widget.levelIndex == current) {
        await repo.recordMathSession(
          firstTryCorrect: firstTryCorrect,
          total: total,
        );
        ref.invalidate(mathLevelIndexProvider);
        ref.invalidate(homeSummaryProvider);
        ref.invalidate(todayLessonProvider);
      }
    } catch (e, st) {
      debugPrint('math practice progress failed: $e\n$st');
      messenger.showSnackBar(
        const SnackBar(content: Text('Không lưu được kết quả')),
      );
    } finally {
      _busy = false;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/subject/toan');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.levelIndex < 0 || widget.levelIndex >= mathLevels.length) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Chưa có cấp này')),
      );
    }
    return MathSessionScreen(
      level: mathLevels[widget.levelIndex],
      onCompleted: _onCompleted,
    );
  }
}
