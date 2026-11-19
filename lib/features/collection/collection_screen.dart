import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../collection/certificate_pdf.dart';
import '../../collection/collection_model.dart';
import '../../collection/collection_provider.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/floating_nav_bar.dart';
import '../../ui/widgets/nav_rail.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/speech_bubble.dart';
import '../../voice/speaker.dart';
import '../../worksheet/worksheet_pdf.dart';
import '../../worksheet/worksheet_printer.dart';
import '../home/kid_nav.dart';

const _phoneMaxWidth = 560.0;
const _tabletMaxWidth = 1140.0;
const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

BoxDecoration _primaryButtonDecoration({
  required bool pressed,
  double radius = AppRadii.pill,
}) =>
    BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(radius),
      border: Border(
        bottom: BorderSide(
          width: pressed ? AppDepth.pressedLip : AppDepth.lip,
          color: AppColors.primaryOnTint,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.26),
          blurRadius: pressed ? 8 : 16,
          offset: Offset(0, pressed ? 3 : 8),
        ),
      ],
    );

/// Single-pass greyscale + 0.38 alpha matrix (avoids nested Opacity +
/// ColorFiltered double saveLayer during 120fps scrolling).
const _lockedGreyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 0.38, 0,
];

enum CollectionTab { stickers, calendar, certificates }

/// "Sưu tập" tab (/collection): learning sticker album, attendance calendar
/// (no streak pressure), and printable kid certificates. 100% learning data.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  CollectionTab _tab = CollectionTab.stickers;

  void _shiftMonth(int delta) {
    final now = ref.read(collectionClockProvider)();
    final current = ref.read(collectionMonthProvider);
    final candidate = DateTime(current.year, current.month + delta, 1);
    final maxMonth = DateTime(now.year, now.month, 1);
    if (candidate.isAfter(maxMonth)) return;
    ref.read(collectionMonthProvider.notifier).state = candidate;
  }

  bool _canGoNextMonth(DateTime viewed) {
    final now = ref.read(collectionClockProvider)();
    final next = DateTime(viewed.year, viewed.month + 1, 1);
    final maxMonth = DateTime(now.year, now.month, 1);
    return !next.isAfter(maxMonth);
  }

  void _openStickerDetail(LearningSticker sticker) {
    final speaker = ref.read(speakerProvider);
    final line = sticker.unlocked
        ? sticker.praise
        : '${sticker.title}. ${sticker.hint} để mở sticker này nhé!';
    unawaited(speaker.speak(line));
    showDialog<void>(
      context: context,
      builder: (_) => _StickerDetailDialog(sticker: sticker),
    );
  }

  void _openCertificate(LearningCertificate cert, LearningSnapshot snap) {
    final speaker = ref.read(speakerProvider);
    if (!cert.unlocked) {
      unawaited(speaker.speak(
        'Giấy khen ${cert.title}. ${cert.requirement} để nhận giấy khen nhé!',
      ));
      showDialog<void>(
        context: context,
        builder: (_) => _LockedCertificateDialog(certificate: cert),
      );
      return;
    }
    unawaited(speaker.speak(
      'Chúc mừng ${snap.displayKidName} nhận giấy khen ${cert.title}! ${cert.citation}',
    ));
    showDialog<void>(
      context: context,
      builder: (_) => _CertificateModal(
        certificate: cert,
        kidName: snap.displayKidName,
        issuedAt: ref.read(collectionClockProvider)(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapAsync = ref.watch(collectionSnapshotProvider);
    final ff = context.formFactor;
    final tablet = ff != FormFactor.phone;
    final landscape = ff == FormFactor.tabletLandscape;
    final viewedMonth = ref.watch(collectionMonthProvider);
    final now = ref.watch(collectionClockProvider)();

    final sky = Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 260,
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
              height: 120,
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

    Widget buildBody(LearningSnapshot snap) {
      final stickers = buildLearningStickers(snap);
      final certs = buildLearningCertificates(snap);
      final unlockedStickers = stickers.where((s) => s.unlocked).length;
      final unlockedCerts = certs.where((c) => c.unlocked).length;

      final content = CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              tablet ? 8 : 16,
              tablet ? 20 : 12,
              tablet ? 28 : 16,
              14,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderRow(
                    title: 'Sưu tập của ${snap.displayKidName}',
                    stars: snap.totalStars,
                    tablet: tablet,
                  ),
                  SizedBox(height: tablet ? 18 : 14),
                  _ChipHeroBanner(
                    snapshot: snap,
                    unlockedStickers: unlockedStickers,
                    totalStickers: stickers.length,
                    unlockedCerts: unlockedCerts,
                    totalCerts: certs.length,
                    tablet: tablet,
                  ),
                  SizedBox(height: tablet ? 20 : 14),
                  _SectionSwitcher(
                    selected: _tab,
                    stickerBadge: '$unlockedStickers/${stickers.length}',
                    certBadge: '$unlockedCerts/${certs.length}',
                    tablet: tablet,
                    onSelect: (t) => setState(() => _tab = t),
                  ),
                ],
              ),
            ),
          ),
          if (_tab == CollectionTab.stickers)
            _buildStickersSliver(stickers, ff)
          else if (_tab == CollectionTab.calendar)
            _buildCalendarSliver(snap, viewedMonth, now, tablet, landscape)
          else
            _buildCertificatesSliver(certs, snap, ff),
          SliverToBoxAdapter(
            child: SizedBox(height: tablet ? 36 : 124),
          ),
        ],
      );

      if (!tablet) {
        return Stack(
          children: [
            sky,
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _phoneMaxWidth),
                  child: content,
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
                    constraints:
                        const BoxConstraints(maxWidth: _phoneMaxWidth),
                    child: FloatingNavBar(
                      items: kidNavItems,
                      selected: kidNavCollection,
                      onSelect: (i) =>
                          onKidNav(context, i, current: kidNavCollection),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          sky,
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                right: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: NavRail(
                      items: kidNavItems,
                      selected: kidNavCollection,
                      onSelect: (i) =>
                          onKidNav(context, i, current: kidNavCollection),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  left: false,
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _tabletMaxWidth),
                      child: content,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final snapshot = snapAsync.valueOrNull ??
        LearningSnapshot(
          kidName: 'Bé',
          totalStars: 0,
          totalLessons: 0,
          totalLearnedDays: 0,
          learnedDaysThisWeek: 0,
          masteredWriting: 0,
          mathLevelIndex: 0,
          vietnameseLevelIndex: 0,
          englishLevelIndex: 0,
          viewedYear: viewedMonth.year,
          viewedMonth: viewedMonth.month,
          learnedDaysInMonth: const {},
          learnedToday: false,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        body: DottedBackground(
          child: buildBody(snapshot),
        ),
      ),
    );
  }

  SliverPadding _buildStickersSliver(
    List<LearningSticker> stickers,
    FormFactor ff,
  ) {
    final tablet = ff != FormFactor.phone;
    final columns = switch (ff) {
      FormFactor.phone => 2,
      FormFactor.tabletPortrait => 3,
      FormFactor.tabletLandscape => 4,
    };
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        tablet ? 8 : 16,
        4,
        tablet ? 28 : 16,
        8,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: tablet ? 18 : 14,
          crossAxisSpacing: tablet ? 18 : 14,
          mainAxisExtent: tablet ? 236 : 210,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final sticker = stickers[index];
            return _StickerCard(
              key: ValueKey('learning-sticker-${sticker.id}'),
              sticker: sticker,
              tablet: tablet,
              onTap: () => _openStickerDetail(sticker),
            );
          },
          childCount: stickers.length,
        ),
      ),
    );
  }

  SliverPadding _buildCalendarSliver(
    LearningSnapshot snap,
    DateTime viewedMonth,
    DateTime now,
    bool tablet,
    bool landscape,
  ) {
    final calendarCard = _AttendanceCalendarCard(
      year: viewedMonth.year,
      month: viewedMonth.month,
      learnedDays: snap.learnedDaysInMonth,
      today: now,
      canGoNext: _canGoNextMonth(viewedMonth),
      onPrevMonth: () => _shiftMonth(-1),
      onNextMonth: () => _shiftMonth(1),
      tablet: tablet,
    );
    final summaryCard = _MonthSummaryCard(
      snapshot: snap,
      tablet: tablet,
    );

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        tablet ? 8 : 16,
        4,
        tablet ? 28 : 16,
        8,
      ),
      sliver: SliverToBoxAdapter(
        child: landscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 62, child: calendarCard),
                  const SizedBox(width: 20),
                  Expanded(flex: 38, child: summaryCard),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  calendarCard,
                  SizedBox(height: tablet ? 20 : 16),
                  summaryCard,
                ],
              ),
      ),
    );
  }

  SliverPadding _buildCertificatesSliver(
    List<LearningCertificate> certs,
    LearningSnapshot snap,
    FormFactor ff,
  ) {
    final tablet = ff != FormFactor.phone;
    final columns = switch (ff) {
      FormFactor.phone => 1,
      FormFactor.tabletPortrait => 2,
      FormFactor.tabletLandscape => 3,
    };
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        tablet ? 8 : 16,
        4,
        tablet ? 28 : 16,
        8,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: tablet ? 18 : 14,
          crossAxisSpacing: tablet ? 18 : 14,
          mainAxisExtent: tablet ? 236 : 186,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final cert = certs[index];
            return _CertificateCard(
              key: ValueKey('learning-cert-${cert.id}'),
              certificate: cert,
              kidName: snap.displayKidName,
              tablet: tablet,
              onTap: () => _openCertificate(cert, snap),
            );
          },
          childCount: certs.length,
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.stars,
    required this.tablet,
  });

  final String title;
  final int stars;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tablet ? 30 : 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 18 : 14,
            vertical: tablet ? 10 : 8,
          ),
          decoration: raisedDecoration(radius: AppRadii.pill),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.icStar,
                width: tablet ? 26 : 22,
                height: tablet ? 26 : 22,
              ),
              const SizedBox(width: 6),
              Text(
                '$stars',
                style: TextStyle(
                  fontSize: tablet ? 20 : 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipHeroBanner extends StatelessWidget {
  const _ChipHeroBanner({
    required this.snapshot,
    required this.unlockedStickers,
    required this.totalStickers,
    required this.unlockedCerts,
    required this.totalCerts,
    required this.tablet,
  });

  final LearningSnapshot snapshot;
  final int unlockedStickers;
  final int totalStickers;
  final int unlockedCerts;
  final int totalCerts;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final mascotImage = snapshot.learnedToday
        ? AppImages.chipJoy
        : (snapshot.totalLessons == 0
            ? AppImages.chipMain
            : AppImages.chipEncourage);

    return Container(
      padding: EdgeInsets.all(tablet ? 20 : 14),
      decoration: raisedDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                mascotImage,
                width: tablet ? 90 : 70,
                height: tablet ? 90 : 70,
                fit: BoxFit.contain,
              ),
              SizedBox(width: tablet ? 16 : 12),
              Expanded(
                child: SpeechBubble(
                  text: snapshot.chipGreeting,
                ),
              ),
            ],
          ),
          SizedBox(height: tablet ? 16 : 12),
          Row(
            children: [
              Expanded(
                child: _MiniStatBadge(
                  icon: AppImages.icFlame,
                  value: '${snapshot.totalLearnedDays}',
                  label: 'Ngày học',
                  tint: Subject.viet.tint,
                  tablet: tablet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatBadge(
                  icon: AppImages.icStar,
                  value: '$unlockedStickers/$totalStickers',
                  label: 'Sticker',
                  tint: CollectionColors.goldFill,
                  tablet: tablet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatBadge(
                  icon: AppImages.icCrown,
                  value: '$unlockedCerts/$totalCerts',
                  label: 'Giấy khen',
                  tint: Subject.tiengViet.tint,
                  tablet: tablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  const _MiniStatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    required this.tablet,
  });

  final String icon;
  final String value;
  final String label;
  final Color tint;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 12 : 8,
        vertical: tablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(icon, width: tablet ? 22 : 18, height: tablet ? 22 : 18),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: tablet ? 19 : 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: tablet ? 14 : 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSwitcher extends StatelessWidget {
  const _SectionSwitcher({
    required this.selected,
    required this.stickerBadge,
    required this.certBadge,
    required this.tablet,
    required this.onSelect,
  });

  final CollectionTab selected;
  final String stickerBadge;
  final String certBadge;
  final bool tablet;
  final ValueChanged<CollectionTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabPill(
            key: const ValueKey('collection-tab-stickers'),
            label: 'Sticker',
            sublabel: stickerBadge,
            icon: Icons.auto_awesome_rounded,
            active: selected == CollectionTab.stickers,
            tablet: tablet,
            onTap: () => onSelect(CollectionTab.stickers),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabPill(
            key: const ValueKey('collection-tab-calendar'),
            label: 'Lịch học',
            sublabel: 'Tháng',
            icon: Icons.calendar_month_rounded,
            active: selected == CollectionTab.calendar,
            tablet: tablet,
            onTap: () => onSelect(CollectionTab.calendar),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TabPill(
            key: const ValueKey('collection-tab-certificates'),
            label: 'Giấy khen',
            sublabel: certBadge,
            icon: Icons.workspace_premium_rounded,
            active: selected == CollectionTab.certificates,
            tablet: tablet,
            onTap: () => onSelect(CollectionTab.certificates),
          ),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    super.key,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.active,
    required this.tablet,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool active;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : AppColors.text;
    final subFg = active ? Colors.white.withOpacity(0.92) : AppColors.textMuted;
    return Pressable(
      onTap: onTap,
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: tablet ? 80 : 64),
        padding: EdgeInsets.symmetric(
          horizontal: tablet ? 14 : 8,
          vertical: tablet ? 12 : 8,
        ),
        decoration: active
            ? _primaryButtonDecoration(
                pressed: pressed,
                radius: AppRadii.tile,
              )
            : raisedDecoration(
                pressed: pressed,
                radius: AppRadii.tile,
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: tablet ? 24 : 20, color: fg),
                const SizedBox(width: 5),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: tablet ? 19 : 15,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                sublabel,
                style: TextStyle(
                  fontSize: tablet ? 14 : 12,
                  fontWeight: FontWeight.w800,
                  color: subFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerCard extends StatelessWidget {
  const _StickerCard({
    super.key,
    required this.sticker,
    required this.tablet,
    required this.onTap,
  });

  final LearningSticker sticker;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = sticker.unlocked;
    final image = Image.asset(sticker.image, fit: BoxFit.contain);

    return Semantics(
      button: true,
      label: unlocked
          ? 'Sticker ${sticker.title}, đã mở khóa'
          : 'Sticker ${sticker.title}, chưa mở. ${sticker.hint}, ${sticker.clampedCurrent} trên ${sticker.target}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        builder: (pressed) => Container(
          padding: EdgeInsets.all(tablet ? 14 : 12),
          decoration: unlocked
              ? raisedDecoration(
                  accent: sticker.accentColor,
                  pressed: pressed,
                )
              : BoxDecoration(
                  color: CollectionColors.lockedSurface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: CollectionColors.lockedBorder,
                    width: 1.5,
                  ),
                ),
          child: Column(
            children: [
              Expanded(
                child: unlocked
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          FractionallySizedBox(
                            widthFactor: 0.9,
                            heightFactor: 0.9,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    CollectionColors.goldHalo.withOpacity(0.55),
                                    CollectionColors.goldHalo.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: image,
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: ColorFiltered(
                          colorFilter:
                              const ColorFilter.matrix(_lockedGreyscaleMatrix),
                          child: image,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                sticker.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tablet ? 18 : 15,
                  fontWeight: FontWeight.w900,
                  color: unlocked ? AppColors.text : CollectionColors.lockedInk,
                ),
              ),
              const SizedBox(height: 4),
              if (unlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: CollectionColors.goldFill,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: const Text(
                    'Đã mở!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: CollectionColors.goldInk,
                    ),
                  ),
                )
              else ...[
                Text(
                  '${sticker.hint} (${sticker.clampedCurrent}/${sticker.target})',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: CollectionColors.lockedInk,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: sticker.progress,
                    minHeight: 7,
                    backgroundColor: CollectionColors.progressTrack,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(sticker.accentColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceCalendarCard extends StatelessWidget {
  const _AttendanceCalendarCard({
    required this.year,
    required this.month,
    required this.learnedDays,
    required this.today,
    required this.canGoNext,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.tablet,
  });

  final int year;
  final int month;
  final Set<int> learnedDays;
  final DateTime today;
  final bool canGoNext;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final totalDays = daysInMonth(year, month);
    final leadingBlanks = firstWeekdayOfMonth(year, month) - 1;
    final totalCells = leadingBlanks + totalDays;
    final rows = (totalCells / 7).ceil();
    final isCurrentMonth = year == today.year && month == today.month;

    return Container(
      padding: EdgeInsets.all(tablet ? 22 : 16),
      decoration: raisedDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _MonthArrowButton(
                key: const ValueKey('calendar-prev-month'),
                icon: Icons.chevron_left_rounded,
                semanticLabel: 'Tháng trước',
                enabled: true,
                tablet: tablet,
                onTap: onPrevMonth,
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Tháng $month / $year',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: tablet ? 24 : 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              _MonthArrowButton(
                key: const ValueKey('calendar-next-month'),
                icon: Icons.chevron_right_rounded,
                semanticLabel: 'Tháng sau',
                enabled: canGoNext,
                tablet: tablet,
                onTap: onNextMonth,
              ),
            ],
          ),
          SizedBox(height: tablet ? 18 : 14),
          Row(
            children: [
              for (final w in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: tablet ? 16 : 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) const SizedBox(height: 6),
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _buildDayCell(
                      dayNum: r * 7 + c - leadingBlanks + 1,
                      totalDays: totalDays,
                      isCurrentMonth: isCurrentMonth,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required int dayNum,
    required int totalDays,
    required bool isCurrentMonth,
  }) {
    if (dayNum < 1 || dayNum > totalDays) {
      return SizedBox(height: tablet ? 56 : 44);
    }
    final learned = learnedDays.contains(dayNum);
    final isToday = isCurrentMonth && dayNum == today.day;

    return Semantics(
      label: learned
          ? 'Ngày $dayNum, đã học'
          : (isToday ? 'Ngày $dayNum, hôm nay' : 'Ngày $dayNum'),
      excludeSemantics: true,
      child: Container(
        key: ValueKey('calendar-day-$year-$month-$dayNum'),
        height: tablet ? 56 : 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: learned
              ? CollectionColors.calendarStampFill
              : (isToday
                  ? CollectionColors.calendarTodayFill
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          border: isToday
              ? Border.all(color: AppColors.accent, width: 2)
              : (learned
                  ? Border.all(
                      color: CollectionColors.goldBorder.withOpacity(0.55),
                      width: 1.2,
                    )
                  : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (learned)
              Image.asset(
                AppImages.icStar,
                width: tablet ? 24 : 18,
                height: tablet ? 24 : 18,
              ),
            Text(
              '$dayNum',
              style: TextStyle(
                fontSize: tablet ? (learned ? 13 : 16) : (learned ? 11 : 14),
                fontWeight:
                    (learned || isToday) ? FontWeight.w900 : FontWeight.w700,
                color: learned
                    ? CollectionColors.goldInk
                    : (isToday ? AppColors.primary : AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.tablet,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final bool enabled;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = tablet ? 64.0 : 52.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Pressable(
        onTap: enabled ? onTap : null,
        builder: (pressed) => Container(
          width: size,
          height: size,
          decoration: enabled
              ? raisedDecoration(pressed: pressed, radius: 18)
              : BoxDecoration(
                  color: CollectionColors.lockedSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: CollectionColors.lockedBorder),
                ),
          child: Icon(
            icon,
            size: tablet ? 32 : 28,
            color: enabled ? AppColors.text : CollectionColors.lockedInk.withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.snapshot, required this.tablet});

  final LearningSnapshot snapshot;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final monthCount = snapshot.learnedDaysInMonth.length;
    return Container(
      padding: EdgeInsets.all(tablet ? 22 : 16),
      decoration: raisedDecoration(tint: CollectionColors.goldFill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                AppImages.icStar,
                width: tablet ? 36 : 30,
                height: tablet ? 36 : 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tháng ${snapshot.viewedMonth}: $monthCount ngày học',
                  style: TextStyle(
                    fontSize: tablet ? 22 : 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tổng cộng bé đã hoàn thành ${snapshot.totalLessons} bài học trong ${snapshot.totalLearnedDays} ngày.',
            style: TextStyle(
              fontSize: tablet ? 17 : 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: Row(
              children: [
                Image.asset(
                  AppImages.chipThumb,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Bỏ lỡ ngày cũng không mất sao nào đâu, Chíp luôn vui khi bé quay lại học!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    super.key,
    required this.certificate,
    required this.kidName,
    required this.tablet,
    required this.onTap,
  });

  final LearningCertificate certificate;
  final String kidName;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = certificate.unlocked;
    final badgeImage = Image.asset(
      certificate.image,
      width: tablet ? 68 : 56,
      height: tablet ? 68 : 56,
      fit: BoxFit.contain,
    );

    return Semantics(
      button: true,
      label: unlocked
          ? 'Giấy khen ${certificate.title} trao tặng bé $kidName. Nhấn để xem'
          : 'Giấy khen ${certificate.title}, chưa mở. ${certificate.requirement}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        builder: (pressed) => Container(
          padding: EdgeInsets.all(tablet ? 18 : 14),
          decoration: unlocked
              ? BoxDecoration(
                  color: CollectionColors.certPaper,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: CollectionColors.certFrameOuter,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CollectionColors.certFrameOuter.withOpacity(0.35),
                      offset: Offset(0, pressed ? 2 : 5),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: CollectionColors.lockedSurface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: CollectionColors.lockedBorder,
                    width: 1.5,
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  unlocked
                      ? badgeImage
                      : ColorFiltered(
                          colorFilter:
                              const ColorFilter.matrix(_lockedGreyscaleMatrix),
                          child: badgeImage,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unlocked ? 'GIẤY KHEN' : 'SẮP ĐẠT ĐƯỢC',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: unlocked
                                ? CollectionColors.goldInk
                                : CollectionColors.lockedInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          certificate.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: tablet ? 20 : 18,
                            fontWeight: FontWeight.w900,
                            color: unlocked
                                ? AppColors.text
                                : CollectionColors.lockedInk,
                          ),
                        ),
                        if (unlocked) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Trao tặng bé $kidName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (unlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: CollectionColors.goldFill,
                    borderRadius: BorderRadius.circular(AppRadii.tile),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                        color: CollectionColors.goldInk,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Mở xem giấy khen',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: CollectionColors.goldInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${certificate.requirement} (${certificate.clampedCurrent}/${certificate.target})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: CollectionColors.lockedInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: certificate.progress,
                        minHeight: 8,
                        backgroundColor: CollectionColors.progressTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          certificate.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerDetailDialog extends StatelessWidget {
  const _StickerDetailDialog({required this.sticker});

  final LearningSticker sticker;

  @override
  Widget build(BuildContext context) {
    final unlocked = sticker.unlocked;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: raisedDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 130,
                child: unlocked
                    ? Image.asset(sticker.image, fit: BoxFit.contain)
                    : ColorFiltered(
                        colorFilter:
                            const ColorFilter.matrix(_lockedGreyscaleMatrix),
                        child: Image.asset(sticker.image, fit: BoxFit.contain),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                sticker.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unlocked
                    ? sticker.praise
                    : '${sticker.hint} (${sticker.clampedCurrent}/${sticker.target}) để mở khóa sticker này nhé!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Pressable(
                onTap: () => Navigator.of(context).pop(),
                builder: (pressed) => Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  alignment: Alignment.center,
                  decoration: _primaryButtonDecoration(pressed: pressed),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedCertificateDialog extends StatelessWidget {
  const _LockedCertificateDialog({required this.certificate});

  final LearningCertificate certificate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: raisedDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.chipEncourage,
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                'Giấy khen ${certificate.title}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${certificate.requirement} (${certificate.clampedCurrent}/${certificate.target}) để mở khóa giấy khen mang tên bé nhé!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Pressable(
                onTap: () => Navigator.of(context).pop(),
                builder: (pressed) => Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  alignment: Alignment.center,
                  decoration: _primaryButtonDecoration(pressed: pressed),
                  child: const Text(
                    'Cố lên nhé!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateModal extends ConsumerStatefulWidget {
  const _CertificateModal({
    required this.certificate,
    required this.kidName,
    required this.issuedAt,
  });

  final LearningCertificate certificate;
  final String kidName;
  final DateTime issuedAt;

  @override
  ConsumerState<_CertificateModal> createState() => _CertificateModalState();
}

class _CertificateModalState extends ConsumerState<_CertificateModal> {
  bool _exporting = false;

  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final fonts = await WorksheetPdfFonts.loadFromAssets();
      final bytes = await buildCertificatePdf(
        certificate: widget.certificate,
        kidName: widget.kidName,
        issuedAt: widget.issuedAt,
        fonts: fonts,
      );
      final printer = ref.read(worksheetPrinterProvider);
      await printer.sharePdf(
        bytes,
        fileName: 'giay-khen-${widget.certificate.id}.pdf',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.certificate;
    final d = widget.issuedAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CollectionColors.certPaper,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: CollectionColors.certFrameOuter,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.text.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CollectionColors.certFrameInner,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(AppImages.icCrown, width: 34, height: 34),
                      const SizedBox(width: 8),
                      const Text(
                        'GIẤY KHEN',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(AppImages.icCrown, width: 34, height: 34),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'CHÍP CHÍP TRAO TẶNG BÉ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.kidName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CollectionColors.goldFill,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: c.accentColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(c.image, width: 26, height: 26),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            c.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: c.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    c.citation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(AppImages.chipJoy, width: 54, height: 54),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày $dateStr',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Text(
                            'Bạn nhỏ Chíp Chíp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Pressable(
                          onTap: _exporting ? null : _exportPdf,
                          builder: (pressed) => Container(
                            key: const ValueKey('cert-export-pdf'),
                            constraints: const BoxConstraints(minHeight: 54),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: raisedDecoration(
                              pressed: pressed,
                              radius: AppRadii.pill,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_exporting)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                const SizedBox(width: 6),
                                const Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Lưu / In PDF',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Pressable(
                          onTap: () => Navigator.of(context).pop(),
                          builder: (pressed) => Container(
                            constraints: const BoxConstraints(minHeight: 54),
                            alignment: Alignment.center,
                            decoration:
                                _primaryButtonDecoration(pressed: pressed),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
