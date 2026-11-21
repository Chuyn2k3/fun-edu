import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/app_database.dart';
import '../uuid.dart';

/// One record as the server stores it: `kind:...` key, JSON object payload,
/// `null` payload for a deletion.
class SyncRecord {
  const SyncRecord(this.key, this.payload, {this.version = 0});

  final String key;
  final Map<String, Object?>? payload;

  /// Server version (0 for a record not yet on the server).
  final int version;

  bool get deleted => payload == null;
  String get kind => key.substring(0, key.indexOf(':'));
}

/// A local change to send: [baseVersion] is the server version this device
/// last saw for the key (null = the key is new to this device).
class SyncChange {
  const SyncChange(this.key, this.payload, this.baseVersion);

  final String key;
  final Map<String, Object?>? payload;
  final int? baseVersion;

  Map<String, Object?> toJson() => {
        'key': key,
        'payload': payload,
        'deleted': payload == null,
        'baseVersion': baseVersion,
      };
}

/// JSON with sorted keys, so equal payloads compare equal as strings.
String canonicalJson(Object? value) => jsonEncode(_sorted(value));

Object? _sorted(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => '$k').toList()..sort();
    return {for (final k in keys) k: _sorted(v[k])};
  }
  if (v is List) return v.map(_sorted).toList();
  return v;
}

/// Per-kid settings that follow the kid to other devices. Device settings
/// (voice, current kid, consent) stay on the device.
const _kidSettings = [
  'dailyLimitMinutes',
  'bedtimeStart',
  'bedtimeEnd',
  'chipHouse',
  'raceNickname',
];

/// Maps the local database to sync records and merges records from the
/// server back in. Stroke attempts (drawing coordinates) are never synced.
///
/// Merge rules when both sides changed a record:
/// - finished lessons, races and owned items are only ever added (union), so
///   stars are never lost;
/// - practice counters, usage seconds, badge counters and cosmic stars take
///   the larger value; a badge keeps its earliest date;
/// - everything else (kid profile, levels, rewards, settings, selected
///   rocket) keeps the copy changed on this device;
/// - a deletion from the server always wins (it is an explicit parent action).
class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------- export

  /// Every syncable record on this device, by key.
  Future<Map<String, Map<String, Object?>>> exportAll() async {
    final out = <String, Map<String, Object?>>{};
    final uuidOf = await _kidUuids();
    String? ku(int kidId) => uuidOf[kidId];

    for (final k in await _db.select(_db.kidProfiles).get()) {
      out['kid:${uuidOf[k.id]}'] = {
        'nickname': k.nickname,
        'avatar': k.avatar,
        'age': k.age,
        'createdAt': _ms(k.createdAt),
      };
    }
    for (final g in await _db.select(_db.glyphProgress).get()) {
      final u = ku(g.kidId);
      if (u == null) continue;
      out['glyph:$u:${g.glyphId}'] = {
        'completions': g.completions,
        'clean': g.cleanCompletions,
        'last': _ms(g.lastPracticedAt),
      };
    }
    for (final l in await _db.select(_db.lessonCompletions).get()) {
      final u = ku(l.kidId);
      if (u == null) continue;
      out['lesson:$u:${_ms(l.completedAt)}'] = {'stars': l.starsEarned};
    }
    for (final s in await _db.select(_db.subjectLevels).get()) {
      final u = ku(s.kidId);
      if (u == null) continue;
      out['level:$u:${s.subject}'] = {
        'level': s.levelIndex,
        'placedAt': _ms(s.placedAt),
      };
    }
    for (final d in await _db.select(_db.dailyUsage).get()) {
      final u = ku(d.kidId);
      if (u == null) continue;
      out['usage:$u:${d.day}'] = {'seconds': d.seconds};
    }
    for (final r in await _db.select(_db.realRewards).get()) {
      final u = ku(r.kidId);
      if (u == null) continue;
      out['reward:$u:${_ms(r.createdAt)}'] = {
        'title': r.title,
        'starsNeeded': r.starsNeeded,
        'redeemedAt': r.redeemedAt == null ? null : _ms(r.redeemedAt!),
      };
    }
    for (final s in await _db.select(_db.appSettings).get()) {
      final parsed = _kidSetting(s.key);
      if (parsed == null) continue;
      final u = ku(parsed.$1);
      if (u == null) continue;
      out['setting:$u:${parsed.$2}'] = {'value': s.value};
    }
    for (final r in await _db.select(_db.raceResults).get()) {
      final u = ku(r.kidId);
      if (u == null) continue;
      out['race:$u:${_ms(r.finishedAt)}'] = {
        'subject': r.subject,
        'won': r.won,
        'kidTimeMs': r.kidTimeMs,
        'firstTry': r.firstTryCorrect,
        'comets': r.cometsFirstTry,
        'stars': r.stars,
      };
    }
    for (final g in await _db.select(_db.gameProfile).get()) {
      final u = ku(g.kidId);
      if (u == null) continue;
      out['game:$u'] = {
        'cosmicStars': g.cosmicStars,
        'rocket': g.selectedRocket,
        'trail': g.selectedTrail,
        'meanAnswerMs': g.meanAnswerMs,
        'slowNextRace': g.slowNextRace,
        'retryAfterLossPending': g.retryAfterLossPending,
      };
    }
    for (final i in await _db.select(_db.gameItems).get()) {
      final u = ku(i.kidId);
      if (u == null) continue;
      out['item:$u:${i.itemId}'] = const {'owned': true};
    }
    for (final b in await _db.select(_db.gameBadges).get()) {
      final u = ku(b.kidId);
      if (u == null) continue;
      out['badge:$u:${b.badgeId}'] = {'earnedAt': _ms(b.earnedAt)};
    }
    for (final c in await _db.select(_db.gameCounters).get()) {
      final u = ku(c.kidId);
      if (u == null) continue;
      out['counter:$u:${c.key}'] = {'value': c.value};
    }
    return out;
  }

  /// Local records that differ from what was last synced, plus deletions of
  /// records that were synced and are now gone.
  Future<List<SyncChange>> pendingChanges() async {
    final local = await exportAll();
    final synced = {
      for (final r in await _db.select(_db.syncedRecords).get()) r.key: r,
    };
    final changes = <SyncChange>[];
    local.forEach((key, payload) {
      final s = synced[key];
      if (s == null || s.payloadJson != canonicalJson(payload)) {
        changes.add(SyncChange(key, payload, s?.version));
      }
    });
    for (final s in synced.values) {
      if (s.payloadJson != null && !local.containsKey(s.key)) {
        changes.add(SyncChange(s.key, null, s.version));
      }
    }
    return changes;
  }

  /// Remembers that the server now holds [payload] at [version] for [key].
  Future<void> markSynced(String key, int version, Map<String, Object?>? payload) =>
      _db.into(_db.syncedRecords).insertOnConflictUpdate(
            SyncedRecordsCompanion.insert(
              key: key,
              version: version,
              payloadJson: Value(payload == null ? null : canonicalJson(payload)),
            ),
          );

  // ----------------------------------------------------------------- apply

  /// Merges records pulled from the server. Kids are applied first so their
  /// progress can find them, whatever order the records came in.
  Future<void> applyRemote(List<SyncRecord> records) => _db.transaction(() async {
        final sorted = [...records]..sort((a, b) {
            final ak = a.kind == 'kid' ? 0 : 1;
            final bk = b.kind == 'kid' ? 0 : 1;
            return ak != bk ? ak - bk : a.version - b.version;
          });
        final local = await exportAll();
        final synced = {
          for (final r in await _db.select(_db.syncedRecords).get()) r.key: r,
        };
        for (final r in sorted) {
          final mine = local[r.key];
          final s = synced[r.key];
          final dirty = mine != null &&
              (s == null || s.payloadJson != canonicalJson(mine));
          final merged = r.deleted ? null : _merge(r.kind, mine, r.payload!, dirty);
          final applied = await _write(r.key, merged, existed: mine != null);
          // What the server holds: the next export sends `merged` back with
          // this version as its base when it differs from the server's copy.
          await markSynced(r.key, r.version, applied ? r.payload : null);
        }
      });

  Map<String, Object?> _merge(
    String kind,
    Map<String, Object?>? mine,
    Map<String, Object?> theirs,
    bool dirty,
  ) {
    if (mine == null) return theirs;
    int i(Map<String, Object?> m, String k) => (m[k] as num?)?.toInt() ?? 0;
    switch (kind) {
      case 'lesson':
      case 'race':
      case 'item':
        return mine; // Same key = same event: nothing to merge.
      case 'glyph':
        return {
          'completions': _max(i(mine, 'completions'), i(theirs, 'completions')),
          'clean': _max(i(mine, 'clean'), i(theirs, 'clean')),
          'last': _max(i(mine, 'last'), i(theirs, 'last')),
        };
      case 'usage':
        return {'seconds': _max(i(mine, 'seconds'), i(theirs, 'seconds'))};
      case 'counter':
        return {'value': _max(i(mine, 'value'), i(theirs, 'value'))};
      case 'badge':
        final a = i(mine, 'earnedAt');
        final b = i(theirs, 'earnedAt');
        return {'earnedAt': a < b ? a : b};
      case 'game':
        final base = dirty ? mine : theirs;
        return {
          ...base,
          'cosmicStars': _max(i(mine, 'cosmicStars'), i(theirs, 'cosmicStars')),
        };
      default:
        return dirty ? mine : theirs;
    }
  }

  static int _max(int a, int b) => a > b ? a : b;

  /// Writes one merged record into the local tables; null deletes it.
  /// Returns false when the record cannot be held (its kid is unknown).
  Future<bool> _write(String key, Map<String, Object?>? p, {required bool existed}) async {
    final parts = key.split(':');
    final kind = parts[0];
    final ku = parts[1];
    if (kind == 'kid') return _writeKid(ku, p);

    final kidId = await _kidIdOf(ku);
    if (kidId == null) return false;
    final rest = parts.sublist(2).join(':');
    int i(String k) => (p![k] as num).toInt();
    DateTime t(String k) => DateTime.fromMillisecondsSinceEpoch(i(k));

    switch (kind) {
      case 'glyph':
        if (p == null) {
          await (_db.delete(_db.glyphProgress)
                ..where((r) => r.kidId.equals(kidId) & r.glyphId.equals(rest)))
              .go();
        } else {
          await _db.into(_db.glyphProgress).insertOnConflictUpdate(
                GlyphProgressCompanion.insert(
                  kidId: kidId,
                  glyphId: rest,
                  completions: Value(i('completions')),
                  cleanCompletions: Value(i('clean')),
                  lastPracticedAt: t('last'),
                ),
              );
        }
      case 'lesson':
        final at = DateTime.fromMillisecondsSinceEpoch(int.parse(rest));
        await (_db.delete(_db.lessonCompletions)
              ..where((r) => r.kidId.equals(kidId) & r.completedAt.equals(at)))
            .go();
        if (p != null) {
          await _db.into(_db.lessonCompletions).insert(
                LessonCompletionsCompanion.insert(
                    kidId: kidId, completedAt: at, starsEarned: i('stars')),
              );
        }
      case 'level':
        if (p == null) {
          await (_db.delete(_db.subjectLevels)
                ..where((r) => r.kidId.equals(kidId) & r.subject.equals(rest)))
              .go();
        } else {
          await _db.into(_db.subjectLevels).insertOnConflictUpdate(
                SubjectLevelsCompanion.insert(
                  kidId: kidId,
                  subject: rest,
                  levelIndex: i('level'),
                  placedAt: t('placedAt'),
                ),
              );
        }
      case 'usage':
        if (p == null) {
          await (_db.delete(_db.dailyUsage)
                ..where((r) => r.kidId.equals(kidId) & r.day.equals(rest)))
              .go();
        } else {
          await _db.into(_db.dailyUsage).insertOnConflictUpdate(
                DailyUsageCompanion.insert(
                    kidId: kidId, day: rest, seconds: Value(i('seconds'))),
              );
        }
      case 'reward':
        final at = DateTime.fromMillisecondsSinceEpoch(int.parse(rest));
        await (_db.delete(_db.realRewards)
              ..where((r) => r.kidId.equals(kidId) & r.createdAt.equals(at)))
            .go();
        if (p != null) {
          final redeemed = p['redeemedAt'] as num?;
          await _db.into(_db.realRewards).insert(
                RealRewardsCompanion.insert(
                  kidId: kidId,
                  title: p['title']! as String,
                  starsNeeded: i('starsNeeded'),
                  createdAt: at,
                  redeemedAt: Value(redeemed == null
                      ? null
                      : DateTime.fromMillisecondsSinceEpoch(redeemed.toInt())),
                ),
              );
        }
      case 'setting':
        final localKey = _localSettingKey(rest, kidId);
        if (localKey == null) return false;
        if (p == null) {
          await (_db.delete(_db.appSettings)..where((r) => r.key.equals(localKey)))
              .go();
        } else {
          await _db.into(_db.appSettings).insertOnConflictUpdate(
                AppSettingsCompanion.insert(key: localKey, value: p['value']! as String),
              );
        }
      case 'race':
        final at = DateTime.fromMillisecondsSinceEpoch(int.parse(rest));
        await (_db.delete(_db.raceResults)
              ..where((r) => r.kidId.equals(kidId) & r.finishedAt.equals(at)))
            .go();
        if (p != null) {
          await _db.into(_db.raceResults).insert(
                RaceResultsCompanion.insert(
                  kidId: kidId,
                  subject: p['subject']! as String,
                  finishedAt: at,
                  won: p['won']! as bool,
                  kidTimeMs: i('kidTimeMs'),
                  firstTryCorrect: i('firstTry'),
                  cometsFirstTry: i('comets'),
                  stars: i('stars'),
                ),
              );
        }
      case 'game':
        if (p == null) {
          await (_db.delete(_db.gameProfile)..where((r) => r.kidId.equals(kidId)))
              .go();
        } else {
          await _db.into(_db.gameProfile).insertOnConflictUpdate(
                GameProfileCompanion.insert(
                  kidId: Value(kidId),
                  cosmicStars: Value(i('cosmicStars')),
                  selectedRocket: Value(p['rocket']! as String),
                  selectedTrail: Value(p['trail']! as String),
                  meanAnswerMs: Value(i('meanAnswerMs')),
                  slowNextRace: Value(p['slowNextRace']! as bool),
                  retryAfterLossPending: Value(p['retryAfterLossPending']! as bool),
                ),
              );
        }
      case 'item':
        if (p == null) {
          await (_db.delete(_db.gameItems)
                ..where((r) => r.kidId.equals(kidId) & r.itemId.equals(rest)))
              .go();
        } else {
          await _db.into(_db.gameItems).insertOnConflictUpdate(
                GameItemsCompanion.insert(kidId: kidId, itemId: rest),
              );
        }
      case 'badge':
        if (p == null) {
          await (_db.delete(_db.gameBadges)
                ..where((r) => r.kidId.equals(kidId) & r.badgeId.equals(rest)))
              .go();
        } else {
          await _db.into(_db.gameBadges).insertOnConflictUpdate(
                GameBadgesCompanion.insert(
                    kidId: kidId, badgeId: rest, earnedAt: t('earnedAt')),
              );
        }
      case 'counter':
        if (p == null) {
          await (_db.delete(_db.gameCounters)
                ..where((r) => r.kidId.equals(kidId) & r.key.equals(rest)))
              .go();
        } else {
          await _db.into(_db.gameCounters).insertOnConflictUpdate(
                GameCountersCompanion.insert(
                    kidId: kidId, key: rest, value: Value(i('value'))),
              );
        }
      default:
        return false;
    }
    return p != null || existed;
  }

  Future<bool> _writeKid(String ku, Map<String, Object?>? p) async {
    final id = await _kidIdOf(ku);
    if (p == null) {
      if (id != null) await _deleteKid(id);
      return false;
    }
    final row = KidProfilesCompanion(
      nickname: Value(p['nickname']! as String),
      avatar: Value(p['avatar']! as String),
      age: Value((p['age']! as num).toInt()),
      createdAt: Value(DateTime.fromMillisecondsSinceEpoch((p['createdAt']! as num).toInt())),
      uuid: Value(ku),
    );
    if (id == null) {
      final newId = await _db.into(_db.kidProfiles).insert(row);
      // A device with no kid yet picks the first one that arrives.
      final current = await (_db.select(_db.appSettings)
            ..where((r) => r.key.equals('currentKidId')))
          .getSingleOrNull();
      if (current == null) {
        await _db.into(_db.appSettings).insert(
              AppSettingsCompanion.insert(key: 'currentKidId', value: '$newId'),
            );
      }
    } else {
      await (_db.update(_db.kidProfiles)..where((r) => r.id.equals(id))).write(row);
    }
    return true;
  }

  /// Same cleanup as deleting a kid in Góc ba mẹ.
  Future<void> _deleteKid(int id) async {
    for (final t in <TableInfo>[
      _db.strokeAttempts,
      _db.glyphProgress,
      _db.lessonCompletions,
      _db.subjectLevels,
      _db.dailyUsage,
      _db.realRewards,
      _db.raceResults,
      _db.gameProfile,
      _db.gameItems,
      _db.gameBadges,
      _db.gameCounters,
    ]) {
      await _db.customStatement('DELETE FROM ${t.actualTableName} WHERE kid_id = ?', [id]);
    }
    await _db.customStatement(
      "DELETE FROM app_settings WHERE key IN (?, ?, ?, ?, ?) OR key LIKE ?",
      [
        'dailyLimitMinutes.$id',
        'bedtimeStart.$id',
        'bedtimeEnd.$id',
        'chipHouse.$id',
        'raceNickname.$id',
        'extraMinutes.$id.%',
      ],
    );
    await (_db.delete(_db.kidProfiles)..where((r) => r.id.equals(id))).go();
    final current = await (_db.select(_db.appSettings)
          ..where((r) => r.key.equals('currentKidId')))
        .getSingleOrNull();
    if (current?.value == '$id') {
      final next = await (_db.select(_db.kidProfiles)..limit(1)).getSingleOrNull();
      if (next == null) {
        await (_db.delete(_db.appSettings)..where((r) => r.key.equals('currentKidId')))
            .go();
      } else {
        await _db.into(_db.appSettings).insertOnConflictUpdate(
              AppSettingsCompanion.insert(key: 'currentKidId', value: '${next.id}'),
            );
      }
    }
  }

  // --------------------------------------------------------------- helpers

  /// Local kid id -> uuid; gives a uuid to any kid that lacks one.
  Future<Map<int, String>> _kidUuids() async {
    final out = <int, String>{};
    for (final k in await _db.select(_db.kidProfiles).get()) {
      var u = k.uuid;
      if (u == null) {
        u = newUuid();
        await (_db.update(_db.kidProfiles)..where((r) => r.id.equals(k.id)))
            .write(KidProfilesCompanion(uuid: Value(u)));
      }
      out[k.id] = u;
    }
    return out;
  }

  Future<int?> _kidIdOf(String uuid) async =>
      (await (_db.select(_db.kidProfiles)..where((r) => r.uuid.equals(uuid)))
              .getSingleOrNull())
          ?.id;

  /// `dailyLimitMinutes.3` -> (3, 'dailyLimitMinutes');
  /// `extraMinutes.3.2026-11-21` -> (3, 'extraMinutes.2026-11-21').
  static (int, String)? _kidSetting(String key) {
    final parts = key.split('.');
    if (parts.length < 2) return null;
    final id = int.tryParse(parts[1]);
    if (id == null) return null;
    if (_kidSettings.contains(parts[0]) && parts.length == 2) return (id, parts[0]);
    if (parts[0] == 'extraMinutes' && parts.length == 3) {
      return (id, 'extraMinutes.${parts[2]}');
    }
    return null;
  }

  static String? _localSettingKey(String name, int kidId) {
    if (_kidSettings.contains(name)) return '$name.$kidId';
    if (name.startsWith('extraMinutes.')) {
      return 'extraMinutes.$kidId.${name.substring('extraMinutes.'.length)}';
    }
    return null;
  }

  static int _ms(DateTime t) => t.millisecondsSinceEpoch;
}
