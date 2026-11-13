import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../profile/kid_refresh.dart';
import '../../profile/kid_repository.dart';
import '../../progress/level_repository.dart';
import '../../screen_time/screen_time_service.dart';
import '../../ui/theme/tokens.dart';
import '../parent_unlock.dart';
import 'parent_card.dart';
import 'privacy_screen.dart';

const String _confirmWord = 'XÓA';

/// "Cài đặt" tab: voice, redo placement, privacy policy, delete all data.
/// [kidId] is the kid selected in the parent corner, null when none exists.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key, required this.kidId});

  final int? kidId;

  Future<void> _setVoice(WidgetRef ref, bool on) async {
    await ref.read(kidRepositoryProvider).setSetting(voiceEnabledKey, '$on');
    ref.invalidate(voiceEnabledProvider);
  }

  Future<void> _redoPlacement(
      BuildContext context, WidgetRef ref, int id) async {
    final messenger = ScaffoldMessenger.of(context);
    await LevelRepository(ref.read(databaseProvider), kidId: id)
        .clearLevels();
    refreshAfterKidChange(ref);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Bé sẽ làm lại bài xếp cấp lần sau')),
      );
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAllDialog(),
    );
    if (ok != true || !context.mounted) return;
    final router = GoRouter.of(context);
    await ref.read(kidRepositoryProvider).deleteAllData();
    // Leave the corner first: its rebuild must not ask for the gate again.
    router.go('/setup');
    ref.read(parentUnlockedUntilProvider.notifier).state = null;
    refreshAfterKidChange(ref);
    ref.invalidate(voiceEnabledProvider);
    ref.invalidate(screenTimeStatusProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceEnabledProvider).valueOrNull ?? true;
    final kids = ref.watch(kidsProvider).valueOrNull ?? const <KidProfile>[];
    final kid = kids.where((k) => k.id == kidId).firstOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Giọng đọc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Switch(
                  value: voice,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _setVoice(ref, v),
                ),
              ],
            ),
          ),
          if (kid != null) ...[
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.restart_alt_rounded,
              label: 'Làm lại bài xếp cấp cho ${kid.nickname}',
              onTap: () => _redoPlacement(context, ref, kid.id),
            ),
          ],
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.privacy_tip_rounded,
            label: 'Chính sách quyền riêng tư',
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.delete_forever_rounded,
            label: 'Xóa toàn bộ dữ liệu',
            color: AppColors.primary,
            onTap: () => _deleteAll(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.text,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: const [AppShadows.card],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks to type [_confirmWord]; pops true only when it matches exactly.
class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xóa toàn bộ dữ liệu?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mọi hồ sơ, tiến độ và cài đặt sẽ bị xóa khỏi máy này và '
              'không khôi phục được. Gõ $_confirmWord để xác nhận.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: _confirmWord),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _controller.text == _confirmWord
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Xóa hết'),
        ),
      ],
    );
  }
}
