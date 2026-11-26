import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../explore/explore_flags.dart';
import '../../progress/level_repository.dart';
import '../../ui/assets.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';

const _contentMaxWidth = 560.0;
const _tabletMaxWidth = 1000.0;

/// Explore island hall: geography is open, biology and history come later.
class ExploreHubScreen extends ConsumerWidget {
  const ExploreHubScreen({super.key});

  void _soon(BuildContext context) =>
      showAppToast(context, 'Sắp có', kind: AppToastKind.info);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablet = context.isTablet;

    final cards = [
      for (final island in ref.watch(exploreIslandsProvider))
        if (ref.watch(exploreReadyProvider(island.id)))
          _IslandCard(
            key: ValueKey('island-${island.id}'),
            image: island.islandImage,
            title: island.name,
            subtitle: island.mapTitle,
            badge: switch (ref
                .watch(exploreLevelIndexProvider(island.id))
                .valueOrNull) {
              null => '',
              final l => '${l + 1}/${island.levels.length}',
            },
            tablet: tablet,
            onTap: () => context.push('/subject/${island.id}'),
          )
        else
          _IslandCard(
            key: ValueKey('island-${island.id}'),
            image: island.islandImage,
            title: island.name,
            subtitle: 'Sắp có',
            tablet: tablet,
            onTap: () => _soon(context),
          ),
      _IslandCard(
        key: const ValueKey('island-lich-su'),
        image: AppImages.islandLichSu,
        title: 'Lịch sử',
        subtitle: 'Sắp có',
        tablet: tablet,
        onTap: () => _soon(context),
      ),
    ];

    final backSize = tablet ? TabletSizes.kidTarget : 64.0;
    final header = SizedBox(
      height: tablet ? 96 : 72,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Pressable(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/'),
            semanticsLabel: 'Quay lại',
            builder: (pressed) => Container(
              width: backSize,
              height: backSize,
              decoration: raisedDecoration(
                  radius: backSize / 2, pressed: pressed),
              child: Icon(Icons.chevron_left_rounded,
                  size: tablet ? 44 : 36, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Đảo Khám phá',
                style: TextStyle(
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
    );

    final Widget list = tablet
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 20),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => cards[i],
          );

    final body = Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: tablet ? _tabletMaxWidth : _contentMaxWidth),
              child: Column(
                children: [
                  header,
                  Expanded(
                    child: tablet ? SingleChildScrollView(child: list) : list,
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

class _IslandCard extends StatelessWidget {
  const _IslandCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.tablet,
    required this.onTap,
    this.badge,
  });

  final String image;
  final String title;
  final String subtitle;
  final String? badge;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = badge != null;
    final accent = open ? Subject.diaLy.color : AppColors.textMuted;
    final imageSize = tablet ? 160.0 : 88.0;
    final art = Image.asset(
      image,
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: imageSize,
        height: imageSize,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Subject.diaLy.tint,
          borderRadius: BorderRadius.circular(AppRadii.tile),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Subject.diaLy.color,
            ),
          ),
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment:
          tablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: tablet ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: tablet ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: open ? AppColors.text : AppColors.textMuted,
          ),
        ),
        if (badge != null && badge!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            badge!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ],
    );
    return Pressable(
      onTap: onTap,
      semanticsLabel: '$title. $subtitle',
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: tablet ? 260 : 112),
        padding: const EdgeInsets.all(14),
        decoration: raisedDecoration(
          accent: accent,
          tint: open ? Subject.diaLy.tint : AppDepth.neutralTint,
          radius: AppRadii.card,
          pressed: pressed,
        ),
        child: tablet
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [art, const SizedBox(height: 12), text],
              )
            : Row(
                children: [
                  art,
                  const SizedBox(width: 14),
                  Expanded(child: text),
                ],
              ),
      ),
    );
  }
}
