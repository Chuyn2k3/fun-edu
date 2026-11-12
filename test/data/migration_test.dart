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

  const v2Tables = '''
CREATE TABLE stroke_attempts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  glyph_id TEXT NOT NULL,
  stroke_index INTEGER NOT NULL,
  ok INTEGER NOT NULL CHECK (ok IN (0, 1)),
  error TEXT NULL,
  deviation REAL NOT NULL,
  created_at INTEGER NOT NULL,
  points TEXT NULL
)''';

  test('upgrading from v2 keeps lessons and adds subject_levels', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(v2Tables);
          raw.execute('''
CREATE TABLE glyph_progress (
  glyph_id TEXT NOT NULL,
  completions INTEGER NOT NULL DEFAULT 0,
  clean_completions INTEGER NOT NULL DEFAULT 0,
  last_practiced_at INTEGER NOT NULL,
  PRIMARY KEY (glyph_id)
)''');
          raw.execute('''
CREATE TABLE lesson_completions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  completed_at INTEGER NOT NULL,
  stars_earned INTEGER NOT NULL
)''');
          raw.execute(
            'INSERT INTO lesson_completions (completed_at, stars_earned) VALUES (1700000000, 7)',
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);

    final lessons = await db.select(db.lessonCompletions).get();
    expect(lessons, hasLength(1));
    expect(lessons.single.starsEarned, 7);
    await db.into(db.subjectLevels).insert(
          SubjectLevelsCompanion.insert(
            subject: 'toan',
            levelIndex: 3,
            placedAt: DateTime(2026, 11, 12),
          ),
        );
    expect(await db.select(db.subjectLevels).get(), hasLength(1));
  });

  test('upgrading from v1 reaches v3 with subject_levels', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(v2Tables);
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);
    await db.into(db.subjectLevels).insert(
          SubjectLevelsCompanion.insert(
            subject: 'viet',
            levelIndex: 0,
            placedAt: DateTime(2026, 11, 12),
          ),
        );
    expect(await db.select(db.subjectLevels).get(), hasLength(1));
    expect(await db.select(db.lessonCompletions).get(), isEmpty);
  });
}
