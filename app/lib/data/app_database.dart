import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// One graded stroke, logged so false rejections can be counted later.
class StrokeAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get glyphId => text()();
  IntColumn get strokeIndex => integer()();
  BoolColumn get ok => boolean()();
  TextColumn get error => text().nullable()();
  RealColumn get deviation => real()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [StrokeAttempts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<void> logAttempt({
    required String glyphId,
    required int strokeIndex,
    required bool ok,
    required String? error,
    required double deviation,
  }) async {
    await into(strokeAttempts).insert(
      StrokeAttemptsCompanion.insert(
        glyphId: glyphId,
        strokeIndex: strokeIndex,
        ok: ok,
        error: Value(error),
        deviation: deviation,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<({int total, int ok})> summary(String glyphId) async {
    final rows = await (select(strokeAttempts)
          ..where((t) => t.glyphId.equals(glyphId)))
        .get();
    return (total: rows.length, ok: rows.where((r) => r.ok).length);
  }
}

/// Opened lazily, so screens that never read it never touch the database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'funedu'));
  ref.onDispose(db.close);
  return db;
});
