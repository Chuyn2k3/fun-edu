import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/link/account_summary.dart';
import '../../online/link/link_controller.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';

/// Warning dialog shown when a guest device signs into an account that already
/// contains family data.
class ReplaceDataDialog extends ConsumerStatefulWidget {
  const ReplaceDataDialog({
    super.key,
    required this.local,
    required this.account,
    required this.accountLabel,
  });

  final List<KidSummary> local;
  final AccountSummary account;
  final String accountLabel;

  @override
  ConsumerState<ReplaceDataDialog> createState() => _ReplaceDataDialogState();
}

class _ReplaceDataDialogState extends ConsumerState<ReplaceDataDialog> {
  @override
  void dispose() {
    _isReplaceDataDialogOpen = false;
    super.dispose();
  }

  String _formatKid(KidSummary k) {
    return '${k.nickname} · ${k.stars}⭐ · ${k.glyphs} chữ · ${k.pages} trang vở · ${k.items} món đồ';
  }

  Future<void> _onCancel(BuildContext context) async {
    await ref.read(linkControllerProvider.notifier).cancelReplace();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _onConfirmDanger(BuildContext context) async {
    final kidsNames = widget.local.map((k) => k.nickname).where((n) => n.isNotEmpty).join(', ');
    final target = kidsNames.isNotEmpty ? kidsNames : 'các bé';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa dữ liệu của $target trên máy này?'),
        content: const Text(
          'Dữ liệu trên máy này sẽ bị xóa và thay bằng dữ liệu của tài khoản. '
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-second-delete'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            key: const ValueKey('confirm-second-delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(linkControllerProvider.notifier).confirmReplace();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Widget _buildBox({
    required Key key,
    required String title,
    required List<KidSummary> kids,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.dot, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          for (final k in kids)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.w900)),
                  Expanded(
                    child: Text(
                      _formatKid(k),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    final localBox = _buildBox(
      key: const ValueKey('local-data-box'),
      title: 'Trên máy này (dùng thử)',
      kids: widget.local,
    );

    final accountBox = _buildBox(
      key: const ValueKey('account-data-box'),
      title: 'Tài khoản ${widget.accountLabel}',
      kids: widget.account.kids,
    );

    return PopScope(
      canPop: false,
      child: Semantics(
        label: 'Hộp cảnh báo thay dữ liệu',
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 720 : 440,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tài khoản này đã có dữ liệu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: localBox),
                        const SizedBox(width: 14),
                        Expanded(child: accountBox),
                      ],
                    )
                  else ...[
                    localBox,
                    const SizedBox(height: 10),
                    accountBox,
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'Nếu tiếp tục, dữ liệu trên máy này (tiến độ, sao, sticker, vở của bé) sẽ bị XÓA và thay bằng dữ liệu của tài khoản. Không hoàn tác được.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const ValueKey('cancel-replace'),
                    onPressed: () => _onCancel(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppColors.dot, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.tile),
                      ),
                    ),
                    child: const Text(
                      'Hủy, tiếp tục dùng thử',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    key: const ValueKey('confirm-replace-danger'),
                    onPressed: () => _onConfirmDanger(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.tile),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Xóa dữ liệu trên máy và dùng tài khoản',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isReplaceDataDialogOpen = false;
bool get isReplaceDataDialogOpen => _isReplaceDataDialogOpen;
@visibleForTesting
set isReplaceDataDialogOpen(bool value) => _isReplaceDataDialogOpen = value;

Future<void> showReplaceDataDialog(
  BuildContext context, {
  required List<KidSummary> local,
  required AccountSummary account,
  required String accountLabel,
}) async {
  if (_isReplaceDataDialogOpen) return;
  _isReplaceDataDialogOpen = true;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReplaceDataDialog(
        local: local,
        account: account,
        accountLabel: accountLabel,
      ),
    );
  } finally {
    _isReplaceDataDialogOpen = false;
  }
}
