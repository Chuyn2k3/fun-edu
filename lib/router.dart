import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'features/collection/collection_screen.dart';
import 'features/dev/gallery_screen.dart';
import 'features/dev/recorder_screen.dart';
import 'game/engine/race_question.dart';
import 'features/online_race/room_entry_screen.dart';
import 'features/online_race/room_lobby_screen.dart';
import 'features/online_race/room_race_screen.dart';
import 'features/online_race/room_result_screen.dart';
import 'features/game/badge_cabinet_screen.dart';
import 'features/game/game_hub_screen.dart';
import 'features/game/garage_screen.dart';
import 'features/game/race_controller.dart';
import 'features/game/race_result_screen.dart';
import 'features/game/race_screen.dart';
import 'features/game/sticker_album_screen.dart';
import 'features/game/subject_picker.dart';
import 'features/home/home_screen.dart';
import 'features/house/house_screen.dart';
import 'features/lesson/lesson_done_screen.dart';
import 'features/lesson/lesson_flow_screen.dart';
import 'features/placement/placement_screen.dart';
import 'features/setup/first_run_screen.dart';
import 'features/setup/restore_screen.dart';
import 'features/subject/english_map_screen.dart';
import 'features/subject/math_map_screen.dart';
import 'features/subject/vietnamese_map_screen.dart';
import 'features/subject/writing_map_screen.dart';
import 'features/trace/trace_screen.dart';
import 'parent/screens/parent_home.dart';
import 'stroke/glyph_repository.dart';
import 'ui/transitions/smooth_page_transition.dart';

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

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: GameHubScreen(),
      ),
      routes: [
        GoRoute(
          path: 'pick',
          pageBuilder: (context, state) => buildSmoothTransitionPage(
            key: state.pageKey,
            child: const SubjectPickerScreen(),
          ),
        ),
        GoRoute(
          path: 'garage',
          pageBuilder: (context, state) => buildSmoothTransitionPage(
            key: state.pageKey,
            child: const GarageScreen(),
          ),
        ),
        GoRoute(
          path: 'badges',
          pageBuilder: (context, state) => buildSmoothTransitionPage(
            key: state.pageKey,
            child: const BadgeCabinetScreen(),
          ),
        ),
        GoRoute(
          path: 'stickers',
          pageBuilder: (context, state) => buildSmoothTransitionPage(
            key: state.pageKey,
            child: const StickerAlbumScreen(),
          ),
        ),
        GoRoute(
          path: 'race/:subject',
          redirect: (context, state) =>
              subjectFromSlug(state.pathParameters['subject']!) == null
                  ? '/game'
                  : null,
          pageBuilder: (context, state) {
            final args = state.extra is RaceArgs
                ? state.extra! as RaceArgs
                : const RaceArgs();
            return buildSmoothTransitionPage(
              // A new key per visit: "Đua lại!" always starts a fresh race.
              key: ValueKey(state.pageKey),
              child: RaceScreen(
                key: ValueKey(state.pageKey),
                subject: subjectFromSlug(state.pathParameters['subject']!)!,
                retryAfterLoss: args.retryAfterLoss,
              ),
            );
          },
        ),
        // 2B-2 online rooms (entry is behind the parent gate).
        GoRoute(
          path: 'room',
          pageBuilder: (context, state) => buildSmoothTransitionPage(
            key: state.pageKey,
            child: RoomEntryScreen(
                join: state.uri.queryParameters['mode'] == 'join'),
          ),
          routes: [
            GoRoute(
              path: 'lobby',
              pageBuilder: (context, state) => buildSmoothTransitionPage(
                key: state.pageKey,
                child: const RoomLobbyScreen(),
              ),
            ),
            GoRoute(
              path: 'race',
              pageBuilder: (context, state) => buildSmoothTransitionPage(
                key: ValueKey(state.pageKey),
                child: RoomRaceScreen(
                  key: ValueKey(state.pageKey),
                  subject: state.extra is RaceSubject
                      ? state.extra! as RaceSubject
                      : RaceSubject.toan,
                ),
              ),
            ),
            GoRoute(
              path: 'result',
              pageBuilder: (context, state) => buildSmoothTransitionPage(
                key: state.pageKey,
                child: RoomResultScreen(
                  rewards: state.extra is RaceResultArgs
                      ? state.extra! as RaceResultArgs
                      : null,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'result',
          redirect: (context, state) =>
              state.extra is RaceResultArgs ? null : '/game',
          pageBuilder: (context, state) => buildSmoothTransitionPage(
            key: state.pageKey,
            child: RaceResultScreen(args: state.extra! as RaceResultArgs),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/collection',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CollectionScreen(),
      ),
    ),
    GoRoute(
      path: '/house',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HouseScreen(),
      ),
    ),
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
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: const WritingMapScreen(),
      ),
    ),
    GoRoute(
      path: '/parent',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: const ParentHome(),
      ),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const FirstRunScreen(),
    ),
    GoRoute(
      path: '/restore',
      builder: (context, state) => const RestoreScreen(),
    ),
    GoRoute(
      path: '/placement',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: const PlacementScreen(),
      ),
    ),
    GoRoute(
      path: '/subject/toan',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: const MathMapScreen(),
      ),
    ),
    GoRoute(
      path: '/subject/tieng-viet',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: const VietnameseMapScreen(),
      ),
    ),
    GoRoute(
      path: '/subject/tieng-anh',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: const EnglishMapScreen(),
      ),
    ),
    GoRoute(
      path: '/practice-math/:levelIndex',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: PracticeMathScreen(
          int.tryParse(state.pathParameters['levelIndex']!) ?? -1,
        ),
      ),
    ),
    GoRoute(
      path: '/practice-vietnamese/:levelIndex',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: PracticeVietnameseScreen(
          int.tryParse(state.pathParameters['levelIndex']!) ?? -1,
        ),
      ),
    ),
    GoRoute(
      path: '/practice-english/:levelIndex',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: PracticeEnglishScreen(
          int.tryParse(state.pathParameters['levelIndex']!) ?? -1,
        ),
      ),
    ),
    GoRoute(
      path: '/practice/:glyphId',
      pageBuilder: (context, state) => buildSmoothTransitionPage(
        key: state.pageKey,
        child: PracticeScreen(state.pathParameters['glyphId']!),
      ),
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
