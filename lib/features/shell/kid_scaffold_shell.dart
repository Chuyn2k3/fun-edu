import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The root shell hosting the kid's 4 primary navigation branches:
/// Home (/), Góc Chơi (/game), Sưu tập (/collection), and Nhà Chíp (/house).
///
/// Uses [StatefulNavigationShell] so branch states and scroll positions
/// are preserved in an [IndexedStack] across tab switches without
/// destroying/recreating widget trees, enabling 0ms instant tab changes.
class KidScaffoldShell extends StatelessWidget {
  const KidScaffoldShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return navigationShell;
  }
}
