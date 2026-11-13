import 'package:flutter/material.dart';

import 'parent_gate.dart';

/// Opens the parent gate full screen. Resolves to true only when the adult
/// answered correctly; closing or system back resolves to false.
Future<bool> showParentGate(BuildContext context) async {
  // Pop the route at most once, whichever callback fires first.
  var done = false;
  void finish(BuildContext routeContext, bool result) {
    if (done) return;
    done = true;
    Navigator.of(routeContext).pop(result);
  }

  final passed = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (routeContext) => ParentGate(
        onPassed: () => finish(routeContext, true),
        onCancel: () => finish(routeContext, false),
      ),
    ),
  );
  return passed ?? false;
}
