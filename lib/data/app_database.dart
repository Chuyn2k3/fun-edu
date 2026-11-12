import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/progress_tables.dart';
import '../stroke/glyph.dart';

part 'app_database.g.dart';

/// One graded stroke, logged so false rejections can be counted later.
class StrokeAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
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

@DriftDatabase(tables: [StrokeAttempts, GlyphProgress, LessonCompletions, SubjectLevels])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

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
        },
      );

  Future<void> logAttempt({
    required String glyphId,
    required int strokeIndex,
    required bool ok,
    required String? error,
    required double deviation,
    Stroke? drawn,
  }) async {
    await into(strokeAttempts).insert(
      StrokeAttemptsCompanion.insert(
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

  Future<List<StrokeAttempt>> attemptsFor(String glyphId) =>
      (select(strokeAttempts)
            ..where((t) => t.glyphId.equals(glyphId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<({int total, int ok})> summary(String glyphId) async {
    final rows = await (select(
      strokeAttempts,
    )..where((t) => t.glyphId.equals(glyphId)))
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
