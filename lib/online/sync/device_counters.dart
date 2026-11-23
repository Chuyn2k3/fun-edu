import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../data/app_database.dart';
import '../device_id.dart';

/// Stores monotonic counter contributions broken down by `deviceId` in
/// `device_counters` so concurrent offline writes across devices always add up
/// cleanly and resends remain idempotent.
class DeviceCounterStore {
  DeviceCounterStore(this._db, {String? deviceId}) : _deviceId = deviceId;

  final AppDatabase _db;
  final String? _deviceId;

  Future<String> _id() async => _deviceId ?? await ensureDeviceId(_db);

  /// Adds [delta] to this device's row for [counterKey]. Participates in the
  /// caller's transaction when already inside one.
  Future<void> add(String counterKey, int delta) async {
    if (delta == 0) return;
    await _db.transaction(() async {
      final did = await _id();
      final row = await (_db.select(_db.deviceCounters)
            ..where((t) => t.key.equals(counterKey) & t.deviceId.equals(did)))
          .getSingleOrNull();
      final next = (row?.value ?? 0) + delta;
      await _db.into(_db.deviceCounters).insertOnConflictUpdate(
            DeviceCountersCompanion.insert(
              key: counterKey,
              deviceId: did,
              value: next,
            ),
          );
    });
  }

  /// Sum across all devices for [counterKey].
  Future<int> total(String counterKey) async {
    final rows = await (_db.select(_db.deviceCounters)
          ..where((t) => t.key.equals(counterKey)))
        .get();
    var sum = 0;
    for (final r in rows) {
      sum += r.value;
    }
    return sum;
  }

  /// Per-device contributions for [counterKey] (omitting non-positive rows).
  Future<Map<String, int>> byDevice(String counterKey) async {
    final rows = await (_db.select(_db.deviceCounters)
          ..where((t) => t.key.equals(counterKey)))
        .get();
    return {
      for (final r in rows)
        if (r.value > 0) r.deviceId: r.value,
    };
  }

  /// Merges remote per-device counts into [deviceCounters], keeping the larger
  /// value per device.
  Future<void> mergeRemote(String counterKey, Map<String, int> byDevice) async {
    if (byDevice.isEmpty) return;
    await _db.transaction(() async {
      for (final entry in byDevice.entries) {
        if (entry.value <= 0) continue;
        final row = await (_db.select(_db.deviceCounters)
              ..where((t) =>
                  t.key.equals(counterKey) & t.deviceId.equals(entry.key)))
            .getSingleOrNull();
        final current = row?.value ?? 0;
        if (entry.value > current) {
          await _db.into(_db.deviceCounters).insertOnConflictUpdate(
                DeviceCountersCompanion.insert(
                  key: counterKey,
                  deviceId: entry.key,
                  value: entry.value,
                ),
              );
        }
      }
    });
  }

  /// Merges a pre-v11 scalar counter record from an un-updated device into the
  /// `'legacy'` bucket without double-counting contributions from known devices.
  Future<void> mergeLegacyRemote(String counterKey, int legacyTotal) async {
    if (legacyTotal <= 0) return;
    await _db.transaction(() async {
      final rows = await (_db.select(_db.deviceCounters)
            ..where((t) => t.key.equals(counterKey)))
          .get();
      var nonLegacy = 0;
      var currentLegacy = 0;
      for (final r in rows) {
        if (r.deviceId == 'legacy') {
          currentLegacy = r.value;
        } else {
          nonLegacy += r.value;
        }
      }
      final needed = math.max(0, legacyTotal - nonLegacy);
      if (needed > currentLegacy) {
        await _db.into(_db.deviceCounters).insertOnConflictUpdate(
              DeviceCountersCompanion.insert(
                key: counterKey,
                deviceId: 'legacy',
                value: needed,
              ),
            );
      }
    });
  }

  /// Replaces/upserts exact per-device values for [counterKey] (used after an
  /// in-memory merge).
  Future<int> writeMerged(String counterKey, Map<String, int> merged) async {
    return _db.transaction(() async {
      var sum = 0;
      for (final entry in merged.entries) {
        await _db.into(_db.deviceCounters).insertOnConflictUpdate(
              DeviceCountersCompanion.insert(
                key: counterKey,
                deviceId: entry.key,
                value: entry.value,
              ),
            );
        sum += entry.value;
      }
      return sum;
    });
  }
}
