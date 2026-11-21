import 'package:drift/drift.dart';

/// One child profile; up to four per device.
class KidProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nickname => text().withLength(min: 1, max: 20)();
  TextColumn get avatar => text()();
  IntColumn get age => integer()();
  DateTimeColumn get createdAt => dateTime()();

  /// Stable id across devices for online sync (v8). Set for every kid; null
  /// only in the instant between the v8 column add and its backfill.
  TextColumn get uuid => text().nullable()();
}

/// Plain key/value store for app-wide settings (current kid, voice, ...).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
