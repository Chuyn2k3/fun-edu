import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/engine/race_question.dart';
import '../../game/scene/online_race_painter.dart'
    show roomRocketForIndex, roomRocketIds, safeOnlineAvatar;
import '../../game/scene/rocket_sprite.dart';
import '../../game/scene/smoke_particles.dart' show ParticleSprites;
import '../../online/room/room_controller.dart';
import '../../profile/kid_repository.dart';
import '../../ui/assets.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/pressable.dart';
import 'room_widgets.dart';

/// Which subject this kid answers in the online race (each kid picks their
/// own; questions follow each kid's level).
final roomSubjectProvider = StateProvider<RaceSubject>((_) => RaceSubject.toan);

/// Hook for `precacheImage` during the 3-2-1 countdown (overridden in tests).
final lobbyPrecacheImageProvider =
    Provider<Future<void> Function(ImageProvider<Object>, BuildContext)>(
  (_) => precacheImage,
);

/// Asset paths decoded ahead of entering [RoomRaceScreen] so the countdown-to-
/// race transition renders cleanly in <= 1 frame.
Set<String> lobbyRaceAssetsToPrecache(List<RoomPlayer> players) => {
      for (var i = 0; i < players.length; i++) ...[
        RocketSprite.forItem(
          players[i].rocket.isNotEmpty
              ? players[i].rocket
              : roomRocketForIndex(i),
        ).asset,
        safeOnlineAvatar(players[i].avatar, i),
      ],
      for (final r in roomRocketIds) RocketSprite.forItem(r).asset,
      AppImages.planet,
      AppImages.comet,
      AppImages.icStar,
      AppImages.icFlame,
      AppImages.chipMain,
      AppImages.chipJoy,
      AppImages.chipSurprise,
      AppImages.chipEncourage,
      for (final entry in roomStickerArt.values) entry.$1,
    };

/// `/game/room/lobby`: game-lobby waiting room with 4 player slots, presence
/// dots, room code, stickers, and the host's "Bắt đầu! 3 chặng".
class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  Timer? _tick;
  final Set<String> _precachedAssets = {};
  final Map<String, RoomSticker> _slotStickers = {};
  final Map<String, Timer> _slotStickerTimers = {};
  bool _inviteDialogOpen = false;

  void _syncCountdownTick(bool active) {
    if (!active) {
      _tick?.cancel();
      _tick = null;
      return;
    }
    _tick ??= Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted &&
          ref.read(roomControllerProvider).phase == RoomPhase.countdown) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final room = ref.read(roomControllerProvider);
    _syncCountdownTick(room.phase == RoomPhase.countdown);
    if (room.phase == RoomPhase.countdown) {
      _maybePrecacheRaceAssets(room);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final timer in _slotStickerTimers.values) {
      timer.cancel();
    }
    _slotStickerTimers.clear();
    super.dispose();
  }

  void _maybePrecacheRaceAssets(RoomState room) {
    if (!mounted || room.phase != RoomPhase.countdown) return;
    // Warm up the star/smoke sprite atlas before RaceScene mounts.
    ParticleSprites.image;

    final toLoad = lobbyRaceAssetsToPrecache(room.players)
        .difference(_precachedAssets);
    if (toLoad.isEmpty) return;
    _precachedAssets.addAll(toLoad);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final precache = ref.read(lobbyPrecacheImageProvider);
      for (final asset in toLoad) {
        unawaited(
          precache(AssetImage(asset), context).catchError((Object _) {}),
        );
      }
    });
  }

  void _onIncomingSticker(RoomSticker? s) {
    if (s == null) return;
    final teaseOn = ref.read(teaseStickersProvider).valueOrNull ?? true;
    if (isTeaseSticker(s.id) && !teaseOn) return;
    setState(() => _slotStickers[s.from] = s);
    _slotStickerTimers[s.from]?.cancel();
    late final Timer timer;
    timer = Timer(const Duration(seconds: 2), () {
      if (_slotStickerTimers[s.from] == timer) {
        _slotStickerTimers.remove(s.from);
      }
      if (!mounted) return;
      if (_slotStickers[s.from]?.seq == s.seq) {
        setState(() => _slotStickers.remove(s.from));
      }
    });
    _slotStickerTimers[s.from] = timer;
  }

  Future<void> _leave() async {
    await ref.read(roomControllerProvider.notifier).leave();
    if (mounted) context.go('/game');
  }

  void _copyCode(String code) {
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    showAppToast(context, 'Đã chép mã phòng', kind: AppToastKind.success);
  }

  Future<void> _showInviteCodeDialog(String code) async {
    final hasCode = code.isNotEmpty;
    _inviteDialogOpen = true;
    final bool? confirmed;
    try {
      confirmed = await showAppDialog<bool>(
        context,
        audience: AppAudience.kid,
        image: AppImages.chipMain,
        title: 'Mời bạn vào đua!',
        message: hasCode
            ? 'Đưa mã phòng này cho ba mẹ của bạn nhé:'
            : 'Đang lấy mã phòng…',
        body: hasCode
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: raisedDecoration(accent: AppColors.accent),
                child: Text(
                  code.split('').join(' '),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              )
            : null,
        primaryLabel: hasCode ? 'Chép mã' : 'Được rồi',
        secondaryLabel: hasCode ? 'Đóng' : null,
      );
    } finally {
      _inviteDialogOpen = false;
    }
    if (confirmed == true && hasCode && mounted) {
      _copyCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RoomState>(roomControllerProvider, (prev, next) {
      _syncCountdownTick(next.phase == RoomPhase.countdown);
      if (next.phase == RoomPhase.racing && mounted) {
        if (_inviteDialogOpen) {
          _inviteDialogOpen = false;
          Navigator.of(context, rootNavigator: true).maybePop();
        }
        context.go('/game/room/race', extra: ref.read(roomSubjectProvider));
        return;
      }
      if (next.phase == RoomPhase.countdown) {
        _maybePrecacheRaceAssets(next);
      }
      if (next.sticker?.seq != prev?.sticker?.seq) {
        _onIncomingSticker(next.sticker);
      }
    });

    final room = ref.watch(roomControllerProvider);
    final tablet = context.isTablet;

    if (room.phase == RoomPhase.error || room.phase == RoomPhase.idle) {
      return _Message(
        text: roomErrorText(room.error),
        onBack: () => context.go('/game'),
      );
    }

    final countdown = room.phase == RoomPhase.countdown && room.startsAt != null
        ? (room.startsAt!.difference(DateTime.now()).inMilliseconds / 1000)
            .ceil()
            .clamp(1, 9)
        : null;

    final code = room.code ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const LobbySpaceBackdrop(),
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: tablet ? 920 : 480),
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: tablet ? 24 : 12,
                          vertical: tablet ? 16 : 10,
                        ),
                        children: [
                          Row(
                            children: [
                              _BackButton(onTap: _leave),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _RoomHeaderPill(
                                  code: code,
                                  onCopy: code.isEmpty
                                      ? null
                                      : () => _copyCode(code),
                                ),
                              ),
                            ],
                          ),
                          if (room.reconnecting) ...[
                            const SizedBox(height: 10),
                            const AppStatusBanner(
                              key: ValueKey('room-reconnecting-banner'),
                              kind: AppToastKind.offline,
                              text: 'Đang kết nối lại…',
                            ),
                          ],
                          if (room.phase == RoomPhase.connecting) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: raisedDecoration(),
                              child: const Text(
                                'Đang vào phòng…',
                                textAlign: TextAlign.center,
                                style: _muted,
                              ),
                            ),
                          ],
                          SizedBox(height: tablet ? 16 : 12),
                          _LobbySlotsGrid(
                            room: room,
                            tablet: tablet,
                            slotStickers: _slotStickers,
                            onInvite: () => _showInviteCodeDialog(code),
                          ),
                          SizedBox(height: tablet ? 16 : 12),
                          Container(
                            padding: EdgeInsets.all(tablet ? 18 : 14),
                            decoration: raisedDecoration(
                              tint: GameColors.cockpitBg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Bé đua môn', style: _label),
                                const SizedBox(height: 8),
                                const _SubjectPicker(),
                                SizedBox(height: tablet ? 14 : 10),
                                const StickerBar(),
                                SizedBox(height: tablet ? 16 : 12),
                                if (room.isHost)
                                  RoomBigButton(
                                    key: const ValueKey('room-start'),
                                    label: 'Bắt đầu! 3 chặng',
                                    onTap: room.phase == RoomPhase.lobby &&
                                            room.connectedCount >= 2
                                        ? () => ref
                                            .read(
                                                roomControllerProvider.notifier)
                                            .start()
                                        : null,
                                  )
                                else
                                  const Text(
                                    'Chờ chủ phòng bắt đầu nhé!',
                                    textAlign: TextAlign.center,
                                    style: _label,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(child: StickerToast()),
                  ),
                  if (countdown != null)
                    Positioned.fill(
                      child: ColoredBox(
                        color: GameColors.spaceTop.withOpacity(0.75),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$countdown',
                                key: const ValueKey('room-countdown'),
                                style: TextStyle(
                                  fontSize: tablet ? 160 : 132,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.card,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chuẩn bị cất cánh!',
                                style: TextStyle(
                                  fontSize: tablet ? 28 : 22,
                                  fontWeight: FontWeight.w900,
                                  color: GameColors.starWarm,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _muted = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
  );
  static const _label = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );
}

class _RoomHeaderPill extends StatelessWidget {
  const _RoomHeaderPill({required this.code, required this.onCopy});

  final String code;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final title = code.isEmpty ? 'Phòng đua' : 'Phòng $code';
    return Pressable(
      key: const ValueKey('room-copy-code'),
      semanticsLabel:
          code.isEmpty ? 'Phòng đua' : 'Phòng $code, chạm để chép mã',
      onTap: onCopy,
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: tablet ? 80 : 64),
        padding: EdgeInsets.symmetric(
          horizontal: tablet ? 20 : 14,
          vertical: 8,
        ),
        decoration: raisedDecoration(
          accent: AppColors.accent,
          pressed: pressed,
        ),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  key: const ValueKey('room-code-text'),
                  style: TextStyle(
                    fontSize: tablet ? 32 : 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tablet ? 14 : 10,
                  vertical: tablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: Subject.viet.tint,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: tablet ? 22 : 18,
                      color: AppColors.primaryOnTint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Chép mã',
                      style: TextStyle(
                        fontSize: tablet ? 16 : 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryOnTint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LobbySlotsGrid extends StatelessWidget {
  const _LobbySlotsGrid({
    required this.room,
    required this.tablet,
    required this.slotStickers,
    required this.onInvite,
  });

  final RoomState room;
  final bool tablet;
  final Map<String, RoomSticker> slotStickers;
  final VoidCallback onInvite;

  Widget _slot(int i) {
    if (i < room.players.length) {
      final p = room.players[i];
      return LobbyPlayerSlot(
        player: p,
        slotIndex: i,
        isYou: p.id == room.you,
        isHost: p.id == room.host,
        receivedSticker: slotStickers[p.id],
      );
    }
    return LobbyEmptySlot(slotIndex: i, onTap: onInvite);
  }

  @override
  Widget build(BuildContext context) {
    if (tablet) {
      return KeyedSubtree(
        key: const ValueKey('lobby-slots-4x1'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _slot(i)),
              ],
            ],
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('lobby-slots-2x2'),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _slot(0)),
                const SizedBox(width: 10),
                Expanded(child: _slot(1)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _slot(2)),
                const SizedBox(width: 10),
                Expanded(child: _slot(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectPicker extends ConsumerWidget {
  const _SubjectPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(roomSubjectProvider);
    final tablet = context.isTablet;
    Widget option(RaceSubject s, String label) => Expanded(
          child: Pressable(
            key: ValueKey('room-subject-${s.name}'),
            semanticsLabel: label,
            onTap: () => ref.read(roomSubjectProvider.notifier).state = s,
            builder: (pressed) => Container(
              constraints: BoxConstraints(minHeight: tablet ? 80 : 64),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: raisedDecoration(
                accent: current == s ? AppColors.primary : AppDepth.neutral,
                pressed: pressed || current == s,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: tablet ? 24 : 20,
                    fontWeight: FontWeight.w900,
                    color:
                        current == s ? AppColors.primaryOnTint : AppColors.text,
                  ),
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        option(RaceSubject.toan, 'Toán'),
        const SizedBox(width: 10),
        option(RaceSubject.tiengViet, 'Tiếng Việt'),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = context.isTablet ? 80.0 : 64.0;
    return Pressable(
      onTap: onTap,
      semanticsLabel: 'Rời phòng',
      builder: (pressed) => Container(
        width: size,
        height: size,
        decoration: raisedDecoration(pressed: pressed),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 32,
          color: AppColors.text,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onBack});

  final String text;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    key: const ValueKey('room-message'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RoomBigButton(label: 'Về Góc Chơi', onTap: onBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
