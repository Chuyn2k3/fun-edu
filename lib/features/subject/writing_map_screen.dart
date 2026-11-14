import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning/today_lesson_provider.dart';
import '../../learning/writing_ladder.dart';
import '../../learning/writing_sections.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../writing/writing_screen.dart';
import 'map_layout.dart';

const _contentMaxWidth = 560.0;

/// Per-glyph stats for the writing map; invalidated after each practice.
final writingStatsProvider = FutureProvider.autoDispose<Map<String, GlyphStat>>(
  (ref) async =>
      (await ref.watch(progressRepositoryProvider.future)).glyphStats(),
);

/// Viết subject map: a grid of the writing ladder, tap a glyph to practice.
class WritingMapScreen extends ConsumerStatefulWidget {
  const WritingMapScreen({super.key});

  @override
  ConsumerState<WritingMapScreen> createState() => _WritingMapScreenState();
}

class _WritingMapScreenState extends ConsumerState<WritingMapScreen> {
  // True while a practice route is pushed; ignores further taps (double-tap).
  bool _navigating = false;

  Future<void> _openPractice(String id) async {
    if (_navigating) return;
    _navigating = true;
    try {
      await context.push('/practice/$id');
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(writingStatsProvider).valueOrNull ?? const {};
    final available =
        ref.watch(glyphListProvider).valueOrNull ?? const <Glyph>[];
    final byId = {for (final g in available) g.id: g};
    final ids = [
      for (final id in writingLadder)
        if (byId.containsKey(id)) id,
    ];
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
                          'Viết',
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in groupLadder(ids).entries) ...[
                            _SectionHeading(entry.key.title, tablet: tablet),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: mapColumnsFor(
                                  context.formFactor,
                                  phoneColumns: 3,
                                ),
                                mainAxisSpacing: tablet ? 16 : 12,
                                crossAxisSpacing: tablet ? 16 : 12,
                                childAspectRatio: tablet ? 1.0 : 1.1,
                              ),
                              itemCount: entry.value.length,
                              itemBuilder: (context, i) {
                                final id = entry.value[i];
                                return _GlyphTile(
                                  tablet: tablet,
                                  label: byId[id]!.label,
                                  mastered: stats[id]?.mastered ?? false,
                                  onTap: () => _openPractice(id),
                                );
                              },
                            ),
                          ],
                        ],
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {required this.tablet});

  final String title;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.only(top: tablet ? 20 : 16, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: tablet ? 24 : 20,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _GlyphTile extends StatelessWidget {
  const _GlyphTile({
    required this.label,
    required this.mastered,
    required this.onTap,
    this.tablet = false,
  });

  final bool tablet;
  final String label;
  final bool mastered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (pressed) => Container(
        decoration: raisedDecoration(
          accent: Subject.viet.color,
          tint: Subject.viet.tint,
          radius: AppRadii.tile,
          pressed: pressed,
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: tablet ? 22 : 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
            ),
            if (mastered)
              Positioned(
                top: 6,
                right: 8,
                child: Icon(
                  Icons.check_circle_rounded,
                  key: const ValueKey('mastered'),
                  size: tablet ? 32 : 24,
                  color: Subject.viet.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Single-glyph practice: records the glyph only (no lesson stars).
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen(this.glyphId, {super.key});

  final String glyphId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glyph = ref.watch(glyphProvider(glyphId));
    return glyph.when(
      data: (g) => WritingScreen(
        glyph: g,
        onCompleted: (failed) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            final repo = await ref.read(progressRepositoryProvider.future);
            await repo.recordGlyphCompleted(g.id, failedStrokes: failed);
            ref.invalidate(homeSummaryProvider);
            ref.invalidate(todayLessonProvider);
            ref.invalidate(writingStatsProvider);
          } catch (e, st) {
            debugPrint('practice progress failed: $e\n$st');
            messenger.showSnackBar(
              const SnackBar(content: Text('Không lưu được kết quả')),
            );
          }
          if (!context.mounted) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/subject/viet');
          }
        },
      ),
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Chưa có chữ này')),
      ),
    );
  }
}
