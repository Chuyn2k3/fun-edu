import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/online/sync/sync_store.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/ui/assets.dart';

Set<String> _parseServerAllowedKinds() {
  final file = File('server/src/main/java/com/ibme/funedu/server/sync/SyncKinds.java');
  expect(file.existsSync(), isTrue, reason: 'SyncKinds.java must exist');
  final source = file.readAsStringSync();
  final setBlock = RegExp(
    r'ALLOWED\s*=\s*Set\.of\((.*?)\);',
    dotAll: true,
  ).firstMatch(source);
  expect(setBlock, isNotNull, reason: 'Could not locate ALLOWED = Set.of(...)');
  return RegExp(r'"([a-z]+)"')
      .allMatches(setBlock!.group(1)!)
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  test('every exported kind has an explicit merge rule and matches server SyncKinds.ALLOWED',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final kids = KidRepository(db);
    final kidId = await kids.addKid(
      nickname: 'Bé Test',
      avatar: AppImages.chipMain,
      age: 5,
    );
    await db.into(db.glyphProgress).insert(GlyphProgressCompanion.insert(
          kidId: kidId,
          glyphId: 'so-1',
          lastPracticedAt: DateTime(2026, 11, 20),
        ));
    await db.into(db.notebookPages).insert(NotebookPagesCompanion.insert(
          kidId: kidId,
          glyphId: 'so-1',
          strokes: '[[0.1,0.2,0.8,0.8]]',
          mistakes: 0,
          writtenAt: DateTime(2026, 11, 20),
        ));
    await db.into(db.lessonCompletions).insert(LessonCompletionsCompanion.insert(
          kidId: kidId,
          completedAt: DateTime(2026, 11, 20, 8),
          starsEarned: 5,
        ));
    await db.into(db.subjectLevels).insert(SubjectLevelsCompanion.insert(
          kidId: kidId,
          subject: 'toan',
          levelIndex: 1,
          placedAt: DateTime(2026, 11, 20),
        ));
    await db.into(db.dailyUsage).insert(DailyUsageCompanion.insert(
          kidId: kidId,
          day: '2026-11-20',
          seconds: const Value(60),
        ));
    await db.into(db.realRewards).insert(RealRewardsCompanion.insert(
          kidId: kidId,
          title: 'Đi công viên',
          starsNeeded: 10,
          createdAt: DateTime(2026, 11, 20),
        ));
    await kids.setSetting('dailyLimitMinutes.$kidId', '30');
    await db.into(db.raceResults).insert(RaceResultsCompanion.insert(
          kidId: kidId,
          subject: 'toan',
          finishedAt: DateTime(2026, 11, 20, 9),
          won: true,
          kidTimeMs: 12000,
          firstTryCorrect: 8,
          cometsFirstTry: 2,
          stars: 5,
        ));
    await db.into(db.gameProfile).insert(GameProfileCompanion.insert(
          kidId: Value(kidId),
        ));
    await db.into(db.gameItems).insert(GameItemsCompanion.insert(
          kidId: kidId,
          itemId: 'rocket_blue',
        ));
    await db.into(db.gameBadges).insert(GameBadgesCompanion.insert(
          kidId: kidId,
          badgeId: 'speed_king',
          earnedAt: DateTime(2026, 11, 20),
        ));
    await db.into(db.gameCounters).insert(GameCountersCompanion.insert(
          kidId: kidId,
          key: 'wins',
          value: const Value(1),
        ));

    final exported = await SyncStore(db).exportAll();
    final exportedKinds = {
      for (final key in exported.keys) key.substring(0, key.indexOf(':')),
    };

    final serverAllowed = _parseServerAllowedKinds();

    expect(exportedKinds, equals(SyncStore.mergeKinds));
    expect(SyncStore.mergeKinds, equals(serverAllowed));
  });
}
