import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../online/uuid.dart';

const int maxKids = 4;
const String _currentKidKey = 'currentKidId';
const String voiceEnabledKey = 'voiceEnabled';
const String restorePendingKey = 'link.restorePending';
const String restoreStageFresh = 'fresh';
const String restoreStageReplace = 'replace';
const String restoreStagePull = 'pull';
const String consentAtKey = 'consentAt';
const String dataOwnerKey = 'dataOwnerFamilyId';

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
        final now = _now();
        final id = await _db.into(_db.kidProfiles).insert(
              KidProfilesCompanion.insert(
                nickname: nickname,
                avatar: avatar,
                age: age,
                createdAt: now,
                uuid: Value(newUuid()),
                updatedAt: Value(now),
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
        updatedAt: Value(_now()),
      ),
    );
  }

  /// Deletes the kid and all of their progress. Deleting the current kid
  /// selects the first remaining one (or none).
  Future<void> deleteKid(int id) => _db.transaction(() async {
        final kidRow = await (_db.select(_db.kidProfiles)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        final wasCurrent = await currentKidId() == id;
        await _deleteProgressOf(id, uuid: kidRow?.uuid);
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

  Future<void> _deleteProgressOf(int id, {String? uuid}) async {
    await (_db.delete(_db.strokeAttempts)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.notebookPages)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.glyphProgress)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.lessonCompletions)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.subjectLevels)..where((t) => t.kidId.equals(id)))
        .go();
    await (_db.delete(_db.dailyUsage)..where((t) => t.kidId.equals(id))).go();
    await (_db.delete(_db.realRewards)..where((t) => t.kidId.equals(id))).go();
    // Game data (race results, cosmic stars, items, badges, counters).
    await (_db.delete(_db.raceResults)..where((t) => t.kidId.equals(id))).go();
    await (_db.delete(_db.gameProfile)..where((t) => t.kidId.equals(id))).go();
    await (_db.delete(_db.gameItems)..where((t) => t.kidId.equals(id))).go();
    await (_db.delete(_db.gameBadges)..where((t) => t.kidId.equals(id))).go();
    await (_db.delete(_db.gameCounters)..where((t) => t.kidId.equals(id))).go();
    if (uuid != null) {
      await _db.customStatement(
        'DELETE FROM device_counters WHERE key LIKE ? OR key LIKE ?',
        ['%:$uuid', '%:$uuid:%'],
      );
    }
    // Screen-time, Nhà Chíp, race-nickname, tease-stickers and showcase settings of this kid.
    await (_db.delete(_db.appSettings)
          ..where((t) =>
              t.key.equals('dailyLimitMinutes.$id') |
              t.key.equals('bedtimeStart.$id') |
              t.key.equals('bedtimeEnd.$id') |
              t.key.equals('chipHouse.$id') |
              t.key.equals('raceNickname.$id') |
              t.key.equals('teaseStickers.$id') |
              t.key.equals('showcaseOn.$id') |
              t.key.equals('showcaseLearning.$id') |
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
            AppSettingsCompanion.insert(
              key: key,
              value: value,
              updatedAt: Value(_now()),
            ),
          );

  Future<void> removeSetting(String key) =>
      (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();

  /// Wipes all kid profiles, progress, and settings, preserving only device-level
  /// identifiers and consent: deviceId, consentAt, link.restorePending.
  Future<void> wipeKidData() => _db.transaction(() async {
        for (final table in _db.allTables) {
          if (table == _db.appSettings) continue;
          await _db.delete(table).go();
        }
        await (_db.delete(_db.appSettings)
              ..where((t) => t.key.isNotIn(const [
                    'deviceId',
                    'consentAt',
                    restorePendingKey,
                  ])))
            .go();
      });

  /// Wipes every table: kids, settings and all progress, keeping only deviceId.
  Future<void> deleteAllData() => _db.transaction(() async {
        final deviceId = await setting('deviceId');
        for (final table in _db.allTables) {
          await _db.delete(table).go();
        }
        if (deviceId != null) {
          await setSetting('deviceId', deviceId);
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

/// Per-kid setting key for showing/sending tease stickers in online races.
String teaseStickersKey(int kidId) => 'teaseStickers.$kidId';

/// Whether tease stickers are enabled for [kidId] (defaults to `true`).
final kidTeaseStickersProvider = FutureProvider.family<bool, int>((ref, kidId) async {
  final raw = await ref.watch(kidRepositoryProvider).setting(teaseStickersKey(kidId));
  return raw != 'false';
});

/// Whether tease stickers are enabled for the currently selected kid (defaults to `true`).
final teaseStickersProvider = FutureProvider<bool>((ref) async {
  final kidId = await ref.watch(currentKidIdProvider.future);
  if (kidId == null) return true;
  return ref.watch(kidTeaseStickersProvider(kidId).future);
});

/// Per-kid setting key for showing the kid's Tủ khoe to connected friends.
String showcaseOnKey(int kidId) => 'showcaseOn.$kidId';

/// Whether Tủ khoe is visible to friends for [kidId] (defaults to `true`).
final kidShowcaseOnProvider = FutureProvider.family<bool, int>((ref, kidId) async {
  final raw = await ref.watch(kidRepositoryProvider).setting(showcaseOnKey(kidId));
  return raw != 'false';
});

/// Whether Tủ khoe is visible to friends for the currently selected kid (defaults to `true`).
final showcaseOnProvider = FutureProvider<bool>((ref) async {
  final kidId = await ref.watch(currentKidIdProvider.future);
  if (kidId == null) return true;
  return ref.watch(kidShowcaseOnProvider(kidId).future);
});

/// Per-kid setting key for including learning progress in Tủ khoe (strict opt-in).
String showcaseLearningKey(int kidId) => 'showcaseLearning.$kidId';

/// Whether learning progress is included in Tủ khoe for [kidId] (defaults to `false`).
final kidShowcaseLearningProvider = FutureProvider.family<bool, int>((ref, kidId) async {
  final raw = await ref.watch(kidRepositoryProvider).setting(showcaseLearningKey(kidId));
  return raw == 'true';
});

/// Whether learning progress is included in Tủ khoe for the currently selected kid (defaults to `false`).
final showcaseLearningProvider = FutureProvider<bool>((ref) async {
  final kidId = await ref.watch(currentKidIdProvider.future);
  if (kidId == null) return false;
  return ref.watch(kidShowcaseLearningProvider(kidId).future);
});

/// Whether Chip speaks aloud; defaults to true.
final voiceEnabledProvider = FutureProvider<bool>((ref) async {
  final v = await ref.watch(kidRepositoryProvider).setting(voiceEnabledKey);
  return v != 'false';
});

final consentAtProvider = FutureProvider<String?>((ref) async {
  return ref.watch(kidRepositoryProvider).setting(consentAtKey);
});
