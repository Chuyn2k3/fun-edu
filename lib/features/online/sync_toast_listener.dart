import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/online_config.dart';
import '../../online/sync/sync_health.dart';
import '../../router.dart';
import '../../router_location.dart';
import '../../ui/feedback/feedback.dart';

/// Returns true for routes where parent-facing sync toast notifications are
/// allowed (Home and Góc ba mẹ); kid learning/racing routes stay quiet.
bool isSyncToastRoute(String path) =>
    path == '/' || path == '/parent' || path.startsWith('/parent/');

/// Listens for `syncHealthProvider`'s [SyncHealthNotifier.onSavedAfterOffline]
/// and displays a gentle online toast only on Home or Góc ba mẹ.
class SyncToastListener extends ConsumerStatefulWidget {
  const SyncToastListener({
    super.key,
    required this.child,
    this.pathResolver,
    this.navigatorKey,
  });

  final Widget child;
  final String Function()? pathResolver;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  ConsumerState<SyncToastListener> createState() => _SyncToastListenerState();
}

class _SyncToastListenerState extends ConsumerState<SyncToastListener> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(syncHealthProvider.notifier).onSavedAfterOffline.listen((_) {
      if (!mounted) return;
      final path =
          widget.pathResolver?.call() ?? RouterLocation.of(appRouter).path;
      if (!isSyncToastRoute(path)) return;
      final navState = widget.navigatorKey?.currentState ??
          appRouter.routerDelegate.navigatorKey.currentState;
      final navContext = navState?.context ?? context;
      if (!navContext.mounted) return;
      showAppToast(
        navContext,
        'Đã lưu online tiến độ của bé ✓',
        kind: AppToastKind.online,
        overlayState: navState?.overlay,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep provider alive when online is enabled.
    if (ref.watch(onlineConfigProvider).enabled) {
      ref.watch(syncHealthProvider);
    }
    return widget.child;
  }
}
