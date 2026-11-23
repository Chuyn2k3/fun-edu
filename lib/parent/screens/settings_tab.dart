import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../online/sync/sync_engine.dart';
import '../../profile/kid_refresh.dart';
import '../../profile/kid_repository.dart';
import '../../progress/level_repository.dart';
import '../../screen_time/screen_time_service.dart';
import '../../ui/feedback/feedback.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../parent_unlock.dart';
import 'family_account_card.dart';
import 'parent_card.dart';
import 'privacy_screen.dart';

const String _confirmWord = 'XÓA';

/// "Cài đặt" tab: voice, family account (online), redo placement, privacy
/// policy, delete all data.
/// [kidId] is the kid selected in the parent corner, null when none exists.
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({
    super.key,
    required this.kidId,
    this.focusAccount = false,
  });

  final int? kidId;
  final bool focusAccount;

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _accountKey = GlobalKey();
  bool _scrolledToAccount = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusAccount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _scrolledToAccount) return;
        final ctx = _accountKey.currentContext;
        if (ctx != null) {
          _scrolledToAccount = true;
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.1,
          );
        }
      });
    }
  }

  Future<void> _setVoice(bool on) async {
    await ref.read(kidRepositoryProvider).setSetting(voiceEnabledKey, '$on');
    ref.invalidate(voiceEnabledProvider);
  }

  Future<void> _setTeaseStickers(int kidId, bool on) async {
    await ref
        .read(kidRepositoryProvider)
        .setSetting(teaseStickersKey(kidId), '$on');
    ref.invalidate(kidTeaseStickersProvider(kidId));
    ref.invalidate(teaseStickersProvider);
    ref.read(syncControllerProvider.notifier).requestSync();
  }

  Future<void> _redoPlacement(BuildContext context, int id) async {
    await LevelRepository(ref.read(databaseProvider), kidId: id)
        .clearLevels();
    refreshAfterKidChange(ref);
    if (context.mounted) {
      showAppToast(context, 'Bé sẽ làm lại bài xếp cấp lần sau',
          kind: AppToastKind.info);
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    final canDelete = ValueNotifier<bool>(false);
    final confirmed = await showAppDialog<bool>(
      context,
      title: 'Xóa toàn bộ dữ liệu?',
      primaryLabel: 'Hủy',
      secondaryLabel: 'Xóa hết',
      tone: AppDialogTone.danger,
      audience: AppAudience.parent,
      secondaryEnabled: canDelete,
      body: _DeleteAllBody(canDelete: canDelete),
    );
    canDelete.dispose();

    if (confirmed != false || !context.mounted) return;
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
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceEnabledProvider).valueOrNull ?? true;
    final kids = ref.watch(kidsProvider).valueOrNull ?? const <KidProfile>[];
    final kid = kids.where((k) => k.id == widget.kidId).firstOrNull;
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
                  key: const ValueKey('voice-enabled-switch'),
                  value: voice,
                  activeColor: AppColors.primary,
                  onChanged: _setVoice,
                ),
              ],
            ),
          ),
          if (kid != null) ...[
            const SizedBox(height: 12),
            ParentCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sticker trêu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hiện và gửi sticker trêu vui khi đua cùng bạn',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('tease-stickers-switch'),
                    value: ref.watch(kidTeaseStickersProvider(kid.id)).valueOrNull ??
                        true,
                    activeColor: AppColors.primary,
                    onChanged: (on) => _setTeaseStickers(kid.id, on),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          FamilyAccountCard(key: _accountKey),
          if (kid != null) ...[
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.restart_alt_rounded,
              label: 'Làm lại bài xếp cấp cho ${kid.nickname}',
              onTap: () => _redoPlacement(context, kid.id),
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
            onTap: () => _deleteAll(context),
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
        decoration: raisedDecoration(),
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

class _DeleteAllBody extends StatefulWidget {
  final ValueNotifier<bool> canDelete;
  const _DeleteAllBody({required this.canDelete});

  @override
  State<_DeleteAllBody> createState() => _DeleteAllBodyState();
}

class _DeleteAllBodyState extends State<_DeleteAllBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mọi hồ sơ, tiến độ và cài đặt sẽ bị xóa khỏi máy này và '
          'không khôi phục được. Gõ $_confirmWord để xác nhận.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (text) => widget.canDelete.value = (text == _confirmWord),
          decoration: const InputDecoration(hintText: _confirmWord),
        ),
      ],
    );
  }
}


