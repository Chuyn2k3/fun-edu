import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/game_repository.dart';
import '../../game/scene/online_race_painter.dart'
    show roomRocketForIndex, safeOnlineAvatar;
import '../../game/scene/rocket_sprite.dart';
import '../../game/scene/space_track.dart'
    show SceneClock, SkyMotionPainter, TrackGeometry;
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
  'love': (AppImages.stickerHugHeart, 'Thương!'),
  'party': (AppImages.stickerParty, 'Chúc mừng!'),
  'bubble': (AppImages.stickerTeaseBubble, 'Bong bóng!'),
  'tongue': (AppImages.stickerTeaseTongue, 'Lè lưỡi!'),
  'byebye': (AppImages.stickerTeaseByebye, 'Bái bai!'),
  'rain': (AppImages.stickerTeaseRain, 'Mưa rơi!'),
  'sleepy': (AppImages.stickerTeaseSleepy, 'Buồn ngủ!'),
  'turtle': (AppImages.stickerTeaseTurtle, 'Rùa bò!'),
  'smoke': (AppImages.stickerTeaseSmoke, 'Xịt khói!'),
  'wow': (AppImages.stickerLaugh, 'Hihi!'),
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

/// Shared raised button displaying an image sticker.
class StickerImageTile extends StatelessWidget {
  const StickerImageTile({
    super.key,
    required this.tileKey,
    required this.size,
    required this.asset,
    required this.label,
    required this.locked,
    required this.onTap,
  });

  final Key tileKey;
  final double size;
  final String asset;
  final String label;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: tileKey,
      semanticsLabel: 'Gửi sticker $label',
      onTap: locked ? null : onTap,
      builder: (pressed) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(6),
        decoration: raisedDecoration(
          tint: locked ? GameColors.lockedFill : AppColors.card,
          pressed: pressed,
        ),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}

/// Chíp stickers to cheer or tease friends (no free text; 3 s cooldown).
class StickerBar extends ConsumerWidget {
  const StickerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = context.isTablet ? 80.0 : 64.0;
    final teaseOn = ref.watch(teaseStickersProvider).valueOrNull ?? true;
    final lockedUntil =
        ref.watch(roomControllerProvider.select((s) => s.stickerLockedUntil));
    final locked = lockedUntil != null &&
        lockedUntil.isAfter(ref.read(stickerClockProvider)());
    final entries = [
      for (final e in roomStickerArt.entries)
        if (teaseOn || !isTeaseSticker(e.key)) e,
    ];
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final e = entries[index];
          return StickerImageTile(
            tileKey: ValueKey('sticker-${e.key}'),
            size: size,
            asset: e.value.$1,
            label: e.value.$2,
            locked: locked,
            onTap: () => ref.read(roomControllerProvider.notifier).sticker(e.key),
          );
        },
      ),
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
      final teaseOn = ref.read(teaseStickersProvider).valueOrNull ?? true;
      if (isTeaseSticker(s.id) && !teaseOn) return;
      setState(() => _shown = s);
      _hide?.cancel();
      _hide = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _shown = null);
      });
    });
    final s = _shown;
    final art = s == null ? null : roomStickerArt[s.id];
    final phrase = s == null ? null : quickPhraseTexts[s.id];
    if (s == null || (art == null && phrase == null)) {
      return const SizedBox.shrink();
    }
    final room = ref.read(roomControllerProvider);
    final from = room.players.where((p) => p.id == s.from).firstOrNull?.name ?? '';
    final size = context.isTablet ? 120.0 : 96.0;
    final caption = art?.$2 ?? phrase!;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: raisedDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (art != null) Image.asset(art.$1, width: size, height: size),
            Text(
              from.isEmpty ? caption : '$from: $caption',
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

/// Accent colour matching each rocket's hull so lobby borders echo the art.
Color rocketAccentColor(String rocketId) => switch (rocketId) {
      'rocket_blue' => Subject.toan.color,
      'rocket_green' => Subject.tiengAnh.color,
      'rocket_purple' => Subject.tiengViet.color,
      _ => Subject.viet.color,
    };

/// Space backdrop shared with the race scene (`SkyMotionPainter` + static
/// twilight gradient) driven by a single [Ticker] and paused under reduce-motion.
class LobbySpaceBackdrop extends StatefulWidget {
  const LobbySpaceBackdrop({super.key});

  @override
  State<LobbySpaceBackdrop> createState() => _LobbySpaceBackdropState();
}

class _LobbySpaceBackdropState extends State<LobbySpaceBackdrop>
    with SingleTickerProviderStateMixin {
  final SceneClock _clock = SceneClock();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduceMotion || (!reduce && !_ticker.isActive)) {
      _reduceMotion = reduce;
      if (reduce) {
        _ticker.stop();
        _clock.touch();
      } else if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    final rawDt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (rawDt <= 0) return;
    _clock.advance(math.min(rawDt, 0.05));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GameColors.skyTop,
                  GameColors.skyUpper,
                  GameColors.skyLower,
                  GameColors.skyHorizon,
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: LayoutBuilder(
            builder: (_, c) => CustomPaint(
              painter: SkyMotionPainter(
                clock: _clock,
                geometry: TrackGeometry(c.biggest),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One joined player's card in the 4-slot lobby grid: 78 px avatar framed in
/// their rocket colour, presence dot, host crown, mini rocket, and status.
class LobbyPlayerSlot extends StatelessWidget {
  const LobbyPlayerSlot({
    super.key,
    required this.player,
    required this.slotIndex,
    required this.isYou,
    required this.isHost,
    this.receivedSticker,
    this.onTap,
  });

  final RoomPlayer player;
  final int slotIndex;
  final bool isYou;
  final bool isHost;
  final RoomSticker? receivedSticker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final narrow = !tablet && MediaQuery.sizeOf(context).width < 360;
    final avatarSize = tablet ? 78.0 : (narrow ? 64.0 : 78.0);
    final rocketId =
        player.rocket.isNotEmpty ? player.rocket : roomRocketForIndex(slotIndex);
    final rocketColor = rocketAccentColor(rocketId);
    final rocketAsset = RocketSprite.forItem(rocketId).asset;
    final avatarAsset = safeOnlineAvatar(player.avatar, slotIndex);
    final online = player.connected && !player.away && !player.left;
    final faded = !online;

    final String statusText;
    final Color statusColor;
    if (player.left) {
      statusText = 'Đã rời';
      statusColor = AppColors.textMuted;
    } else if (!online) {
      statusText = player.awayMsLeft != null
          ? 'Mất mạng · chờ ${(player.awayMsLeft! / 1000).ceil()}s'
          : 'Mất mạng · đang chờ';
      statusColor = AppColors.textMuted;
    } else {
      statusText = '✓ Sẵn sàng';
      statusColor = AppColors.onlineInk;
    }

    final displayName = player.name.trim().isEmpty
        ? 'Bạn ${slotIndex + 1}'
        : (isYou ? '${player.name} (bé)' : player.name);

    final sticker = receivedSticker;
    final stickerArt = sticker == null ? null : roomStickerArt[sticker.id];
    final stickerPhrase = sticker == null ? null : quickPhraseTexts[sticker.id];

    Widget buildCard(bool pressed) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: BoxConstraints(minHeight: tablet ? 196 : 150),
            padding: EdgeInsets.symmetric(
              horizontal: narrow ? 8 : 12,
              vertical: tablet ? 14 : 10,
            ),
            decoration: raisedDecoration(
              accent: rocketColor,
              tint: isYou ? Subject.viet.tint : AppColors.card,
              pressed: pressed,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: avatarSize + 6,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (isHost)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Semantics(
                            label: 'Chủ phòng',
                            child: Image.asset(
                              AppImages.icCrown,
                              key: ValueKey('lobby-crown-${player.id}'),
                              width: tablet ? 28 : 22,
                              height: tablet ? 28 : 22,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Image.asset(
                          rocketAsset,
                          key: ValueKey('lobby-rocket-${player.id}'),
                          width: tablet ? 28 : 22,
                          height: tablet ? 36 : 28,
                          fit: BoxFit.contain,
                          color: faded
                              ? GameColors.star.withOpacity(0.42)
                              : null,
                          colorBlendMode: faded ? BlendMode.modulate : null,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.card,
                              border: Border.all(
                                color: faded
                                    ? AppColors.textMuted.withOpacity(0.5)
                                    : rocketColor,
                                width: 3.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                avatarAsset,
                                fit: BoxFit.contain,
                                color: faded
                                    ? GameColors.star.withOpacity(0.42)
                                    : null,
                                colorBlendMode:
                                    faded ? BlendMode.modulate : null,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Semantics(
                              label: online ? 'Đang kết nối' : 'Mất mạng',
                              child: Container(
                                key: ValueKey('lobby-dot-${player.id}'),
                                width: tablet ? 18 : 16,
                                height: tablet ? 18 : 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: online
                                      ? AppColors.online
                                      : AppColors.textMuted,
                                  border: Border.all(
                                    color: AppColors.card,
                                    width: 2.5,
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
                SizedBox(height: tablet ? 10 : 6),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tablet ? 19 : (narrow ? 14 : 16),
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: online
                          ? AppColors.online.withOpacity(0.14)
                          : AppColors.dot.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      statusText,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: tablet ? 14 : 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (sticker != null && (stickerArt != null || stickerPhrase != null))
            Positioned(
              top: -10,
              right: -4,
              child: IgnorePointer(
                child: Container(
                  key: ValueKey('lobby-slot-sticker-${player.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: raisedDecoration(
                    accent: AppColors.accent,
                    radius: AppRadii.tile,
                  ),
                  child: stickerArt != null
                      ? Image.asset(
                          stickerArt.$1,
                          width: tablet ? 40 : 32,
                          height: tablet ? 40 : 32,
                          fit: BoxFit.contain,
                        )
                      : Text(
                          stickerPhrase!,
                          style: TextStyle(
                            fontSize: tablet ? 13 : 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                ),
              ),
            ),
        ],
      );
    }

    if (onTap == null) {
      return Semantics(
        container: true,
        child: KeyedSubtree(
          key: ValueKey('lobby-slot-${player.id}'),
          child: buildCard(false),
        ),
      );
    }
    return Pressable(
      key: ValueKey('lobby-slot-${player.id}'),
      semanticsLabel: displayName,
      onTap: onTap,
      builder: buildCard,
    );
  }
}

/// Dashed empty slot in the 4-slot lobby grid. Tapping opens an invite / room
/// code sheet (Task 14 extends this with online friends).
class LobbyEmptySlot extends StatelessWidget {
  const LobbyEmptySlot({
    super.key,
    required this.slotIndex,
    required this.onTap,
  });

  final int slotIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final narrow = !tablet && MediaQuery.sizeOf(context).width < 360;
    return Pressable(
      key: ValueKey('lobby-empty-slot-$slotIndex'),
      semanticsLabel: 'Mời bạn vào phòng',
      onTap: onTap,
      builder: (pressed) => CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: AppColors.card.withOpacity(0.55),
          radius: AppRadii.card,
          strokeWidth: 2.5,
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: tablet ? 196 : 150),
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 8 : 12,
            vertical: tablet ? 14 : 10,
          ),
          decoration: BoxDecoration(
            color: GameColors.skyTop.withOpacity(pressed ? 0.68 : 0.52),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: tablet ? 56 : (narrow ? 44 : 50),
                height: tablet ? 56 : (narrow ? 44 : 50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card.withOpacity(0.16),
                  border: Border.all(
                    color: AppColors.card.withOpacity(0.65),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: tablet ? 34 : 28,
                  color: AppColors.card,
                ),
              ),
              SizedBox(height: tablet ? 10 : 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '+ Chờ bạn',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: tablet ? 18 : 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.card,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GameColors.starWarm,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  'Mời bạn',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: tablet ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
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

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  Size? _cachedSize;
  double? _cachedRadius;
  double? _cachedStrokeWidth;
  Path? _cachedPath;
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  Path _buildDashedPath(Size size) {
    final inset = strokeWidth * 0.5;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(0.0, size.width - strokeWidth),
      math.max(0.0, size.height - strokeWidth),
    );
    final innerRadius = math.max(0.0, radius - inset);
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(innerRadius)));

    final out = Path();
    const dashLen = 8.0;
    const gapLen = 6.0;
    for (final metric in base.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = math.min(dist + dashLen, metric.length);
        out.addPath(metric.extractPath(dist, next), Offset.zero);
        dist = next + gapLen;
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_cachedPath == null ||
        _cachedSize != size ||
        _cachedRadius != radius ||
        _cachedStrokeWidth != strokeWidth) {
      _cachedSize = size;
      _cachedRadius = radius;
      _cachedStrokeWidth = strokeWidth;
      _cachedPath = _buildDashedPath(size);
    }
    _paint
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawPath(_cachedPath!, _paint);
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
