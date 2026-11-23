import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../collection/notebook_pages.dart';
import '../data/app_database.dart';
import '../learning/writing_ladder.dart';
import '../online/sync/device_counters.dart';
import '../online/uuid.dart';
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
      final kidRow = await (_db.select(_db.kidProfiles)
            ..where((t) => t.id.equals(kid)))
          .getSingleOrNull();
      var uuid = kidRow?.uuid;
      if (uuid == null && kidRow != null) {
        uuid = newUuid();
        await (_db.update(_db.kidProfiles)..where((t) => t.id.equals(kid)))
            .write(KidProfilesCompanion(uuid: Value(uuid)));
      }
      final existing = await (_db.select(
        _db.glyphProgress,
      )..where((t) => t.kidId.equals(kid) & t.glyphId.equals(glyphId)))
          .getSingleOrNull();

      var nextC = (existing?.completions ?? 0) + 1;
      var nextK = (existing?.cleanCompletions ?? 0) + clean;
      if (uuid != null) {
        final counters = DeviceCounterStore(_db);
        final cKey = 'glyph.c:$uuid:$glyphId';
        final kKey = 'glyph.k:$uuid:$glyphId';
        final dcTotal = await counters.total(cKey);
        if (dcTotal < (existing?.completions ?? 0)) {
          await counters.add(cKey, (existing?.completions ?? 0) - dcTotal);
        }
        await counters.add(cKey, 1);
        nextC = await counters.total(cKey);

        final dkTotal = await counters.total(kKey);
        if (dkTotal < (existing?.cleanCompletions ?? 0)) {
          await counters.add(kKey, (existing?.cleanCompletions ?? 0) - dkTotal);
        }
        if (clean > 0) {
          await counters.add(kKey, clean);
        }
        nextK = await counters.total(kKey);
      }

      await _db.into(_db.glyphProgress).insertOnConflictUpdate(
            GlyphProgressCompanion.insert(
              kidId: kid,
              glyphId: glyphId,
              completions: Value(nextC),
              cleanCompletions: Value(nextK),
              lastPracticedAt: at,
            ),
          );
    });
    try {
      await refreshNotebookPage(_db, kid, glyphId);
    } catch (e, st) {
      debugPrint('Failed to refresh notebook page for $glyphId: $e\n$st');
    }
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

  /// Lessons this kid finished since local midnight today.
  Future<int> lessonsCompletedToday() async {
    final kid = kidId;
    if (kid == null) return 0;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final count = _db.lessonCompletions.id.count();
    final row = await (_db.selectOnly(_db.lessonCompletions)
          ..addColumns([count])
          ..where(
            _db.lessonCompletions.kidId.equals(kid) &
                _db.lessonCompletions.completedAt.isBiggerOrEqualValue(today) &
                _db.lessonCompletions.completedAt.isSmallerThanValue(tomorrow),
          ))
        .getSingle();
    return row.read(count) ?? 0;
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

  /// Total number of completed lessons for this kid across all time.
  Future<int> totalLessons() async {
    final kid = kidId;
    if (kid == null) return 0;
    final count = _db.lessonCompletions.id.count();
    final row = await (_db.selectOnly(_db.lessonCompletions)
          ..addColumns([count])
          ..where(_db.lessonCompletions.kidId.equals(kid)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// Total number of distinct local calendar days on which this kid finished
  /// at least one lesson.
  Future<int> totalLearnedDays() async {
    final kid = kidId;
    if (kid == null) return 0;
    final rows = await (_db.select(_db.lessonCompletions)
          ..where((t) => t.kidId.equals(kid)))
        .get();
    final days = <(int, int, int)>{
      for (final r in rows)
        () {
          final d = r.completedAt.toLocal();
          return (d.year, d.month, d.day);
        }(),
    };
    return days.length;
  }

  /// Day-of-month numbers (1..31) in [year]/[month] (local time) that have at
  /// least one completed lesson.
  Future<Set<int>> learnedDaysInMonth(int year, int month) async {
    final kid = kidId;
    if (kid == null) return {};
    final start = DateTime(year, month, 1);
    final nextMonth = DateTime(year, month + 1, 1);
    final rows = await (_db.select(_db.lessonCompletions)
          ..where(
            (t) =>
                t.kidId.equals(kid) &
                t.completedAt.isBiggerOrEqualValue(start) &
                t.completedAt.isSmallerThanValue(nextMonth),
          ))
        .get();
    return {for (final r in rows) r.completedAt.toLocal().day};
  }
}

class HomeSummary {
  const HomeSummary({
    required this.totalStars,
    required this.learnedDaysThisWeek,
    required this.masteredWriting,
    this.mathLevelIndex = 0,
    this.vietnameseLevelIndex = 0,
    this.englishLevelIndex = 0,
    this.lessonsToday = 0,
    this.learnedWeekdays = const {},
  });

  final int totalStars;
  final int learnedDaysThisWeek;
  final int masteredWriting;
  final int mathLevelIndex;
  final int vietnameseLevelIndex;
  final int englishLevelIndex;

  /// Lessons finished today; the home card shows the lesson as done when > 0.
  final int lessonsToday;

  /// Weekdays of this week with a finished lesson, 1 = Monday .. 7 = Sunday.
  final Set<int> learnedWeekdays;

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
  final weekdays = await repo.learnedWeekdaysThisWeek();
  return HomeSummary(
    totalStars: await repo.totalStars(),
    learnedDaysThisWeek: weekdays.length,
    learnedWeekdays: weekdays,
    masteredWriting: mastered,
    mathLevelIndex: await ref.watch(mathLevelIndexProvider.future),
    vietnameseLevelIndex: await ref.watch(vietnameseLevelIndexProvider.future),
    englishLevelIndex: await ref.watch(englishLevelIndexProvider.future),
    lessonsToday: await repo.lessonsCompletedToday(),
  );
});
