import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/data/badges.dart';
import '../../game/data/game_repository.dart';
import '../../game/data/reward_pool.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import 'game_widgets.dart';

/// One Chíp Chíp sticker: from a milestone gift ([badge] null) or given
/// with a badge.
class StickerInfo {
  const StickerInfo(this.id, this.title, {this.badge, this.rare = false});

  final String id;
  final String title;
  final GameBadge? badge;

  /// A rare sticker (gold frame): a lucky drop from races with friends.
  final bool rare;
}

/// Every sticker, gifts first (pool order), then one per badge.
final List<StickerInfo> stickerCatalogue = [
  for (final id in rewardPool)
    if (id.startsWith('sticker_'))
      StickerInfo(id, itemTitle(id).replaceFirst('Sticker ', '')),
  for (final b in GameBadge.values)
    StickerInfo(b.stickerId, _badgeStickerTitles[b]!, badge: b),
  for (final id in rareStickers)
    StickerInfo(id, rareStickerTitles[id]!, rare: true),
];

const _badgeStickerTitles = {
  GameBadge.speedKing: 'Chíp đeo kính phi công',
  GameBadge.scholar: 'Chíp đội mũ tốt nghiệp',
  GameBadge.cometHunter: 'Chíp ôm ngôi sao',
  GameBadge.neverGiveUp: 'Chíp giơ nắm tay cố lên',
  GameBadge.chipBuddy: 'Chíp ôm tim',
  GameBadge.mathWhiz: 'Chíp cầm bàn tính',
  GameBadge.letterMaster: 'Chíp cầm bút sáp',
  GameBadge.pilot: 'Chíp vẫy tay trên tên lửa',
  GameBadge.friendRacer: 'Chíp giơ ngón cái',
  GameBadge.friendChampion: 'Chíp vui mừng',
  GameBadge.bigRace: 'Chíp ngạc nhiên',
  GameBadge.cheerleader: 'Chíp cổ vũ',
};

/// Sticker ids the kid has: gift stickers owned, plus one per badge earned.
Set<String> ownedStickers(Set<String> owned, Set<GameBadge> badges) => {
      for (final s in stickerCatalogue)
        if (owned.contains(s.id) || badges.contains(s.badge)) s.id,
    };

class StickerAlbumData {
  const StickerAlbumData({
    required this.owned,
    required this.items,
    required this.stars,
  });

  final Set<String> owned;

  /// Owned garage/gift items (for "Còn N sao vũ trụ").
  final Set<String> items;
  final int stars;
}

final stickerAlbumProvider =
    FutureProvider.autoDispose<StickerAlbumData>((ref) async {
  ref.watch(gameDataRevisionProvider);
  final repo = await ref.watch(gameRepositoryProvider.future);
  final items = await repo.owned();
  return StickerAlbumData(
    owned: ownedStickers(items, await repo.badges()),
    items: items,
    stars: await repo.totalStars(),
  );
});

/// "Album sticker": every Chíp Chíp sticker; the ones the kid does not have
/// yet are flat silhouettes with how to get them.
class StickerAlbumScreen extends ConsumerWidget {
  const StickerAlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(stickerAlbumProvider).valueOrNull;
    final ff = context.formFactor;
    final tablet = ff != FormFactor.phone;
    final columns = switch (ff) {
      FormFactor.phone => 2,
      FormFactor.tabletPortrait => 3,
      FormFactor.tabletLandscape => 5,
    };
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
                            title: 'Album sticker',
                            onBack: () => context.go('/game'),
                          ),
                          SizedBox(height: tablet ? 16 : 10),
                          if (data != null)
                            Text(
                              'Đã có ${data.owned.length}/${stickerCatalogue.length} sticker',
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
                  if (data != null)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(pad, 4, pad, pad + 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: tablet ? 26 : 18,
                          crossAxisSpacing: tablet ? 22 : 14,
                          childAspectRatio: tablet ? 0.86 : 0.82,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final s = stickerCatalogue[i];
                            return _StickerTile(
                              key: ValueKey('sticker-${s.id}'),
                              sticker: s,
                              owned: data.owned.contains(s.id),
                              howTo: _howTo(s, data),
                            );
                          },
                          childCount: stickerCatalogue.length,
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

  static String _howTo(StickerInfo s, StickerAlbumData d) {
    final b = s.badge;
    if (b != null) return 'Huy hiệu ${b.title}';
    if (s.rare) return 'Hiếm: có thể nhận khi đua với bạn';
    final left = starsUntilOffered(s.id, owned: d.items, stars: d.stars);
    if (left == null) return 'Quà sao vũ trụ';
    return left == 0 ? 'Quà đang chờ bé!' : 'Còn $left sao vũ trụ';
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({
    super.key,
    required this.sticker,
    required this.owned,
    required this.howTo,
  });

  final StickerInfo sticker;
  final bool owned;
  final String howTo;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final art = Image.asset(
      AppImages.stickers[sticker.id] ?? AppImages.chipMain,
      fit: BoxFit.contain,
    );
    return Semantics(
      container: true,
      label: owned
          ? 'Sticker ${sticker.title}'
          : 'Sticker ${sticker.title}, chưa có. $howTo',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, tablet ? 16 : 12, 10, 12),
        decoration: owned && sticker.rare
            ? BoxDecoration(
                color: GameColors.rareGoldTint,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: GameColors.rareGold, width: 4),
                boxShadow: const [
                  BoxShadow(color: GameColors.rareGold, offset: Offset(0, 7)),
                ],
              )
            : owned
                ? whiteChunkyDecoration(lip: 7)
                : BoxDecoration(
                    color: GameColors.lockedFill,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                          color: GameColors.lockedEdge, offset: Offset(0, 7)),
                    ],
                  ),
        child: Column(
          children: [
            Expanded(
              child: owned
                  // A die-cut sticker: white border ring around the art.
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GameColors.keyOrangeTop.withOpacity(0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 4),
                      ),
                      child: art,
                    )
                  : Silhouette(child: art),
            ),
            SizedBox(height: tablet ? 10 : 8),
            Text(
              sticker.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: tablet ? 19 : 15,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: owned
                    ? (sticker.rare ? GameColors.rareInk : GameColors.ink)
                    : GameColors.lockedInk,
              ),
            ),
            if (owned && sticker.rare)
              Text(
                'Hiếm',
                style: TextStyle(
                  fontSize: tablet ? 16 : 13,
                  fontWeight: FontWeight.w900,
                  color: GameColors.rareInk,
                ),
              ),
            if (!owned) ...[
              const SizedBox(height: 6),
              TilePill(text: howTo, icon: Icons.lock_rounded, maxLines: 2),
            ],
          ],
        ),
      ),
    );
  }
}
