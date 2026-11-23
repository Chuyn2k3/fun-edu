import 'online/link/link_controller.dart';
import 'online/online_config.dart';
import 'online/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/online/link_warning_listener.dart';
import 'features/splash/splash_view.dart';
import 'profile/kid_repository.dart';
import 'progress/level_repository.dart';
import 'router.dart';
import 'router_location.dart';
import 'screen_time/screen_time_guard.dart';
import 'ui/layout/orientation_lock.dart';
import 'ui/precache.dart';
import 'ui/theme/app_theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  static bool _precached = false;

  // GoRouter's redirect is synchronous, so the async checks live here:
  // no kid -> /setup, then an unplaced kid -> /placement.
  // Follows pops as well as go/push, so leaving /parent re-applies the rules.
  static RouterLocation get _location => RouterLocation.of(appRouter);
  static String _currentPath() => _location.path;

  static bool _isDev(String p) => p.startsWith('/dev/');
  static bool _isParent(String p) => p == '/parent' || p.startsWith('/parent/');

  /// Where the app must be sent from [path], or null to stay.
  static String? _target(
    String path, {
    required bool hasKid,
    bool? placed,
    required bool isRestoring,
  }) {
    if (_isDev(path)) return null;
    if (isRestoring) {
      return path == '/restore' ? null : '/restore';
    }
    if (path == '/restore') {
      if (!hasKid) return '/setup';
      return placed == false ? '/placement' : '/';
    }
    if (path == '/setup' || _isParent(path)) return null;
    if (!hasKid) return '/setup';
    if (placed == false && path != '/placement') return '/placement';
    return null;
  }

  void _redirect() {
    final restorePending = ref.read(restorePendingSettingProvider);
    if (!restorePending.hasValue && restorePending.isLoading) return;

    final isRestoring = ref.read(restoringProvider);
    final kid = ref.read(currentKidIdProvider);
    if (!isRestoring && (kid.isLoading || !kid.hasValue)) return;
    final hasKid = kid.valueOrNull != null;
    bool? placed;
    if (hasKid && !isRestoring) {
      final p = ref.read(isPlacedProvider);
      if (p.isLoading || !p.hasValue) return;
      placed = p.value;
    }
    final target = _target(
      _currentPath(),
      hasKid: hasKid,
      placed: placed,
      isRestoring: isRestoring,
    );
    if (target != null) appRouter.go(target);
  }

  @override
  void initState() {
    super.initState();
    if (ref.read(onlineConfigProvider).enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(linkControllerProvider.notifier).resumeIfPending();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<int?>>(currentKidIdProvider, (_, __) {
      _redirect();
    });
    ref.listen<AsyncValue<bool>>(isPlacedProvider, (_, __) {
      _redirect();
    });
    ref.listen<bool>(restoringProvider, (_, __) {
      _redirect();
    });
    final kid = ref.watch(currentKidIdProvider);
    final placed = ref.watch(isPlacedProvider);
    final isRestoring = ref.watch(restoringProvider);
    final restorePending = ref.watch(restorePendingSettingProvider);
    // Load the voice setting before any screen can speak.
    final voice = ref.watch(voiceEnabledProvider);
    // Online sync runs only in a build with a server address, and only once a
    // parent signed in (the controller does nothing until then).
    if (ref.watch(onlineConfigProvider).enabled) {
      ref.listen(syncControllerProvider, (_, __) {});
    }
    // Pre-warm subject levels so the maps open with them. Listening (not
    // watching) keeps them alive without rebuilding the whole app when a
    // level changes.
    if (kid.valueOrNull != null) {
      ref.listen(mathLevelIndexProvider, (_, __) {});
      ref.listen(vietnameseLevelIndexProvider, (_, __) {});
      ref.listen(englishLevelIndexProvider, (_, __) {});
    }
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
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
            final loading = (!kidKnown && kid.isLoading && !isRestoring) ||
                (hasKid && !placedKnown && placed.isLoading && !isRestoring) ||
                (!voice.hasValue && voice.isLoading) ||
                (!restorePending.hasValue && restorePending.isLoading);
            final due = (isRestoring || kidKnown) &&
                _target(
                  _currentPath(),
                  hasKid: hasKid,
                  placed: hasKid ? placed.valueOrNull : null,
                  isRestoring: isRestoring,
                ) != null;
            // A reload keeps the previous value; only wait when it is a
            // settled answer that demands a move.
            if (due) {
              // A location change (e.g. leaving /parent) can make a move due
              // without any provider changing: make it after this frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) _redirect();
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
                  : LinkWarningListener(
                      child: ScreenTimeGuard(
                        key: const ValueKey('app'),
                        router: appRouter,
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
