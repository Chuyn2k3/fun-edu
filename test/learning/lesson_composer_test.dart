import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/learning/lesson_composer.dart';
import 'package:funedu/learning/lesson_item.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/learning/writing_ladder.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/stroke/glyph_repository.dart';

const ladder = ['a', 'b', 'c', 'd', 'e', 'f'];
final all = ladder.toSet();
GlyphStat clean([int n = 1]) => GlyphStat(completions: n, cleanCompletions: n);
GlyphStat sloppy(int misses) =>
    GlyphStat(completions: misses + 1, cleanCompletions: 1);

List<String> compose(Map<String, GlyphStat> stats, [Set<String>? avail]) =>
    composeTodayLesson(ladder: ladder, stats: stats, available: avail ?? all);

class _FakeGlyphRepository extends GlyphRepository {
  @override
  Future<List<String>> listIds() async => writingLadder.toList()..sort();
}

void main() {
  test('new child gets the first three', () {
    expect(compose({}), ['a', 'b', 'c']);
  });

  test('two mastered: next two new plus a review', () {
    expect(compose({'a': clean(), 'b': clean()}), ['c', 'd', 'a']);
  });

  test('review is the most-missed mastered glyph', () {
    expect(compose({'a': clean(), 'b': sloppy(3)}), ['c', 'd', 'b']);
  });

  test('review ties go to the earlier glyph', () {
    expect(compose({'a': sloppy(2), 'b': sloppy(2)}), ['c', 'd', 'a']);
  });

  test('all mastered gives three distinct review glyphs', () {
    final r = compose({for (final id in ladder) id: clean()});
    expect(r.length, 3);
    expect(r.toSet().length, 3);
  });

  test('one left unmastered: one new plus two reviews', () {
    final r = compose({
      for (final id in ladder.take(5)) id: clean(),
    });
    expect(r.first, 'f');
    expect(r.toSet().length, 3);
  });

  test('limited availability', () {
    expect(compose({}, {'a', 'b'}), ['a', 'b']);
    expect(compose({}, {}), isEmpty);
  });

  test('never returns ids outside available', () {
    final avail = {'b', 'd', 'x'};
    final r = compose({'b': clean()}, avail);
    expect(avail.containsAll(r), isTrue);
    expect(r, ['d', 'b']);
  });

  List<LessonItem> items({
    Map<String, GlyphStat> stats = const {},
    Set<String>? avail,
    int start = 0,
    int math = 0,
    List<String>? lad,
  }) =>
      composeTodayLessonItems(
        ladder: lad ?? writingLadder,
        stats: stats,
        available: avail ?? writingLadder.toSet(),
        writingStartIndex: start,
        mathLevelIndex: math,
      );

  test('new child: writing, math, writing', () {
    expect(items(), const [
      WritingItem('net-ngang'),
      MathItem(0),
      WritingItem('net-thang-dung'),
    ]);
  });

  test('one mastered glyph: new glyph, math, then review of the mastered one',
      () {
    expect(items(stats: {'net-ngang': clean()}, math: 2), const [
      WritingItem('net-thang-dung'),
      MathItem(2),
      WritingItem('net-ngang'),
    ]);
  });

  test('writingStartIndex 5: earlier glyphs are learned, review the earliest',
      () {
    expect(items(start: 5, math: 2), const [
      WritingItem('so-0'),
      MathItem(2),
      WritingItem('net-ngang'),
    ]);
  });

  test('no glyphs available: math only', () {
    expect(items(avail: {}, math: 3), const [MathItem(3)]);
  });

  test('one glyph: writing then math', () {
    expect(items(avail: {'net-ngang'}), const [
      WritingItem('net-ngang'),
      MathItem(0),
    ]);
  });

  test('real stats are kept for skipped glyphs', () {
    // net-ngang is skipped but has real stats; so-0 start still comes first.
    expect(
      items(start: 5, stats: {'net-ngang': sloppy(2)}).first,
      const WritingItem('so-0'),
    );
  });

  test('todayLessonProvider yields writing, math, writing for a new child',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      glyphRepositoryProvider.overrideWithValue(_FakeGlyphRepository()),
      databaseProvider.overrideWithValue(db),
      currentKidIdProvider.overrideWith((ref) async => 1),
    ]);
    addTearDown(container.dispose);
    expect(await container.read(todayLessonProvider.future), const [
      WritingItem('net-ngang'),
      MathItem(0),
      WritingItem('net-thang-dung'),
    ]);
  });

  test('todayLessonProvider uses stored levels', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      glyphRepositoryProvider.overrideWithValue(_FakeGlyphRepository()),
      databaseProvider.overrideWithValue(db),
      currentKidIdProvider.overrideWith((ref) async => 1),
    ]);
    addTearDown(container.dispose);
    final levels = await container.read(levelRepositoryProvider.future);
    await levels.setLevel('viet', 5);
    await levels.setLevel('toan', 1);
    expect(await container.read(todayLessonProvider.future), const [
      WritingItem('so-0'),
      MathItem(1),
      WritingItem('net-ngang'),
    ]);
  });
}
