import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../online/auth/session_controller.dart';
import '../../online/friends/friends_api.dart';
import '../../online/friends/friends_controller.dart';
import '../../online/friends/lobby_client.dart';
import '../../online/net/network_status.dart';
import '../../online/online_config.dart';
import '../../online/room/room_controller.dart';
import '../../profile/avatars.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../collection/showcase_screen.dart';
import '../online_race/room_widgets.dart';

/// Friendly Vietnamese text for a lobby error code that follows an invite.
String friendInviteErrorText(String code) => switch (code) {
      'friend_offline' => 'Bạn ấy vừa thoát rồi, lát nữa mời lại nhé',
      'not_friends' => 'Hai nhà chưa là bạn đua của nhau',
      'invite_pending' => 'Bạn ấy đang xem lời mời trước đó, chờ một chút nhé',
      'not_in_room' => 'Phòng đua chưa sẵn sàng, thử lại nhé',
      'too_many' => 'Mời nhiều lần quá, đợi một chút rồi thử lại nhé',
      'room_full' => 'Phòng đã đủ 4 bạn rồi',
      'started' => 'Các bạn đã bắt đầu đua mất rồi',
      _ => 'Chưa mời được bạn. Thử lại sau nhé',
    };

/// Whether the family can use friends features (online build + signed in).
bool _canUseFriends(WidgetRef ref) =>
    ref.watch(onlineConfigProvider).enabled &&
    ref.watch(sessionProvider).valueOrNull != null;

/// Online friend kids (one entry per kid of every online friend family).
List<(FriendFamily, FriendKid)> onlineFriendKids(List<FriendFamily> friends) {
  return [
    for (final f in friends)
      if (f.online)
        for (final k in f.kids) (f, k),
  ];
}

/// Shows a toast for lobby errors (invite refusals) while the widget lives.
void listenInviteErrors(WidgetRef ref, BuildContext context) {
  ref.listen<LobbyErrorEvent?>(
    lobbyClientProvider.select((s) => s.lastError),
    (prev, next) {
      if (next == null || next.seq == prev?.seq) return;
      if (!context.mounted) return;
      showAppToast(
        context,
        friendInviteErrorText(next.code),
        kind: AppToastKind.warning,
      );
    },
  );
}

/// Sends an invite to [family] for [roomCode] and shows a toast when the
/// lobby is not reachable. Returns true when the invite was sent.
bool sendFriendInvite(
  WidgetRef ref,
  BuildContext context, {
  required FriendFamily family,
  required String roomCode,
  required String kidUuid,
}) {
  final lobby = ref.read(lobbyClientProvider);
  if (!lobby.connected) {
    showAppToast(
      context,
      'Chưa kết nối được với trạm vũ trụ, thử lại nhé',
      kind: AppToastKind.warning,
    );
    return false;
  }
  ref.read(lobbyClientProvider.notifier).sendInvite(
        toFamilyId: family.familyId,
        roomCode: roomCode,
        kidUuid: kidUuid,
      );
  return true;
}

/// One-tap invite from the hub: create a room when the kid is not in one,
/// invite the friend, then go to the lobby.
Future<void> inviteFriendFromHub(
  WidgetRef ref,
  BuildContext context,
  FriendFamily family,
) async {
  if (ref.read(networkStatusProvider) == NetState.offline) {
    showAppToast(context, 'Cần có mạng để đua với bạn nhé',
        kind: AppToastKind.offline);
    return;
  }
  if (!ref.read(lobbyClientProvider).connected) {
    showAppToast(
      context,
      'Chưa kết nối được với trạm vũ trụ, thử lại nhé',
      kind: AppToastKind.warning,
    );
    return;
  }
  final kid = await currentRoomKid(ref);
  if (!context.mounted) return;
  if (kid == null) {
    showAppToast(context, 'Chưa có hồ sơ bé', kind: AppToastKind.warning);
    return;
  }
  final room = ref.read(roomControllerProvider.notifier);
  var rs = ref.read(roomControllerProvider);
  final inRoom = rs.code != null &&
      (rs.phase == RoomPhase.lobby ||
          rs.phase == RoomPhase.connecting ||
          rs.phase == RoomPhase.countdown);
  if (!inRoom) {
    await room.create(kid);
    if (!context.mounted) return;
    rs = ref.read(roomControllerProvider);
    if (rs.phase == RoomPhase.error || rs.code == null) {
      showAppToast(context, roomErrorText(rs.error),
          kind: AppToastKind.warning);
      return;
    }
  }
  final sent = sendFriendInvite(
    ref,
    context,
    family: family,
    roomCode: rs.code!,
    kidUuid: kid.uuid,
  );
  if (sent && context.mounted) {
    context.go('/game/room/lobby');
  }
}

/// Horizontal "Bạn đua" row on the game hub. Renders nothing for guests,
/// signed-out families, builds without a server, or when there are no friends.
class FriendsRow extends ConsumerWidget {
  const FriendsRow({super.key, this.topGap = 0, this.bottomGap = 0});

  /// Spacing included only while the row is visible.
  final double topGap;
  final double bottomGap;

  /// Height the row needs (title included); 0-height callers use [visible].
  static double heightFor(bool tablet) => tablet ? 190 : 150;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canUseFriends(ref)) return const SizedBox.shrink();
    listenInviteErrors(ref, context);
    final friends = ref.watch(friendsProvider).valueOrNull ?? const [];
    final kids = [
      for (final f in friends)
        for (final k in f.kids) (f, k),
    ];
    if (kids.isEmpty) return const SizedBox.shrink();
    final tablet = context.isTablet;
    return Padding(
        padding: EdgeInsets.only(top: topGap, bottom: bottomGap),
        child: SizedBox(
          key: const ValueKey('friends-row'),
          height: heightFor(tablet),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đua',
                style: TextStyle(
                  fontSize: tablet ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: GameColors.ink,
                ),
              ),
              SizedBox(height: tablet ? 12 : 8),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: kids.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: tablet ? 16 : 12),
                  itemBuilder: (context, i) {
                    final (family, kid) = kids[i];
                    return _FriendTile(
                      key: ValueKey('friend-${kid.kidUuid}'),
                      kid: kid,
                      online: family.online,
                      onTap: () {
                        if (family.online) {
                          inviteFriendFromHub(ref, context, family);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ShowcaseScreen(
                                familyId: family.familyId,
                                kidUuid: kid.kidUuid,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    super.key,
    required this.kid,
    required this.online,
    required this.onTap,
  });

  final FriendKid kid;
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final avatar = kidAvatars.contains(kid.avatar) ? kid.avatar : kidAvatars[1];
    final name = kid.nickname.trim().isEmpty ? 'Bạn đua' : kid.nickname.trim();
    final size = tablet ? 64.0 : 52.0;
    final width = tablet ? 112.0 : 88.0;
    final card = Container(
      width: width,
      constraints: BoxConstraints(minHeight: tablet ? 80 : 64),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: raisedDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                avatar,
                width: size,
                height: size,
                color: online ? null : GameColors.star.withOpacity(0.42),
                colorBlendMode: online ? null : BlendMode.modulate,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  key: ValueKey('friend-dot-${kid.kidUuid}'),
                  width: tablet ? 20 : 16,
                  height: tablet ? 20 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online ? AppColors.online : AppColors.textMuted,
                    border: Border.all(color: AppColors.card, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tablet ? 17 : 14,
              fontWeight: FontWeight.w900,
              color: online ? AppColors.text : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
    if (!online) {
      return Tooltip(
        message: 'Bạn $name đang không online',
        triggerMode: TooltipTriggerMode.tap,
        child: Semantics(
          label: '$name, đang không online',
          child: card,
        ),
      );
    }
    return Pressable(
      semanticsLabel: 'Mời $name đua',
      onTap: onTap,
      builder: (_) => card,
    );
  }
}

/// Body of the lobby "Mời bạn" modal: online friend kids with one-tap "Mời".
class FriendsInviteList extends ConsumerStatefulWidget {
  const FriendsInviteList({
    super.key,
    required this.roomCode,
    required this.kidUuid,
  });

  final String roomCode;
  final String? kidUuid;

  @override
  ConsumerState<FriendsInviteList> createState() => _FriendsInviteListState();
}

class _FriendsInviteListState extends ConsumerState<FriendsInviteList> {
  final Set<String> _sent = {};

  Future<void> _invite(FriendFamily family, FriendKid kid) async {
    var uuid = widget.kidUuid;
    uuid ??= (await currentRoomKid(ref))?.uuid;
    if (!mounted || uuid == null) return;
    final ok = sendFriendInvite(
      ref,
      context,
      family: family,
      roomCode: widget.roomCode,
      kidUuid: uuid,
    );
    if (ok) setState(() => _sent.add(kid.kidUuid));
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isTablet;
    final friends = ref.watch(friendsProvider).valueOrNull ?? const [];
    final online = onlineFriendKids(friends);
    if (online.isEmpty) {
      return Text(
        'Chưa có bạn nào đang online. Đưa mã phòng cho ba mẹ của bạn nhé.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: tablet ? 20 : 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
        ),
      );
    }
    final rowH = tablet ? 80.0 : 64.0;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: (rowH + 8) * (tablet ? 3 : 2)),
      child: ListView.separated(
        key: const ValueKey('invite-friends-list'),
        shrinkWrap: true,
        itemCount: online.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final (family, kid) = online[i];
          final avatar =
              kidAvatars.contains(kid.avatar) ? kid.avatar : kidAvatars[1];
          final name =
              kid.nickname.trim().isEmpty ? 'Bạn đua' : kid.nickname.trim();
          final sent = _sent.contains(kid.kidUuid);
          return SizedBox(
            height: rowH,
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(avatar,
                        width: tablet ? 56 : 44, height: tablet ? 56 : 44),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.online,
                          border: Border.all(color: AppColors.card, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: tablet ? 22 : 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: tablet ? 120 : 92,
                  height: rowH,
                  child: ElevatedButton(
                    key: ValueKey('invite-${kid.kidUuid}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor:
                          AppColors.accent.withOpacity(0.4),
                      foregroundColor: AppColors.card,
                      disabledForegroundColor: AppColors.card,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      elevation: 0,
                      textStyle: TextStyle(
                        fontSize: tablet ? 20 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: sent ? null : () => _invite(family, kid),
                    child: Text(sent ? 'Đã mời' : 'Mời'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
