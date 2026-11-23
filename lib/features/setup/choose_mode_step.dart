import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/auth/identity_providers.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/message_card.dart';
import '../../ui/widgets/primary_button.dart';

/// The first-launch step asking parents to choose between signing in
/// to sync and persist progress or trying guest mode.
class ChooseModeStep extends ConsumerWidget {
  const ChooseModeStep({
    super.key,
    required this.onGuest,
    required this.onSignIn,
  });

  final VoidCallback onGuest;
  final Future<void> Function(String provider) onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(identityProvidersProvider);
    final isTablet = context.isTablet;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Image.asset(
            AppImages.chipMain,
            height: isTablet ? 140.0 * tabletChipScale : 140.0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Lưu tiến độ của bé',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đăng nhập để giữ tiến độ khi đổi máy và dùng trên nhiều máy.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          key: const ValueKey('sign-in-google'),
          label: 'Đăng nhập với Google',
          onPressed: () => onSignIn('google'),
        ),
        if (ids.appleAvailable) ...[
          const SizedBox(height: 12),
          PrimaryButton(
            key: const ValueKey('sign-in-apple'),
            label: 'Đăng nhập với Apple',
            onPressed: () => onSignIn('apple'),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          key: const ValueKey('guest-mode-button'),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: AppColors.text,
          ),
          onPressed: onGuest,
          child: const Text(
            'Dùng thử không cần tài khoản',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dữ liệu chỉ lưu trên máy này, xóa app là mất.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
