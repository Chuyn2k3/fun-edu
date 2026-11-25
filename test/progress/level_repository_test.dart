import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';

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
}
