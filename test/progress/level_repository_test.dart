import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/explore/explore_flags.dart';
import 'package:funedu/explore/explore_island.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/theme/tokens.dart';

/// A stand-in second island with nine levels.
final _bio = ExploreIsland(
    id: 'sinh-hoc',
    prefix: 'bio',
    name: 'Sinh học',
    mapTitle: 'Khám phá sự sống',
    subject: Subject.sinhHoc,
    islandImage: '',
    levels: geographyIsland.levels,
    ready: false);

void main() {
  late AppDatabase db;
  late LevelRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LevelRepository(db, kidId: 1, now: () => DateTime(2026, 11, 12));
  });
  tearDown(() => db.close());

  test('empty database is not placed', () async {
    expect(await repo.isPlaced(), isFalse);
    expect(await repo.levelOf('toan'), isNull);
  });

  test('placed once both subjects are set', () async {
    await repo.setLevel('viet', 1);
    expect(await repo.isPlaced(), isFalse);
    await repo.setLevel('toan', 2);
    expect(await repo.isPlaced(), isTrue);
    expect(await repo.levelOf('toan'), 2);
  });

  test('setLevel overwrites', () async {
    await repo.setLevel('toan', 2);
    await repo.setLevel('toan', 4);
    expect(await repo.levelOf('toan'), 4);
  });

  test('recordMathSession moves level and persists', () async {
    await repo.setLevel('toan', 2);
    expect(await repo.recordMathSession(firstTryCorrect: 5, total: 5), 3);
    expect(await repo.levelOf('toan'), 3);
  });

  test('recordMathSession defaults to level 0', () async {
    expect(await repo.recordMathSession(firstTryCorrect: 0, total: 5), 0);
    expect(await repo.levelOf('toan'), 0);
  });
  test('recordGeographySession moves the dia-ly level by the level rule',
      () async {
    expect(
        await repo.recordGeographySession(firstTryCorrect: 5, total: 5), 1);
    expect(await repo.levelOf('dia-ly'), 1);
    expect(
        await repo.recordGeographySession(firstTryCorrect: 3, total: 5), 1);
    expect(await repo.levelOf('dia-ly'), 1);
  });

  for (final (stored, shown) in [(12, 8), (-3, 0)]) {
    test('geographyLevelIndexProvider clamps $stored to $shown', () async {
      final kid = await KidRepository(db)
          .addKid(nickname: 'Na', avatar: 'a', age: 5);
      await LevelRepository(db, kidId: kid).setLevel('dia-ly', stored);
      final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      addTearDown(container.dispose);
      expect(await container.read(geographyLevelIndexProvider.future), shown);
    });
  }

  test('recordExploreSession moves the island level like geography', () async {
    await repo.setLevel('dia-ly', 4);
    expect(
        await repo.recordExploreSession(geographyIsland,
            firstTryCorrect: 5, total: 5),
        5);
    expect(await repo.levelOf('dia-ly'), 5);
  });

  test('another island writes its own key only', () async {
    const thu = ExploreIsland(
        id: 'thu',
        prefix: 'geo',
        name: 'Thử',
        mapTitle: 'Thử',
        subject: Subject.diaLy,
        islandImage: '',
        levels: [],
        ready: true);
    final island = ExploreIsland(
        id: thu.id,
        prefix: thu.prefix,
        name: thu.name,
        mapTitle: thu.mapTitle,
        subject: thu.subject,
        islandImage: thu.islandImage,
        levels: geographyIsland.levels,
        ready: true);
    await repo.setLevel('dia-ly', 2);
    await repo.recordExploreSession(island, firstTryCorrect: 5, total: 5);
    expect(await repo.levelOf('thu'), 1);
    expect(await repo.levelOf('dia-ly'), 2);
  });

  Future<ProviderContainer> container(List<Override> extra) async {
    final kid = await KidRepository(db)
        .addKid(nickname: 'Na', avatar: 'a', age: 5);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      exploreIslandEnabledProvider.overrideWithValue(true),
      ...extra,
    ]);
    addTearDown(c.dispose);
    await LevelRepository(db, kidId: kid).setLevel('dia-ly', 3);
    await LevelRepository(db, kidId: kid).setLevel('sinh-hoc', 1);
    return c;
  }

  for (final (stored, shown) in [(12, 8), (-1, 0)]) {
    test('exploreLevelIndexProvider clamps sinh-hoc $stored to $shown',
        () async {
      final c = await container([
        exploreIslandsProvider.overrideWithValue([geographyIsland, _bio]),
      ]);
      final kid = (await KidRepository(db).kids()).single.id;
      await LevelRepository(db, kidId: kid).setLevel('sinh-hoc', stored);
      expect(await c.read(exploreLevelIndexProvider('sinh-hoc').future),
          shown);
    });
  }

  test('home total counts ready islands only', () async {
    final c = await container(const []);
    final s = await c.read(homeSummaryProvider.future);
    expect((s.exploreDone, s.exploreTotal), (4, 9));
  });

  test('home total adds a second ready island', () async {
    final c = await container([
      exploreReadyProvider.overrideWith((ref, id) => true),
      exploreIslandsProvider.overrideWithValue([geographyIsland, _bio]),
    ]);
    final s = await c.read(homeSummaryProvider.future);
    expect((s.exploreDone, s.exploreTotal), (6, 18));
  });
}
