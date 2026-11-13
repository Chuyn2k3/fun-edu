import 'package:flutter/material.dart';

import '../layout/form_factor.dart';
import '../theme/depth.dart';
import '../theme/tokens.dart';
import 'floating_nav_bar.dart';

/// Vertical navigation rail for tablets: a white raised pill with the icon
/// above the label; the selected item sits on a soft orange pill.
class NavRail extends StatelessWidget {
  const NavRail({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: TabletSizes.railWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: raisedDecoration(radius: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _RailTile(
              item: items[i],
              active: i == selected,
              onTap: () => onSelect(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The active icon stays orange; its label uses the text colour so it
    // reads at 4.5:1 on the orange pill.
    final iconColor = active ? AppColors.accent : AppColors.textMuted;
    final labelColor = active ? AppColors.text : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: TabletSizes.kidTarget,
              minHeight: TabletSizes.kidTarget,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.accent.withOpacity(0.12) : null,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: iconColor, size: 32),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    color: labelColor,
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
