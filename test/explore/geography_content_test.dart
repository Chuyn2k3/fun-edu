import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/ui/assets.dart';

void main() {
  test('nine geography levels in spec order', () {
    expect(geographyLevels.map((l) => l.id), [
      'canh-vat',
      'thoi-tiet',
      'viet-nam',
      'mien-bac',
      'mien-trung',
      'mien-nam',
      'chau-a',
      'chau-au-phi',
      'chau-my-uc',
    ]);
  });

  test('47 items, each with art and complete copy', () {
    final items = [for (final l in geographyLevels) ...l.items];
    expect(items.length, 47);
    expect(items.map((i) => i.id).toSet().length, 47);
    for (final l in geographyLevels) {
      expect(l.items.length, greaterThanOrEqualTo(5), reason: l.id);
    }
    for (final i in items) {
      expect(AppImages.geography.keys, contains(i.id));
      expect(i.image, AppImages.geography[i.id]);
      for (final s in [i.name, i.speech, i.fact, i.clue]) {
        expect(s.trim(), isNotEmpty, reason: i.id);
      }
    }
  });

  test('facts are short, number-free and never name the answer', () {
    for (final l in geographyLevels) {
      for (final i in l.items) {
        expect(i.fact.trim().split(RegExp(r'\s+')).length,
            lessThanOrEqualTo(15),
            reason: i.id);
        expect(RegExp(r'\d').hasMatch(i.fact), isFalse, reason: i.id);
        final name = i.name.toLowerCase();
        expect(i.fact.toLowerCase(), isNot(contains(name)), reason: i.id);
        expect(i.clue.toLowerCase(), isNot(contains(name)), reason: i.id);
        expect(i.fact, isNot(i.clue), reason: i.id);
      }
    }
  });

  test('clue questions start at level 4', () {
    expect(geographyLevels.map((l) => l.clues),
        [false, false, false, true, true, true, true, true, true]);
  });
}
