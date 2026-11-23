import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/data/reward_pool.dart';
import '../../online/room/room_controller.dart';
import '../../online/sync/sync_engine.dart';
import '../../ui/assets.dart';
import '../../ui/theme/depth.dart';
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
        (room.phase == RoomPhase.error && room.error == 'network');

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
                        const SizedBox(height: 16),
                        for (final p in ranked) ...[
                          RoomPlayerTile(
                            player: p,
                            isYou: p.id == room.you,
                            isHost: false,
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
