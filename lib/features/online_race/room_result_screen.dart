import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../online/room/room_controller.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import 'room_widgets.dart';

/// `/game/room/result`: who landed first. Updates live while the others are
/// still racing; the host can start another race in the same room.
class RoomResultScreen extends ConsumerWidget {
  const RoomResultScreen({super.key});

  static String _rankLabel(int? rank) => switch (rank) {
        1 => 'Về nhất',
        2 => 'Về nhì',
        3 => 'Về ba',
        4 => 'Về tư',
        _ => 'Đang bay…',
      };

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    await ref.read(roomControllerProvider.notifier).leave();
    if (context.mounted) context.go('/game');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(roomControllerProvider.select((s) => s.phase), (_, phase) {
      if (phase == RoomPhase.lobby) context.go('/game/room/lobby');
    });
    final room = ref.watch(roomControllerProvider);
    final tablet = context.isTablet;
    final ranked = [...room.players]..sort((a, b) {
        final ar = a.rank ?? 99, br = b.rank ?? 99;
        return ar != br ? ar - br : b.steps - a.steps;
      });
    final me = room.me;
    final title = switch (me?.rank) {
      1 => 'Bé về nhất!',
      null => 'Cố lên nào!',
      _ => 'Giỏi lắm!',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context, ref);
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
                        const SizedBox(height: 16),
                        for (final p in ranked) ...[
                          RoomPlayerTile(
                            player: p,
                            isYou: p.id == room.you,
                            isHost: false,
                            trailing: Text(
                              _rankLabel(p.rank),
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
                          onTap: () => _leave(context, ref),
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
