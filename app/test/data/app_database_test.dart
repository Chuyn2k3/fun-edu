import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';

void main() {
  test('summary counts total and ok attempts per glyph', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    Future<void> log(bool ok, String glyph) => db.logAttempt(
      glyphId: glyph,
      strokeIndex: 0,
      ok: ok,
      error: ok ? null : 'offPath',
      deviation: 0.1,
    );
    await log(true, 'net-ngang');
    await log(false, 'net-ngang');
    await log(true, 'net-ngang');
    await log(true, 'net-thang-dung');
    expect(await db.summary('net-ngang'), (total: 3, ok: 2));
    expect(await db.summary('khac'), (total: 0, ok: 0));
  });
}
