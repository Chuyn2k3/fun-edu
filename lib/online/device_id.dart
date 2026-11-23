import '../data/app_database.dart';
import 'uuid.dart';

const deviceIdKey = 'deviceId';

/// Ensures this device has a unique persistent UUID v4 identifier.
/// Stored in [AppSettings] table, never cleared on sign-out.
Future<String> ensureDeviceId(AppDatabase db) async {
  final row = await (db.select(db.appSettings)
        ..where((t) => t.key.equals(deviceIdKey)))
      .getSingleOrNull();
  if (row != null && row.value.isNotEmpty) {
    return row.value;
  }
  final id = newUuid();
  await db.into(db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: deviceIdKey, value: id),
      );
  return id;
}
