import 'package:flutter/material.dart';

import 'parent_gate.dart';

/// Opens the parent gate full screen. Resolves to true only when the adult
/// answered correctly; closing or system back resolves to false.
Future<bool> showParentGate(BuildContext context) async {
  final passed = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (routeContext) => ParentGate(
        onPassed: () => Navigator.of(routeContext).pop(true),
        onCancel: () => Navigator.of(routeContext).pop(false),
      ),
    ),
  );
  return passed ?? false;
}
