import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/learning/lesson_composer.dart';
import 'package:funedu/learning/today_lesson_provider.dart';
import 'package:funedu/learning/writing_ladder.dart';
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

  test('todayLessonProvider yields first 3 ladder ids for a new child',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      glyphRepositoryProvider.overrideWithValue(_FakeGlyphRepository()),
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    expect(
      await container.read(todayLessonProvider.future),
      writingLadder.take(3).toList(),
    );
  });
}
