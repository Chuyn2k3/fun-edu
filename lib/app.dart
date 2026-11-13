import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/splash/splash_view.dart';
import 'profile/kid_repository.dart';
import 'progress/level_repository.dart';
import 'router.dart';
import 'router_location.dart';
import 'screen_time/screen_time_guard.dart';
import 'ui/layout/orientation_lock.dart';
import 'ui/precache.dart';
import 'ui/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  static bool _precached = false;

  // GoRouter's redirect is synchronous, so the async checks live here:
  // no kid -> /setup, then an unplaced kid -> /placement.
  // Follows pops as well as go/push, so leaving /parent re-applies the rules.
  static RouterLocation get _location => RouterLocation.of(appRouter);
  static String _currentPath() => _location.path;

  static bool _isDev(String p) => p.startsWith('/dev/');
  static bool _isParent(String p) => p == '/parent' || p.startsWith('/parent/');

  /// Where the app must be sent from [path], or null to stay.
  static String? _target(String path, {required bool hasKid, bool? placed}) {
    if (_isDev(path) || path == '/setup' || _isParent(path)) return null;
    if (!hasKid) return '/setup';
    if (placed == false && path != '/placement') return '/placement';
    return null;
  }

  void _redirect(WidgetRef ref) {
    final kid = ref.read(currentKidIdProvider);
    if (kid.isLoading || !kid.hasValue) return;
    final hasKid = kid.value != null;
    bool? placed;
    if (hasKid) {
      final p = ref.read(isPlacedProvider);
      if (p.isLoading || !p.hasValue) return;
      placed = p.value;
    }
    final target = _target(_currentPath(), hasKid: hasKid, placed: placed);
    if (target != null) appRouter.go(target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<int?>>(currentKidIdProvider, (_, __) {
      _redirect(ref);
    });
    ref.listen<AsyncValue<bool>>(isPlacedProvider, (_, __) {
      _redirect(ref);
    });
    final kid = ref.watch(currentKidIdProvider);
    final placed = ref.watch(isPlacedProvider);
    // Load the voice setting before any screen can speak.
    final voice = ref.watch(voiceEnabledProvider);
    return MaterialApp.router(
      title: 'Chíp Chíp',
      theme: buildAppTheme(),
      routeInformationProvider: appRouter.routeInformationProvider,
      routeInformationParser: appRouter.routeInformationParser,
      routerDelegate: appRouter.routerDelegate,
      backButtonDispatcher: screenTimeBackDispatcher,
      builder: (context, child) {
        if (!PortraitLock.decided) {
          // main() saw no window size yet: decide from the first real one.
          final size = MediaQuery.sizeOf(context);
          WidgetsBinding.instance
              .addPostFrameCallback((_) => PortraitLock.decide(size));
        }
        // Hold back the navigator until we know where to go: while loading,
        // and while a redirect is due but has not taken effect yet.
        return ListenableBuilder(
          listenable: _location,
          builder: (context, _) {
            final kidKnown = kid.hasValue;
            final hasKid = kid.valueOrNull != null;
            final placedKnown = placed.hasValue;
            final loading = !kidKnown && kid.isLoading ||
                hasKid && !placedKnown && placed.isLoading ||
                !voice.hasValue && voice.isLoading;
            final due = kidKnown &&
                _target(_currentPath(),
                        hasKid: hasKid,
                        placed: hasKid ? placed.valueOrNull : null) !=
                    null;
            // A reload keeps the previous value; only wait when it is a
            // settled answer that demands a move.
            if (due) {
              // A location change (e.g. leaving /parent) can make a move due
              // without any provider changing: make it after this frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) _redirect(ref);
              });
            }
            final waiting = loading || due;
            if (waiting && !_precached) {
              _precached = true;
              // Warm the image cache while the splash is visible. Needs a
              // context under MaterialApp (MediaQuery -> right 2x/3x variant).
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) precacheAppImages(context);
              });
            }
            // The splash fades out as soon as data is ready (no minimum time).
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: waiting
                  ? const SplashView()
                  : ScreenTimeGuard(
                      key: const ValueKey('app'),
                      router: appRouter,
                      child: child ?? const SizedBox.shrink(),
                    ),
            );
          },
        );
      },
    );
  }
}
