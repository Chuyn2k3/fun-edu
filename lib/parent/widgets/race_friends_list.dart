// Friend code box and the list of friend families.
part of 'race_friends_card.dart';

class _ActiveCodeBox extends StatelessWidget {
  const _ActiveCodeBox({
    required this.code,
    required this.now,
    required this.onCopy,
  });

  final FriendCode code;
  final DateTime now;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final formatted = formatFriendCode(code.code);
    final expiryText = formatFriendCodeExpiry(code.expiresAt.difference(now));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Subject.viet.tint,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: Subject.viet.color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatted,
                  key: const ValueKey('active-friend-code'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expiryText,
                  key: const ValueKey('friend-code-expiry'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            key: const ValueKey('copy-friend-code'),
            semanticsLabel: 'Chép mã',
            onTap: onCopy,
            builder: (pressed) => Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: raisedDecoration(
                accent: Subject.viet.color,
                radius: 14,
                pressed: pressed,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.primaryOnTint,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Chép mã',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryOnTint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsListSection extends StatelessWidget {
  const _FriendsListSection({
    required this.friendsAsync,
    required this.removingFamilyId,
    required this.onRetry,
    required this.onRemove,
  });

  final AsyncValue<FriendsState> friendsAsync;
  final String? removingFamilyId;
  final VoidCallback onRetry;
  final ValueChanged<FriendFamily> onRemove;

  @override
  Widget build(BuildContext context) {
    final state = friendsAsync.valueOrNull;
    if (friendsAsync.isLoading && state == null) {
      return const Text(
        'Đang tải danh sách bạn…',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      );
    }

    final friends = state?.friends ?? const <FriendFamily>[];
    final errorMessage = state?.errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  errorMessage,
                  key: const ValueKey('friends-load-error'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('friends-retry'),
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Danh sách bạn (${friends.length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        if (friends.isEmpty)
          const Text(
            'Chưa có bạn đua nào. Ba mẹ tạo mã hoặc nhập mã từ nhà bạn để kết nối nhé.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          )
        else
          for (var i = 0; i < friends.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _FriendRow(
              friend: friends[i],
              removing: removingFamilyId == friends[i].familyId,
              onRemove: () => onRemove(friends[i]),
            ),
          ],
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.removing,
    required this.onRemove,
  });

  final FriendFamily friend;
  final bool removing;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final kids = friend.kids;
    final firstAvatar =
        kids.isNotEmpty && kidAvatars.contains(kids.first.avatar)
            ? kids.first.avatar
            : kidAvatars[0];
    final displayNames = kids.isEmpty
        ? 'Gia đình bạn'
        : kids
            .map((k) =>
                k.nickname.trim().isNotEmpty ? k.nickname.trim() : 'Bạn đua')
            .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppDepth.neutralTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: ClipOval(
              child: Image.asset(
                firstAvatar,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayNames,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      key: ValueKey('presence-dot-${friend.familyId}'),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: friend.online
                            ? AppColors.online
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        friend.online ? 'Đang mở app' : 'Ngoại tuyến',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: friend.online
                              ? AppColors.onlineInk
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            key: ValueKey('remove-friend-${friend.familyId}'),
            onPressed: removing ? null : onRemove,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Xóa',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
