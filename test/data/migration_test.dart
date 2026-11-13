import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/assets.dart';

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
            kidId: 1,
            completedAt: DateTime(2026, 11, 11),
            starsEarned: 5,
          ),
        );
    expect(await db.select(db.lessonCompletions).get(), hasLength(1));
    expect(await db.summary(1, 'so-1'), (total: 1, ok: 1));
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
            kidId: 1,
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
            kidId: 1,
            subject: 'viet',
            levelIndex: 0,
            placedAt: DateTime(2026, 11, 12),
          ),
        );
    expect(await db.select(db.subjectLevels).get(), hasLength(1));
    expect(await db.select(db.lessonCompletions).get(), isEmpty);
  });

  const v3Tables = '''
CREATE TABLE glyph_progress (
  glyph_id TEXT NOT NULL,
  completions INTEGER NOT NULL DEFAULT 0,
  clean_completions INTEGER NOT NULL DEFAULT 0,
  last_practiced_at INTEGER NOT NULL,
  PRIMARY KEY (glyph_id)
);
CREATE TABLE lesson_completions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  completed_at INTEGER NOT NULL,
  stars_earned INTEGER NOT NULL
);
CREATE TABLE subject_levels (
  subject TEXT NOT NULL,
  level_index INTEGER NOT NULL,
  placed_at INTEGER NOT NULL,
  PRIMARY KEY (subject)
)''';

  test('upgrading from v3 gives old progress to a default kid', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(v2Tables);
          for (final stmt in v3Tables.split(';')) {
            raw.execute(stmt);
          }
          raw.execute(
            "INSERT INTO stroke_attempts (glyph_id, stroke_index, ok, deviation, created_at) VALUES ('so-1', 0, 1, 0.1, 1700000000)",
          );
          raw.execute(
            "INSERT INTO glyph_progress VALUES ('so-1', 2, 1, 1700000000)",
          );
          raw.execute(
            'INSERT INTO lesson_completions (completed_at, stars_earned) VALUES (1700000000, 7)',
          );
          raw.execute(
            "INSERT INTO subject_levels VALUES ('toan', 3, 1700000000)",
          );
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(db.close);

    final repo = KidRepository(db);
    final kid = (await repo.kids()).single;
    expect((kid.nickname, kid.avatar, kid.age), ('Bé', AppImages.chipMain, 5));
    expect(await repo.currentKidId(), kid.id);
    expect(await ProgressRepository(db, kidId: kid.id).totalStars(), 7);
    expect(
      (await ProgressRepository(db, kidId: kid.id).glyphStats())['so-1']
          ?.completions,
      2,
    );
    expect(await LevelRepository(db, kidId: kid.id).levelOf('toan'), 3);
    expect(await db.summary(kid.id, 'so-1'), (total: 1, ok: 1));
    // Composite primary keys now allow another kid to own the same rows.
    await LevelRepository(db, kidId: kid.id + 1).setLevel('toan', 1);
    expect(await db.select(db.subjectLevels).get(), hasLength(2));
  });

  test('upgrading an empty v3 database creates no kid', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(v2Tables);
          for (final stmt in v3Tables.split(';')) {
            raw.execute(stmt);
          }
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(db.close);
    expect(await KidRepository(db).kids(), isEmpty);
    expect(await KidRepository(db).currentKidId(), isNull);
  });

  test('upgrading from v1 reaches v4 and keeps attempts under a kid', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(v2Tables);
          raw.execute(
            "INSERT INTO stroke_attempts (glyph_id, stroke_index, ok, deviation, created_at) VALUES ('so-1', 0, 1, 0.1, 1700000000)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);
    final kid = (await KidRepository(db).kids()).single;
    expect(await db.summary(kid.id, 'so-1'), (total: 1, ok: 1));
    await ProgressRepository(db, kidId: kid.id)
        .recordLessonCompleted(itemsCompleted: 1);
    expect(await ProgressRepository(db, kidId: kid.id).totalStars(), 3);
  });

  test('upgrading from v4 adds daily_usage and keeps the kids', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE kid_profiles (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'nickname TEXT NOT NULL, avatar TEXT NOT NULL, age INTEGER NOT NULL, '
            'created_at INTEGER NOT NULL)',
          );
          raw.execute(
            "INSERT INTO kid_profiles (nickname, avatar, age, created_at) VALUES ('Na', 'a', 5, 1700000000)",
          );
          raw.execute('PRAGMA user_version = 4');
        },
      ),
    );
    addTearDown(db.close);
    await db.into(db.dailyUsage).insert(
          DailyUsageCompanion.insert(kidId: 1, day: '2026-11-13'),
        );
    expect(await db.select(db.dailyUsage).get(), hasLength(1));
    expect(await KidRepository(db).kids(), hasLength(1));
  });

  test('upgrading from v5 adds real_rewards', () async {
    final db = AppDatabase(
      NativeDatabase.memory(setup: (raw) => raw.execute('PRAGMA user_version = 5')),
    );
    addTearDown(db.close);
    await db.into(db.realRewards).insert(
          RealRewardsCompanion.insert(
            kidId: 1,
            title: 'Đi công viên',
            starsNeeded: 10,
            createdAt: DateTime(2026, 11, 13),
          ),
        );
    expect(await db.select(db.realRewards).get(), hasLength(1));
  });
}
