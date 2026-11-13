import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/kid_tables.dart';
import '../progress/progress_tables.dart';
import '../rewards/reward_tables.dart';
import '../screen_time/screen_time_tables.dart';
import '../stroke/glyph.dart';
import '../ui/assets.dart';

part 'app_database.g.dart';

/// One graded stroke, logged so false rejections can be counted later.
class StrokeAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kidId => integer()();
  TextColumn get glyphId => text()();
  IntColumn get strokeIndex => integer()();
  BoolColumn get ok => boolean()();
  TextColumn get error => text().nullable()();
  RealColumn get deviation => real()();

  /// JSON array of [x, y] pairs (4 decimals) of the drawn stroke, so a false
  /// rejection can be replayed in a test.
  TextColumn get points => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    StrokeAttempts,
    GlyphProgress,
    LessonCompletions,
    SubjectLevels,
    KidProfiles,
    AppSettings,
    DailyUsage,
    RealRewards,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(glyphProgress);
            await m.createTable(lessonCompletions);
          }
          if (from < 3) {
            await m.createTable(subjectLevels);
          }
          if (from < 4) await _upgradeToV4(m, from);
          if (from < 5) await m.createTable(dailyUsage);
          if (from < 6) await m.createTable(realRewards);
        },
      );

  /// v3 -> v4: adds kid profiles and scopes every progress table by kid.
  ///
  /// SQLite cannot change a primary key in place, so each legacy table is
  /// renamed, recreated in its v4 shape, refilled with the old rows tagged
  /// with the default kid, and the old copy dropped. Tables that did not
  /// exist before this upgrade (created earlier in the same run from the v4
  /// definitions) are already in the new shape and are left alone.
  Future<void> _upgradeToV4(Migrator m, int from) => transaction(() async {
        await m.createTable(kidProfiles);
        await m.createTable(appSettings);

        // [table, plain columns to carry over, first version that had it]
        final legacy = <(TableInfo, String, String, int)>[
          (
            strokeAttempts,
            'stroke_attempts',
            'id, glyph_id, stroke_index, ok, error, deviation, points, created_at',
            1
          ),
          (
            glyphProgress,
            'glyph_progress',
            'glyph_id, completions, clean_completions, last_practiced_at',
            2
          ),
          (
            lessonCompletions,
            'lesson_completions',
            'id, completed_at, stars_earned',
            2
          ),
          (
            subjectLevels,
            'subject_levels',
            'subject, level_index, placed_at',
            3
          ),
        ].where((t) => from >= t.$4).toList();

        var hasData = false;
        for (final t in legacy) {
          final rows = await customSelect('SELECT COUNT(*) AS c FROM ${t.$2}')
              .getSingle();
          if (rows.read<int>('c') > 0) hasData = true;
        }

        var kidId = 0;
        if (hasData) {
          kidId = await into(kidProfiles).insert(
            KidProfilesCompanion.insert(
              nickname: 'Bé',
              avatar: AppImages.chipMain,
              age: 5,
              createdAt: DateTime.now(),
            ),
          );
          await into(appSettings).insert(
            AppSettingsCompanion.insert(key: 'currentKidId', value: '$kidId'),
          );
        }

        for (final t in legacy) {
          await customStatement('ALTER TABLE ${t.$2} RENAME TO ${t.$2}_old');
          await m.createTable(t.$1);
          await customStatement(
            'INSERT INTO ${t.$2} (${t.$3}, kid_id) '
            'SELECT ${t.$3}, $kidId FROM ${t.$2}_old',
          );
          await customStatement('DROP TABLE ${t.$2}_old');
        }
      });

  Future<void> logAttempt({
    required int kidId,
    required String glyphId,
    required int strokeIndex,
    required bool ok,
    required String? error,
    required double deviation,
    Stroke? drawn,
  }) async {
    await into(strokeAttempts).insert(
      StrokeAttemptsCompanion.insert(
        kidId: kidId,
        glyphId: glyphId,
        strokeIndex: strokeIndex,
        ok: ok,
        error: Value(error),
        deviation: deviation,
        points: Value(drawn == null ? null : encodePoints(drawn)),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<StrokeAttempt>> attemptsFor(int kidId, String glyphId) =>
      (select(strokeAttempts)
            ..where((t) => t.kidId.equals(kidId) & t.glyphId.equals(glyphId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<({int total, int ok})> summary(int kidId, String glyphId) async {
    final rows = await (select(
      strokeAttempts,
    )..where((t) => t.kidId.equals(kidId) & t.glyphId.equals(glyphId)))
        .get();
    return (total: rows.length, ok: rows.where((r) => r.ok).length);
  }
}

/// Encodes a stroke as a JSON array of [x, y] pairs rounded to 4 decimals.
String encodePoints(Stroke s) => jsonEncode([
      for (final p in s.points)
        [
          double.parse(p.x.toStringAsFixed(4)),
          double.parse(p.y.toStringAsFixed(4)),
        ],
    ]);

/// Opened lazily, so screens that never read it never touch the database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'funedu'));
  ref.onDispose(db.close);
  return db;
});
