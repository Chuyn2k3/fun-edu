import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../explore/explore_island.dart';
import '../../explore/geography_level.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/layout/scale_down_to_fit.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';
import '../explore/geography_session_screen.dart';
import 'map_layout.dart';

const _contentMaxWidth = 560.0;

/// An explore island's map: its levels; done and current
/// ones are tappable.
class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen(this.island, {super.key});

  final ExploreIsland island;

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

/// The geography island's map.
class GeographyMapScreen extends ExploreMapScreen {
  const GeographyMapScreen({super.key}) : super(geographyIsland);
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  bool _navigating = false;

  Future<void> _openPractice(int index) async {
    if (_navigating) return;
    _navigating = true;
    try {
      await context.push('/practice-${widget.island.id}/$index');
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(exploreLevelIndexProvider(widget.island.id));
    final levels = widget.island.levels;
    final subject = widget.island.subject;
    // Null until loaded: tiles show neutral (no lock, no tick, no tap)
    // rather than claiming level 1 is current.
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
                            onTap: () => context.canPop()
                                ? context.pop()
                                : context.go('/kham-pha'),
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
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.island.mapTitle,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                      (levels.length / cols).ceil();
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
                                    itemCount: levels.length,
                                    itemBuilder: (context, i) => _LevelTile(
                                      key: ValueKey('geo-level-$i'),
                                      subject: subject,
                                      index: i,
                                      level: levels[i],
                                      current: current,
                                      tablet: true,
                                      onTap: current != null && i <= current
                                          ? () => _openPractice(i)
                                          : null,
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: levels.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) => _LevelTile(
                                      key: ValueKey('geo-level-$i'),
                                      subject: subject,
                                  index: i,
                                  level: levels[i],
                                  current: current,
                                  tablet: false,
                                  onTap: current != null && i <= current
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
    super.key,
    required this.subject,
    required this.index,
    required this.level,
    required this.current,
    required this.tablet,
    required this.onTap,
  });

  final int index;
  final GeographyLevel level;
  final Subject subject;
  /// The kid's level; null while it is still loading.
  final int? current;
  final bool tablet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = current != null && index < current!;
    final active = index == current;
    final locked = current != null && index > current!;
    final accent = locked ? AppColors.textMuted : subject.color;

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
                        ? subject.tint
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
                                ? subject.color
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
                            ? subject.color
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
                    key: ValueKey('geo-done-$index'),
                    size: 28,
                    color: subject.color,
                  ),
                if (locked)
                  Icon(
                    Icons.lock_rounded,
                    key: ValueKey('geo-locked-$index'),
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

/// Single-level practice of an island: only the current level moves the
/// kid's level.
class PracticeExploreScreen extends ConsumerStatefulWidget {
  const PracticeExploreScreen(this.island, this.levelIndex,
      {this.random, super.key});

  final ExploreIsland island;
  final int levelIndex;

  /// Fixed question order for tests.
  final Random? random;

  @override
  ConsumerState<PracticeExploreScreen> createState() =>
      _PracticeExploreScreenState();
}

/// Geography practice (kept for the existing route and tests).
class PracticeGeographyScreen extends PracticeExploreScreen {
  const PracticeGeographyScreen(int levelIndex, {super.random, super.key})
      : super(geographyIsland, levelIndex);
}

class _PracticeExploreScreenState
    extends ConsumerState<PracticeExploreScreen> {
  bool _busy = false;

  Future<void> _onCompleted(int firstTryCorrect, int total) async {
    if (_busy) return;
    _busy = true;
    final island = widget.island;
    try {
      final repo = await ref.read(levelRepositoryProvider.future);
      final current = (await repo.levelOf(island.id) ?? 0)
          .clamp(0, island.levels.length - 1);
      if (widget.levelIndex == current) {
        await repo.recordExploreSession(
          island,
          firstTryCorrect: firstTryCorrect,
          total: total,
        );
        ref.invalidate(exploreLevelIndexProvider(island.id));
        ref.invalidate(homeSummaryProvider);
      }
    } catch (e, st) {
      debugPrint('${island.id} practice progress failed: $e\n$st');
      if (mounted) {
        showAppToast(context, 'Không lưu được kết quả',
            kind: AppToastKind.warning);
      }
    } finally {
      _busy = false;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/subject/${island.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.island.levels;
    if (widget.levelIndex < 0 || widget.levelIndex >= levels.length) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Chưa có cấp này')),
      );
    }
    return ExploreSessionScreen(
      island: widget.island,
      level: levels[widget.levelIndex],
      random: widget.random,
      onCompleted: _onCompleted,
    );
  }
}
