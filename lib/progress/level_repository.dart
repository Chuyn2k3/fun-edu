import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../math/level_rule.dart';
import '../math/math_level.dart';
import 'progress_repository.dart';

class LevelRepository {
  LevelRepository(this._db, {Clock now = DateTime.now}) : _now = now;

  final AppDatabase _db;
  final Clock _now;

  Future<int?> levelOf(String subject) async {
    final row = await (_db.select(_db.subjectLevels)
          ..where((t) => t.subject.equals(subject)))
        .getSingleOrNull();
    return row?.levelIndex;
  }

  Future<void> setLevel(String subject, int index) =>
      _db.into(_db.subjectLevels).insertOnConflictUpdate(
            SubjectLevelsCompanion.insert(
              subject: subject,
              levelIndex: index,
              placedAt: _now(),
            ),
          );

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
}

final levelRepositoryProvider = Provider<LevelRepository>(
  (ref) => LevelRepository(ref.watch(databaseProvider)),
);

final mathLevelIndexProvider = FutureProvider<int>(
  (ref) async => await ref.watch(levelRepositoryProvider).levelOf('toan') ?? 0,
);

final isPlacedProvider = FutureProvider<bool>(
  (ref) => ref.watch(levelRepositoryProvider).isPlaced(),
);
