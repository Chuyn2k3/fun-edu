import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/auth/token_store.dart';
import 'package:funedu/online/device_id.dart';

void main() {
  test('device id is created once and matches UUID v4', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final id1 = await ensureDeviceId(db);
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
          .hasMatch(id1),
      isTrue,
    );

    final id2 = await ensureDeviceId(db);
    expect(id2, equals(id1));
  });

  test('session read from old json is unlinked', () {
    final oldJson = {
      'accessToken': 'a1',
      'refreshToken': 'r1',
      'familyId': 'fam-1',
      'provider': 'google',
      'email': 'test@x.vn',
    };
    final session = StoredSession.fromJson(oldJson);
    expect(session, isNotNull);
    expect(session!.linked, isFalse);
  });
}
