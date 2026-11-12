import 'package:drift/drift.dart';

/// Per-glyph practice counters.
class GlyphProgress extends Table {
  TextColumn get glyphId => text()();
  IntColumn get completions => integer().withDefault(const Constant(0))();

  /// Completions with at most one failed stroke.
  IntColumn get cleanCompletions => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPracticedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {glyphId};
}

/// One row per finished lesson; also the source of "learned days".
class LessonCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get starsEarned => integer()();
}
