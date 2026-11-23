import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/online/online_consent_dialog.dart';
import '../../features/online/replace_data_dialog.dart';
import '../../online/auth/identity_providers.dart';
import '../../online/auth/session_controller.dart';
import '../../online/link/link_controller.dart';
import '../../online/net/network_status.dart';
import '../../online/online_config.dart';
import '../../online/sync/sync_engine.dart';
import '../../online/sync/sync_health.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/theme/tokens.dart';
import 'parent_card.dart';

/// "Tài khoản gia đình" in Góc ba mẹ: sign in with Google or Apple to keep
/// the kids' progress online and share it between devices. Hidden entirely
/// in a build without a server address.
class FamilyAccountCard extends ConsumerStatefulWidget {
  const FamilyAccountCard({super.key});

  @override
  ConsumerState<FamilyAccountCard> createState() => _FamilyAccountCardState();
}

class _FamilyAccountCardState extends ConsumerState<FamilyAccountCard> {
  bool _signingIn = false;

  static void _say(BuildContext context, String text) {
    showAppToast(context, text, kind: AppToastKind.info);
  }

  Future<void> _signIn(BuildContext context, String provider) async {
    if (_signingIn) return;
    _signingIn = true;
    try {
      final agreed = await showOnlineConsentDialog(context);
      if (!agreed || !context.mounted) return;
      try {
        final result = await ref.read(sessionProvider.notifier).signIn(provider);
        await ref.read(linkControllerProvider.notifier).afterSignIn(result);
        if (!context.mounted) return;
        final linkState = ref.read(linkControllerProvider);
        if (linkState is! LinkNeedsWarning) {
          _say(context, 'Đã đăng nhập. Đang lưu tiến độ online…');
        }
      } on SignInException catch (e) {
        if (!context.mounted) return;
        final why = kDebugMode && e.detail != null ? '\n(${e.detail})' : '';
        switch (e.failure) {
          case SignInFailure.cancelled:
            break;
          case SignInFailure.setup:
            _say(context, 'Chưa đăng nhập được với Google/Apple trên máy này, ba mẹ thử lại sau nhé$why');
          case SignInFailure.network:
            _say(context, 'Không kết nối được máy chủ, ba mẹ thử lại sau nhé$why');
          case SignInFailure.rejected:
            _say(context, 'Đăng nhập không thành công, ba mẹ thử lại nhé$why');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _signingIn = false);
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await ref.read(sessionProvider.notifier).signOut();
    if (context.mounted) _say(context, 'Đã đăng xuất. Dữ liệu vẫn ở trên máy này');
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showAppDialog<bool>(
      context,
      title: 'Xóa tài khoản online?',
      message: 'Mọi dữ liệu online của gia đình sẽ bị xóa vĩnh viễn khỏi máy chủ. '
          'Dữ liệu trên máy này vẫn giữ nguyên.',
      primaryLabel: 'Giữ lại',
      secondaryLabel: 'Xóa',
      secondaryKey: const ValueKey('confirm-delete-account'),
      tone: AppDialogTone.danger,
      audience: AppAudience.parent,
    );
    if (ok != false || !context.mounted) return;
    try {
      await ref.read(sessionProvider.notifier).deleteAccount();
      if (context.mounted) _say(context, 'Đã xóa tài khoản online');
    } catch (_) {
      if (context.mounted) {
        _say(context, 'Chưa xóa được, ba mẹ kiểm tra mạng rồi thử lại nhé');
      }
    }
  }

  Future<void> _openWarning(BuildContext context, LinkNeedsWarning warning) async {
    final session = ref.read(sessionProvider).valueOrNull;
    final who = session?.email ?? (session?.provider == 'apple' ? 'Apple' : 'Google');
    await showReplaceDataDialog(
      context,
      local: warning.local,
      account: warning.account,
      accountLabel: who,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(onlineConfigProvider).enabled) return const SizedBox.shrink();
    final session = ref.watch(sessionProvider).valueOrNull;
    final ids = ref.watch(identityProvidersProvider);

    if (session == null) {
      return ParentCard(
        title: 'Lưu tiến độ online',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đang dùng thử: dữ liệu chỉ ở trên máy này',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Đăng nhập để giữ tiến độ của các bé khi đổi máy và dùng chung '
              'trên điện thoại, máy tính bảng.',
              style: _body,
            ),
            const SizedBox(height: 14),
            _Button(
              key: const ValueKey('sign-in-google'),
              icon: Icons.account_circle_rounded,
              label: 'Đăng nhập với Google',
              onTap: _signingIn ? null : () => _signIn(context, 'google'),
            ),
            if (ids.appleAvailable) ...[
              const SizedBox(height: 10),
              _Button(
                key: const ValueKey('sign-in-apple'),
                icon: Icons.apple_rounded,
                label: 'Đăng nhập với Apple',
                onTap: _signingIn ? null : () => _signIn(context, 'apple'),
              ),
            ],
          ],
        ),
      );
    }

    final sync = ref.watch(syncControllerProvider);
    final health = ref.watch(syncHealthProvider);
    final linkState = ref.watch(linkControllerProvider);
    final isUnlinkedWarning = !session.linked && linkState is LinkNeedsWarning;
    final who = session.email ?? (session.provider == 'apple' ? 'Apple' : 'Google');
    final lastAt = health.lastOkAt ?? sync.lastAt;
    final status = (sync.running || health.running)
        ? 'Đang lưu online…'
        : health.net == NetState.offline
            ? 'Đang offline · ${health.pending} bài chưa lưu, sẽ tự lưu khi có mạng'
            : health.net == NetState.serverUnreachable
                ? 'Không kết nối được máy chủ · ${health.pending} bài chưa lưu, sẽ tự lưu khi kết nối lại'
                : sync.failed
                ? 'Chưa lưu được, sẽ thử lại khi có mạng'
                : lastAt == null
                    ? 'Chưa lưu lần nào'
                    : 'Đã lưu online lúc ${_hhmm(lastAt)}';
    return ParentCard(
      title: 'Tài khoản gia đình',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Đã đăng nhập: $who', style: _body),
          if (isUnlinkedWarning) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chưa lưu online: cần ba mẹ chọn dữ liệu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const ValueKey('reopen-warning'),
                  onPressed: () => _openWarning(context, linkState),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text(
                    'Xem',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(status, key: const ValueKey('sync-status'), style: _muted),
          ],
          const SizedBox(height: 14),
          _Button(
            key: const ValueKey('sync-now'),
            icon: Icons.cloud_sync_rounded,
            label: 'Lưu online ngay',
            onTap: sync.running
                ? null
                : () => ref.read(syncControllerProvider.notifier).syncNow(),
          ),
          const SizedBox(height: 10),
          _Button(
            key: const ValueKey('sign-out'),
            icon: Icons.logout_rounded,
            label: 'Đăng xuất',
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 10),
          _Button(
            key: const ValueKey('delete-account'),
            icon: Icons.delete_forever_rounded,
            label: 'Xóa tài khoản online',
            color: AppColors.primary,
            onTap: () => _delete(context),
          ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static const _body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const _muted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.text,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.dot, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.tile)),
      ),
    );
  }
}
