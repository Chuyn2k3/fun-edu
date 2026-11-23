import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/auth/identity_providers.dart';
import '../../online/auth/session_controller.dart';
import '../../online/link/link_controller.dart';
import '../../ui/assets.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/message_card.dart';
import '../../ui/widgets/primary_button.dart';
import '../online/online_consent_dialog.dart';

/// Screen displayed while restoring an existing family's data from the server.
class RestoreScreen extends ConsumerWidget {
  const RestoreScreen({super.key});

  Future<void> _reSignIn(BuildContext context, WidgetRef ref) async {
    final ids = ref.read(identityProvidersProvider);
    if (!ids.appleAvailable) {
      await _doSignIn(context, ref, 'google');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                key: const ValueKey('re-sign-in-google'),
                label: 'Đăng nhập với Google',
                onPressed: () {
                  Navigator.pop(ctx);
                  _doSignIn(context, ref, 'google');
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                key: const ValueKey('re-sign-in-apple'),
                label: 'Đăng nhập với Apple',
                onPressed: () {
                  Navigator.pop(ctx);
                  _doSignIn(context, ref, 'apple');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doSignIn(
      BuildContext context, WidgetRef ref, String provider) async {
    final agreed = await showOnlineConsentDialog(context);
    if (!agreed || !context.mounted) return;
    try {
      await ref.read(sessionProvider.notifier).signIn(provider);
      if (!context.mounted) return;
      await ref.read(linkControllerProvider.notifier).resumeIfPending();
    } on SignInException catch (e) {
      if (!context.mounted) return;
      final why = kDebugMode && e.detail != null ? '\n(${e.detail})' : '';
      String msg;
      switch (e.failure) {
        case SignInFailure.cancelled:
          return;
        case SignInFailure.setup:
          msg =
              'Chưa đăng nhập được với Google/Apple trên máy này, ba mẹ thử lại sau nhé$why';
        case SignInFailure.network:
          msg = 'Không kết nối được máy chủ, ba mẹ thử lại sau nhé$why';
        case SignInFailure.rejected:
          msg = 'Đăng nhập không thành công, ba mẹ thử lại nhé$why';
      }
      showAppToast(context, msg, kind: AppToastKind.warning);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(linkControllerProvider);
    final isSignedOut =
        state is LinkRestoreFailed && state.message == 'signed_out';
    final isFailed = state is LinkFailed;
    final isTablet = context.isTablet;

    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? TabletSizes.messageMaxWidth : 560,
                ),
                child: MessageCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: Image.asset(
                          AppImages.chipMain,
                          height: isTablet ? 140.0 * tabletChipScale : 140.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isSignedOut) ...[
                        const Text(
                          'Phiên đăng nhập đã hết, ba mẹ đăng nhập lại nhé',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          key: const ValueKey('re-sign-in'),
                          label: 'Đăng nhập lại',
                          onPressed: () => _reSignIn(context, ref),
                        ),
                      ] else if (isFailed) ...[
                        const Text(
                          'Chưa tải được, ba mẹ kiểm tra mạng nhé',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          key: const ValueKey('retry-restore'),
                          label: 'Thử lại',
                          onPressed: () => ref
                              .read(linkControllerProvider.notifier)
                              .retryRestore(),
                        ),
                      ] else ...[
                        const Text(
                          'Đang tải dữ liệu của bé…',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
