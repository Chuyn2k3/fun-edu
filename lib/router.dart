import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'features/dev/gallery_screen.dart';
import 'features/dev/recorder_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lesson/lesson_done_screen.dart';
import 'features/lesson/lesson_flow_screen.dart';
import 'features/placement/placement_screen.dart';
import 'features/subject/math_map_screen.dart';
import 'features/subject/writing_map_screen.dart';
import 'features/trace/trace_screen.dart';
import 'stroke/glyph_repository.dart';

/// Dev-only: lists the bundled glyphs to pick one to trace.
class GlyphListScreen extends ConsumerWidget {
  const GlyphListScreen({super.key});

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
        path: '/lesson', builder: (context, state) => const LessonFlowScreen()),
    GoRoute(
      path: '/lesson/done',
      builder: (context, state) => LessonDoneScreen(
        starsEarned: state.extra is int ? state.extra! as int : 0,
      ),
    ),
    GoRoute(
      path: '/subject/viet',
      builder: (context, state) => const WritingMapScreen(),
    ),
    GoRoute(
      path: '/placement',
      builder: (context, state) => const PlacementScreen(),
    ),
    GoRoute(
      path: '/subject/toan',
      builder: (context, state) => const MathMapScreen(),
    ),
    GoRoute(
      path: '/practice-math/:levelIndex',
      builder: (context, state) => PracticeMathScreen(
        int.tryParse(state.pathParameters['levelIndex']!) ?? -1,
      ),
    ),
    GoRoute(
      path: '/practice/:glyphId',
      builder: (context, state) =>
          PracticeScreen(state.pathParameters['glyphId']!),
    ),
    GoRoute(
      path: '/trace/:glyphId',
      builder: (context, state) =>
          TraceScreen(state.pathParameters['glyphId']!),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/dev/glyphs',
        builder: (context, state) => const GlyphListScreen(),
      ),
    if (kDebugMode)
      GoRoute(
        path: '/dev/recorder',
        builder: (context, state) => const RecorderScreen(),
      ),
    if (kDebugMode)
      GoRoute(
        path: '/dev/gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
  ],
);
