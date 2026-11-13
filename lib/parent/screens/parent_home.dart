import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../profile/kid_repository.dart';
import '../../ui/layout/form_factor.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';
import '../parent_gate_route.dart';
import '../parent_unlock.dart';
import 'kids_tab.dart';
import 'parent_home_tablet.dart';
import 'progress_tab.dart';
import 'rewards_tab.dart';
import 'settings_tab.dart';
import 'time_tab.dart';

const _tabs = [
  (icon: Icons.insights_rounded, label: 'Tiến bộ'),
  (icon: Icons.face_rounded, label: 'Hồ sơ'),
  (icon: Icons.schedule_rounded, label: 'Thời gian'),
  (icon: Icons.card_giftcard_rounded, label: 'Phần thưởng'),
  (icon: Icons.settings_rounded, label: 'Cài đặt'),
];

const _contentMaxWidth = 640.0;

/// Parent corner shell: kid chips, tab body and bottom navigation. Behind the
/// parent gate: a deep link without a recent gate pass asks for it here.
class ParentHome extends ConsumerStatefulWidget {
  const ParentHome({super.key});

  @override
  ConsumerState<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends ConsumerState<ParentHome> {
  int _tab = 0;

  /// Kid shown in the corner; null until the user picks one (then the
  /// current kid is shown). Independent of the kid who is playing.
  int? _pickedKid;
  bool _asking = false;

  bool get _unlocked => isParentUnlocked(
        ref.read(parentUnlockedUntilProvider),
        DateTime.now(),
      );

  @override
  void initState() {
    super.initState();
    if (!_unlocked) WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  Future<void> _ask() async {
    if (_asking || !mounted) return;
    // The corner may still be on screen while a route change away from it
    // (e.g. after deleting all data) finishes animating: do not gate then.
    // `state` is the top route, also when the corner was pushed.
    final path = GoRouter.of(context).routerDelegate.state.uri.path;
    if (path != '/parent') return;
    _asking = true;
    final passed = await showParentGate(context);
    _asking = false;
    if (!mounted) return;
    if (passed) {
      setState(() {});
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      // Expired while open (or never unlocked): ask again.
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
      return const Scaffold(body: DottedBackground(child: SizedBox.expand()));
    }
    final kids = ref.watch(kidsProvider).valueOrNull ?? const <KidProfile>[];
    final currentId = ref.watch(currentKidIdProvider).valueOrNull;
    final selected = kids.any((k) => k.id == _pickedKid)
        ? _pickedKid
        : (kids.any((k) => k.id == currentId)
            ? currentId
            : kids.firstOrNull?.id);

    if (context.isTablet) {
      return ParentTabletShell(
        tabs: _tabs,
        tab: _tab,
        onTab: (i) => setState(() => _tab = i),
        kids: kids,
        selectedKid: selected,
        onSelectKid: (id) => setState(() => _pickedKid = id),
        body: _body(selected),
      );
    }

    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                children: [
                  _Header(
                    kids: kids,
                    selected: selected,
                    onSelect: (id) => setState(() => _pickedKid = id),
                  ),
                  Expanded(child: _body(selected)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.card,
        indicatorColor: Subject.viet.tint,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon, color: AppColors.textMuted),
              selectedIcon: Icon(t.icon, color: AppColors.text),
              label: t.label,
            ),
        ],
      ),
    );
  }

  Widget _body(int? kidId) {
    // Per-kid tabs are keyed by kid so their state resets on a kid change.
    switch (_tab) {
      case 0:
        return kidId == null
            ? const SizedBox.shrink()
            : ProgressTab(kidId: kidId);
      case 1:
        return const KidsTab();
      case 2:
        return kidId == null
            ? const SizedBox.shrink()
            : TimeTab(key: ValueKey(kidId), kidId: kidId);
      case 3:
        return kidId == null
            ? const SizedBox.shrink()
            : RewardsTab(key: ValueKey(kidId), kidId: kidId);
      default:
        return SettingsTab(kidId: kidId);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.kids,
    required this.selected,
    required this.onSelect,
  });

  final List<KidProfile> kids;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Góc ba mẹ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Về màn bé',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final k in kids)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(k.nickname),
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: k.id == selected ? Colors.white : AppColors.text,
                      ),
                      selected: k.id == selected,
                      selectedColor: AppColors.text,
                      backgroundColor: AppColors.card,
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      onSelected: (_) => onSelect(k.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
