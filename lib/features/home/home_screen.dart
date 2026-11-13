import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning/lesson_item.dart';
import '../../learning/today_lesson_provider.dart';
import '../../learning/writing_ladder.dart';
import '../../data/app_database.dart';
import '../../math/math_level.dart';
import '../../parent/parent_gate_route.dart';
import '../../profile/kid_repository.dart';
import '../../progress/progress_repository.dart';
import '../../rewards/reward_repository.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/assets.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/floating_nav_bar.dart';
import '../../ui/widgets/info_pill.dart';
import '../../ui/widgets/speech_bubble.dart';
import 'kid_switcher.dart';
import '../../ui/widgets/subject_card.dart';

const _contentMaxWidth = 560.0;

const _navItems = [
  NavItem(icon: Icons.home_rounded, label: 'Học'),
  NavItem(icon: Icons.sports_esports_rounded, label: 'Chơi'),
  NavItem(icon: Icons.collections_bookmark_rounded, label: 'Sưu tập'),
  NavItem(icon: Icons.cottage_rounded, label: 'Nhà Chíp'),
];

/// Home screen: greeting, today's lesson, streak and the subject grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);
    final lessonAsync = ref.watch(todayLessonProvider);
    // Spinner only before the first value; reloads keep showing the old one.
    final loading = !summaryAsync.hasValue && summaryAsync.isLoading ||
        !lessonAsync.hasValue && lessonAsync.isLoading;

    // On error fall back to zeros rather than crashing.
    final summary = summaryAsync.valueOrNull ??
        const HomeSummary(
          totalStars: 0,
          learnedDaysThisWeek: 0,
          masteredWriting: 0,
        );
    final lesson = lessonAsync.valueOrNull ?? const <LessonItem>[];
    final firstWriting = lesson.whereType<WritingItem>().firstOrNull;
    final firstLabel = firstWriting == null
        ? null
        : ref.watch(glyphProvider(firstWriting.glyphId)).valueOrNull?.label;

    final kids = ref.watch(kidsProvider).valueOrNull ?? const <KidProfile>[];
    final currentId = ref.watch(currentKidIdProvider).valueOrNull;
    final kid = kids.where((k) => k.id == currentId).firstOrNull;

    return Scaffold(
      body: DottedBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : _HomeBody(
                kid: kid,
                summary: summary,
                lessonTotal: lesson.length,
                firstLabel: firstLabel,
                reward: ref.watch(pendingRewardProvider).valueOrNull,
              ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.kid,
    required this.summary,
    required this.lessonTotal,
    required this.firstLabel,
    required this.reward,
  });

  final PendingReward? reward;
  final KidProfile? kid;
  final HomeSummary summary;
  final int lessonTotal;
  final String? firstLabel;

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openParents(BuildContext context) async {
    final passed = await showParentGate(context);
    if (passed && context.mounted) context.push('/parent');
  }

  @override
  Widget build(BuildContext context) {
    final bubbleText = firstLabel == null
        ? 'Hôm nay mình làm Toán nhé!'
        : 'Hôm nay mình viết $firstLabel và làm Toán nhé!';

    return Stack(
      children: [
        // Sky image fading into the cream background.
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
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
                children: [
                  _TopRow(
                    kid: kid,
                    level: summary.level,
                    stars: summary.totalStars,
                    onParents: () => _openParents(context),
                    onSwitchKid: () => showKidSwitcher(context),
                  ),
                  const SizedBox(height: 16),
                  _ChipBlock(
                    bubbleText: bubbleText,
                    total: lessonTotal,
                    doneToday: summary.lessonsToday,
                    onStart: () => context.push('/lesson'),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: InfoPill(
                        leading: Image.asset(AppImages.icFlame,
                            width: 26, height: 26, fit: BoxFit.contain),
                        label:
                            '${summary.learnedDaysThisWeek} ngày học tuần này',
                      ),
                    ),
                  ),
                  if (reward != null) ...[
                    const SizedBox(height: 12),
                    _RewardPill(reward: reward!),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Hôm nay học gì?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SubjectGrid(
                    masteredWriting: summary.masteredWriting,
                    mathLevelIndex: summary.mathLevelIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: FloatingNavBar(
                  items: _navItems,
                  selected: 0,
                  onSelect: (i) {
                    if (i != 0) _soon(context, 'Sắp có');
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The kid's next real-life reward and how many stars they have toward it.
class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.reward});

  final PendingReward reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        children: [
          Image.asset(AppImages.icStar,
              width: 32, height: 32, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${math.min(reward.stars, reward.starsNeeded)}/'
              '${reward.starsNeeded} sao: ${reward.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.kid,
    required this.level,
    required this.stars,
    required this.onParents,
    required this.onSwitchKid,
  });

  final KidProfile? kid;
  final int level;
  final int stars;
  final VoidCallback onParents;
  final VoidCallback onSwitchKid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Semantics(
            button: true,
            label: 'Đổi bé',
            excludeSemantics: true,
            child: Material(
              type: MaterialType.transparency,
              child: Ink(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: const [AppShadows.card],
                ),
                child: InkWell(
                  key: const ValueKey('greeting-pill'),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: onSwitchKid,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              kid?.avatar ?? AppImages.chipMain,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                kid == null
                                    ? 'Chào bé!'
                                    : 'Chào ${kid!.nickname}!',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(AppImages.icCrown,
                                      width: 18,
                                      height: 13,
                                      fit: BoxFit.contain),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Cấp $level',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        InfoPill(
          leading: Image.asset(AppImages.icStar,
              width: 28, height: 28, fit: BoxFit.contain),
          label: '$stars',
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Góc ba mẹ',
          excludeSemantics: true,
          child: Material(
            color: AppColors.card,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: AppShadows.card.color,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onParents,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.lock_outline_rounded,
                    size: 22, color: AppColors.text),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipBlock extends StatelessWidget {
  const _ChipBlock({
    required this.bubbleText,
    required this.total,
    required this.onStart,
    this.doneToday = 0,
  });

  final String bubbleText;
  final int total;
  final int doneToday;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 112,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 96, 18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Bài hôm nay',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doneToday == 0
                        ? '0/$total bài'
                        : 'Xong $total/$total bài · $doneToday lần',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 34,
            width: 160,
            height: 166,
            child: ExcludeSemantics(
              child: Image.asset(AppImages.chipMain, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            left: 6,
            top: 14,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: SpeechBubble(text: bubbleText),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 26,
            child: Semantics(
              button: true,
              label: 'Bắt đầu bài hôm nay',
              excludeSemantics: true,
              child: Material(
                color: AppColors.accent,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.card, width: 4),
                ),
                elevation: 6,
                shadowColor: AppColors.accent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onStart,
                  child: const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.play_arrow_rounded,
                        size: 38, color: AppColors.card),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({
    required this.masteredWriting,
    required this.mathLevelIndex,
  });

  final int masteredWriting;
  final int mathLevelIndex;

  @override
  Widget build(BuildContext context) {
    final cards = [
      SubjectCard(
        subject: Subject.viet,
        imagePath: AppImages.icViet,
        title: 'Viết',
        subtitle: 'Nét và số',
        done: masteredWriting,
        total: writingLadder.length,
        onTap: () => context.push('/subject/viet'),
      ),
      const SubjectCard(
        subject: Subject.tiengViet,
        imagePath: AppImages.icTiengViet,
        title: 'Tiếng Việt',
        subtitle: 'Chữ, âm, vần',
      ),
      SubjectCard(
        subject: Subject.toan,
        imagePath: AppImages.icToan,
        title: 'Toán',
        subtitle: 'Đếm, cộng trừ',
        done: mathLevelIndex + 1,
        total: mathLevels.length,
        onTap: () => context.push('/subject/toan'),
      ),
      const SubjectCard(
        subject: Subject.tiengAnh,
        imagePath: AppImages.icTiengAnh,
        title: 'Tiếng Anh',
        subtitle: 'Chữ cái, từ',
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 12),
              Expanded(child: cards[i + 1]),
            ],
          ),
        ],
      ],
    );
  }
}
