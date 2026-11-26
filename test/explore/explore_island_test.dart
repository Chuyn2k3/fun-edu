import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/explore/explore_island.dart';
import 'package:funedu/explore/geography_level.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/tokens.dart';

void main() {
  test('geography is the first island, unchanged', () {
    expect(geographyIsland.id, 'dia-ly');
    expect(geographyIsland.prefix, 'geo');
    expect(geographyIsland.name, 'Địa lý');
    expect(geographyIsland.mapTitle, 'Khám phá Việt Nam');
    expect(geographyIsland.subject, Subject.diaLy);
    expect(geographyIsland.ready, isTrue);
    expect(geographyIsland.levels, same(geographyLevels));
    expect(exploreIslands.first, same(geographyIsland));
  });

  test('islands by id', () {
    expect(exploreIslandById('dia-ly'), same(geographyIsland));
    expect(exploreIslandById('x'), isNull);
  });

  test('geography pictures keep their paths', () {
    for (final l in geographyLevels) {
      for (final i in l.items) {
        expect(i.prefix, 'geo');
        expect(i.image, AppImages.geography[i.id]);
      }
    }
  });
}
