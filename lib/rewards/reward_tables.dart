import 'package:drift/drift.dart';

/// A real-life reward a parent promises a kid once they have enough stars.
/// Redeeming only sets [redeemedAt]; stars are never spent.
class RealRewards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kidId => integer()();
  TextColumn get title => text().withLength(min: 1, max: 60)();
  IntColumn get starsNeeded => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get redeemedAt => dateTime().nullable()();
}
