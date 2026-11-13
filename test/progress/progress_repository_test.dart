import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/progress/progress_repository.dart';

void main() {
  late AppDatabase db;
  late DateTime clock;
  late ProgressRepository repo;

  setUp(() {
    // 2026-11-11 is a Wednesday.
    clock = DateTime(2026, 11, 11, 10);
    db = AppDatabase(NativeDatabase.memory());
    repo = ProgressRepository(db, kidId: 1, now: () => clock);
  });
  tearDown(() => db.close());

  test('glyph completions count clean ones separately', () async {
    await repo.recordGlyphCompleted('so-1', failedStrokes: 3);
    var stat = (await repo.glyphStats())['so-1']!;
    expect(stat.completions, 1);
    expect(stat.mastered, isFalse);
    await repo.recordGlyphCompleted('so-1', failedStrokes: 0);
    stat = (await repo.glyphStats())['so-1']!;
    expect(stat.completions, 2);
    expect(stat.cleanCompletions, 1);
    expect(stat.mastered, isTrue);
  });

  test('one failed stroke still counts as clean', () async {
    await repo.recordGlyphCompleted('so-2', failedStrokes: 1);
    expect((await repo.glyphStats())['so-2']!.cleanCompletions, 1);
  });

  test('lesson stars are glyphs plus a 2-star bonus', () async {
    expect(await repo.totalStars(), 0);
    expect(await repo.recordLessonCompleted(itemsCompleted: 3), 5);
    expect(await repo.recordLessonCompleted(itemsCompleted: 3), 5);
    expect(await repo.totalStars(), 10);
  });

  test('learned weekdays split at local midnight', () async {
    clock = DateTime(2026, 11, 11, 23, 59);
    await repo.recordLessonCompleted(itemsCompleted: 1);
    clock = DateTime(2026, 11, 12, 0, 1);
    await repo.recordLessonCompleted(itemsCompleted: 1);
    expect(await repo.learnedWeekdaysThisWeek(), {3, 4});
  });

  test('week resets on Monday; Sunday belongs to the ending week', () async {
    clock = DateTime(2026, 11, 15, 12); // Sunday
    await repo.recordLessonCompleted(itemsCompleted: 1);
    expect(await repo.learnedWeekdaysThisWeek(), {7});
    clock = DateTime(2026, 11, 16, 0, 0); // next Monday
    expect(await repo.learnedWeekdaysThisWeek(), isEmpty);
    await repo.recordLessonCompleted(itemsCompleted: 1);
    expect(await repo.learnedWeekdaysThisWeek(), {1});
  });

  test('lessonsCompletedToday counts only today', () async {
    clock = DateTime(2026, 11, 12, 23, 59);
    await repo.recordLessonCompleted(itemsCompleted: 3);
    clock = DateTime(2026, 11, 13, 8);
    expect(await repo.lessonsCompletedToday(), 0);
    await repo.recordLessonCompleted(itemsCompleted: 3);
    await repo.recordLessonCompleted(itemsCompleted: 3);
    expect(await repo.lessonsCompletedToday(), 2);
  });
}
