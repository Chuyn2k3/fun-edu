import 'package:drift/drift.dart';

/// Seconds a kid spent in the app on one calendar day.
class DailyUsage extends Table {
  IntColumn get kidId => integer()();

  /// Local date as `yyyy-MM-dd`.
  TextColumn get day => text()();
  IntColumn get seconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {kidId, day};
}
