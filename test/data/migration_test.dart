import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';

void main() {
  test('upgrading from v1 keeps attempts and adds progress tables', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
CREATE TABLE stroke_attempts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  glyph_id TEXT NOT NULL,
  stroke_index INTEGER NOT NULL,
  ok INTEGER NOT NULL CHECK (ok IN (0, 1)),
  error TEXT NULL,
  deviation REAL NOT NULL,
  created_at INTEGER NOT NULL,
  points TEXT NULL
)''');
          raw.execute(
            "INSERT INTO stroke_attempts (glyph_id, stroke_index, ok, deviation, created_at) VALUES ('so-1', 0, 1, 0.1, 1700000000)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);

    await db.into(db.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
            completedAt: DateTime(2026, 11, 11),
            starsEarned: 5,
          ),
        );
    expect(await db.select(db.lessonCompletions).get(), hasLength(1));
    expect(await db.summary('so-1'), (total: 1, ok: 1));
  });
}
