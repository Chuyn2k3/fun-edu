import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/sleep/sleep_screen.dart';
import '../profile/kid_repository.dart';
import '../ui/theme/tokens.dart';
import '../voice/speaker.dart';
import 'screen_time_service.dart';

/// Root back dispatcher that lets the guard take the system back button
/// while the sleep screen is up (so it never pops the hidden kid stack).
class ScreenTimeBackDispatcher extends RootBackButtonDispatcher {
  Future<bool> Function()? intercept;

  @override
  Future<bool> didPopRoute() {
    final handler = intercept;
    return handler != null ? handler() : super.didPopRoute();
  }
}

final ScreenTimeBackDispatcher screenTimeBackDispatcher =
    ScreenTimeBackDispatcher();

/// Speaker handed to the kid screens under the guard: silent while the
/// sleep screen is shown, otherwise the real one.
class _GatedSpeaker implements Speaker {
  _GatedSpeaker(this._real, this._muted);

  final Speaker Function() _real;
  final bool Function() _muted;

  @override
  Future<void> speak(String text) async {
    if (!_muted()) await _real().speak(text);
  }

  @override
  Future<void> stop() async {
    if (!_muted()) await _real().stop();
  }
}

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
  int? _kidId;
  ScreenTimeStatus _blocked = ScreenTimeStatus.ok;

  /// True from a route change until its async status check answers.
  bool _pending = false;
  int _checkGen = 0;
  bool _started = false;
  final _sleepNavigator = GlobalKey<NavigatorState>();
  // Captured early: kid screens call stop() from dispose, when this guard's
  // own ref may already be deactivated.
  late final ProviderContainer _container =
      ProviderScope.containerOf(context, listen: false);
  late final Speaker _gatedSpeaker = _GatedSpeaker(
    () => _container.read(speakerProvider),
    () => _blocked != ScreenTimeStatus.ok,
  );

  Listenable get _location => widget.router.routeInformationProvider;
  String get _path => widget.router.routeInformationProvider.value.uri.path;

  bool get _resumed =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _kidId = ref.read(currentKidIdProvider).valueOrNull;
    _container; // capture now
    _location.addListener(_onLocation);
    _onLocation();
    _syncTimer();
    _started = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _location.removeListener(_onLocation);
    screenTimeBackDispatcher.intercept = null;
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

  void _update(VoidCallback fn) {
    if (_started && mounted) {
      setState(fn);
    } else {
      fn();
    }
  }

  void _onLocation() {
    final path = _path;
    if (path == _lastPath) return;
    _lastPath = path;
    _flush();
    if (!isKidRoute(path) || path == '/placement') {
      // Never interrupt the placement test; parent/setup/dev are not kid time.
      _setBlocked(ScreenTimeStatus.ok);
    } else {
      _check();
    }
    _syncTimer();
  }

  void _onKidChanged(int? kid) {
    if (kid == _kidId) return;
    _flush(); // credits the previous kid
    _kidId = kid;
    _lastPath = null;
    _onLocation();
  }

  /// The timer runs only while resumed on a kid route and not asleep.
  void _syncTimer() {
    final active =
        _resumed && isKidRoute(_path) && _blocked == ScreenTimeStatus.ok;
    if (active && _timer == null) {
      _mark = ref.read(screenTimeClockProvider)();
      _timer = Timer.periodic(usageTick, (_) => _flush());
    } else if (!active && _timer != null) {
      _timer!.cancel();
      _timer = null;
      _mark = null;
    }
  }

  /// Saves the time since the last mark to the current kid; a clock jump is
  /// ignored.
  void _flush() {
    final mark = _mark;
    if (mark == null) return;
    final now = ref.read(screenTimeClockProvider)();
    _mark = now;
    final elapsed = now.difference(mark);
    if (elapsed <= Duration.zero || elapsed > const Duration(minutes: 5)) {
      return;
    }
    final kid = _kidId;
    if (kid == null) return;
    unawaited(ref.read(screenTimeServiceProvider).addUsage(kid, elapsed));
  }

  Future<void> _check() async {
    final gen = ++_checkGen;
    _update(() => _pending = true);
    final kid = await ref.read(currentKidIdProvider.future);
    final status = kid == null
        ? ScreenTimeStatus.ok
        : await ref.read(screenTimeServiceProvider).status(kid);
    if (!mounted || gen != _checkGen) return;
    _setBlocked(status);
  }

  void _setBlocked(ScreenTimeStatus s) {
    _checkGen++;
    if (s != ScreenTimeStatus.ok) _flush(); // credit the time before sleeping
    _update(() {
      _pending = false;
      _blocked = s;
    });
    screenTimeBackDispatcher.intercept =
        s == ScreenTimeStatus.ok ? null : _handleBack;
    _syncTimer();
  }

  /// Back while asleep closes the parent gate or dialog, else does nothing.
  Future<bool> _handleBack() async {
    await _sleepNavigator.currentState?.maybePop();
    return true;
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
    ref.listen<AsyncValue<int?>>(currentKidIdProvider, (_, next) {
      if (next.hasValue && !next.isLoading) _onKidChanged(next.value);
    });
    final asleep = _blocked != ScreenTimeStatus.ok;
    // The navigator stays mounted underneath (same tree position in every
    // state, so it keeps its state); while asleep it is hidden, frozen and
    // muted. A nested navigator gives the sleep screen its own routes.
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: asleep || _pending,
          child: TickerMode(
            enabled: !asleep,
            child: ProviderScope(
              overrides: [speakerProvider.overrideWithValue(_gatedSpeaker)],
              child: widget.child,
            ),
          ),
        ),
        if (_pending && !asleep) const ColoredBox(color: AppColors.background),
        if (asleep)
          Navigator(
            key: _sleepNavigator,
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
