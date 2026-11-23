import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../data/app_database.dart';
import '../device_id.dart';
import '../uuid.dart';
import 'device_counters.dart';

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

  /// Kid uuid -> local id while a page is being applied: every record looks
  /// its kid up, and one query per record made a restore twice as slow.
  /// Null outside [applyPage] / [applyWaiting]; dropped when a kid changes.
  Map<String, int>? _kidIds;

  /// Every record kind explicitly handled by [_merge]. Tested against
  /// `exportAll()` and `SyncKinds.ALLOWED`.
  static const Set<String> mergeKinds = {
    'kid',
    'glyph',
    'lesson',
    'level',
    'usage',
    'reward',
    'setting',
    'race',
    'game',
    'item',
    'badge',
    'counter',
    'page',
  };

  // ---------------------------------------------------------------- export

  /// Every syncable record on this device, by key.
  Future<Map<String, Map<String, Object?>>> exportAll() async {
    final out = <String, Map<String, Object?>>{};
    final uuidOf = await _kidUuids();
    final deviceId = await ensureDeviceId(_db);
    String? ku(int kidId) => uuidOf[kidId];

    final allDc = await _db.select(_db.deviceCounters).get();
    final dcByKey = <String, Map<String, int>>{};
    for (final r in allDc) {
      if (r.value > 0) {
        (dcByKey[r.key] ??= {})[r.deviceId] = r.value;
      }
    }

    final syncedRows = await _db.select(_db.syncedRecords).get();
    final syncedPayloads = <String, Map<String, Object?>>{};
    for (final s in syncedRows) {
      if (s.payloadJson != null) {
        syncedPayloads[s.key] =
            (jsonDecode(s.payloadJson!) as Map).cast<String, Object?>();
      }
    }

    String pickLwwDevice(String key, Map<String, Object?> fields) {
      final prev = syncedPayloads[key];
      if (prev != null && prev['d'] is String) {
        final prevWithoutD = Map<String, Object?>.from(prev)..remove('d');
        if (canonicalJson(prevWithoutD) == canonicalJson(fields)) {
          return prev['d'] as String;
        }
      }
      return deviceId;
    }

    for (final k in await _db.select(_db.kidProfiles).get()) {
      final key = 'kid:${uuidOf[k.id]}';
      final fields = <String, Object?>{
        'nickname': k.nickname,
        'avatar': k.avatar,
        'age': k.age,
        'createdAt': _ms(k.createdAt),
        'u': _u(k.updatedAt),
      };
      out[key] = {...fields, 'd': pickLwwDevice(key, fields)};
    }
    for (final g in await _db.select(_db.glyphProgress).get()) {
      final u = ku(g.kidId);
      if (u == null) continue;
      final cMap =
          Map<String, int>.from(dcByKey['glyph.c:$u:${g.glyphId}'] ?? const {});
      final kMap =
          Map<String, int>.from(dcByKey['glyph.k:$u:${g.glyphId}'] ?? const {});
      final cSum = cMap.values.fold(0, (a, b) => a + b);
      if (cSum < g.completions) {
        cMap[deviceId] = (cMap[deviceId] ?? 0) + (g.completions - cSum);
      }
      final kSum = kMap.values.fold(0, (a, b) => a + b);
      if (kSum < g.cleanCompletions) {
        kMap[deviceId] = (kMap[deviceId] ?? 0) + (g.cleanCompletions - kSum);
      }
      final devs = {...cMap.keys, ...kMap.keys}.toList()..sort();
      out['glyph:$u:${g.glyphId}'] = {
        'by': {
          for (final d in devs)
            d: {
              'c': cMap[d] ?? 0,
              'k': kMap[d] ?? 0,
            },
        },
        'last': _ms(g.lastPracticedAt),
      };
    }
    for (final p in await _db.select(_db.notebookPages).get()) {
      final u = ku(p.kidId);
      if (u == null) continue;
      out['page:$u:${p.glyphId}'] = {
        's': jsonDecode(p.strokes),
        'm': p.mistakes,
        'at': _ms(p.writtenAt),
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
      final uMap =
          Map<String, int>.from(dcByKey['usage:$u:${d.day}'] ?? const {});
      final uSum = uMap.values.fold(0, (a, b) => a + b);
      if (uSum < d.seconds) {
        uMap[deviceId] = (uMap[deviceId] ?? 0) + (d.seconds - uSum);
      }
      out['usage:$u:${d.day}'] = {'by': uMap};
    }
    for (final r in await _db.select(_db.realRewards).get()) {
      final u = ku(r.kidId);
      if (u == null) continue;
      final key = 'reward:$u:${_ms(r.createdAt)}';
      final fields = <String, Object?>{
        'title': r.title,
        'starsNeeded': r.starsNeeded,
        'redeemedAt': r.redeemedAt == null ? null : _ms(r.redeemedAt!),
        'u': _u(r.updatedAt),
      };
      out[key] = {...fields, 'd': pickLwwDevice(key, fields)};
    }
    for (final s in await _db.select(_db.appSettings).get()) {
      final parsed = _kidSetting(s.key);
      if (parsed == null) continue;
      final u = ku(parsed.$1);
      if (u == null) continue;
      final key = 'setting:$u:${parsed.$2}';
      final fields = <String, Object?>{
        'value': s.value,
        'u': _u(s.updatedAt),
      };
      out[key] = {...fields, 'd': pickLwwDevice(key, fields)};
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
      final key = 'game:$u';
      final eMap =
          Map<String, int>.from(dcByKey['stars.earned:$u'] ?? const {});
      final sMap = Map<String, int>.from(dcByKey['stars.spent:$u'] ?? const {});
      final net = eMap.values.fold<int>(0, (a, b) => a + b) -
          sMap.values.fold<int>(0, (a, b) => a + b);
      if (net < g.cosmicStars) {
        eMap[deviceId] = (eMap[deviceId] ?? 0) + (g.cosmicStars - net);
      }
      final fields = <String, Object?>{
        'earned': eMap,
        'spent': sMap,
        'rocket': g.selectedRocket,
        'trail': g.selectedTrail,
        'meanAnswerMs': g.meanAnswerMs,
        'slowNextRace': g.slowNextRace,
        'retryAfterLossPending': g.retryAfterLossPending,
        'u': _u(g.updatedAt),
      };
      out[key] = {...fields, 'd': pickLwwDevice(key, fields)};
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
      final cKey = 'counter:$u:${c.key}';
      final cMap = Map<String, int>.from(dcByKey[cKey] ?? const {});
      final dMap = Map<String, int>.from(
          dcByKey[DeviceCounterStore.decKey(cKey)] ?? const {});
      // Whatever the table says that the device rows do not explain is this
      // device's own change (written before v11, or set directly).
      final net = cMap.values.fold<int>(0, (a, b) => a + b) -
          dMap.values.fold<int>(0, (a, b) => a + b);
      if (net < c.value) {
        cMap[deviceId] = (cMap[deviceId] ?? 0) + (c.value - net);
      } else if (net > c.value) {
        dMap[deviceId] = (dMap[deviceId] ?? 0) + (net - c.value);
      }
      out[cKey] = {'by': cMap, if (dMap.isNotEmpty) 'dec': dMap};
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
  Future<void> applyRemote(List<SyncRecord> records) => applyPage(records, 0);

  /// Applies one page of records in a single transaction, saving [cursor]
  /// to `app_settings` (key `sync.cursor`). Records for unknown kids are placed
  /// in `sync_pending_remote` to be applied later when the kid arrives.
  Future<void> applyPage(List<SyncRecord> records, int cursor) =>
      _db.transaction(() => _withKidCache(() async {
        final sorted = [...records]..sort((a, b) {
            final ak = a.kind == 'kid' ? 0 : 1;
            final bk = b.kind == 'kid' ? 0 : 1;
            return ak != bk ? ak - bk : a.version - b.version;
          });
        final local = await exportAll();
        final synced = {
          for (final r in await _db.select(_db.syncedRecords).get()) r.key: r,
        };
        // Usually empty: only these keys need clearing from the waiting list.
        final waiting = {
          for (final w in await _db.select(_db.syncPendingRemote).get()) w.key,
        };
        var hasNewKids = false;
        for (final r in sorted) {
          final parts = r.key.split(':');
          final kind = parts[0];
          final ku = parts.length > 1 ? parts[1] : null;

          if (kind != 'kid' && ku != null && await _kidIdOf(ku) == null) {
            // Kid unknown: queue in syncPendingRemote without error
            await _db.into(_db.syncPendingRemote).insertOnConflictUpdate(
                  SyncPendingRemoteCompanion.insert(
                    key: r.key,
                    version: r.version,
                    payloadJson: Value(
                        r.payload == null ? null : canonicalJson(r.payload)),
                  ),
                );
            continue;
          }

          final mine = local[r.key];
          final s = synced[r.key];
          final dirty = mine != null &&
              (s == null || s.payloadJson != canonicalJson(mine));
          final merged =
              r.deleted ? null : _merge(r.kind, mine, r.payload!, dirty);
          final applied = await _write(r.key, merged, existed: mine != null);
          await markSynced(r.key, r.version, applied ? r.payload : null);

          // Clear from the waiting list if it was there
          if (waiting.contains(r.key)) {
            await (_db.delete(_db.syncPendingRemote)
                  ..where((t) => t.key.equals(r.key)))
                .go();
          }

          if (kind == 'kid') {
            hasNewKids = true;
          }
        }

        if (hasNewKids) {
          await _applyWaitingInternal();
        }

        if (cursor > 0) {
          await _db.into(_db.appSettings).insertOnConflictUpdate(
                AppSettingsCompanion.insert(
                    key: 'sync.cursor', value: '$cursor'),
              );
        }
      }));

  /// Applies pending remote records whose kid is now known locally.
  Future<void> applyWaiting() =>
      _db.transaction(() => _withKidCache(_applyWaitingInternal));

  Future<void> _applyWaitingInternal() async {
    final pending = await _db.select(_db.syncPendingRemote).get();
    if (pending.isEmpty) return;

    final local = await exportAll();
    final synced = {
      for (final r in await _db.select(_db.syncedRecords).get()) r.key: r,
    };

    for (final row in pending) {
      final parts = row.key.split(':');
      final ku = parts.length > 1 ? parts[1] : null;
      if (ku == null || await _kidIdOf(ku) == null) continue;

      final payload = row.payloadJson == null
          ? null
          : (jsonDecode(row.payloadJson!) as Map).cast<String, Object?>();
      final record = SyncRecord(row.key, payload, version: row.version);

      final mine = local[record.key];
      final s = synced[record.key];
      final dirty = mine != null &&
          (s == null || s.payloadJson != canonicalJson(mine));
      final merged = record.deleted
          ? null
          : _merge(record.kind, mine, record.payload!, dirty);
      final applied = await _write(record.key, merged, existed: mine != null);
      await markSynced(
          record.key, record.version, applied ? record.payload : null);

      await (_db.delete(_db.syncPendingRemote)
            ..where((t) => t.key.equals(row.key)))
          .go();
    }
  }

  Map<String, Object?> _merge(
    String kind,
    Map<String, Object?>? mine,
    Map<String, Object?> theirs,
    bool dirty,
  ) {
    assert(mergeKinds.contains(kind), 'Unhandled sync kind: $kind');
    int i(Map<String, Object?> m, String k) => (m[k] as num?)?.toInt() ?? 0;

    switch (kind) {
      case 'lesson':
      case 'race':
      case 'item':
        return mine ?? theirs; // Same key = same event: nothing to merge.
      case 'level':
        if (mine == null) return theirs;
        return dirty ? mine : theirs;
      case 'kid':
      case 'reward':
      case 'setting':
        if (mine == null) return theirs;
        return _theirsWinsLww(mine, theirs, dirty) ? theirs : mine;
      case 'glyph':
        final myBy = _glyphBy(mine);
        final merged = <String, Map<String, int>>{
          for (final e in myBy.entries) e.key: Map<String, int>.from(e.value),
        };
        if (theirs.containsKey('by')) {
          final theirBy = _glyphBy(theirs);
          for (final e in theirBy.entries) {
            final cur = merged[e.key];
            final c = _max(cur?['c'] ?? 0, e.value['c'] ?? 0);
            final k = _max(cur?['k'] ?? 0, e.value['k'] ?? 0);
            if (c > 0 || k > 0) merged[e.key] = {'c': c, 'k': k};
          }
        } else {
          final theirC = i(theirs, 'completions');
          final theirK = i(theirs, 'clean');
          var nonLegacyC = 0;
          var nonLegacyK = 0;
          for (final e in merged.entries) {
            if (e.key == 'legacy') continue;
            nonLegacyC += e.value['c'] ?? 0;
            nonLegacyK += e.value['k'] ?? 0;
          }
          final neededC = math.max(0, theirC - nonLegacyC);
          final neededK = math.max(0, theirK - nonLegacyK);
          final legacyC = _max(merged['legacy']?['c'] ?? 0, neededC);
          final legacyK = _max(merged['legacy']?['k'] ?? 0, neededK);
          if (legacyC > 0 || legacyK > 0) {
            merged['legacy'] = {'c': legacyC, 'k': legacyK};
          }
        }
        final sortedKeys = merged.keys.toList()..sort();
        return {
          'by': {for (final d in sortedKeys) d: merged[d]!},
          'last': _max(mine != null ? i(mine, 'last') : 0, i(theirs, 'last')),
        };
      case 'page':
        if (mine == null) return theirs;
        final myMistakes = i(mine, 'm');
        final theirMistakes = i(theirs, 'm');
        if (myMistakes < theirMistakes) return mine;
        if (theirMistakes < myMistakes) return theirs;
        final myAt = i(mine, 'at');
        final theirAt = i(theirs, 'at');
        return myAt >= theirAt ? mine : theirs;
      case 'usage':
        return {
          'by': _mergeDeviceCounterMap(
            _intMap(mine?['by']),
            theirs.containsKey('by') ? _intMap(theirs['by']) : null,
            legacyScalar: theirs.containsKey('by') ? null : i(theirs, 'seconds'),
          ),
        };
      case 'counter':
        final dec = _mergeDeviceCounterMap(
            _intMap(mine?['dec']), _intMap(theirs['dec']));
        return {
          'by': _mergeDeviceCounterMap(
            _intMap(mine?['by']),
            theirs.containsKey('by') ? _intMap(theirs['by']) : null,
            legacyScalar: theirs.containsKey('by') ? null : i(theirs, 'value'),
          ),
          if (dec.isNotEmpty) 'dec': dec,
        };
      case 'badge':
        if (mine == null) return theirs;
        final a = i(mine, 'earnedAt');
        final b = i(theirs, 'earnedAt');
        return {'earnedAt': a < b ? a : b};
      case 'game':
        final myEarned = _intMap(mine?['earned']);
        final mySpent = _intMap(mine?['spent']);
        Map<String, int> mergedEarned;
        Map<String, int> mergedSpent;
        if (theirs.containsKey('earned')) {
          mergedEarned = _mergeDeviceCounterMap(
            myEarned,
            _intMap(theirs['earned']),
          );
          mergedSpent = _mergeDeviceCounterMap(
            mySpent,
            _intMap(theirs['spent']),
          );
        } else {
          final theirStars = i(theirs, 'cosmicStars');
          var nonLegacyNet = 0;
          for (final e in myEarned.entries) {
            if (e.key != 'legacy') nonLegacyNet += e.value;
          }
          for (final e in mySpent.entries) {
            if (e.key != 'legacy') nonLegacyNet -= e.value;
          }
          final needed = math.max(0, theirStars - nonLegacyNet);
          mergedEarned = Map<String, int>.from(myEarned);
          if (needed > (mergedEarned['legacy'] ?? 0)) {
            mergedEarned['legacy'] = needed;
          }
          mergedSpent = Map<String, int>.from(mySpent);
        }
        final base = (mine == null || _theirsWinsLww(mine, theirs, dirty))
            ? theirs
            : mine;
        return {
          'earned': mergedEarned,
          'spent': mergedSpent,
          'rocket': base['rocket'] ?? 'rocket_orange',
          'trail': base['trail'] ?? 'trail_flame',
          'meanAnswerMs': base['meanAnswerMs'] ?? 6000,
          'slowNextRace': base['slowNextRace'] ?? false,
          'retryAfterLossPending': base['retryAfterLossPending'] ?? false,
          'u': (base['u'] as num?)?.toInt() ?? 0,
          if (base['d'] != null) 'd': base['d'],
        };
      default:
        throw StateError('Unknown sync kind: $kind');
    }
  }

  static bool _theirsWinsLww(
    Map<String, Object?> mine,
    Map<String, Object?> theirs,
    bool dirty,
  ) {
    final myU = (mine['u'] as num?)?.toInt() ?? 0;
    final theirU = (theirs['u'] as num?)?.toInt() ?? 0;
    if (myU == 0 && theirU == 0) {
      // Un-timestamped edits fall back to keeping dirty local changes.
      return !dirty;
    }
    if (theirU != myU) return theirU > myU;
    final myD = mine['d'] as String? ?? '';
    final theirD = theirs['d'] as String? ?? '';
    if (theirD != myD) return theirD.compareTo(myD) > 0;
    return !dirty;
  }

  static Map<String, Map<String, int>> _glyphBy(Map<String, Object?>? p) {
    final raw = p?['by'];
    if (raw is! Map) return const {};
    final out = <String, Map<String, int>>{};
    for (final e in raw.entries) {
      if (e.value is! Map) continue;
      final v = e.value as Map;
      out['${e.key}'] = {
        'c': (v['c'] as num?)?.toInt() ?? 0,
        'k': (v['k'] as num?)?.toInt() ?? 0,
      };
    }
    return out;
  }

  static Map<String, int> _intMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.value is num && (e.value as num).toInt() > 0)
          '${e.key}': (e.value as num).toInt(),
    };
  }

  static Map<String, int> _mergeDeviceCounterMap(
    Map<String, int> myBy,
    Map<String, int>? theirBy, {
    int? legacyScalar,
  }) {
    final out = Map<String, int>.from(myBy);
    if (theirBy != null) {
      for (final e in theirBy.entries) {
        final v = _max(out[e.key] ?? 0, e.value);
        if (v > 0) out[e.key] = v;
      }
    } else if (legacyScalar != null) {
      var nonLegacy = 0;
      for (final e in out.entries) {
        if (e.key != 'legacy') nonLegacy += e.value;
      }
      final needed = math.max(0, legacyScalar - nonLegacy);
      final legacy = _max(out['legacy'] ?? 0, needed);
      if (legacy > 0) out['legacy'] = legacy;
    }
    return out;
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
    final counters = DeviceCounterStore(_db);
    int i(String k) => (p![k] as num).toInt();
    DateTime t(String k) => DateTime.fromMillisecondsSinceEpoch(i(k));

    switch (kind) {
      case 'glyph':
        final cKey = 'glyph.c:$ku:$rest';
        final kKey = 'glyph.k:$ku:$rest';
        if (p == null) {
          await (_db.delete(_db.glyphProgress)
                ..where((r) => r.kidId.equals(kidId) & r.glyphId.equals(rest)))
              .go();
          await (_db.delete(_db.deviceCounters)
                ..where((r) => r.key.equals(cKey) | r.key.equals(kKey)))
              .go();
        } else {
          final by = _glyphBy(p);
          final cMap = {for (final e in by.entries) e.key: e.value['c'] ?? 0};
          final kMap = {for (final e in by.entries) e.key: e.value['k'] ?? 0};
          final totalC = await counters.writeMerged(cKey, cMap);
          final totalK = await counters.writeMerged(kKey, kMap);
          await _db.into(_db.glyphProgress).insertOnConflictUpdate(
                GlyphProgressCompanion.insert(
                  kidId: kidId,
                  glyphId: rest,
                  completions: Value(totalC),
                  cleanCompletions: Value(totalK),
                  lastPracticedAt: t('last'),
                ),
              );
        }
      case 'page':
        if (p == null) {
          await (_db.delete(_db.notebookPages)
                ..where((r) => r.kidId.equals(kidId) & r.glyphId.equals(rest)))
              .go();
        } else {
          final strokes = p['s'];
          await _db.into(_db.notebookPages).insertOnConflictUpdate(
                NotebookPagesCompanion.insert(
                  kidId: kidId,
                  glyphId: rest,
                  strokes: jsonEncode(strokes),
                  mistakes: i('m'),
                  writtenAt: t('at'),
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
        final uKey = 'usage:$ku:$rest';
        if (p == null) {
          await (_db.delete(_db.dailyUsage)
                ..where((r) => r.kidId.equals(kidId) & r.day.equals(rest)))
              .go();
          await (_db.delete(_db.deviceCounters)..where((r) => r.key.equals(uKey)))
              .go();
        } else {
          final uMap = _intMap(p['by']);
          final totalSec = await counters.writeMerged(uKey, uMap);
          await _db.into(_db.dailyUsage).insertOnConflictUpdate(
                DailyUsageCompanion.insert(
                    kidId: kidId, day: rest, seconds: Value(totalSec)),
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
                  updatedAt: Value(_optTime(p['u'])),
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
                AppSettingsCompanion.insert(
                  key: localKey,
                  value: p['value']! as String,
                  updatedAt: Value(_optTime(p['u'])),
                ),
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
        final eKey = 'stars.earned:$ku';
        final sKey = 'stars.spent:$ku';
        if (p == null) {
          await (_db.delete(_db.gameProfile)..where((r) => r.kidId.equals(kidId)))
              .go();
          await (_db.delete(_db.deviceCounters)
                ..where((r) => r.key.equals(eKey) | r.key.equals(sKey)))
              .go();
        } else {
          final eMap = _intMap(p['earned']);
          final sMap = _intMap(p['spent']);
          final earned = await counters.writeMerged(eKey, eMap);
          final spent = await counters.writeMerged(sKey, sMap);
          await _db.into(_db.gameProfile).insertOnConflictUpdate(
                GameProfileCompanion.insert(
                  kidId: Value(kidId),
                  cosmicStars: Value(earned - spent),
                  selectedRocket: Value(p['rocket']! as String),
                  selectedTrail: Value(p['trail']! as String),
                  meanAnswerMs: Value(i('meanAnswerMs')),
                  slowNextRace: Value(p['slowNextRace']! as bool),
                  retryAfterLossPending: Value(p['retryAfterLossPending']! as bool),
                  updatedAt: Value(_optTime(p['u'])),
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
        final cKey = 'counter:$ku:$rest';
        if (p == null) {
          await (_db.delete(_db.gameCounters)
                ..where((r) => r.kidId.equals(kidId) & r.key.equals(rest)))
              .go();
          await (_db.delete(_db.deviceCounters)
                ..where((r) => r.key.isIn([cKey, DeviceCounterStore.decKey(cKey)])))
              .go();
        } else {
          final cMap = _intMap(p['by']);
          final up = await counters.writeMerged(cKey, cMap);
          final down = await counters.writeMerged(
              DeviceCounterStore.decKey(cKey), _intMap(p['dec']));
          final val = math.max(0, up - down);
          await _db.into(_db.gameCounters).insertOnConflictUpdate(
                GameCountersCompanion.insert(
                    kidId: kidId, key: rest, value: Value(val)),
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
      if (id != null) await _deleteKid(id, ku: ku);
      _kidIds?.remove(ku);
      return false;
    }
    final row = KidProfilesCompanion(
      nickname: Value(p['nickname']! as String),
      avatar: Value(p['avatar']! as String),
      age: Value((p['age']! as num).toInt()),
      createdAt: Value(DateTime.fromMillisecondsSinceEpoch((p['createdAt']! as num).toInt())),
      uuid: Value(ku),
      updatedAt: Value(_optTime(p['u'])),
    );
    if (id == null) {
      final newId = await _db.into(_db.kidProfiles).insert(row);
      _kidIds?[ku] = newId;
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
  Future<void> _deleteKid(int id, {String? ku}) async {
    for (final t in <TableInfo>[
      _db.strokeAttempts,
      _db.notebookPages,
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
    if (ku != null) {
      await _db.customStatement(
        'DELETE FROM device_counters WHERE key LIKE ? OR key LIKE ?',
        ['%:$ku', '%:$ku:%'],
      );
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

  Future<int?> _kidIdOf(String uuid) async {
    if (_kidIds == null) {
      return (await (_db.select(_db.kidProfiles)..where((r) => r.uuid.equals(uuid)))
              .getSingleOrNull())
          ?.id;
    }
    return _kidIds![uuid];
  }

  Future<Map<String, int>> _loadKidIds() async => {
        for (final k in await _db.select(_db.kidProfiles).get())
          if (k.uuid != null) k.uuid!: k.id,
      };

  /// Runs [body] with the kid cache on (rebuilt after any kid record).
  Future<T> _withKidCache<T>(Future<T> Function() body) async {
    _kidIds = await _loadKidIds();
    try {
      return await body();
    } finally {
      _kidIds = null;
    }
  }

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
  static int _u(DateTime? t) => t?.millisecondsSinceEpoch ?? 0;
  static DateTime? _optTime(Object? v) {
    if (v is num && v.toInt() > 0) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }
    return null;
  }
}
