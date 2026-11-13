import 'package:drift/drift.dart';

/// Per-glyph practice counters.
class GlyphProgress extends Table {
  IntColumn get kidId => integer()();
  TextColumn get glyphId => text()();
  IntColumn get completions => integer().withDefault(const Constant(0))();

  /// Completions with at most one failed stroke.
  IntColumn get cleanCompletions => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPracticedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kidId, glyphId};
}

/// One row per finished lesson; also the source of "learned days".
class LessonCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kidId => integer()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get starsEarned => integer()();
}

/// Current level index per kid and subject ('viet' or 'toan'); a row exists once the
/// subject has been placed.
class SubjectLevels extends Table {
  IntColumn get kidId => integer()();
  TextColumn get subject => text()();
  IntColumn get levelIndex => integer()();
  DateTimeColumn get placedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kidId, subject};
}
