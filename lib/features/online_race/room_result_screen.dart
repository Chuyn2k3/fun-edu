import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/data/reward_pool.dart';
import '../../online/friends/friends_controller.dart';
import '../../online/friends/showcase.dart';
import '../../online/room/room_controller.dart';
import '../../online/sync/sync_engine.dart';
import '../../profile/avatars.dart';
import '../../ui/assets.dart';
import '../../ui/theme/depth.dart';
import '../../ui/widgets/pressable.dart';
import '../collection/showcase_screen.dart';
import '../game/badge_popup.dart';
import '../game/race_controller.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import 'room_widgets.dart';

/// `/game/room/result`: who landed first. Updates live while the others are
/// still racing; the host can start another race in the same room.
class RoomResultScreen extends ConsumerStatefulWidget {
  const RoomResultScreen({super.key, this.rewards});

  /// What this race gave the kid (stars, badges, rare sticker); null when
  /// opened without one (e.g. after "Đua lại!" round trips).
  final RaceResultArgs? rewards;

  @override
  ConsumerState<RoomResultScreen> createState() => _RoomResultScreenState();
}

class _RoomResultScreenState extends ConsumerState<RoomResultScreen> {
  @override
  void initState() {
    super.initState();
    final lost = widget.rewards?.networkLost ?? false;
    if (!lost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(syncControllerProvider.notifier).requestSync();
        ref.read(showcaseSyncProvider).request();
      });
    }
    final badges = widget.rewards?.onlineRecord?.newBadges ?? const [];
    if (badges.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        for (final b in badges) {
          if (!mounted) return;
          await showBadgePopup(context, b);
        }
      });
    }
  }

  String _rankLabel(RoomPlayer p) => switch (p.rank) {
        1 => 'Về nhất',
        2 => 'Về nhì',
        3 => 'Về ba',
        4 => 'Về tư',
        _ => p.left ? 'Rời trận' : 'Đang bay…',
      };

  void _openShowcase(RoomPlayer p, String? you) {
    if (p.id == you) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ShowcaseScreen(isOwn: true),
        ),
      );
      return;
    }
    final friends = ref.read(friendsProvider).valueOrNull ?? const [];
    String? familyId;
    for (final f in friends) {
      for (final k in f.kids) {
        if (k.kidUuid == p.id) {
          familyId = f.familyId;
          break;
        }
      }
      if (familyId != null) break;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShowcaseScreen(
          familyId: familyId,
          kidUuid: p.id,
        ),
      ),
    );
  }

  Future<void> _leave(BuildContext context) async {
    await ref.read(roomControllerProvider.notifier).leave();
    if (context.mounted) context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomControllerProvider.select((s) => s.phase), (_, phase) {
      if (phase == RoomPhase.lobby) context.go('/game/room/lobby');
    });
    final room = ref.watch(roomControllerProvider);
    final tablet = context.isTablet;
    final networkLost = (widget.rewards?.networkLost ?? false) ||
        (room.phase == RoomPhase.error &&
            (room.error == 'network' || room.error == 'server_unreachable'));

    if (networkLost) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave(context);
        },
        child: Scaffold(
          body: DottedBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tablet ? 560 : 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppImages.chipEncourage,
                          width: tablet ? 180 : 140,
                          height: tablet ? 180 : 140,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mạng chập chờn mất rồi, mình đua lại sau nhé!',
                          key: const ValueKey('room-network-lost'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: tablet ? 30 : 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 24),
                        RoomBigButton(
                          key: const ValueKey('room-leave'),
                          label: 'Về Góc Chơi',
                          onTap: () => _leave(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final ranked = [...room.players]..sort((a, b) {
        final ar = a.rank ?? 99, br = b.rank ?? 99;
        return ar != br ? ar - br : b.steps - a.steps;
      });
    final me = room.me;
    final myRank = me?.rank ?? widget.rewards?.rank;
    final endReason = widget.rewards?.endReason ?? room.endReason;
    final String title;
    if (endReason == 'others_left') {
      title = switch (myRank) {
        2 => 'Các bạn đã rời trận, bé về nhì!',
        3 => 'Các bạn đã rời trận, bé về ba!',
        _ => 'Các bạn đã rời trận, con thắng rồi!',
      };
    } else {
      title = switch (myRank) {
        1 => 'Bé về nhất!',
        null => 'Cố lên nào!',
        _ => 'Giỏi lắm!',
      };
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        body: DottedBackground(
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tablet ? 720 : 480),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          title,
                          key: const ValueKey('room-result-title'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: tablet ? 44 : 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        if (widget.rewards?.onlineRecord case final r?) ...[
                          const SizedBox(height: 12),
                          _RewardRow(stars: r.starsEarned),
                          if (r.rareSticker case final rare?) ...[
                            const SizedBox(height: 12),
                            _RareStickerCard(id: rare),
                          ],
                          if (r.milestonesCrossed.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Có quà mới ở Xưởng độ!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryOnTint,
                              ),
                            ),
                          ],
                        ],
                        if (ranked.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ResultPodium(
                            ranked: ranked,
                            you: room.you,
                            tablet: tablet,
                            onTap: (p) => _openShowcase(p, room.you),
                          ),
                        ],
                        const SizedBox(height: 16),
                        for (final p in ranked) ...[
                          RoomPlayerTile(
                            player: p,
                            isYou: p.id == room.you,
                            isHost: false,
                            onTap: () => _openShowcase(p, room.you),
                            trailing: Text(
                              _rankLabel(p),
                              style: TextStyle(
                                fontSize: tablet ? 22 : 18,
                                fontWeight: FontWeight.w900,
                                color: p.rank == 1 ? AppColors.primaryOnTint : AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        const StickerBar(),
                        const SizedBox(height: 16),
                        if (room.phase == RoomPhase.done && room.isHost)
                          RoomBigButton(
                            key: const ValueKey('room-again'),
                            label: 'Đua lại!',
                            onTap: () => ref.read(roomControllerProvider.notifier).again(),
                          )
                        else
                          Text(
                            room.phase == RoomPhase.done
                                ? 'Chờ chủ phòng cho đua lại nhé!'
                                : 'Chờ các bạn về đích…',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                            ),
                          ),
                        const SizedBox(height: 12),
                        RoomBigButton(
                          key: const ValueKey('room-leave'),
                          label: 'Về Góc Chơi',
                          onTap: () => _leave(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(top: 80, left: 0, right: 0, child: Center(child: StickerToast())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Container(
      key: const ValueKey('room-reward'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: raisedDecoration(accent: AppColors.accent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppImages.icStar, width: tablet ? 44 : 36, height: tablet ? 44 : 36),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '+$stars sao vũ trụ',
              style: TextStyle(
                fontSize: tablet ? 28 : 22,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Sticker hiếm!": the rare sticker this race dropped, gold-framed.
class _RareStickerCard extends StatelessWidget {
  const _RareStickerCard({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final size = tablet ? 120.0 : 96.0;
    return Container(
      key: const ValueKey('room-rare-sticker'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.rareGoldTint,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: GameColors.rareGold, width: 4),
        boxShadow: [
          BoxShadow(color: GameColors.rareGold.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Image.asset(AppImages.stickers[id] ?? AppImages.chipMain, width: size, height: size),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sticker hiếm!',
                  style: TextStyle(
                    fontSize: tablet ? 28 : 22,
                    fontWeight: FontWeight.w900,
                    color: GameColors.rareInk,
                  ),
                ),
                Text(
                  rareStickerTitles[id] ?? '',
                  style: TextStyle(
                    fontSize: tablet ? 20 : 17,
                    fontWeight: FontWeight.w800,
                    color: GameColors.rareInk,
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

class _ResultPodium extends StatelessWidget {
  const _ResultPodium({
    required this.ranked,
    required this.you,
    required this.tablet,
    this.onTap,
  });

  final List<RoomPlayer> ranked;
  final String? you;
  final bool tablet;
  final void Function(RoomPlayer player)? onTap;

  @override
  Widget build(BuildContext context) {
    final top = ranked.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    // Order left-to-right: 2nd, 1st, 3rd (or 2nd, 1st when 2 players).
    final entries = <(int index, RoomPlayer player, int place)>[
      for (var i = 0; i < top.length; i++)
        (i, top[i], top[i].rank ?? (i + 1)),
    ];
    final ordered = switch (entries.length) {
      1 => [entries[0]],
      2 => [entries[1], entries[0]],
      _ => [entries[1], entries[0], entries[2]],
    };

    return Container(
      key: const ValueKey('room-result-podium'),
      padding: EdgeInsets.fromLTRB(
        tablet ? 20 : 10,
        tablet ? 16 : 12,
        tablet ? 20 : 10,
        tablet ? 16 : 12,
      ),
      decoration: raisedDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < ordered.length; i++) ...[
            if (i > 0) SizedBox(width: tablet ? 12 : 6),
            Expanded(
              child: _PodiumColumn(
                index: ordered[i].$1,
                player: ordered[i].$2,
                place: ordered[i].$3,
                isYou: ordered[i].$2.id == you,
                tablet: tablet,
                onTap: onTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.index,
    required this.player,
    required this.place,
    required this.isYou,
    required this.tablet,
    this.onTap,
  });

  final int index;
  final RoomPlayer player;
  final int place;
  final bool isYou;
  final bool tablet;
  final void Function(RoomPlayer player)? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color fill, Color ink, double pedestalH) =
        switch (place) {
      1 => (
          GameColors.rareGold,
          GameColors.rareGoldTint,
          GameColors.rareInk,
          tablet ? 82.0 : 60.0,
        ),
      2 => (
          GameColors.podiumSilver,
          GameColors.podiumSilverTint,
          AppColors.text,
          tablet ? 60.0 : 44.0,
        ),
      _ => (
          GameColors.podiumBronze,
          GameColors.podiumBronzeTint,
          GameColors.keyOrangeInk,
          tablet ? 44.0 : 32.0,
        ),
    };
    final avatar = kidAvatars.contains(player.avatar)
        ? player.avatar
        : kidAvatars[index % kidAvatars.length];
    final avatarSize =
        place == 1 ? (tablet ? 72.0 : 54.0) : (tablet ? 60.0 : 44.0);
    final name = player.name.isEmpty ? 'Bạn ${index + 1}' : player.name;

    final content = Column(
      key: ValueKey('podium-rank-$place'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (place == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Image.asset(
              AppImages.icCrown,
              width: tablet ? 30 : 24,
              height: tablet ? 30 : 24,
              fit: BoxFit.contain,
            ),
          ),
        Container(
          width: avatarSize,
          height: avatarSize,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card,
            border: Border.all(color: border, width: place == 1 ? 3.5 : 2.5),
          ),
          child: ClipOval(
            child: Image.asset(avatar, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isYou ? '$name (bé)' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: tablet ? 17 : 13,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: pedestalH,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
              bottom: Radius.circular(8),
            ),
            border: Border.all(color: border, width: 2),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 12 : 9,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: border, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              '#$place',
              style: TextStyle(
                fontSize: tablet ? 17 : 13,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return Pressable(
      key: ValueKey('podium-tap-$place'),
      semanticsLabel: isYou ? '$name (bé)' : name,
      onTap: () => onTap!(player),
      builder: (_) => content,
    );
  }
}
