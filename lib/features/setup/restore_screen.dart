import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/link/link_controller.dart';
import '../../ui/assets.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../../ui/widgets/message_card.dart';
import '../../ui/widgets/primary_button.dart';

/// Screen displayed while restoring an existing family's data from the server.
class RestoreScreen extends ConsumerWidget {
  const RestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(linkControllerProvider);
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
                      if (isFailed) ...[
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
