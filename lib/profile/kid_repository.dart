import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';

const int maxKids = 4;
const String _currentKidKey = 'currentKidId';
const String voiceEnabledKey = 'voiceEnabled';

class KidRepository {
  KidRepository(this._db, {DateTime Function() now = DateTime.now})
      : _now = now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Adds a kid; the first kid ever added becomes the current one.
  /// Throws [StateError] when [maxKids] profiles already exist.
  Future<int> addKid({
    required String nickname,
    required String avatar,
    required int age,
  }) =>
      _db.transaction(() async {
        final count = await _db.kidProfiles.count().getSingle();
        if (count >= maxKids) {
          throw StateError('At most $maxKids kid profiles are allowed');
        }
        final id = await _db.into(_db.kidProfiles).insert(
              KidProfilesCompanion.insert(
                nickname: nickname,
                avatar: avatar,
                age: age,
                createdAt: _now(),
              ),
            );
        if (await currentKidId() == null) await setCurrentKid(id);
        return id;
      });

  Future<void> updateKid(
    int id, {
    String? nickname,
    String? avatar,
    int? age,
  }) async {
    await (_db.update(_db.kidProfiles)..where((t) => t.id.equals(id))).write(
      KidProfilesCompanion(
        nickname: Value.absentIfNull(nickname),
        avatar: Value.absentIfNull(avatar),
        age: Value.absentIfNull(age),
      ),
    );
  }

  /// Deletes the kid and all of their progress. Deleting the current kid
  /// selects the first remaining one (or none).
  Future<void> deleteKid(int id) => _db.transaction(() async {
        final wasCurrent = await currentKidId() == id;
        await _deleteProgressOf(id);
        await (_db.delete(_db.kidProfiles)..where((t) => t.id.equals(id))).go();
        if (wasCurrent) {
          final rest = await kids();
          if (rest.isEmpty) {
            await (_db.delete(_db.appSettings)
                  ..where((t) => t.key.equals(_currentKidKey)))
                .go();
          } else {
            await setCurrentKid(rest.first.id);
          }
        }
      });

  Future<void> _deleteProgressOf(int id) async {
    await (_db.delete(_db.strokeAttempts)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.glyphProgress)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.lessonCompletions)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.subjectLevels)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.dailyUsage)..where((t) => t.kidId.equals(id))).go();
    await (_db.delete(_db.realRewards)..where((t) => t.kidId.equals(id))).go();
    // Screen-time settings (limit, bedtime, extra minutes) of this kid.
    await (_db.delete(_db.appSettings)
          ..where((t) =>
              t.key.equals('dailyLimitMinutes.$id') |
              t.key.equals('bedtimeStart.$id') |
              t.key.equals('bedtimeEnd.$id') |
              t.key.like('extraMinutes.$id.%')))
        .go();
  }

  Future<List<KidProfile>> kids() =>
      (_db.select(_db.kidProfiles)..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// The selected kid, or null when no kid exists. A stale stored id falls
  /// back to the first kid.
  Future<int?> currentKidId() async {
    final all = await kids();
    if (all.isEmpty) return null;
    final stored = int.tryParse(await setting(_currentKidKey) ?? '');
    if (stored != null && all.any((k) => k.id == stored)) return stored;
    return all.first.id;
  }

  Future<void> setCurrentKid(int id) => setSetting(_currentKidKey, '$id');

  Future<String?> setting(String key) async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: key, value: value),
          );

  Future<void> removeSetting(String key) =>
      (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();

  /// Wipes every table: kids, settings and all progress.
  Future<void> deleteAllData() => _db.transaction(() async {
        for (final table in _db.allTables) {
          await _db.delete(table).go();
        }
      });
}

final kidRepositoryProvider = Provider<KidRepository>(
  (ref) => KidRepository(ref.watch(databaseProvider)),
);

final kidsProvider = FutureProvider<List<KidProfile>>(
  (ref) => ref.watch(kidRepositoryProvider).kids(),
);

/// The selected kid, or null on a fresh install. Re-reads the database when
/// invalidated (e.g. after `setCurrentKid`).
final currentKidIdProvider = FutureProvider<int?>(
  (ref) => ref.watch(kidRepositoryProvider).currentKidId(),
);

/// Whether Chip speaks aloud; defaults to true.
final voiceEnabledProvider = FutureProvider<bool>((ref) async {
  final v = await ref.watch(kidRepositoryProvider).setting(voiceEnabledKey);
  return v != 'false';
});
