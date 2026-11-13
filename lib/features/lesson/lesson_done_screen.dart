import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../progress/progress_repository.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/app_card.dart';
import '../../ui/widgets/primary_button.dart';

const _contentMaxWidth = 560.0;
const _weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Weekdays (1 = Monday .. 7 = Sunday) learned in the current week.
final learnedWeekdaysProvider = FutureProvider.autoDispose<Set<int>>(
  (ref) async => (await ref.watch(progressRepositoryProvider.future))
      .learnedWeekdaysThisWeek(),
);

/// "Xong bài hôm nay!" celebration with this lesson's stars and the week.
class LessonDoneScreen extends ConsumerWidget {
  const LessonDoneScreen({this.starsEarned = 0, super.key});

  final int starsEarned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(learnedWeekdaysProvider).valueOrNull ?? const {};
    final level = ref.watch(homeSummaryProvider).valueOrNull?.level ?? 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppImages.bgSky,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 130,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withOpacity(0),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                        children: [
                          const _Title(),
                          const SizedBox(height: 14),
                          const _Hero(),
                          const SizedBox(height: 14),
                          _StatsCard(
                            stars: starsEarned,
                            days: days.length,
                            level: level,
                          ),
                          const SizedBox(height: 14),
                          _WeekCard(
                            learned: days,
                            today: DateTime.now().weekday,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Về trang chính',
                          onPressed: () => context.go('/'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Xong bài hôm nay!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Chíp Chíp tự hào về bé lắm',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    Widget star(double size) => Image.asset(
          AppImages.icStar,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
    return ExcludeSemantics(
      child: SizedBox(
        height: 190,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              star(36),
              const SizedBox(width: 8),
              Align(alignment: Alignment.topCenter, child: star(52)),
              const SizedBox(width: 4),
              Image.asset(
                AppImages.chipThumb,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 4),
              Align(alignment: Alignment.topCenter, child: star(52)),
              const SizedBox(width: 8),
              star(36),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.stars,
    required this.days,
    required this.level,
  });

  final int stars;
  final int days;
  final int level;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: AppImages.icStar,
              value: '+$stars',
              caption: 'sao',
            ),
          ),
          Expanded(
            child: _Stat(
              icon: AppImages.icFlame,
              value: '$days',
              caption: 'ngày học tuần này',
            ),
          ),
          Expanded(
            child: _Stat(
              icon: AppImages.icCrown,
              value: 'Cấp $level',
              caption: 'cấp độ',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.caption});

  final String icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Image.asset(icon, width: 40, height: 40, fit: BoxFit.contain),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.learned, required this.today});

  final Set<int> learned;
  final int today;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Tuần này của bé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _DayCell(
                    key: ValueKey('day-${i + 1}'),
                    label: _weekLabels[i],
                    learned: learned.contains(i + 1),
                    isToday: today == i + 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.learned,
    required this.isToday,
    super.key,
  });

  final String label;
  final bool learned;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isToday ? AppColors.accent : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: learned
                ? Image.asset(AppImages.icStar, fit: BoxFit.contain)
                : null,
          ),
        ),
      ],
    );
  }
}
