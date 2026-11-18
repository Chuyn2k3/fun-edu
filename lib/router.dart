import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'features/dev/gallery_screen.dart';
import 'features/dev/recorder_screen.dart';
import 'features/game/badge_cabinet_screen.dart';
import 'features/game/game_hub_screen.dart';
import 'features/game/garage_screen.dart';
import 'features/game/race_controller.dart';
import 'features/game/race_result_screen.dart';
import 'features/game/race_screen.dart';
import 'features/game/sticker_album_screen.dart';
import 'features/game/subject_picker.dart';
import 'features/home/home_screen.dart';
import 'features/lesson/lesson_done_screen.dart';
import 'features/lesson/lesson_flow_screen.dart';
import 'features/placement/placement_screen.dart';
import 'features/setup/first_run_screen.dart';
import 'features/subject/math_map_screen.dart';
import 'features/subject/vietnamese_map_screen.dart';
import 'features/subject/writing_map_screen.dart';
import 'features/trace/trace_screen.dart';
import 'parent/screens/parent_home.dart';
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
      path: '/parent',
      builder: (context, state) => const ParentHome(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const FirstRunScreen(),
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
      path: '/subject/tieng-viet',
      builder: (context, state) => const VietnameseMapScreen(),
    ),
    GoRoute(
      path: '/practice-math/:levelIndex',
      builder: (context, state) => PracticeMathScreen(
        int.tryParse(state.pathParameters['levelIndex']!) ?? -1,
      ),
    ),
    GoRoute(
      path: '/practice-vietnamese/:levelIndex',
      builder: (context, state) => PracticeVietnameseScreen(
        int.tryParse(state.pathParameters['levelIndex']!) ?? -1,
      ),
    ),
    GoRoute(
      path: '/practice/:glyphId',
      builder: (context, state) =>
          PracticeScreen(state.pathParameters['glyphId']!),
    ),
    // Rocket race (2B-1): /game is the Góc Chơi hub (nav "Chơi").
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameHubScreen(),
      routes: [
        GoRoute(
          path: 'pick',
          builder: (context, state) => const SubjectPickerScreen(),
        ),
        GoRoute(
          path: 'garage',
          builder: (context, state) => const GarageScreen(),
        ),
        GoRoute(
          path: 'badges',
          builder: (context, state) => const BadgeCabinetScreen(),
        ),
        GoRoute(
          path: 'stickers',
          builder: (context, state) => const StickerAlbumScreen(),
        ),
        GoRoute(
          path: 'race/:subject',
          redirect: (context, state) =>
              subjectFromSlug(state.pathParameters['subject']!) == null
                  ? '/game'
                  : null,
          builder: (context, state) {
            final args = state.extra is RaceArgs
                ? state.extra! as RaceArgs
                : const RaceArgs();
            return RaceScreen(
              // A new key per visit: "Đua lại!" always starts a fresh race.
              key: ValueKey(state.pageKey),
              subject: subjectFromSlug(state.pathParameters['subject']!)!,
              retryAfterLoss: args.retryAfterLoss,
            );
          },
        ),
        GoRoute(
          path: 'result',
          redirect: (context, state) =>
              state.extra is RaceResultArgs ? null : '/game',
          builder: (context, state) =>
              RaceResultScreen(args: state.extra! as RaceResultArgs),
        ),
      ],
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
