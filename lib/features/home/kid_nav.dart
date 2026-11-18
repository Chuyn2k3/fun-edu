import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/widgets/floating_nav_bar.dart';

/// The kid's main navigation (bottom bar on phones, rail on tablets):
/// "Học" is home, "Chơi" the Góc Chơi hub, "Sưu tập" the learning collection;
/// "Nhà Chíp" is not built yet.
const kidNavItems = [
  NavItem(icon: Icons.home_rounded, label: 'Học'),
  NavItem(icon: Icons.sports_esports_rounded, label: 'Chơi'),
  NavItem(icon: Icons.collections_bookmark_rounded, label: 'Sưu tập'),
  NavItem(icon: Icons.cottage_rounded, label: 'Nhà Chíp'),
];

const kidNavHome = 0;
const kidNavPlay = 1;
const kidNavCollection = 2;

/// Handles a tap on item [i] of [kidNavItems] from the tab [current].
void onKidNav(BuildContext context, int i, {required int current}) {
  if (i == current) return;
  switch (i) {
    case kidNavHome:
      context.go('/');
    case kidNavPlay:
      context.go('/game');
    case kidNavCollection:
      context.go('/collection');
    default:
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Sắp có')));
  }
}
