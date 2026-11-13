import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../profile/kid_repository.dart';
import '../progress/progress_repository.dart' show Clock;

enum ScreenTimeStatus { ok, limitReached, bedtime }

const int defaultDailyLimitMinutes = 45;
const int minDailyLimitMinutes = 15;
const int maxDailyLimitMinutes = 180;

String dailyLimitKey(int kidId) => 'dailyLimitMinutes.$kidId';
String bedtimeStartKey(int kidId) => 'bedtimeStart.$kidId';
String bedtimeEndKey(int kidId) => 'bedtimeEnd.$kidId';
String extraMinutesKey(int kidId, String day) => 'extraMinutes.$kidId.$day';

/// Local date as `yyyy-MM-dd`.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Per-kid daily usage, daily limit and bedtime. Limits live in
/// [AppSettings] (see the key helpers above).
class ScreenTimeService {
  ScreenTimeService(this._db, this._kids, {Clock now = DateTime.now})
      : _now = now;

  final AppDatabase _db;
  final KidRepository _kids;
  final Clock _now;

  Future<void> addUsage(int kidId, Duration d) async {
    final seconds = d.inSeconds;
    if (seconds <= 0) return;
    final day = dayKey(_now());
    await _db.transaction(() async {
      final row = await (_db.select(_db.dailyUsage)
            ..where((t) => t.kidId.equals(kidId) & t.day.equals(day)))
          .getSingleOrNull();
      await _db.into(_db.dailyUsage).insertOnConflictUpdate(
            DailyUsageCompanion.insert(
              kidId: kidId,
              day: day,
              seconds: Value((row?.seconds ?? 0) + seconds),
            ),
          );
    });
  }

  Future<Duration> usedToday(int kidId) async {
    final row = await (_db.select(_db.dailyUsage)
          ..where((t) => t.kidId.equals(kidId) & t.day.equals(dayKey(_now()))))
        .getSingleOrNull();
    return Duration(seconds: row?.seconds ?? 0);
  }

  Future<int> dailyLimitMinutes(int kidId) async {
    final v = int.tryParse(await _kids.setting(dailyLimitKey(kidId)) ?? '');
    if (v == null) return defaultDailyLimitMinutes;
    return v.clamp(minDailyLimitMinutes, maxDailyLimitMinutes);
  }

  Future<ScreenTimeStatus> status(int kidId) async {
    final now = _now();
    if (await _isBedtime(kidId, now)) return ScreenTimeStatus.bedtime;
    final extra = int.tryParse(
            await _kids.setting(extraMinutesKey(kidId, dayKey(now))) ?? '') ??
        0;
    final allowed = Duration(minutes: await dailyLimitMinutes(kidId) + extra);
    return await usedToday(kidId) >= allowed
        ? ScreenTimeStatus.limitReached
        : ScreenTimeStatus.ok;
  }

  /// Adds [minutes] to today's allowance (parents only).
  Future<void> grantExtra(int kidId, int minutes) async {
    final key = extraMinutesKey(kidId, dayKey(_now()));
    final current = int.tryParse(await _kids.setting(key) ?? '') ?? 0;
    await _kids.setSetting(key, '${current + minutes}');
  }

  Future<bool> _isBedtime(int kidId, DateTime now) async {
    final start = _parseMinutes(await _kids.setting(bedtimeStartKey(kidId)));
    final end = _parseMinutes(await _kids.setting(bedtimeEndKey(kidId)));
    if (start == null || end == null || start == end) return false;
    final t = now.hour * 60 + now.minute;
    // A window that crosses midnight (start > end) wraps around.
    return start < end ? t >= start && t < end : t >= start || t < end;
  }

  static int? _parseMinutes(String? hhmm) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm ?? '');
    if (m == null) return null;
    final h = int.parse(m[1]!);
    final min = int.parse(m[2]!);
    if (h > 23 || min > 59) return null;
    return h * 60 + min;
  }
}

/// Overridable in tests to fake the time of day.
final screenTimeClockProvider = Provider<Clock>((ref) => DateTime.now);

final screenTimeServiceProvider = Provider<ScreenTimeService>(
  (ref) => ScreenTimeService(
    ref.watch(databaseProvider),
    ref.watch(kidRepositoryProvider),
    now: ref.watch(screenTimeClockProvider),
  ),
);

/// Status of the current kid; `ok` when there is no kid yet. Refresh it to
/// re-read after usage or settings change.
final screenTimeStatusProvider = FutureProvider<ScreenTimeStatus>((ref) async {
  final kid = await ref.watch(currentKidIdProvider.future);
  if (kid == null) return ScreenTimeStatus.ok;
  return ref.watch(screenTimeServiceProvider).status(kid);
});
