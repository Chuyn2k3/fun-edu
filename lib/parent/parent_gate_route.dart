import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'parent_gate.dart';
import 'parent_unlock.dart';

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
  if (passed == true && context.mounted) {
    // Remember the pass so the parent corner does not ask again right away.
    // Some callers (tests) have no ProviderScope above them.
    try {
      ProviderScope.containerOf(context, listen: false)
          .read(parentUnlockedUntilProvider.notifier)
          .state = DateTime.now().add(parentUnlockDuration);
    } on StateError {
      // No ProviderScope: nothing to remember.
    }
  }
  return passed ?? false;
}

/// Shows the parent gate and pushes `/parent` on success (optionally focusing a
/// section such as `account`).
Future<void> openParentCorner(BuildContext context, {String? focus}) async {
  final passed = await showParentGate(context);
  if (!passed || !context.mounted) return;
  final target = Uri(
    path: '/parent',
    queryParameters: focus == null ? null : {'focus': focus},
  ).toString();
  context.push(target);
}
