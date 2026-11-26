import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/explore/biology_level.dart';
import 'package:funedu/explore/explore_island.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/ui/assets.dart';

const _forbidden = ['ăn thịt', 'săn', 'chết', 'máu'];

void _copy(String text, String name, String where) {
  expect(text.trim(), isNotEmpty, reason: where);
  expect(text.trim().split(RegExp(r'\s+')).length, lessThanOrEqualTo(15),
      reason: where);
  expect(RegExp(r'\d').hasMatch(text), isFalse, reason: where);
  expect(text.toLowerCase(), isNot(contains(name.toLowerCase())),
      reason: where);
  for (final w in _forbidden) {
    expect(text.toLowerCase(), isNot(contains(w)), reason: '$where: $w');
  }
}

void main() {
  test('nine biology levels in spec order, pairs at 5 and 6', () {
    expect(biologyLevels.map((l) => l.id), [
      'vat-nuoi',
      'trong-rung',
      'duoi-nuoc',
      'bau-troi',
      'an-gi',
      'lon-len',
      'cay-hoa',
      'rau-qua',
      'co-the',
    ]);
    for (var i = 0; i < 9; i++) {
      final l = biologyLevels[i];
      if (i == 4 || i == 5) {
        expect(l.pairs.length, 5, reason: l.id);
      } else {
        expect(l.pairs, isEmpty, reason: l.id);
        expect(l.items.length, greaterThanOrEqualTo(5), reason: l.id);
      }
    }
    expect(biologyLevels.map((l) => l.clues),
        [false, false, false, true, false, false, true, true, true]);
  });

  test('every picture exists and every line follows the rules', () {
    for (final l in biologyLevels) {
      for (final i in l.items) {
        expect(i.prefix, 'bio');
        expect(AppImages.exploreArt.keys, contains('bio-${i.id}'));
        _copy(i.fact, i.name, '${i.id} fact');
        _copy(i.clue, i.name, '${i.id} clue');
      }
      for (final p in l.pairs) {
        for (final g in [p.ask, p.answer]) {
          expect(g.prefix, 'bio');
          expect(AppImages.exploreArt.keys, contains('bio-${g.id}'));
        }
        _copy(p.fact, p.answer.name, '${p.id} fact');
        expect(p.question.trim(), isNotEmpty);
        final answers = {for (final o in l.pairs) o.answer.id};
        for (final id in p.alsoRight) {
          expect(answers, contains(id), reason: '${p.id} alsoRight $id');
        }
        final wrong = l.pairs.where((o) =>
            o.answer.id != p.answer.id && !p.alsoRight.contains(o.answer.id));
        expect(wrong.length, greaterThanOrEqualTo(2), reason: p.id);
      }
    }
  });

  test('a rabbit is never told grass is wrong, nor a cow carrots', () {
    final eat = biologyLevels[4].pairs;
    expect(eat.singleWhere((p) => p.ask.id == 'tho').alsoRight,
        contains('bo-co'));
    expect(eat.singleWhere((p) => p.ask.id == 'bo').alsoRight,
        contains('ca-rot'));
  });

  test('biology island waits for approval', () {
    expect(biologyIsland.id, 'sinh-hoc');
    expect(biologyIsland.prefix, 'bio');
    expect(biologyIsland.mapTitle, 'Khám phá sự sống');
    expect(biologyIsland.ready, isFalse);
    expect(exploreIslands.map((i) => i.id), ['dia-ly', 'sinh-hoc']);
  });

  test('shared pictures are the same item', () {
    GeoItem? find(String id) {
      for (final l in biologyLevels) {
        for (final i in l.items) {
          if (i.id == id) return i;
        }
        for (final p in l.pairs) {
          if (p.ask.id == id) return p.ask;
          if (p.answer.id == id) return p.answer;
        }
      }
      return null;
    }

    for (final id in ['ca-rot', 'buom', 'ong', 'khi', 'meo', 'hoa', 'hat', 'bo']) {
      expect(find(id), isNotNull, reason: id);
    }
  });
}
