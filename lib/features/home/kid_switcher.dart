import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../parent/parent_gate_route.dart';
import '../../profile/kid_refresh.dart';
import '../../profile/kid_repository.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../setup/kid_profile_form.dart';

/// Opens the kid switcher as a bottom sheet.
Future<void> showKidSwitcher(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const KidSwitcher(),
    );

/// Lists the kids (current one outlined in orange) and offers "Thêm bé".
class KidSwitcher extends ConsumerStatefulWidget {
  const KidSwitcher({super.key});

  @override
  ConsumerState<KidSwitcher> createState() => _KidSwitcherState();
}

class _KidSwitcherState extends ConsumerState<KidSwitcher> {
  bool _busy = false;

  Future<void> _select(KidProfile kid, int? currentId) async {
    if (_busy) return;
    if (kid.id == currentId) {
      Navigator.of(context).pop();
      return;
    }
    _busy = true;
    final navigator = Navigator.of(context);
    await ref.read(kidRepositoryProvider).setCurrentKid(kid.id);
    refreshAfterKidChange(ref);
    if (mounted) navigator.pop();
  }

  Future<void> _addKid() async {
    if (_busy) return;
    _busy = true;
    try {
      final passed = await showParentGate(context);
      if (!passed || !mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const AddKidScreen()),
      );
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kids = ref.watch(kidsProvider).valueOrNull ?? const <KidProfile>[];
    final currentId = ref.watch(currentKidIdProvider).valueOrNull;
    final full = kids.length >= maxKids;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ai đang học nào?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final kid in kids)
                  _KidTile(
                    kid: kid,
                    selected: kid.id == currentId,
                    onTap: () => _select(kid, currentId),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
              ),
              onPressed: full ? null : _addKid,
              icon: full ? const SizedBox.shrink() : const Icon(Icons.add),
              label: Text(
                full ? 'Tối đa 4 bé' : 'Thêm bé',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidTile extends StatelessWidget {
  const _KidTile({
    required this.kid,
    required this.selected,
    required this.onTap,
  });

  final KidProfile kid;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: kid.nickname,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 104,
          child: InkWell(
            key: ValueKey('kid-${kid.id}'),
            borderRadius: BorderRadius.circular(AppRadii.tile),
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Ink(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.dot,
                      width: selected ? 4 : 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(kid.avatar, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kid.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tạo hồ sơ cho bé" as its own page, opened from [KidSwitcher].
class AddKidScreen extends ConsumerWidget {
  const AddKidScreen({super.key});

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
                  onSubmit: (nickname, avatar, age) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await ref.read(kidRepositoryProvider).addKid(
                            nickname: nickname,
                            avatar: avatar,
                            age: age,
                          );
                      refreshAfterKidChange(ref);
                      navigator.pop();
                    } catch (e, st) {
                      debugPrint('add kid failed: $e\n$st');
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
