import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/sync/device_counters.dart';

void main() {
  late AppDatabase db;
  late DeviceCounterStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DeviceCounterStore(db, deviceId: 'dev-a');
  });

  tearDown(() => db.close());

  test('add increments only my device row and updates total', () async {
    await store.add('glyph.c:k1:so-1', 2);
    await store.add('glyph.c:k1:so-1', 3);
    expect(await store.total('glyph.c:k1:so-1'), 5);
    expect(await store.byDevice('glyph.c:k1:so-1'), {'dev-a': 5});
  });

  test('a decrease grows a separate row; no row ever shrinks', () async {
    const k = 'counter:k1:online_since_rare';
    await store.add(k, 4);
    await store.add(k, -4);
    expect(await store.total(k), 0);
    expect(await store.byDevice(k), {'dev-a': 4});
    expect(await store.byDevice(DeviceCounterStore.decKey(k)), {'dev-a': 4});
    await store.add(k, 1);
    expect(await store.total(k), 1);
  });

  test('add participates cleanly inside caller transaction', () async {
    await expectLater(
      db.transaction(() async {
        await store.add('usage:k1:2026-11-23', 60);
        throw StateError('abort');
      }),
      throwsStateError,
    );
    expect(await store.total('usage:k1:2026-11-23'), 0);
  });

  test('mergeRemote keeps max per device and adds across devices', () async {
    await store.add('usage:k1:2026-11-23', 100);
    await store.mergeRemote('usage:k1:2026-11-23', {'dev-a': 80, 'dev-b': 250});
    expect(await store.byDevice('usage:k1:2026-11-23'), {
      'dev-a': 100,
      'dev-b': 250,
    });
    expect(await store.total('usage:k1:2026-11-23'), 350);

    // Repeating same remote merge is idempotent
    await store.mergeRemote('usage:k1:2026-11-23', {'dev-a': 80, 'dev-b': 250});
    expect(await store.total('usage:k1:2026-11-23'), 350);
  });

  test('mergeLegacyRemote subtracts known non-legacy counts', () async {
    await store.add('glyph.c:k1:chu-a', 4);
    await store.mergeLegacyRemote('glyph.c:k1:chu-a', 6);
    expect(await store.byDevice('glyph.c:k1:chu-a'), {
      'dev-a': 4,
      'legacy': 2,
    });
    expect(await store.total('glyph.c:k1:chu-a'), 6);

    // If legacy scalar is <= known local, legacy stays 0
    await store.mergeLegacyRemote('glyph.c:k1:chu-a', 3);
    expect(await store.total('glyph.c:k1:chu-a'), 6);
  });
}
