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
  void _redirectIfUnplaced(bool placed) {
    if (placed) return;
    final path = appRouter.routeInformationProvider.value.uri.path;
    if (path.startsWith('/dev/') || path == '/placement') return;
    appRouter.go('/placement');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(isPlacedProvider, (_, next) {
      final placed = next.valueOrNull;
      if (placed != null) _redirectIfUnplaced(placed);
    });
    final placed = ref.watch(isPlacedProvider);
    return MaterialApp.router(
      title: 'Chíp Chíp',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      builder: (context, child) {
        // Hold the first frame until we know where to go (no home flash).
        if (!placed.hasValue && placed.isLoading) {
          return const ColoredBox(
            color: AppColors.background,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
