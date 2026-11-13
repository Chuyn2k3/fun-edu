import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../features/home/kid_switcher.dart';
import '../../features/setup/kid_profile_form.dart';
import '../../profile/kid_refresh.dart';
import '../../profile/kid_repository.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import 'parent_card.dart';

/// "Hồ sơ" tab: kid profiles with edit, delete and add.
class KidsTab extends ConsumerWidget {
  const KidsTab({super.key});

  Future<void> _delete(
      BuildContext context, WidgetRef ref, KidProfile kid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Xóa hồ sơ ${kid.nickname}? '
            'Toàn bộ tiến độ của bé sẽ mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(kidRepositoryProvider);
    await repo.deleteKid(kid.id);
    refreshAfterKidChange(ref);
    if ((await repo.kids()).isEmpty && context.mounted) context.go('/setup');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kids = ref.watch(kidsProvider).valueOrNull ?? const <KidProfile>[];
    final full = kids.length >= maxKids;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kid in kids) ...[
            ParentCard(
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(kid.avatar,
                        width: 48, height: 48, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kid.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          '${kid.age} tuổi',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: ValueKey('edit-${kid.id}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                          builder: (_) => EditKidScreen(kid: kid)),
                    ),
                    child: const Text('Sửa', style: _actionStyle),
                  ),
                  TextButton(
                    key: ValueKey('delete-${kid.id}'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: AppColors.textMuted,
                    ),
                    onPressed: () => _delete(context, ref, kid),
                    child: const Text('Xóa', style: _actionStyle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
            onPressed: full
                ? null
                : () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                          builder: (_) => const AddKidScreen()),
                    ),
            icon: full ? const SizedBox.shrink() : const Icon(Icons.add),
            label: Text(
              full ? 'Tối đa 4 bé' : 'Thêm bé',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

const _actionStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);

/// Edits an existing profile with the same form as "Thêm bé".
class EditKidScreen extends ConsumerWidget {
  const EditKidScreen({super.key, required this.kid});

  final KidProfile kid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: DottedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: KidProfileForm(
                  title: 'Sửa hồ sơ',
                  initialNickname: kid.nickname,
                  initialAvatar: kid.avatar,
                  initialAge: kid.age,
                  onSubmit: (nickname, avatar, age) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await ref.read(kidRepositoryProvider).updateKid(
                            kid.id,
                            nickname: nickname,
                            avatar: avatar,
                            age: age,
                          );
                      refreshAfterKidChange(ref);
                      navigator.pop();
                    } catch (e, st) {
                      debugPrint('edit kid failed: $e\n$st');
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Không lưu được hồ sơ')),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
