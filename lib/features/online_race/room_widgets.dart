import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/game_repository.dart';
import '../../online/room/room_controller.dart';
import '../../profile/avatars.dart';
import '../../profile/kid_repository.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';

/// Per-kid "biệt danh đua" (race nickname) set by a parent; the nickname
/// otherwise. Synced like the other per-kid settings.
String raceNicknameKey(int kidId) => 'raceNickname.$kidId';
const int raceNicknameMax = 16;

/// The current kid as the room shows them.
Future<RoomKid?> currentRoomKid(WidgetRef ref) async {
  final repo = ref.read(kidRepositoryProvider);
  final id = await repo.currentKidId();
  final kid = (await repo.kids()).where((k) => k.id == id).firstOrNull;
  if (kid == null || kid.uuid == null) return null;
  final nick = (await repo.setting(raceNicknameKey(kid.id)))?.trim();
  String rocket = 'rocket_orange';
  try {
    rocket = (await (await ref.read(gameRepositoryProvider.future)).selected()).rocket;
  } catch (_) {}
  return RoomKid(
    uuid: kid.uuid!,
    name: nick == null || nick.isEmpty ? kid.nickname : nick,
    avatar: kid.avatar,
    rocket: rocket,
  );
}

/// Sticker id -> (Chíp sticker art, caption).
const roomStickerArt = <String, (String, String)>{
  'cheer': (AppImages.stickerFist, 'Cố lên!'),
  'wow': (AppImages.stickerLaugh, 'Hihi!'),
  'love': (AppImages.stickerHugHeart, 'Thương!'),
  'fast': (AppImages.stickerPilotGoggles, 'Nhanh quá!'),
  'hi': (AppImages.stickerWaveRocket, 'Chào bạn!'),
  'gg': (AppImages.stickerClap, 'Giỏi lắm!'),
};

String roomErrorText(String? code) => switch (code) {
      'not_found' => 'Không tìm thấy phòng. Ba mẹ kiểm tra lại mã nhé',
      'room_full' => 'Phòng đã đủ 4 bạn rồi',
      'started' => 'Các bạn đã bắt đầu đua mất rồi',
      'expired' => 'Phòng đã hết hạn, ba mẹ tạo phòng mới nhé',
      'too_many' => 'Thử nhiều lần quá, đợi một chút rồi thử lại nhé',
      'signed_out' => 'Ba mẹ cần đăng nhập lại Tài khoản gia đình',
      'need_two' => 'Cần ít nhất 2 bạn để bắt đầu',
      'not_host' => 'Chủ phòng sẽ bắt đầu nhé',
      'server_unreachable' => 'Không kết nối được tới máy chủ FunEdu. Thử lại sau nhé',
      'network' => 'Không có kết nối mạng. Kiểm tra lại Wi-Fi hoặc 4G nhé',
      _ => 'Mất kết nối. Kiểm tra mạng rồi thử lại nhé',
    };

/// A kid in the room: avatar, name, waiting / left marker.
class RoomPlayerTile extends StatelessWidget {
  const RoomPlayerTile({
    super.key,
    required this.player,
    required this.isYou,
    required this.isHost,
    this.trailing,
  });

  final RoomPlayer player;
  final bool isYou;
  final bool isHost;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final avatar = kidAvatars.contains(player.avatar) ? player.avatar : kidAvatars[1];
    final faded = !player.connected || player.away || player.left;
    String? subtitle;
    if (player.left) {
      subtitle = 'Đã rời trận';
    } else if (player.away || !player.connected) {
      subtitle = player.awayMsLeft != null
          ? 'Đang kết nối lại… (${(player.awayMsLeft! / 1000).ceil()}s)'
          : 'Đang kết nối lại…';
    } else if (isHost) {
      subtitle = 'Chủ phòng';
    }
    return Container(
      constraints: BoxConstraints(minHeight: tablet ? 88 : 72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: raisedDecoration(),
      child: Row(
        children: [
          Opacity(
            opacity: faded ? 0.4 : 1,
            child: Image.asset(avatar, width: tablet ? 64 : 52, height: tablet ? 64 : 52),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '${player.name} (bé)' : player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tablet ? 24 : 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: tablet ? 17 : 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Six Chíp stickers to cheer friends on (no free text).
class StickerBar extends ConsumerWidget {
  const StickerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = context.isTablet ? 80.0 : 64.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in roomStickerArt.entries)
          Pressable(
            key: ValueKey('sticker-${e.key}'),
            semanticsLabel: 'Gửi sticker ${e.value.$2}',
            onTap: () => ref.read(roomControllerProvider.notifier).sticker(e.key),
            builder: (pressed) => Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(6),
              decoration: raisedDecoration(pressed: pressed),
              child: Image.asset(e.value.$1, fit: BoxFit.contain),
            ),
          ),
      ],
    );
  }
}

/// Shows the last sticker a kid received for two seconds.
class StickerToast extends ConsumerStatefulWidget {
  const StickerToast({super.key});

  @override
  ConsumerState<StickerToast> createState() => _StickerToastState();
}

class _StickerToastState extends ConsumerState<StickerToast> {
  RoomSticker? _shown;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomControllerProvider.select((s) => s.sticker), (_, s) {
      if (s == null) return;
      setState(() => _shown = s);
      _hide?.cancel();
      _hide = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _shown = null);
      });
    });
    final s = _shown;
    final art = s == null ? null : roomStickerArt[s.id];
    if (s == null || art == null) return const SizedBox.shrink();
    final room = ref.read(roomControllerProvider);
    final from = room.players.where((p) => p.id == s.from).firstOrNull?.name ?? '';
    final size = context.isTablet ? 120.0 : 96.0;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: raisedDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(art.$1, width: size, height: size),
            Text(
              from.isEmpty ? art.$2 : '$from: ${art.$2}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big orange kid button (≥ 64, ≥ 80 on tablets).
class RoomBigButton extends StatelessWidget {
  const RoomBigButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    return Pressable(
      onTap: onTap,
      semanticsLabel: label,
      builder: (pressed) => Container(
        constraints: BoxConstraints(minHeight: tablet ? 80 : 64),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: raisedDecoration(
          accent: AppColors.primary,
          tint: onTap == null ? AppColors.dot : AppColors.card,
          pressed: pressed,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: tablet ? 28 : 22,
            fontWeight: FontWeight.w900,
            color: onTap == null ? AppColors.textMuted : AppColors.primaryOnTint,
          ),
        ),
      ),
    );
  }
}
