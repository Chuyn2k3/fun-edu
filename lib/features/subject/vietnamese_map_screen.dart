import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning/today_lesson_provider.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/layout/scale_down_to_fit.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';
import '../../vietnamese/vietnamese_level.dart';
import '../vietnamese/vietnamese_session_screen.dart';
import 'map_layout.dart';

const _contentMaxWidth = 560.0;

/// Tiếng Việt subject map: the 9 levels; done and current ones are tappable.
class VietnameseMapScreen extends ConsumerStatefulWidget {
  const VietnameseMapScreen({super.key});

  @override
  ConsumerState<VietnameseMapScreen> createState() =>
      _VietnameseMapScreenState();
}

class _VietnameseMapScreenState extends ConsumerState<VietnameseMapScreen> {
  bool _navigating = false;

  Future<void> _openPractice(int index) async {
    if (_navigating) return;
    _navigating = true;
    try {
      await context.push('/practice-vietnamese/$index');
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(vietnameseLevelIndexProvider);
    final current = level.valueOrNull ?? 0;
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
                          'Tiếng Việt',
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
                    child: tablet
                        ? LayoutBuilder(
                                builder: (context, c) {
                                  const pad =
                                      EdgeInsets.fromLTRB(16, 8, 16, 24);
                                  const gap = 16.0;
                                  const cols = 3;
                                  final rows =
                                      (vietnameseLevels.length / cols).ceil();
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: gap,
                                      crossAxisSpacing: gap,
                                      childAspectRatio:
                                          (tileW / tileH).clamp(0.5, 4.0),
                                    ),
                                    itemCount: vietnameseLevels.length,
                                    itemBuilder: (context, i) => _LevelTile(
                                      index: i,
                                      level: vietnameseLevels[i],
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
                                itemCount: vietnameseLevels.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) => _LevelTile(
                                  index: i,
                                  level: vietnameseLevels[i],
                                  current: current,
                                  tablet: false,
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
    required this.level,
    required this.current,
    required this.tablet,
    required this.onTap,
  });

  final int index;
  final VietnameseLevel level;
  final int current;
  final bool tablet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final locked = index > current;
    final accent = locked ? AppColors.textMuted : Subject.tiengViet.color;

    return Pressable(
      onTap: onTap,
      semanticsLabel: 'Cấp ${index + 1}: ${level.title}',
      builder: (pressed) {
        final deco = locked
            ? BoxDecoration(
                color: CollectionColors.lockedSurface,
                borderRadius: BorderRadius.circular(AppRadii.tile),
                border: Border.all(
                  color: CollectionColors.lockedBorder,
                  width: 1.5,
                ),
              )
            : raisedDecoration(
                accent: active ? AppColors.primary : accent,
                tint: active
                    ? Subject.viet.tint
                    : done
                        ? Subject.tiengViet.tint
                        : AppColors.card,
                radius: AppRadii.tile,
                pressed: pressed,
              );

          if (tablet) {
            return Container(
              decoration: deco,
              padding: const EdgeInsets.all(14),
              child: ScaleDownToFit(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : done
                                ? Subject.tiengViet.color
                                : AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: locked
                          ? const Icon(
                              Icons.lock_rounded,
                              size: 24,
                              color: AppColors.textMuted,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: active || done
                                    ? AppColors.card
                                    : AppColors.text,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      level.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active
                          ? 'Đang học'
                          : done
                              ? 'Đã xong'
                              : level.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: active
                            ? AppColors.primaryOnTint
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(minHeight: 76),
            decoration: deco,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : done
                            ? Subject.tiengViet.color
                            : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: active || done ? AppColors.card : AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active ? 'Đang học · ${level.subtitle}' : level.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppColors.primaryOnTint
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (done)
                  Icon(
                    Icons.check_circle_rounded,
                    key: ValueKey('vn-done-$index'),
                    size: 28,
                    color: Subject.tiengViet.color,
                  ),
                if (locked)
                  Icon(
                    Icons.lock_rounded,
                    key: ValueKey('vn-locked-$index'),
                    size: 26,
                    color: CollectionColors.lockedInk,
                  ),
              ],
            ),
          );
        },
      );
  }
}

/// Single-level Vietnamese practice: only the current level advances the kid.
class PracticeVietnameseScreen extends ConsumerStatefulWidget {
  const PracticeVietnameseScreen(this.levelIndex, {super.key});

  final int levelIndex;

  @override
  ConsumerState<PracticeVietnameseScreen> createState() =>
      _PracticeVietnameseScreenState();
}

class _PracticeVietnameseScreenState
    extends ConsumerState<PracticeVietnameseScreen> {
  bool _busy = false;

  Future<void> _onCompleted(int firstTryCorrect, int total) async {
    if (_busy) return;
    _busy = true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = await ref.read(levelRepositoryProvider.future);
      final current = await repo.levelOf('tieng-viet') ?? 0;
      if (widget.levelIndex == current) {
        await repo.recordVietnameseSession(
          firstTryCorrect: firstTryCorrect,
          total: total,
        );
        ref.invalidate(vietnameseLevelIndexProvider);
        ref.invalidate(homeSummaryProvider);
        ref.invalidate(todayLessonProvider);
      }
    } catch (e, st) {
      debugPrint('vietnamese practice progress failed: $e\n$st');
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
      context.go('/subject/tieng-viet');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.levelIndex < 0 ||
        widget.levelIndex >= vietnameseLevels.length) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Chưa có cấp này')),
      );
    }
    return VietnameseSessionScreen(
      level: vietnameseLevels[widget.levelIndex],
      onCompleted: _onCompleted,
    );
  }
}
