import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/voice/speaker.dart';

import '../voice/fake_speaker.dart';

void main() {
  late AppDatabase db;
  late KidRepository kids;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    kids = KidRepository(db);
  });
  tearDown(() => db.close());

  Future<int> add(String name) =>
      kids.addKid(nickname: name, avatar: kidAvatars.first, age: 5);

  test('kidAvatars lists the eighteen app images', () {
    expect(kidAvatars, hasLength(18));
  });

  test('a fresh install has no kid and no stars', () async {
    expect(await kids.currentKidId(), isNull);
    final progress = ProgressRepository(db, kidId: null);
    expect(await progress.totalStars(), 0);
    expect(await LevelRepository(db, kidId: null).isPlaced(), isFalse);
    expect(
      () => progress.recordLessonCompleted(itemsCompleted: 1),
      throwsStateError,
    );
  });

  test('progress is separate per kid', () async {
    final a = await add('An');
    final b = await add('Bình');
    expect(await kids.currentKidId(), a);

    await ProgressRepository(db, kidId: a)
        .recordLessonCompleted(itemsCompleted: 3);
    final levelsA = LevelRepository(db, kidId: a);
    await levelsA.setLevel('viet', 1);
    await levelsA.setLevel('toan', 2);
    expect(await levelsA.isPlaced(), isTrue);
    expect(await ProgressRepository(db, kidId: a).totalStars(), 5);

    await kids.setCurrentKid(b);
    expect(await kids.currentKidId(), b);
    expect(await ProgressRepository(db, kidId: b).totalStars(), 0);
    expect(await LevelRepository(db, kidId: b).isPlaced(), isFalse);
  });

  test('deleting a kid removes their data and keeps the others', () async {
    final a = await add('An');
    final b = await add('Bình');
    for (final id in [a, b]) {
      final p = ProgressRepository(db, kidId: id);
      await p.recordLessonCompleted(itemsCompleted: 1);
      await p.recordGlyphCompleted('net-ngang', failedStrokes: 0);
      await LevelRepository(db, kidId: id).setLevel('toan', 1);
      await db.logAttempt(
        kidId: id,
        glyphId: 'net-ngang',
        strokeIndex: 0,
        ok: true,
        error: null,
        deviation: 0.1,
      );
    }
    await kids.deleteKid(a);

    expect(await ProgressRepository(db, kidId: a).totalStars(), 0);
    expect(await ProgressRepository(db, kidId: a).glyphStats(), isEmpty);
    expect(await LevelRepository(db, kidId: a).levelOf('toan'), isNull);
    expect(await db.summary(a, 'net-ngang'), (total: 0, ok: 0));
    expect(await ProgressRepository(db, kidId: b).totalStars(), 3);
    expect(await db.summary(b, 'net-ngang'), (total: 1, ok: 1));
    expect((await kids.kids()).map((k) => k.id), [b]);
    expect(await kids.currentKidId(), b);

    await kids.deleteKid(b);
    expect(await kids.currentKidId(), isNull);
  });

  test('a fifth kid is refused', () async {
    for (var i = 0; i < 4; i++) {
      await add('Bé $i');
    }
    expect(() => add('Bé 5'), throwsStateError);
    expect(await kids.kids(), hasLength(4));
  });

  test('updateKid changes only the given fields', () async {
    final a = await add('An');
    await kids.updateKid(a, nickname: 'Anh', age: 6);
    final k = (await kids.kids()).single;
    expect((k.nickname, k.avatar, k.age), ('Anh', kidAvatars.first, 6));
  });

  test('deleteAllData wipes kids, settings and progress', () async {
    final a = await add('An');
    await ProgressRepository(db, kidId: a)
        .recordLessonCompleted(itemsCompleted: 1);
    await LevelRepository(db, kidId: a).setLevel('viet', 1);
    await kids.setSetting('voiceEnabled', 'false');
    await kids.deleteAllData();

    expect(await kids.kids(), isEmpty);
    expect(await kids.currentKidId(), isNull);
    expect(await kids.setting('voiceEnabled'), isNull);
    expect(await db.select(db.lessonCompletions).get(), isEmpty);
    expect(await db.select(db.subjectLevels).get(), isEmpty);
  });

  test('providers follow the current kid after invalidation', () async {
    final a = await add('An');
    final b = await add('Bình');
    await LevelRepository(db, kidId: a).setLevel('viet', 1);
    await LevelRepository(db, kidId: a).setLevel('toan', 1);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(c.dispose);

    expect(await c.read(isPlacedProvider.future), isTrue);
    await kids.setCurrentKid(b);
    c.invalidate(currentKidIdProvider);
    expect(await c.read(currentKidIdProvider.future), b);
    expect(await c.read(isPlacedProvider.future), isFalse);
  });

  test('voice defaults on and the speaker goes silent when off', () async {
    final device = FakeSpeaker();
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      deviceSpeakerProvider.overrideWithValue(device),
    ]);
    addTearDown(c.dispose);
    expect(await c.read(voiceEnabledProvider.future), isTrue);
    await c.read(speakerProvider).speak('một');
    await kids.setSetting(voiceEnabledKey, 'false');
    c.invalidate(voiceEnabledProvider);
    expect(await c.read(voiceEnabledProvider.future), isFalse);
    await c.read(speakerProvider).speak('hai');
    expect(device.spoken, ['một']);
  });

  test('deleteKid removes the kid\'s screen-time settings and usage', () async {
    final a = await kids.addKid(nickname: 'A', avatar: kidAvatars[0], age: 5);
    final b = await kids.addKid(nickname: 'B', avatar: kidAvatars[0], age: 5);
    for (final id in [a, b]) {
      await kids.setSetting('dailyLimitMinutes.$id', '30');
      await kids.setSetting('bedtimeStart.$id', '20:00');
      await kids.setSetting('bedtimeEnd.$id', '06:00');
      await kids.setSetting('extraMinutes.$id.2026-11-13', '15');
      await kids.setSetting(teaseStickersKey(id), 'false');
      await kids.setSetting(showcaseOnKey(id), 'false');
      await kids.setSetting(showcaseLearningKey(id), 'true');
    }
    await kids.deleteKid(a);
    expect(await kids.setting('dailyLimitMinutes.$a'), isNull);
    expect(await kids.setting('bedtimeStart.$a'), isNull);
    expect(await kids.setting('bedtimeEnd.$a'), isNull);
    expect(await kids.setting('extraMinutes.$a.2026-11-13'), isNull);
    expect(await kids.setting(teaseStickersKey(a)), isNull);
    expect(await kids.setting(showcaseOnKey(a)), isNull);
    expect(await kids.setting(showcaseLearningKey(a)), isNull);
    expect(await kids.setting('dailyLimitMinutes.$b'), '30');
    expect(await kids.setting('extraMinutes.$b.2026-11-13'), '15');
    expect(await kids.setting(teaseStickersKey(b)), 'false');
    expect(await kids.setting(showcaseOnKey(b)), 'false');
    expect(await kids.setting(showcaseLearningKey(b)), 'true');
  });

  test('wipeKidData keeps device keys and removes kid progress', () async {
    final a = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    await ProgressRepository(db, kidId: a).recordGlyphCompleted('so-1', failedStrokes: 0);
    await kids.setSetting('deviceId', 'dev-uuid-1234');
    await kids.setSetting('consentAt', '2026-11-20T10:00:00Z');
    await kids.setSetting(restorePendingKey, 'true');
    await kids.setSetting(dataOwnerKey, 'fam-xyz');
    await kids.setSetting('dailyLimitMinutes.$a', '30');

    await kids.wipeKidData();

    expect(await kids.kids(), isEmpty);
    expect(await db.select(db.glyphProgress).get(), isEmpty);
    expect(await db.select(db.notebookPages).get(), isEmpty);
    expect(await kids.setting('deviceId'), 'dev-uuid-1234');
    expect(await kids.setting('consentAt'), '2026-11-20T10:00:00Z');
    expect(await kids.setting(restorePendingKey), 'true');
    expect(await kids.setting(dataOwnerKey), isNull);
    expect(await kids.setting('dailyLimitMinutes.$a'), isNull);
  });

  test('deleteAllData preserves deviceId', () async {
    await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    await kids.setSetting('deviceId', 'dev-uuid-1234');
    await kids.setSetting('someSetting', 'abc');

    await kids.deleteAllData();

    expect(await kids.kids(), isEmpty);
    expect(await kids.setting('deviceId'), 'dev-uuid-1234');
    expect(await kids.setting('someSetting'), isNull);
  });
}
