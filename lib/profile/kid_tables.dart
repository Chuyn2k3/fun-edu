import 'package:drift/drift.dart';

/// One child profile; up to four per device.
class KidProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nickname => text().withLength(min: 1, max: 20)();
  TextColumn get avatar => text()();
  IntColumn get age => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Plain key/value store for app-wide settings (current kid, voice, ...).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
