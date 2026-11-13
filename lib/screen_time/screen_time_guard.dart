import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/sleep/sleep_screen.dart';
import '../profile/kid_repository.dart';
import 'screen_time_service.dart';

const Duration usageTick = Duration(seconds: 15);

/// Parent corner, setup and dev screens are not kid time.
bool isKidRoute(String path) =>
    path != '/setup' &&
    path != '/parent' &&
    !path.startsWith('/parent/') &&
    !path.startsWith('/dev/');

/// Wraps the app navigator. While the app is in the foreground on a kid
/// route it adds usage every [usageTick] (and flushes when paused). The
/// status is checked only when the location changes, so a screen in progress
/// is never cut short; a non-ok status then swaps in the [SleepScreen].
class ScreenTimeGuard extends ConsumerStatefulWidget {
  const ScreenTimeGuard({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<ScreenTimeGuard> createState() => _ScreenTimeGuardState();
}

class _ScreenTimeGuardState extends ConsumerState<ScreenTimeGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _mark;
  String? _lastPath;
  ScreenTimeStatus _blocked = ScreenTimeStatus.ok;
  int _checkGen = 0;

  Listenable get _location => widget.router.routeInformationProvider;
  String get _path => widget.router.routeInformationProvider.value.uri.path;

  bool get _resumed =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_onLocation);
    _syncTimer();
    _onLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _location.removeListener(_onLocation);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimer();
    } else {
      _flush();
      _timer?.cancel();
      _timer = null;
      _mark = null;
    }
  }

  void _onLocation() {
    final path = _path;
    if (path == _lastPath) return;
    _lastPath = path;
    _flush();
    _syncTimer();
    if (!isKidRoute(path) || path == '/placement') {
      // Never interrupt the placement test; parent/setup/dev are not kid time.
      _setBlocked(ScreenTimeStatus.ok);
      return;
    }
    _check();
  }

  /// The timer runs only while resumed on a kid route.
  void _syncTimer() {
    final active = _resumed && isKidRoute(_path);
    if (active && _timer == null) {
      _mark = ref.read(screenTimeClockProvider)();
      _timer = Timer.periodic(usageTick, (_) => _flush());
    } else if (!active && _timer != null) {
      _timer!.cancel();
      _timer = null;
      _mark = null;
    }
  }

  /// Saves the time since the last mark; a clock jump is ignored.
  void _flush() {
    final mark = _mark;
    if (mark == null) return;
    final now = ref.read(screenTimeClockProvider)();
    _mark = now;
    final elapsed = now.difference(mark);
    if (elapsed <= Duration.zero || elapsed > const Duration(minutes: 5)) {
      return;
    }
    final kid = ref.read(currentKidIdProvider).valueOrNull;
    if (kid == null) return;
    unawaited(ref.read(screenTimeServiceProvider).addUsage(kid, elapsed));
  }

  Future<void> _check() async {
    final gen = ++_checkGen;
    final kid = await ref.read(currentKidIdProvider.future);
    if (kid == null) return;
    final status = await ref.read(screenTimeServiceProvider).status(kid);
    if (!mounted || gen != _checkGen) return;
    _setBlocked(status);
  }

  void _setBlocked(ScreenTimeStatus s) {
    _checkGen++;
    if (s == _blocked) return;
    setState(() => _blocked = s);
  }

  void _afterGrant() {
    widget.router.go('/');
    _setBlocked(ScreenTimeStatus.ok);
    // Re-check in case the location did not change (already at home).
    _check();
  }

  VoidCallback? get _openParent {
    final exists =
        !widget.router.configuration.findMatch(Uri.parse('/parent')).isError;
    if (!exists) return null;
    return () {
      widget.router.go('/parent');
      _setBlocked(ScreenTimeStatus.ok);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked == ScreenTimeStatus.ok) return widget.child;
    // The navigator stays mounted underneath; a nested one gives the sleep
    // screen its own routes for the parent gate.
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(child: widget.child),
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => SleepScreen(
              status: _blocked,
              onExtraGranted: _afterGrant,
              onOpenParentCorner: _openParent,
            ),
          ),
        ),
      ],
    );
  }
}
