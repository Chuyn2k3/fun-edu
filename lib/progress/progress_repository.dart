import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../learning/writing_ladder.dart';
import '../profile/kid_repository.dart';
import 'level_repository.dart';

typedef Clock = DateTime Function();

class GlyphStat {
  const GlyphStat({required this.completions, required this.cleanCompletions});

  final int completions;
  final int cleanCompletions;

  bool get mastered => cleanCompletions >= 1;
}

/// Progress of one kid. With a null [kidId] (fresh install, before a profile
/// exists) reads return empty values and writes throw [StateError]; setup
/// guarantees a kid exists before any screen that records progress.
class ProgressRepository {
  ProgressRepository(this._db, {required this.kidId, Clock now = DateTime.now})
      : _now = now;

  final AppDatabase _db;
  final int? kidId;
  final Clock _now;

  /// A completion with at most one failed stroke counts as clean.
  Future<void> recordGlyphCompleted(
    String glyphId, {
    required int failedStrokes,
  }) async {
    final kid = _requireKid();
    final clean = failedStrokes <= 1 ? 1 : 0;
    final at = _now();
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.glyphProgress,
      )..where((t) => t.kidId.equals(kid) & t.glyphId.equals(glyphId)))
          .getSingleOrNull();
      await _db.into(_db.glyphProgress).insertOnConflictUpdate(
            GlyphProgressCompanion.insert(
              kidId: kid,
              glyphId: glyphId,
              completions: Value((existing?.completions ?? 0) + 1),
              cleanCompletions: Value(
                (existing?.cleanCompletions ?? 0) + clean,
              ),
              lastPracticedAt: at,
            ),
          );
    });
  }

  /// One star per lesson item plus a 2-star bonus; returns the stars just earned.
  Future<int> recordLessonCompleted({required int itemsCompleted}) async {
    final kid = _requireKid();
    final stars = itemsCompleted + 2;
    await _db.into(_db.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
            kidId: kid,
            completedAt: _now(),
            starsEarned: stars,
          ),
        );
    return stars;
  }

  int _requireKid() => kidId ?? (throw StateError('No kid profile selected'));

  Future<int> totalStars() async {
    final kid = kidId;
    if (kid == null) return 0;
    final sum = _db.lessonCompletions.starsEarned.sum();
    final row = await (_db.selectOnly(
      _db.lessonCompletions,
    )
          ..addColumns([sum])
          ..where(_db.lessonCompletions.kidId.equals(kid)))
        .getSingle();
    return row.read(sum) ?? 0;
  }

  Future<Map<String, GlyphStat>> glyphStats() async {
    final kid = kidId;
    if (kid == null) return {};
    final rows = await (_db.select(_db.glyphProgress)
          ..where((t) => t.kidId.equals(kid)))
        .get();
    return {
      for (final r in rows)
        r.glyphId: GlyphStat(
          completions: r.completions,
          cleanCompletions: r.cleanCompletions,
        ),
    };
  }

  /// Weekdays (1 = Monday .. 7 = Sunday) of the current local week that have
  /// at least one completed lesson.
  Future<Set<int>> learnedWeekdaysThisWeek() async {
    final kid = kidId;
    if (kid == null) return {};
    final now = _now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    final rows = await (_db.select(_db.lessonCompletions)
          ..where(
            (t) =>
                t.kidId.equals(kid) &
                t.completedAt.isBiggerOrEqualValue(monday) &
                t.completedAt.isSmallerThanValue(nextMonday),
          ))
        .get();
    return {for (final r in rows) r.completedAt.toLocal().weekday};
  }
}

class HomeSummary {
  const HomeSummary({
    required this.totalStars,
    required this.learnedDaysThisWeek,
    required this.masteredWriting,
    this.mathLevelIndex = 0,
  });

  final int totalStars;
  final int learnedDaysThisWeek;
  final int masteredWriting;
  final int mathLevelIndex;

  int get level => 1 + masteredWriting ~/ 3;
}

/// Async so callers never see a repository built before the current kid is
/// known; await `.future` instead of reading synchronously.
final progressRepositoryProvider =
    FutureProvider<ProgressRepository>((ref) async {
  final kid = await ref.watch(currentKidIdProvider.future);
  return ProgressRepository(ref.watch(databaseProvider), kidId: kid);
});

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final repo = await ref.watch(progressRepositoryProvider.future);
  final stats = await repo.glyphStats();
  final mastered =
      writingLadder.where((id) => stats[id]?.mastered ?? false).length;
  return HomeSummary(
    totalStars: await repo.totalStars(),
    learnedDaysThisWeek: (await repo.learnedWeekdaysThisWeek()).length,
    masteredWriting: mastered,
    mathLevelIndex: await ref.watch(mathLevelIndexProvider.future),
  );
});
