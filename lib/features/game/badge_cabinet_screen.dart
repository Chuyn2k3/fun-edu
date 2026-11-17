import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/data/badges.dart';
import '../../game/data/game_repository.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import 'game_widgets.dart';

/// Earned badges and when.
final badgeDatesProvider =
    FutureProvider.autoDispose<Map<GameBadge, DateTime>>((ref) async {
  final repo = await ref.watch(gameRepositoryProvider.future);
  return repo.badgeDates();
});

/// "Tủ huy hiệu": the 8 badges. Earned ones in full colour with the day
/// they were earned; the others greyed with how to earn them.
class BadgeCabinetScreen extends ConsumerWidget {
  const BadgeCabinetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(badgeDatesProvider).valueOrNull;
    final ff = context.formFactor;
    final tablet = ff != FormFactor.phone;
    final columns = ff == FormFactor.tabletLandscape ? 4 : (tablet ? 3 : 2);
    final pad = tablet ? 32.0 : 16.0;
    return Scaffold(
      backgroundColor: GameColors.panelTop,
      body: GameBackdrop(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, tablet ? 24 : 14, pad, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          GameHeader(
                            title: 'Tủ huy hiệu',
                            onBack: () => context.go('/game'),
                          ),
                          SizedBox(height: tablet ? 16 : 10),
                          if (dates != null)
                            Text(
                              'Đã có ${dates.length}/${GameBadge.values.length} huy hiệu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: tablet ? 24 : 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                              ),
                            ),
                          SizedBox(height: tablet ? 20 : 14),
                        ],
                      ),
                    ),
                  ),
                  if (dates != null)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, 4, pad, pad + 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: tablet ? 26 : 18,
                          crossAxisSpacing: tablet ? 22 : 14,
                          childAspectRatio: tablet ? 0.8 : 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final b = GameBadge.values[i];
                            return _BadgeTile(
                              key: ValueKey('badge-${b.id}'),
                              badge: b,
                              earnedAt: dates[b],
                            );
                          },
                          childCount: GameBadge.values.length,
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
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({super.key, required this.badge, required this.earnedAt});

  final GameBadge badge;
  final DateTime? earnedAt;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final earned = earnedAt != null;
    final image = Image.asset(badge.image, fit: BoxFit.contain);
    return Semantics(
      container: true,
      label: earned
          ? 'Huy hiệu ${badge.title}, đạt ngày ${formatDay(earnedAt!)}'
          : 'Huy hiệu ${badge.title}, chưa đạt. ${badge.howTo}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, tablet ? 18 : 14, 12, 14),
        decoration: earned
            ? whiteChunkyDecoration(lip: 8)
            : BoxDecoration(
                color: GameColors.lockedFill,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(color: GameColors.lockedEdge, offset: Offset(0, 7)),
                ],
              ),
        child: Column(
          children: [
            Expanded(
              child: earned
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // A warm glow behind earned badges.
                        FractionallySizedBox(
                          widthFactor: 0.95,
                          heightFactor: 0.95,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                GameColors.planetHalo.withOpacity(0.55),
                                GameColors.planetHalo.withOpacity(0),
                              ]),
                            ),
                          ),
                        ),
                        image,
                      ],
                    )
                  : LockedLook(opacity: 0.45, child: image),
            ),
            SizedBox(height: tablet ? 10 : 8),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: tablet ? 21 : 16,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: earned ? GameColors.ink : GameColors.lockedInk,
              ),
            ),
            const SizedBox(height: 6),
            if (earned)
              TilePill(
                text: 'Đạt ngày ${formatDay(earnedAt!)}',
                icon: Icons.check_circle_rounded,
                color: GameColors.keyGreenTop,
                ink: GameColors.keyGreenInk,
                edge: GameColors.keyGreen,
              )
            else
              Text(
                badge.howTo,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tablet ? 16 : 13,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: GameColors.lockedInk,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
