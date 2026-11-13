import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../learning/writing_ladder.dart';
import '../../math/math_level.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../screen_time/screen_time_service.dart';
import '../../stroke/glyph.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/theme/tokens.dart';

enum GlyphState { mastered, practicing, notStarted }

GlyphState glyphStateOf(GlyphStat? s) {
  if (s == null || s.completions <= 0) return GlyphState.notStarted;
  return s.mastered ? GlyphState.mastered : GlyphState.practicing;
}

/// Glyph id with the largest `completions - cleanCompletions` (> 0); ties go
/// to the earliest in the ladder. Null when no glyph has mistakes.
String? hardestGlyphId(Map<String, GlyphStat> stats) {
  String? best;
  var bestGap = 0;
  for (final id in writingLadder) {
    final s = stats[id];
    if (s == null) continue;
    final gap = s.completions - s.cleanCompletions;
    if (gap > bestGap) {
      best = id;
      bestGap = gap;
    }
  }
  return best;
}

class ProgressData {
  const ProgressData({
    required this.usedMinutes,
    required this.limitMinutes,
    required this.learnedDays,
    required this.stars,
    required this.stats,
    required this.mathLevel,
  });

  final int usedMinutes;
  final int limitMinutes;
  final int learnedDays;
  final int stars;
  final Map<String, GlyphStat> stats;
  final int? mathLevel;
}

/// Progress of any kid, built straight from the database so it never
/// depends on (or changes) the kid currently playing.
final progressDataProvider =
    FutureProvider.autoDispose.family<ProgressData, int>((ref, kidId) async {
  final db = ref.watch(databaseProvider);
  final progress = ProgressRepository(db, kidId: kidId);
  final screenTime = ref.watch(screenTimeServiceProvider);
  return ProgressData(
    usedMinutes: (await screenTime.usedToday(kidId)).inMinutes,
    limitMinutes: await screenTime.dailyLimitMinutes(kidId),
    learnedDays: (await progress.learnedWeekdaysThisWeek()).length,
    stars: await progress.totalStars(),
    stats: await progress.glyphStats(),
    mathLevel: await LevelRepository(db, kidId: kidId).levelOf('toan'),
  );
});

/// Progress tab of the parent corner for [kidId].
class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key, required this.kidId});

  final int kidId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(progressDataProvider(kidId));
    final d = data.valueOrNull;
    if (d == null) {
      return data.hasError
          ? const Center(child: Text('Không tải được tiến bộ'))
          : const Center(child: CircularProgressIndicator());
    }
    final labels = <String, String>{
      for (final g
          in ref.watch(glyphListProvider).valueOrNull ?? const <Glyph>[])
        g.id: g.label,
    };
    final hardest = hardestGlyphId(d.stats);
    // A handful of cards: no need for a lazy list.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TodayCard(d),
          const SizedBox(height: 12),
          _WeekCard(d),
          const SizedBox(height: 12),
          _WritingCard(
            stats: d.stats,
            labels: labels,
            hardestLabel: hardest == null ? null : (labels[hardest] ?? hardest),
          ),
          const SizedBox(height: 12),
          _MathCard(d.mathLevel),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

const _bodyStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: AppColors.text,
);

class _TodayCard extends StatelessWidget {
  const _TodayCard(this.d);

  final ProgressData d;

  @override
  Widget build(BuildContext context) {
    final ratio = d.limitMinutes <= 0
        ? 0.0
        : (d.usedMinutes / d.limitMinutes).clamp(0.0, 1.0);
    return _Card(
      title: 'Hôm nay',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${d.usedMinutes} / ${d.limitMinutes} phút', style: _bodyStyle),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: Subject.viet.tint,
              color: Subject.viet.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard(this.d);

  final ProgressData d;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Tuần này',
      child: Wrap(
        spacing: 24,
        runSpacing: 6,
        children: [
          Text('${d.learnedDays} ngày học', style: _bodyStyle),
          Text('${d.stars} sao', style: _bodyStyle),
        ],
      ),
    );
  }
}

class _WritingCard extends StatelessWidget {
  const _WritingCard({
    required this.stats,
    required this.labels,
    required this.hardestLabel,
  });

  final Map<String, GlyphStat> stats;
  final Map<String, String> labels;
  final String? hardestLabel;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Tập viết',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in writingLadder)
                _GlyphTile(
                  label: labels[id] ?? id,
                  state: glyphStateOf(stats[id]),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Legend(GlyphState.mastered, 'Viết đúng nét'),
              _Legend(GlyphState.practicing, 'Đang tập'),
              _Legend(GlyphState.notStarted, 'Chưa học'),
            ],
          ),
          if (hardestLabel != null) ...[
            const SizedBox(height: 14),
            Text(
              'Chữ $hardestLabel bé còn hay sai, cho bé tập thêm nhé.',
              style: _bodyStyle,
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _decorationOf(GlyphState s) {
  switch (s) {
    case GlyphState.mastered:
      return BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      );
    case GlyphState.practicing:
      return BoxDecoration(
        color: Subject.viet.tint,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      );
    case GlyphState.notStarted:
      return BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.textMuted, width: 1.5),
      );
  }
}

class _GlyphTile extends StatelessWidget {
  const _GlyphTile({required this.label, required this.state});

  final String label;
  final GlyphState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decorationOf(state),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: state == GlyphState.mastered ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.state, this.text);

  final GlyphState state;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: _decorationOf(state),
          child: const SizedBox(width: 20, height: 20),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: AppColors.text)),
      ],
    );
  }
}

class _MathCard extends StatelessWidget {
  const _MathCard(this.level);

  final int? level;

  @override
  Widget build(BuildContext context) {
    final l = level;
    return _Card(
      title: 'Toán',
      child: l == null
          ? const Text('Chưa xếp cấp', style: _bodyStyle)
          : Row(
              children: [
                Expanded(
                  child: Text(
                    'Đang học: ${mathLevels[l.clamp(0, mathLevels.length - 1)].title}',
                    style: _bodyStyle,
                  ),
                ),
                Text('${l + 1}/${mathLevels.length}', style: _bodyStyle),
              ],
            ),
    );
  }
}
