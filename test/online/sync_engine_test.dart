import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/sync/sync_engine.dart';
import 'package:funedu/online/sync/sync_store.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/progress_repository.dart';
import 'package:funedu/ui/assets.dart';

import 'fake_sync_server.dart';

AppDatabase _device() => AppDatabase(NativeDatabase.memory());

Future<int> _stars(AppDatabase db, int kidId) =>
    ProgressRepository(db, kidId: kidId).totalStars();

Future<int> _onlyKid(AppDatabase db) async =>
    (await KidRepository(db).kids()).single.id;

void main() {
  late FakeSyncServer server;
  late AppDatabase phone;
  late AppDatabase ipad;

  setUp(() {
    server = FakeSyncServer();
    phone = _device();
    ipad = _device();
  });
  tearDown(() async {
    await phone.close();
    await ipad.close();
  });

  Future<void> sync(AppDatabase db) => SyncEngine(db, server.handle).run();

  test('a kid and their progress reach a second device', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    final progress = ProgressRepository(phone, kidId: id);
    await progress.recordGlyphCompleted('so-1', failedStrokes: 0);
    await progress.recordLessonCompleted(itemsCompleted: 3);
    await KidRepository(phone).setSetting('dailyLimitMinutes.$id', '30');
    await phone.into(phone.subjectLevels).insert(SubjectLevelsCompanion.insert(
        kidId: id, subject: 'toan', levelIndex: 4, placedAt: DateTime(2026, 11, 1)));

    await sync(phone);
    await sync(ipad);

    final kid = (await KidRepository(ipad).kids()).single;
    expect(kid.nickname, 'Na');
    expect(await KidRepository(ipad).currentKidId(), kid.id);
    expect(await _stars(ipad, kid.id), await _stars(phone, id));
    expect(await KidRepository(ipad).setting('dailyLimitMinutes.${kid.id}'), '30');
    final level = await ipad.select(ipad.subjectLevels).getSingle();
    expect(level.levelIndex, 4);
    final glyph = await ipad.select(ipad.glyphProgress).getSingle();
    expect(glyph.glyphId, 'so-1');
    expect(glyph.completions, 1);
  });

  test('stars earned offline on two devices add up, never lost or doubled',
      () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    await sync(phone);
    await sync(ipad);
    final ipadKid = await _onlyKid(ipad);

    // Both offline: one lesson each, at different times.
    await phone.into(phone.lessonCompletions).insert(LessonCompletionsCompanion.insert(
        kidId: id, completedAt: DateTime(2026, 11, 20, 9), starsEarned: 5));
    await ipad.into(ipad.lessonCompletions).insert(LessonCompletionsCompanion.insert(
        kidId: ipadKid, completedAt: DateTime(2026, 11, 20, 17), starsEarned: 7));

    await sync(phone);
    await sync(ipad);
    await sync(phone);
    await sync(ipad); // Syncing again changes nothing.

    expect(await _stars(phone, id), 12);
    expect(await _stars(ipad, ipadKid), 12);
    expect(await phone.select(phone.lessonCompletions).get(), hasLength(2));
  });

  test('practice counters merge to the larger value after a conflict', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    await ProgressRepository(phone, kidId: id).recordGlyphCompleted('so-1', failedStrokes: 0);
    await sync(phone);
    await sync(ipad);
    final ipadKid = await _onlyKid(ipad);

    // Phone practises twice more, iPad once more, both offline.
    for (var i = 0; i < 2; i++) {
      await ProgressRepository(phone, kidId: id).recordGlyphCompleted('so-1', failedStrokes: 0);
    }
    await ProgressRepository(ipad, kidId: ipadKid).recordGlyphCompleted('so-1', failedStrokes: 3);

    await sync(phone);
    await sync(ipad); // iPad's push is a conflict: it merges and retries.
    await sync(phone);

    final p = await phone.select(phone.glyphProgress).getSingle();
    final q = await ipad.select(ipad.glyphProgress).getSingle();
    expect(p.completions, 3);
    expect(q.completions, 3);
    expect(p.cleanCompletions, q.cleanCompletions);
    expect(await SyncStore(phone).pendingChanges(), isEmpty);
    expect(await SyncStore(ipad).pendingChanges(), isEmpty);
  });

  test('deleting a kid on one device deletes them everywhere', () async {
    final keep = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    final gone = await KidRepository(phone)
        .addKid(nickname: 'Bo', avatar: AppImages.chipMain, age: 4);
    await ProgressRepository(phone, kidId: gone).recordLessonCompleted(itemsCompleted: 2);
    await sync(phone);
    await sync(ipad);
    expect(await KidRepository(ipad).kids(), hasLength(2));

    await KidRepository(phone).deleteKid(gone);
    await sync(phone);
    await sync(ipad);

    final left = await KidRepository(ipad).kids();
    expect(left.map((k) => k.nickname), ['Na']);
    expect(await ipad.select(ipad.lessonCompletions).get(), isEmpty);
    expect(keep, isNonZero);
    // Every record of the deleted kid is a tombstone on the server.
    expect(server.records.entries.where((e) => e.key.contains(':') && e.value.payload == null),
        isNotEmpty);
  });

  test('stroke coordinates and device settings never leave the device', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    await phone.logAttempt(
        kidId: id, glyphId: 'so-1', strokeIndex: 0, ok: true, error: null, deviation: 0.1);
    await KidRepository(phone).setSetting(voiceEnabledKey, 'false');
    await sync(phone);
    expect(server.records.keys.where((k) => k.startsWith('stroke')), isEmpty);
    expect(server.records.keys.where((k) => k.contains('voice')), isEmpty);
    expect(server.records.keys.where((k) => k.contains('currentKid')), isEmpty);
  });

  test('a big first sync is pushed in batches and pulled in pages', () async {
    server = FakeSyncServer(page: 100);
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    for (var i = 0; i < 700; i++) {
      await phone.into(phone.lessonCompletions).insert(LessonCompletionsCompanion.insert(
          kidId: id, completedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)), starsEarned: 1));
    }
    await sync(phone);
    expect(await SyncStore(phone).pendingChanges(), isEmpty);
    await sync(ipad);
    expect(await ipad.select(ipad.lessonCompletions).get(), hasLength(700));
  });

  test('nothing to send means one call and no new versions', () async {
    await KidRepository(phone).addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    await sync(phone);
    final versions = server.records.values.map((r) => r.version).toList();
    server.calls = 0;
    await sync(phone);
    expect(server.calls, 1);
    expect(server.records.values.map((r) => r.version).toList(), versions);
  });

  test('a reward redeemed on the iPad shows as redeemed on the phone', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    await phone.into(phone.realRewards).insert(RealRewardsCompanion.insert(
        kidId: id, title: 'Đi công viên', starsNeeded: 10, createdAt: DateTime(2026, 11, 2)));
    await sync(phone);
    await sync(ipad);
    await (ipad.update(ipad.realRewards))
        .write(RealRewardsCompanion(redeemedAt: Value(DateTime(2026, 11, 21))));
    await sync(ipad);
    await sync(phone);
    final r = await phone.select(phone.realRewards).getSingle();
    expect(r.redeemedAt, DateTime(2026, 11, 21));
  });

  test('notebook pages sync, better page wins, and stroke_attempts never leave device', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);

    // Phone writes net-ngang with 1 mistake
    await phone.into(phone.notebookPages).insert(
          NotebookPagesCompanion.insert(
            kidId: id,
            glyphId: 'net-ngang',
            strokes: '[[0.1, 0.5, 0.9, 0.5]]',
            mistakes: 1,
            writtenAt: DateTime(2026, 11, 22, 10, 0),
          ),
        );
    // Also add a stroke attempt on phone
    await phone.into(phone.strokeAttempts).insert(
          StrokeAttemptsCompanion.insert(
            kidId: id,
            glyphId: 'net-ngang',
            strokeIndex: 0,
            ok: true,
            deviation: 0.1,
            points: Value('[[0.1, 0.5], [0.9, 0.5]]'),
            createdAt: DateTime(2026, 11, 22, 10, 0),
          ),
        );

    await sync(phone);

    // Verify stroke_attempts was NOT sent to server
    expect(server.records.keys.any((k) => k.startsWith('stroke:')), isFalse);
    expect(server.records.keys.any((k) => k.startsWith('page:')), isTrue);

    await sync(ipad);
    final ipadKid = await _onlyKid(ipad);

    var ipadPages = await (ipad.select(ipad.notebookPages)
          ..where((t) => t.kidId.equals(ipadKid)))
        .get();
    expect(ipadPages, hasLength(1));
    expect(ipadPages.single.glyphId, 'net-ngang');
    expect(ipadPages.single.mistakes, 1);

    // iPad writes a better version (0 mistakes)
    await ipad.into(ipad.notebookPages).insertOnConflictUpdate(
          NotebookPagesCompanion.insert(
            kidId: ipadKid,
            glyphId: 'net-ngang',
            strokes: '[[0.1, 0.5, 0.9, 0.5]]',
            mistakes: 0,
            writtenAt: DateTime(2026, 11, 22, 11, 0),
          ),
        );

    await sync(ipad);
    await sync(phone);

    var phonePages = await (phone.select(phone.notebookPages)
          ..where((t) => t.kidId.equals(id)))
        .get();
    expect(phonePages.single.mistakes, 0);

    // Deleting kid removes pages
    await KidRepository(ipad).deleteKid(ipadKid);
    await sync(ipad);
    await sync(phone);

    expect(await phone.select(phone.notebookPages).get(), isEmpty);
  });
}
