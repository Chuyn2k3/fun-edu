import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/online/online_consent_dialog.dart';
import '../../online/auth/identity_providers.dart';
import '../../online/auth/session_controller.dart';
import '../../online/online_config.dart';
import '../../online/sync/sync_engine.dart';
import '../../ui/theme/tokens.dart';
import 'parent_card.dart';

/// "Tài khoản gia đình" in Góc ba mẹ: sign in with Google or Apple to keep
/// the kids' progress online and share it between devices. Hidden entirely
/// in a build without a server address.
class FamilyAccountCard extends ConsumerWidget {
  const FamilyAccountCard({super.key});

  static void _say(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref, String provider) async {
    final agreed = await showOnlineConsentDialog(context);
    if (!agreed || !context.mounted) return;
    try {
      await ref.read(sessionProvider.notifier).signIn(provider);
      if (context.mounted) _say(context, 'Đã đăng nhập. Đang lưu tiến độ online…');
    } on SignInException catch (e) {
      if (!context.mounted) return;
      // Debug builds add the technical reason, so setting up a build is
      // not guesswork; parents only see the plain sentence.
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
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionProvider.notifier).signOut();
    if (context.mounted) _say(context, 'Đã đăng xuất. Dữ liệu trên máy này vẫn giữ nguyên');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản online?'),
        content: const Text(
          'Mọi dữ liệu online của gia đình sẽ bị xóa vĩnh viễn khỏi máy chủ. '
          'Dữ liệu trên máy này vẫn giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            key: const ValueKey('confirm-delete-account'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(sessionProvider.notifier).deleteAccount();
      if (context.mounted) _say(context, 'Đã xóa tài khoản online');
    } catch (_) {
      if (context.mounted) {
        _say(context, 'Chưa xóa được, ba mẹ kiểm tra mạng rồi thử lại nhé');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(onlineConfigProvider).enabled) return const SizedBox.shrink();
    final session = ref.watch(sessionProvider).valueOrNull;
    final ids = ref.watch(identityProvidersProvider);

    if (session == null) {
      return ParentCard(
        title: 'Lưu tiến độ online',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Đăng nhập để giữ tiến độ của các bé khi đổi máy và dùng chung '
              'trên điện thoại, máy tính bảng. Nét vẽ của bé vẫn chỉ ở trên máy này.',
              style: _body,
            ),
            const SizedBox(height: 14),
            _Button(
              key: const ValueKey('sign-in-google'),
              icon: Icons.account_circle_rounded,
              label: 'Đăng nhập với Google',
              onTap: () => _signIn(context, ref, 'google'),
            ),
            if (ids.appleAvailable) ...[
              const SizedBox(height: 10),
              _Button(
                key: const ValueKey('sign-in-apple'),
                icon: Icons.apple_rounded,
                label: 'Đăng nhập với Apple',
                onTap: () => _signIn(context, ref, 'apple'),
              ),
            ],
          ],
        ),
      );
    }

    final sync = ref.watch(syncControllerProvider);
    final who = session.email ?? (session.provider == 'apple' ? 'Apple' : 'Google');
    final status = sync.running
        ? 'Đang lưu online…'
        : sync.failed
            ? 'Chưa lưu được, sẽ thử lại khi có mạng'
            : sync.lastAt == null
                ? 'Chưa lưu lần nào'
                : 'Đã lưu online lúc ${_hhmm(sync.lastAt!)}';
    return ParentCard(
      title: 'Tài khoản gia đình',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Đã đăng nhập: $who', style: _body),
          const SizedBox(height: 4),
          Text(status, key: const ValueKey('sync-status'), style: _muted),
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
            onTap: () => _signOut(context, ref),
          ),
          const SizedBox(height: 10),
          _Button(
            key: const ValueKey('delete-account'),
            icon: Icons.delete_forever_rounded,
            label: 'Xóa tài khoản online',
            color: AppColors.primary,
            onTap: () => _delete(context, ref),
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

