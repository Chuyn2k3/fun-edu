import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/api_client.dart';
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

  test('SyncEngine with pushLocal: false sends zero changes and applies remote records', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    final progress = ProgressRepository(phone, kidId: id);
    await progress.recordGlyphCompleted('so-1', failedStrokes: 0);

    var changesSent = <Object?>[];
    final engine = SyncEngine(phone, (body) async {
      changesSent = body['changes'] as List<Object?>? ?? [];
      return {
        'version': 1,
        'hasMore': false,
        'conflicts': [],
        'records': [
          {
            'key': 'kid:uuid-cloud',
            'payload': {
              'uuid': 'uuid-cloud',
              'nickname': 'CloudKid',
              'avatar': AppImages.chipMain,
              'age': 6,
              'createdAt': 1700000000,
            },
            'deleted': false,
            'version': 1,
          },
        ],
      };
    });

    final pulled = await engine.run(pushLocal: false);
    expect(pulled, isTrue);
    expect(changesSent, isEmpty);
    final kids = await KidRepository(phone).kids();
    expect(kids.any((k) => k.nickname == 'CloudKid'), isTrue);
  });

  test('lost response after server saved does not double', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    final progress = ProgressRepository(phone, kidId: id);
    for (var i = 0; i < 3; i++) {
      await progress.recordGlyphCompleted('so-1', failedStrokes: 0);
    }
    for (var i = 0; i < 10; i++) {
      await phone.into(phone.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
              kidId: id,
              completedAt: DateTime(2026, 11, 20, 9, i),
              starsEarned: 2));
    }

    server.dropResponseAfterSave = true;
    await expectLater(sync(phone), throwsA(isA<ApiException>()));

    server.dropResponseAfterSave = false;
    await sync(phone);

    // Server has exactly 10 lessons and glyph c=3.
    expect(server.records.keys.where((k) => k.startsWith('lesson:')), hasLength(10));
    final glyphRec = server.records.entries.singleWhere((e) => e.key.startsWith('glyph:'));
    expect(glyphRec.value.payload!['completions'], 3);

    // Local device matches and has no pending changes.
    expect(await phone.select(phone.lessonCompletions).get(), hasLength(10));
    expect((await phone.select(phone.glyphProgress).getSingle()).completions, 3);
    expect(await SyncStore(phone).pendingChanges(), isEmpty);

    // Second device syncs and matches.
    await sync(ipad);
    expect(await ipad.select(ipad.lessonCompletions).get(), hasLength(10));
    expect((await ipad.select(ipad.glyphProgress).getSingle()).completions, 3);
  });

  test('pull resumes from the last applied page', () async {
    server = FakeSyncServer(page: 1000);
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    for (var i = 0; i < 2500; i++) {
      await phone.into(phone.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
              kidId: id,
              completedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
              starsEarned: 1));
    }
    await sync(phone);
    expect(server.records, hasLength(2501)); // 1 kid + 2500 lessons

    // Pull page 1, fail on page 2.
    server.failOnPage = 2;
    server.calls = 0;
    await expectLater(sync(ipad), throwsA(isA<ApiException>()));

    // Page 1 applied & cursor persisted.
    final afterPage1Count = (await ipad.select(ipad.lessonCompletions).get()).length;
    expect(afterPage1Count, inInclusiveRange(999, 1000));
    final cursorSetting = await KidRepository(ipad).setting(SyncEngine.cursorKey);
    expect(cursorSetting, '1000');

    // Resume: must NOT re-fetch page 1 (only page 2 & page 3 -> 2 calls).
    server.failOnPage = null;
    server.calls = 0;
    await sync(ipad);
    expect(server.calls, 2);
    expect(await ipad.select(ipad.lessonCompletions).get(), hasLength(2500));
    expect(await KidRepository(ipad).setting(SyncEngine.cursorKey), '2501');
  });

  test('progress before its kid waits and applies later', () async {
    var call = 0;
    final engine = SyncEngine(ipad, (body) async {
      call++;
      if (call == 1) {
        return {
          'version': 10,
          'hasMore': true,
          'conflicts': [],
          'records': [
            {
              'key': 'glyph:uuid-late:so-1',
              'payload': {
                'completions': 4,
                'clean': 2,
                'last': 1700000100000,
              },
              'deleted': false,
              'version': 10,
            },
          ],
        };
      }
      return {
        'version': 20,
        'hasMore': false,
        'conflicts': [],
        'records': [
          {
            'key': 'kid:uuid-late',
            'payload': {
              'uuid': 'uuid-late',
              'nickname': 'LateKid',
              'avatar': AppImages.chipMain,
              'age': 5,
              'createdAt': 1700000000000,
            },
            'deleted': false,
            'version': 20,
          },
        ],
      };
    });

    await engine.run(pushLocal: false);

    final kids = await KidRepository(ipad).kids();
    expect(kids.single.nickname, 'LateKid');
    final glyph = await ipad.select(ipad.glyphProgress).getSingle();
    expect(glyph.glyphId, 'so-1');
    expect(glyph.completions, 4);
    expect(await ipad.select(ipad.syncPendingRemote).get(), isEmpty);
  });

  test('timeout halves the batch and 3 successes double it back', () async {
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    for (var i = 0; i < 1000; i++) {
      await phone.into(phone.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
              kidId: id,
              completedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
              starsEarned: 1));
    }

    final sentBatchSizes = <int>[];
    final engine = SyncEngine(phone, (body) async {
      final changes = body['changes'] as List<Object?>? ?? const [];
      if (changes.isNotEmpty) sentBatchSizes.add(changes.length);
      if (changes.length > 300) {
        throw const ApiException(0, 'timeout');
      }
      return server.handle(body);
    });

    // First attempt sends 500 -> times out and halves batch to 250.
    await expectLater(engine.run(), throwsA(isA<ApiException>()));
    expect(sentBatchSizes, [500]);
    expect(await KidRepository(phone).setting(SyncEngine.batchKey), '250');

    // Second run pushes all remaining 1001 records in batches <= 250 cleanly.
    sentBatchSizes.clear();
    await engine.run();
    expect(sentBatchSizes.every((s) => s <= 250), isTrue);
    expect(server.records.keys.where((k) => k.startsWith('lesson:')), hasLength(1000));
    expect(await SyncStore(phone).pendingChanges(), isEmpty);
    expect(await KidRepository(phone).setting(SyncEngine.batchOkKey), '1');

    // Two more consecutive successes -> doubles batch back to 500.
    await engine.run();
    expect(await KidRepository(phone).setting(SyncEngine.batchOkKey), '2');
    await engine.run();
    expect(await KidRepository(phone).setting(SyncEngine.batchKey), '500');
    expect(await KidRepository(phone).setting(SyncEngine.batchOkKey), '0');
  });

  test('app killed mid-pull keeps data consistent', () async {
    server = FakeSyncServer(page: 100);
    final id = await KidRepository(phone)
        .addKid(nickname: 'Na', avatar: AppImages.chipMain, age: 5);
    for (var i = 0; i < 250; i++) {
      await phone.into(phone.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
              kidId: id,
              completedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
              starsEarned: 1));
    }
    await sync(phone);

    // Crash/kill simulated by throwing mid-pull on page 2.
    var calls = 0;
    final crashingEngine = SyncEngine(ipad, (body) async {
      calls++;
      if (calls == 2) throw StateError('killed mid-pull');
      return server.handle(body);
    });
    await expectLater(crashingEngine.run(), throwsStateError);

    // Page 1 data and cursor were saved atomically.
    final savedCursor =
        int.tryParse(await KidRepository(ipad).setting(SyncEngine.cursorKey) ?? '') ?? 0;
    expect(savedCursor, greaterThan(0));
    final countAfterCrash = (await ipad.select(ipad.lessonCompletions).get()).length;
    expect(countAfterCrash, inInclusiveRange(99, 100));

    // Relaunch and resume -> gets the rest cleanly without duplicates.
    await sync(ipad);
    expect(await ipad.select(ipad.lessonCompletions).get(), hasLength(250));
  });

  test('switching kid during sync keeps data per kid', () async {
    final kid1Uuid = 'kid-aaa';
    final kid2Uuid = 'kid-bbb';
    var page = 0;
    final engine = SyncEngine(ipad, (body) async {
      page++;
      if (page == 1) {
        return {
          'version': 10,
          'hasMore': true,
          'conflicts': [],
          'records': [
            {
              'key': 'kid:$kid1Uuid',
              'payload': {
                'uuid': kid1Uuid,
                'nickname': 'Bé A',
                'avatar': AppImages.chipMain,
                'age': 5,
                'createdAt': 1700000000000,
              },
              'deleted': false,
              'version': 1,
            },
            {
              'key': 'kid:$kid2Uuid',
              'payload': {
                'uuid': kid2Uuid,
                'nickname': 'Bé B',
                'avatar': AppImages.chipMain,
                'age': 6,
                'createdAt': 1700000001000,
              },
              'deleted': false,
              'version': 2,
            },
            {
              'key': 'glyph:$kid1Uuid:chu-a',
              'payload': {'completions': 2, 'clean': 1, 'last': 1700000005000},
              'deleted': false,
              'version': 10,
            },
          ],
        };
      }
      // Switch active kid on device right between page 1 and page 2!
      final kids = await KidRepository(ipad).kids();
      final kid1 = kids.firstWhere((k) => k.nickname == 'Bé A');
      await KidRepository(ipad).setCurrentKid(kid1.id);

      return {
        'version': 20,
        'hasMore': false,
        'conflicts': [],
        'records': [
          {
            'key': 'glyph:$kid2Uuid:chu-b',
            'payload': {'completions': 5, 'clean': 5, 'last': 1700000010000},
            'deleted': false,
            'version': 20,
          },
        ],
      };
    });

    await engine.run(pushLocal: false);

    final kids = await KidRepository(ipad).kids();
    final kid1 = kids.firstWhere((k) => k.nickname == 'Bé A');
    final kid2 = kids.firstWhere((k) => k.nickname == 'Bé B');

    final g1 = await (ipad.select(ipad.glyphProgress)
          ..where((t) => t.kidId.equals(kid1.id)))
        .get();
    final g2 = await (ipad.select(ipad.glyphProgress)
          ..where((t) => t.kidId.equals(kid2.id)))
        .get();
    expect(g1.map((e) => e.glyphId).toList(), ['chu-a']);
    expect(g2.map((e) => e.glyphId).toList(), ['chu-b']);
  });
}
