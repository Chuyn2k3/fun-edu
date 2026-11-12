import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'features/dev/recorder_screen.dart';
import 'features/trace/trace_screen.dart';
import 'stroke/glyph_repository.dart';

/// Home screen: lists the bundled glyphs to pick one to trace.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glyphs = ref.watch(glyphListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chíp Chíp')),
      body: glyphs.when(
        data: (list) => ListView(
          children: [
            for (final g in list)
              ListTile(
                title: Text(g.label),
                onTap: () => context.push('/trace/${g.id}'),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Không tải được danh sách')),
      ),
    );
  }
}

/// App-wide router. Later tasks add their routes here.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/trace/:glyphId',
      builder: (context, state) => TraceScreen(state.pathParameters['glyphId']!),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/dev/recorder',
        builder: (context, state) => const RecorderScreen(),
      ),
  ],
);
