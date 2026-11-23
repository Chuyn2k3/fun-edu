import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/engine/race_question.dart';
import '../../online/room/online_rival.dart';
import '../../online/room/room_controller.dart';
import '../../ui/assets.dart';
import '../../ui/feedback/feedback.dart';
import '../game/race_screen.dart';

/// `/game/room/race`: the usual race screen with the friends' rocket in
/// place of Chíp's. Handles friend disconnect toasts and self-reconnect banner.
class RoomRaceScreen extends ConsumerStatefulWidget {
  const RoomRaceScreen({super.key, required this.subject});

  final RaceSubject subject;

  @override
  ConsumerState<RoomRaceScreen> createState() => _RoomRaceScreenState();
}

class _RoomRaceScreenState extends ConsumerState<RoomRaceScreen> {
  late final RoomState _initial = ref.read(roomControllerProvider);
  late final OnlineRival _rival = OnlineRival(
    ref.read(roomControllerProvider.notifier),
    _initial,
  );
  late Map<String, RoomPlayer> _prevOthers = {
    for (final p in _initial.others) p.id: p,
  };

  @override
  void initState() {
    super.initState();
    ref.listenManual<RoomState>(roomControllerProvider, (_, next) {
      _rival.update(next);
      if (mounted) _emitFriendToasts(next);
    });
  }

  void _emitFriendToasts(RoomState next) {
    if (next.phase != RoomPhase.racing && next.phase != RoomPhase.done) {
      _prevOthers = {for (final p in next.others) p.id: p};
      return;
    }
    for (final p in next.others) {
      final prev = _prevOthers[p.id];
      if (prev == null) continue;
      if (!prev.away && p.away && !p.left) {
        showAppToast(
          context,
          '${p.name} bị mất mạng, đang chờ ${p.name} quay lại…',
          kind: AppToastKind.warning,
        );
      } else if (prev.away && !p.away && !p.left && p.connected) {
        showAppToast(
          context,
          '${p.name} đã quay lại!',
          kind: AppToastKind.success,
        );
      } else if (!prev.left && p.left) {
        showAppToast(
          context,
          '${p.name} đã rời trận',
          kind: AppToastKind.info,
        );
      }
    }
    _prevOthers = {for (final p in next.others) p.id: p};
  }

  @override
  void dispose() {
    _rival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reconnecting =
        ref.watch(roomControllerProvider.select((s) => s.reconnecting));

    return Stack(
      fit: StackFit.expand,
      children: [
        RaceScreen(
          subject: widget.subject,
          rival: _rival,
          inputLocked: reconnecting,
        ),
        if (reconnecting)
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 72),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppImages.chipEncourage,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: AppStatusBanner(
                        key: ValueKey('room-reconnecting-banner'),
                        kind: AppToastKind.offline,
                        text: 'Đang kết nối lại…',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
