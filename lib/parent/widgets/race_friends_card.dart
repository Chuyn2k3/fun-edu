import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/auth/session_controller.dart';
import '../../online/friends/friends_api.dart';
import '../../online/friends/friends_controller.dart';
import '../../online/online_config.dart';
import '../../online/sync/sync_engine.dart';
import '../../profile/avatars.dart';
import '../../profile/kid_repository.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/pressable.dart';
import '../screens/parent_card.dart';

/// Parent-corner card ("Bạn đua của bé"): friend codes, redeem input, friend
/// list with live presence dots, and per-kid race/showcase privacy switches.
class RaceFriendsCard extends ConsumerStatefulWidget {
  const RaceFriendsCard({
    super.key,
    required this.kidId,
    this.onSignInTap,
  });

  final int? kidId;
  final VoidCallback? onSignInTap;

  @override
  ConsumerState<RaceFriendsCard> createState() => _RaceFriendsCardState();
}

class _RaceFriendsCardState extends ConsumerState<RaceFriendsCard> {
  final _codeInput = TextEditingController();
  bool _creatingCode = false;
  bool _redeeming = false;
  String? _removingFamilyId;
  String? _redeemError;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeInput.dispose();
    super.dispose();
  }

  void _syncCountdownTimer(FriendCode? code) {
    if (code == null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      return;
    }
    _countdownTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _createCode() async {
    if (_creatingCode) return;
    setState(() => _creatingCode = true);
    try {
      final res = await ref.read(friendsControllerProvider.notifier).createCode();
      if (!mounted) return;
      if (!res.ok && res.errorMessage != null) {
        showAppToast(context, res.errorMessage!, kind: AppToastKind.warning);
      }
    } finally {
      if (mounted) {
        setState(() => _creatingCode = false);
      }
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    showAppToast(context, 'Đã chép mã kết bạn', kind: AppToastKind.success);
  }

  Future<void> _redeemCode() async {
    if (_redeeming) return;
    final raw = _codeInput.text;
    setState(() {
      _redeeming = true;
      _redeemError = null;
    });
    try {
      final res =
          await ref.read(friendsControllerProvider.notifier).redeemCode(raw);
      if (!mounted) return;
      if (res.ok) {
        _codeInput.clear();
        setState(() => _redeemError = null);
        showAppToast(context, 'Đã thêm bạn mới!', kind: AppToastKind.success);
      } else {
        setState(() => _redeemError = res.errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _redeeming = false);
      }
    }
  }

  Future<void> _confirmRemoveFriend(FriendFamily friend) async {
    if (_removingFamilyId != null) return;
    final confirmed = await showAppDialog<bool>(
      context,
      title: 'Xóa bạn đua?',
      message: 'Gia đình này sẽ không còn thấy trạng thái online hay Tủ khoe '
          'của bé nữa.',
      primaryLabel: 'Giữ lại',
      secondaryLabel: 'Xóa bạn',
      secondaryKey: const ValueKey('confirm-remove-friend'),
      tone: AppDialogTone.danger,
      audience: AppAudience.parent,
    );
    if (confirmed != false || !mounted) return;

    setState(() => _removingFamilyId = friend.familyId);
    try {
      final res = await ref
          .read(friendsControllerProvider.notifier)
          .removeFriend(friend.familyId);
      if (!mounted) return;
      if (res.ok) {
        showAppToast(context, 'Đã xóa bạn', kind: AppToastKind.info);
      } else if (res.errorMessage != null) {
        showAppToast(context, res.errorMessage!, kind: AppToastKind.warning);
      }
    } finally {
      if (mounted) {
        setState(() => _removingFamilyId = null);
      }
    }
  }

  Future<void> _setTeaseStickers(int kidId, bool on) async {
    await ref
        .read(kidRepositoryProvider)
        .setSetting(teaseStickersKey(kidId), '$on');
    ref.invalidate(kidTeaseStickersProvider(kidId));
    ref.invalidate(teaseStickersProvider);
    ref.read(syncControllerProvider.notifier).requestSync();
  }

  Future<void> _setShowcaseOn(int kidId, bool on) async {
    await ref
        .read(kidRepositoryProvider)
        .setSetting(showcaseOnKey(kidId), '$on');
    ref.invalidate(kidShowcaseOnProvider(kidId));
    ref.invalidate(showcaseOnProvider);
    ref.read(syncControllerProvider.notifier).requestSync();
  }

  Future<void> _setShowcaseLearning(int kidId, bool on) async {
    await ref
        .read(kidRepositoryProvider)
        .setSetting(showcaseLearningKey(kidId), '$on');
    ref.invalidate(kidShowcaseLearningProvider(kidId));
    ref.invalidate(showcaseLearningProvider);
    ref.read(syncControllerProvider.notifier).requestSync();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(onlineConfigProvider).enabled) {
      return const SizedBox.shrink();
    }
    final session = ref.watch(sessionProvider).valueOrNull;
    final kidId = widget.kidId;

    if (session == null) {
      _syncCountdownTimer(null);
      return ParentCard(
        title: 'Bạn đua của bé',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ba mẹ cần đăng nhập Tài khoản gia đình để tạo mã kết bạn, '
              'kết nối bạn đua và đồng bộ Tủ khoe cho bé.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
            if (widget.onSignInTap != null) ...[
              const SizedBox(height: 12),
              _ParentRaisedButton(
                key: const ValueKey('friends-go-sign-in'),
                icon: Icons.login_rounded,
                label: 'Đi tới Tài khoản gia đình',
                onTap: widget.onSignInTap,
              ),
            ],
            if (kidId != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _PrivacySwitches(
                kidId: kidId,
                onTeaseChanged: (on) => _setTeaseStickers(kidId, on),
                onShowcaseChanged: (on) => _setShowcaseOn(kidId, on),
                onShowcaseLearningChanged: (on) =>
                    _setShowcaseLearning(kidId, on),
              ),
            ],
          ],
        ),
      );
    }

    final friendsAsync = ref.watch(friendsControllerProvider);
    final friendsState = friendsAsync.valueOrNull;
    final activeCode = friendsState?.activeCode;
    _syncCountdownTimer(activeCode);

    return ParentCard(
      title: 'Bạn đua của bé',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ParentRaisedButton(
            key: const ValueKey('create-friend-code'),
            icon: Icons.qr_code_2_rounded,
            label: _creatingCode ? 'Đang tạo mã…' : 'Tạo mã kết bạn',
            accent: Subject.viet.color,
            tint: Subject.viet.tint,
            foreground: AppColors.primaryOnTint,
            onTap: _creatingCode ? null : _createCode,
          ),
          if (activeCode != null) ...[
            const SizedBox(height: 12),
            _ActiveCodeBox(
              code: activeCode,
              now: ref.read(friendsClockProvider)(),
              onCopy: () => _copyCode(activeCode.code),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Nhập mã kết bạn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('redeem-friend-code-input'),
                  controller: _codeInput,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [_UpperCaseTextFormatter()],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _redeemCode(),
                  onChanged: (_) {
                    if (_redeemError != null) {
                      setState(() => _redeemError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: AB23CD',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey('redeem-friend-code-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.card,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: _redeeming ? null : _redeemCode,
                  child: Text(_redeeming ? 'Đang kết…' : 'Kết bạn'),
                ),
              ),
            ],
          ),
          if (_redeemError != null) ...[
            const SizedBox(height: 6),
            Text(
              _redeemError!,
              key: const ValueKey('friend-code-error'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _FriendsListSection(
            friendsAsync: friendsAsync,
            removingFamilyId: _removingFamilyId,
            onRetry: () => ref.read(friendsControllerProvider.notifier).refresh(),
            onRemove: _confirmRemoveFriend,
          ),
          if (kidId != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _PrivacySwitches(
              kidId: kidId,
              onTeaseChanged: (on) => _setTeaseStickers(kidId, on),
              onShowcaseChanged: (on) => _setShowcaseOn(kidId, on),
              onShowcaseLearningChanged: (on) =>
                  _setShowcaseLearning(kidId, on),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParentRaisedButton extends StatelessWidget {
  const _ParentRaisedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppDepth.neutral,
    this.tint,
    this.foreground = AppColors.text,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color accent;
  final Color? tint;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticsLabel: label,
      onTap: onTap,
      builder: (pressed) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: raisedDecoration(
          accent: accent,
          tint: tint,
          radius: AppRadii.tile,
          pressed: pressed,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final firstAvatar = kids.isNotEmpty && kidAvatars.contains(kids.first.avatar)
        ? kids.first.avatar
        : kidAvatars[0];
    final displayNames = kids.isEmpty
        ? 'Gia đình bạn'
        : kids
            .map((k) => k.nickname.trim().isNotEmpty ? k.nickname.trim() : 'Bạn đua')
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

class _PrivacySwitches extends ConsumerWidget {
  const _PrivacySwitches({
    required this.kidId,
    required this.onTeaseChanged,
    required this.onShowcaseChanged,
    required this.onShowcaseLearningChanged,
  });

  final int kidId;
  final ValueChanged<bool> onTeaseChanged;
  final ValueChanged<bool> onShowcaseChanged;
  final ValueChanged<bool> onShowcaseLearningChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tease = ref.watch(kidTeaseStickersProvider(kidId)).valueOrNull ?? true;
    final showcaseOn =
        ref.watch(kidShowcaseOnProvider(kidId)).valueOrNull ?? true;
    final showcaseLearning =
        ref.watch(kidShowcaseLearningProvider(kidId)).valueOrNull ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SwitchRow(
          switchKey: const ValueKey('tease-stickers-switch'),
          title: 'Sticker trêu',
          subtitle: 'Hiện và gửi sticker trêu vui khi đua cùng bạn',
          value: tease,
          onChanged: onTeaseChanged,
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          switchKey: const ValueKey('showcase-on-switch'),
          title: 'Cho bạn xem Tủ khoe',
          subtitle: 'Bạn bè đã kết nối xem được Tủ khoe của bé',
          value: showcaseOn,
          onChanged: onShowcaseChanged,
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          switchKey: const ValueKey('showcase-learning-switch'),
          title: 'Cho bạn xem tiến độ học',
          subtitle: 'Hiện số chữ, bài học và sao trong Tủ khoe',
          value: showcaseLearning,
          onChanged: onShowcaseLearningChanged,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchKey,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          Switch(
            key: switchKey,
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Formats a 6- or 8-character code into two evenly spaced groups (`AB2 3CD`).
String formatFriendCode(String code) {
  final clean = normalizeFriendCode(code);
  if (clean.length < 4) return clean;
  final mid = clean.length ~/ 2;
  return '${clean.substring(0, mid)} ${clean.substring(mid)}';
}

/// Formats remaining lifetime of a friend code in Vietnamese.
String formatFriendCodeExpiry(Duration remaining) {
  if (remaining <= Duration.zero) return 'Đã hết hạn';
  final totalMinutes = remaining.inMinutes;
  if (totalMinutes < 1) return 'Hết hạn sau 1 phút';
  if (totalMinutes < 60) return 'Hết hạn sau $totalMinutes phút';
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (mins == 0) return 'Hết hạn sau $hours giờ';
  return 'Hết hạn sau $hours giờ $mins phút';
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(text: upper);
  }
}
