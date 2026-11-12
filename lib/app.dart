import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress/level_repository.dart';
import 'router.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/tokens.dart';

class App extends ConsumerWidget {
  const App({super.key});

  // GoRouter's redirect is synchronous, so the async placement check lives
  // here: an unplaced child is sent to /placement, except on /dev/* routes.
  static String _currentPath() =>
      appRouter.routeInformationProvider.value.uri.path;

  static bool _exempt(String path) =>
      path.startsWith('/dev/') || path == '/placement';

  void _redirectIfUnplaced(bool placed) {
    if (placed || _exempt(_currentPath())) return;
    appRouter.go('/placement');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(isPlacedProvider, (_, next) {
      final placed = next.isLoading ? null : next.valueOrNull;
      if (placed != null) _redirectIfUnplaced(placed);
    });
    final placed = ref.watch(isPlacedProvider);
    return MaterialApp.router(
      title: 'Chíp Chíp',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      builder: (context, child) {
        // Hold back the navigator until we know where to go: while loading,
        // and while an unplaced child waits for the redirect to take effect.
        return ListenableBuilder(
          listenable: appRouter.routeInformationProvider,
          builder: (context, _) {
            final waiting = (!placed.hasValue && placed.isLoading) ||
                (placed.valueOrNull == false && !_exempt(_currentPath()));
            if (waiting) {
              return const ColoredBox(
                color: AppColors.background,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
