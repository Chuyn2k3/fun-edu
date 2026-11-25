import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../english/english_level.dart';
import '../explore/geography_level.dart';
import '../math/level_rule.dart';
import '../profile/kid_repository.dart';
import '../math/math_level.dart';
import '../vietnamese/vietnamese_level.dart';
import 'progress_repository.dart';

/// Placed levels of one kid. With a null [kidId] reads return null/false and
/// writes throw [StateError] (see [ProgressRepository]).
class LevelRepository {
  LevelRepository(this._db, {required this.kidId, Clock now = DateTime.now})
      : _now = now;

  final AppDatabase _db;
  final int? kidId;
  final Clock _now;

  Future<int?> levelOf(String subject) async {
    final kid = kidId;
    if (kid == null) return null;
    final row = await (_db.select(_db.subjectLevels)
          ..where((t) => t.kidId.equals(kid) & t.subject.equals(subject)))
        .getSingleOrNull();
    return row?.levelIndex;
  }

  Future<void> setLevel(String subject, int index) async {
    final kid = kidId ?? (throw StateError('No kid profile selected'));
    await _db.into(_db.subjectLevels).insertOnConflictUpdate(
          SubjectLevelsCompanion.insert(
            kidId: kid,
            subject: subject,
            levelIndex: index,
            placedAt: _now(),
          ),
        );
  }

  /// Forgets this kid's placement so they redo the placement test.
  Future<void> clearLevels() async {
    final kid = kidId ?? (throw StateError('No kid profile selected'));
    await (_db.delete(_db.subjectLevels)..where((t) => t.kidId.equals(kid)))
        .go();
  }

  /// True once both subjects have a stored level.
  Future<bool> isPlaced() async =>
      await levelOf('viet') != null && await levelOf('toan') != null;

  /// Applies the level rule to the math level and returns the new level.
  Future<int> recordMathSession({
    required int firstTryCorrect,
    required int total,
  }) =>
      _db.transaction(() async {
        final next = nextLevelIndex(
          current: await levelOf('toan') ?? 0,
          firstTryCorrect: firstTryCorrect,
          total: total,
          levelCount: mathLevels.length,
        );
        await setLevel('toan', next);
        return next;
      });

  /// Applies the level rule to the Vietnamese level and returns the new level.
  Future<int> recordVietnameseSession({
    required int firstTryCorrect,
    required int total,
  }) =>
      _db.transaction(() async {
        final next = nextLevelIndex(
          current: await levelOf('tieng-viet') ?? 0,
          firstTryCorrect: firstTryCorrect,
          total: total,
          levelCount: vietnameseLevels.length,
        );
        await setLevel('tieng-viet', next);
        return next;
      });

  /// Applies the level rule to the English level and returns the new level.
  Future<int> recordEnglishSession({
    required int firstTryCorrect,
    required int total,
  }) =>
      _db.transaction(() async {
        final next = nextLevelIndex(
          current: await levelOf('tieng-anh') ?? 0,
          firstTryCorrect: firstTryCorrect,
          total: total,
          levelCount: englishLevels.length,
        );
        await setLevel('tieng-anh', next);
        return next;
      });

  /// Applies the level rule to the geography level and returns the new level.
  Future<int> recordGeographySession({
    required int firstTryCorrect,
    required int total,
  }) =>
      _db.transaction(() async {
        final next = nextLevelIndex(
          current: (await levelOf('dia-ly') ?? 0)
              .clamp(0, geographyLevels.length - 1),
          firstTryCorrect: firstTryCorrect,
          total: total,
          levelCount: geographyLevels.length,
        );
        await setLevel('dia-ly', next);
        return next;
      });
}

/// Async so callers never see a repository built before the current kid is
/// known; await `.future` instead of reading synchronously.
final levelRepositoryProvider = FutureProvider<LevelRepository>((ref) async {
  final kid = await ref.watch(currentKidIdProvider.future);
  return LevelRepository(ref.watch(databaseProvider), kidId: kid);
});

final mathLevelIndexProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(levelRepositoryProvider.future);
  return await repo.levelOf('toan') ?? 0;
});

final vietnameseLevelIndexProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(levelRepositoryProvider.future);
  return await repo.levelOf('tieng-viet') ?? 0;
});

final englishLevelIndexProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(levelRepositoryProvider.future);
  return await repo.levelOf('tieng-anh') ?? 0;
});

/// Kept inside the ladder: a level synced from a newer app version, or a
/// bad value, never points past the last level.
final geographyLevelIndexProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(levelRepositoryProvider.future);
  final stored = await repo.levelOf('dia-ly') ?? 0;
  return stored.clamp(0, geographyLevels.length - 1);
});

final isPlacedProvider = FutureProvider<bool>((ref) async {
  final repo = await ref.watch(levelRepositoryProvider.future);
  return repo.isPlaced();
});
