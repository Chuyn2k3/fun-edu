import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../ui/theme/depth.dart';
import '../../ui/theme/tokens.dart';
import '../../ui/widgets/dotted_background.dart';

/// Width of the left pane (kid chips and tab list) of the tablet parent corner.
const parentPaneWidth = 300.0;

/// Widest the right (tab content) pane grows.
const parentDetailMaxWidth = 720.0;

/// Height of one tab row in the left pane.
const parentTabRowHeight = 60.0;

/// Tablet parent corner: list on the left, the selected tab on the right.
/// Uses parent sizes (targets >= 48), not the kid ones.
class ParentTabletShell extends StatelessWidget {
  const ParentTabletShell({
    super.key,
    required this.tabs,
    required this.tab,
    required this.onTab,
    required this.kids,
    required this.selectedKid,
    required this.onSelectKid,
    required this.body,
  });

  final List<({IconData icon, String label})> tabs;
  final int tab;
  final ValueChanged<int> onTab;
  final List<KidProfile> kids;
  final int? selectedKid;
  final ValueChanged<int> onSelectKid;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: parentPaneWidth,
                child: _LeftPane(
                  tabs: tabs,
                  tab: tab,
                  onTab: onTab,
                  kids: kids,
                  selectedKid: selectedKid,
                  onSelectKid: onSelectKid,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: parentDetailMaxWidth),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftPane extends StatelessWidget {
  const _LeftPane({
    required this.tabs,
    required this.tab,
    required this.onTab,
    required this.kids,
    required this.selectedKid,
    required this.onSelectKid,
  });

  final List<({IconData icon, String label})> tabs;
  final int tab;
  final ValueChanged<int> onTab;
  final List<KidProfile> kids;
  final int? selectedKid;
  final ValueChanged<int> onSelectKid;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Góc ba mẹ',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
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
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final k in kids)
                ChoiceChip(
                  label: Text(k.nickname),
                  labelStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: k.id == selectedKid ? AppColors.card : AppColors.text,
                  ),
                  selected: k.id == selectedKid,
                  selectedColor: AppColors.text,
                  backgroundColor: AppColors.card,
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onSelected: (_) => onSelectKid(k.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < tabs.length; i++) ...[
            _TabRow(
              icon: tabs[i].icon,
              label: tabs[i].label,
              selected: i == tab,
              onTap: () => onTab(i),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: parentTabRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // One decoration with fill (and shadow when selected).
          decoration: selected
              ? raisedDecoration(
                  accent: Subject.viet.color,
                  tint: Subject.viet.tint,
                  radius: AppRadii.tile,
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                    color: selected ? AppColors.text : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
