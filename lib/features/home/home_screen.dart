import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../explore/explore_flags.dart';
import '../../learning/lesson_item.dart';
import '../../learning/today_lesson_provider.dart';
import '../../learning/writing_ladder.dart';
import '../../data/app_database.dart';
import '../../english/english_level.dart';
import '../../math/math_level.dart';
import '../../vietnamese/vietnamese_level.dart';
import '../../online/auth/session_controller.dart';
import '../../online/online_config.dart';
import '../../online/sync/sync_health.dart';
import '../../parent/parent_gate_route.dart';
import '../../profile/kid_repository.dart';
import '../../progress/progress_repository.dart';
import '../../rewards/reward_repository.dart';
import '../../stroke/glyph_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/floating_nav_bar.dart';
import '../../ui/widgets/info_pill.dart';
import '../../ui/widgets/nav_rail.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/speech_bubble.dart';
import 'home_tablet.dart';
import 'kid_nav.dart';
import 'kid_switcher.dart';
import 'sync_chip.dart';
import 'week_panel.dart';
import '../../ui/widgets/subject_card.dart';

const _contentMaxWidth = 560.0;

String _progressText(int doneToday, int total) =>
    doneToday == 0 ? '0/$total bài' : 'Xong $total/$total bài · $doneToday lần';


/// Home screen: greeting, today's lesson, streak and the subject grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);
    final lessonAsync = ref.watch(todayLessonProvider);
    // Until both load, the numbers keep their place but stay hidden (no
    // "0 ngày học" flash) and "Bài hôm nay" waits.
    final loading = !summaryAsync.hasValue || !lessonAsync.hasValue;
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

    final config = ref.watch(onlineConfigProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    final health = ref.watch(syncHealthProvider);
    final now = ref.watch(syncHealthClockProvider)();
    final showSyncChip = config.enabled && session != null;
    final showBanner =
        showSyncChip && SyncReminderBanner.staleDays(health, now) != null;

    return Scaffold(
      body: DottedBackground(
        child: _HomeBody(
          kid: kid,
          summary: summary,
          lessonTotal: lesson.length,
          firstLabel: firstLabel,
          reward: ref.watch(pendingRewardProvider).valueOrNull,
          loading: loading,
          showSyncChip: showSyncChip,
          banner: showBanner ? const SyncReminderBanner() : null,
          showExplore: ref.watch(exploreIslandEnabledProvider),
        ),
      ),
    );
  }
}

/// Keeps [child]'s size but hides it while the numbers load.
Widget _hiddenWhile(bool loading, Widget child) => Visibility(
      visible: !loading,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: child,
    );

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.kid,
    required this.summary,
    required this.lessonTotal,
    required this.firstLabel,
    required this.reward,
    this.loading = false,
    this.showSyncChip = false,
    this.banner,
    this.showExplore = false,
  });

  final bool loading;
  final bool showExplore;
  final bool showSyncChip;
  final Widget? banner;
  final PendingReward? reward;
  final KidProfile? kid;
  final HomeSummary summary;
  final int lessonTotal;
  final String? firstLabel;

  Future<void> _openParents(BuildContext context) async {
    final passed = await showParentGate(context);
    if (passed && context.mounted) context.push('/parent');
  }

  @override
  Widget build(BuildContext context) {
    final bubbleText = firstLabel == null
        ? 'Hôm nay mình làm Toán nhé!'
        : 'Hôm nay mình viết $firstLabel và làm Toán nhé!';

    // Sky image fading into the cream background.
    final sky = Positioned(
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
    );

    final formFactor = context.formFactor;
    if (formFactor != FormFactor.phone) {
      return _tabletBody(context, bubbleText, sky,
          landscape: formFactor == FormFactor.tabletLandscape);
    }
    final mq = MediaQuery.of(context);
    final safeHeight = mq.size.height - mq.padding.top - mq.padding.bottom;
    final compact = safeHeight < 700;
    final bottomNavMargin =
        math.max(mq.padding.bottom, FloatingNavBar.bottomMargin);
    final bottomPadding =
        FloatingNavBar.height + bottomNavMargin + (compact ? 8.0 : 12.0);

    return Stack(
      children: [
        sky,
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    18, compact ? 8 : 12, 18, bottomPadding),
                children: [
                  _TopRow(
                    kid: kid,
                    level: summary.level,
                    stars: summary.totalStars,
                    hideStars: loading,
                    showSyncChip: showSyncChip,
                    onParents: () => _openParents(context),
                    onSwitchKid: () => showKidSwitcher(context),
                  ),
                  if (banner != null) ...[
                    SizedBox(height: compact ? 8 : 12),
                    banner!,
                  ],
                  SizedBox(height: compact ? 8 : 16),
                  _ChipBlock(
                    bubbleText: bubbleText,
                    total: lessonTotal,
                    doneToday: summary.lessonsToday,
                    onStart: () {
                      if (!loading) context.push('/lesson');
                    },
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _hiddenWhile(loading, FittedBox(
                      fit: BoxFit.scaleDown,
                      child: InfoPill(
                        leading: Image.asset(AppImages.icFlame,
                            width: compact ? 22 : 26,
                            height: compact ? 22 : 26,
                            fit: BoxFit.contain),
                        label:
                            '${summary.learnedDaysThisWeek} ngày học tuần này',
                      ),
                    )),
                  ),
                  if (reward != null) ...[
                    SizedBox(height: compact ? 6 : 12),
                    _RewardPill(reward: reward!),
                  ],
                  SizedBox(height: compact ? 8 : 18),
                  Text(
                    'Hôm nay học gì?',
                    style: TextStyle(
                      fontSize: compact ? 20 : 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  _SubjectGrid(
                    masteredWriting: summary.masteredWriting,
                    mathLevelIndex: summary.mathLevelIndex,
                    vietnameseLevelIndex: summary.vietnameseLevelIndex,
                    englishLevelIndex: summary.englishLevelIndex,
                    exploreDone: summary.exploreDone,
                    exploreTotal: summary.exploreTotal,
                    showExplore: showExplore,
                    compact: compact,
                    gap: compact ? 8 : 12,
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
            minimum: const EdgeInsets.only(bottom: FloatingNavBar.bottomMargin),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: FloatingNavBar(
                  items: kidNavItems,
                  selected: kidNavHome,
                  onSelect: (i) => onKidNav(context, i, current: kidNavHome),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabletBody(
    BuildContext context,
    String bubbleText,
    Widget sky, {
    required bool landscape,
  }) {
    return HomeTabletBody(
      landscape: landscape,
      sky: sky,
      navRail: NavRail(
        items: kidNavItems,
        selected: kidNavHome,
        onSelect: (i) => onKidNav(context, i, current: kidNavHome),
      ),
      topBar: _TopRow(
        wide: true,
        kid: kid,
        level: summary.level,
        stars: summary.totalStars,
        hideStars: loading,
        showSyncChip: showSyncChip,
        onParents: () => _openParents(context),
        onSwitchKid: () => showKidSwitcher(context),
      ),
      banner: banner,
      hero: HomeHeroCard(
        bubbleText: bubbleText,
        progressText: _progressText(summary.lessonsToday, lessonTotal),
        onStart: () {
          if (!loading) context.push('/lesson');
        },
      ),
      weekPanel: _hiddenWhile(loading, WeekPanel(
        learnedWeekdays: summary.learnedWeekdays,
        masteredWriting: summary.masteredWriting,
        writingTotal: writingLadder.length,
        mathLevel: summary.mathLevelIndex + 1,
        mathTotal: mathLevels.length,
      )),
      reward: reward == null ? null : _RewardPill(reward: reward!),
      subjects: (columns, cardHeight) => _SubjectGrid(
        cardHeight: cardHeight,
        masteredWriting: summary.masteredWriting,
        mathLevelIndex: summary.mathLevelIndex,
        vietnameseLevelIndex: summary.vietnameseLevelIndex,
        englishLevelIndex: summary.englishLevelIndex,
        exploreDone: summary.exploreDone,
                    exploreTotal: summary.exploreTotal,
        showExplore: showExplore,
        // Landscape lays the subjects out in one row (4 columns): the
        // explore card joins that row so the height budget stays the same.
        columns: showExplore && columns == 4 ? 5 : columns,
        gap: 16,
      ),
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
      decoration: raisedDecoration(radius: AppRadii.pill),
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
    this.hideStars = false,
    this.showSyncChip = false,
    required this.onParents,
    required this.onSwitchKid,
    this.wide = false,
  });

  final KidProfile? kid;
  final int level;
  final int stars;

  /// While loading: the star pill keeps its place, empty.
  final bool hideStars;
  final bool showSyncChip;
  final VoidCallback onParents;
  final VoidCallback onSwitchKid;

  /// Tablet: the stars and the parent button sit at the right edge however
  /// narrow the greeting is (a Flexible + Spacer pair splits the free space
  /// in half, leaving a gap on wide screens).
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipWidth = wide
            ? 220.0
            : (constraints.maxWidth * 0.38).clamp(48.0, 145.0);
        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: 'Đổi bé',
                  excludeSemantics: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Ink(
                      decoration: raisedDecoration(radius: AppRadii.pill),
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
            ),
            const SizedBox(width: 8),
            if (showSyncChip) ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                child: SyncChip(compact: !wide),
              ),
              const SizedBox(width: 6),
            ],
            _hiddenWhile(
              hideStars,
              InfoPill(
                leading: Image.asset(AppImages.icStar,
                    width: 28, height: 28, fit: BoxFit.contain),
                label: '$stars',
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Góc ba mẹ',
              excludeSemantics: true,
              child: Material(
                type: MaterialType.transparency,
                child: Ink(
                  width: 48,
                  height: 48,
                  decoration: raisedDecoration(radius: 24),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onParents,
                    child: const Center(
                      child: Icon(Icons.lock_outline_rounded,
                          size: 22, color: AppColors.text),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChipBlock extends StatelessWidget {
  const _ChipBlock({
    required this.bubbleText,
    required this.total,
    required this.onStart,
    this.doneToday = 0,
    this.compact = false,
  });

  final String bubbleText;
  final int total;
  final int doneToday;
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final topSpace = compact ? 60.0 : 88.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: topSpace),
          child: ExcludeSemantics(
            child: Pressable(
              onTap: onStart,
              builder: (pressed) => Container(
                constraints: BoxConstraints(minHeight: compact ? 86 : 112),
                padding: compact
                    ? const EdgeInsets.fromLTRB(16, 12, 80, 12)
                    : const EdgeInsets.fromLTRB(20, 18, 96, 18),
                decoration: raisedDecoration(
                  accent: AppColors.accent,
                  tint: Subject.viet.tint,
                  pressed: pressed,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bài hôm nay',
                        style: TextStyle(
                          fontSize: compact ? 22 : 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 8),
                    Text(
                      _progressText(doneToday, total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: compact ? 4 : 2,
          bottom: compact ? 20 : 34,
          width: compact ? 116 : 160,
          height: compact ? 122 : 166,
          child: ExcludeSemantics(
            child: Image.asset(AppImages.chipMain, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          left: 6,
          top: compact ? 4 : 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 165 : 190),
            child: SpeechBubble(
              text: bubbleText,
              maxLines: compact ? 2 : (textScale > 1.2 ? 2 : null),
            ),
          ),
        ),
        Positioned(
          right: compact ? 14 : 22,
          bottom: compact ? 11 : 24,
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
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({
    required this.masteredWriting,
    required this.mathLevelIndex,
    required this.vietnameseLevelIndex,
    required this.englishLevelIndex,
    this.exploreDone = 0,
    this.exploreTotal = 0,
    this.showExplore = false,
    this.columns = 2,
    this.gap = 12,
    this.cardHeight,
    this.compact = false,
  });

  final int masteredWriting;
  final int mathLevelIndex;
  final int vietnameseLevelIndex;
  final int englishLevelIndex;
  /// Levels reached over the ready explore islands, and their count.
  final int exploreDone;
  final int exploreTotal;
  final bool showExplore;
  final int columns;
  final double gap;

  /// Fixed card height for tablet landscape; null sizes cards by content.
  final double? cardHeight;

  /// Compact mode for low-height phone screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      SubjectCard(
        subject: Subject.viet,
        height: cardHeight,
        compact: compact,
        imagePath: AppImages.icViet,
        title: 'Viết',
        subtitle: 'Nét, số, chữ cái',
        done: masteredWriting,
        total: writingLadder.length,
        onTap: () => context.push('/subject/viet'),
      ),
      SubjectCard(
        subject: Subject.tiengViet,
        height: cardHeight,
        compact: compact,
        imagePath: AppImages.icTiengViet,
        title: 'Tiếng Việt',
        subtitle: 'Chữ, âm, vần',
        done: vietnameseLevelIndex + 1,
        total: vietnameseLevels.length,
        onTap: () => context.push('/subject/tieng-viet'),
      ),
      SubjectCard(
        subject: Subject.toan,
        height: cardHeight,
        compact: compact,
        imagePath: AppImages.icToan,
        title: 'Toán',
        subtitle: 'Đếm, cộng trừ',
        done: mathLevelIndex + 1,
        total: mathLevels.length,
        onTap: () => context.push('/subject/toan'),
      ),
      SubjectCard(
        subject: Subject.tiengAnh,
        height: cardHeight,
        compact: compact,
        imagePath: AppImages.icTiengAnh,
        title: 'Tiếng Anh',
        subtitle: 'Chữ cái, từ',
        done: englishLevelIndex + 1,
        total: englishLevels.length,
        onTap: () => context.push('/subject/tieng-anh'),
      ),
      if (showExplore)
        SubjectCard(
          subject: Subject.diaLy,
          height: cardHeight,
          compact: compact,
          imagePath: AppImages.icKhamPha,
          title: 'Đảo Khám phá',
          subtitle: 'Địa lý, Sinh học, Lịch sử',
          done: exploreDone.clamp(0, exploreTotal),
          total: exploreTotal < 1 ? 1 : exploreTotal,
          onTap: () => context.push('/kham-pha'),
        ),
    ];
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += columns) ...[
          if (i > 0) SizedBox(height: gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A short last row shares the full width.
              for (var j = 0; j < columns && i + j < cards.length; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(child: cards[i + j]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
