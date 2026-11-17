import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/game/badge_cabinet_screen.dart';
import 'package:funedu/features/game/game_hub_screen.dart';
import 'package:funedu/features/game/garage_screen.dart';
import 'package:funedu/features/game/race_screen.dart';
import 'package:funedu/features/game/sticker_album_screen.dart';
import 'package:funedu/features/game/subject_picker.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/router.dart';

import 'game_test_helpers.dart';

Future<void> _stars(AppDatabase db, int kid, int stars) =>
    db.into(db.gameProfile).insert(GameProfileCompanion.insert(
        kidId: Value(kid), cosmicStars: Value(stars)));

Future<void> _own(AppDatabase db, int kid, List<String> ids) async {
  for (final id in ids) {
    await db
        .into(db.gameItems)
        .insert(GameItemsCompanion.insert(kidId: kid, itemId: id));
  }
}

Future<void> _race(AppDatabase db, int kid, String subject,
        {required bool won, required int ms, required int first}) =>
    db.into(db.raceResults).insert(RaceResultsCompanion.insert(
          kidId: kid,
          subject: subject,
          finishedAt: DateTime(2026, 11, 16),
          won: won,
          kidTimeMs: ms,
          firstTryCorrect: first,
          cometsFirstTry: 0,
          stars: won ? 5 : 3,
        ));

Future<void> _openHub(WidgetTester t) async {
  appRouter.go('/game');
  await pumpReal(t, times: 6);
  expect(find.byType(GameHubScreen), findsOneWidget);
}

String _textOf(WidgetTester t, String key) =>
    t.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  for (final size in const [
    Size(390, 844),
    Size(1366, 1024),
    Size(1024, 1366)
  ]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('$name: nav "Chơi" opens the hub, "Học" returns home',
        (t) async {
      await bootGame(t, size: size);
      expect(find.byType(HomeScreen), findsOneWidget);
      await t.tap(find.text('Chơi'));
      await pumpReal(t, times: 6);
      expect(find.byType(GameHubScreen), findsOneWidget);
      expect(find.text('Sắp có'), findsNothing);
      await t.tap(find.text('Học'));
      await pumpReal(t, times: 6);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(GameHubScreen), findsNothing);
    });

    testWidgets('$name: hub, cabinet and album lay out without overflow',
        (t) async {
      await bootGame(t, size: size, seed: (db, kid) async {
        await _stars(db, kid, 128);
        await _own(db, kid, ['rocket_blue', 'trail_rainbow', 'sticker_clap']);
        await _race(db, kid, 'toan', won: true, ms: 75000, first: 9);
      });
      await _openHub(t);
      expect(t.takeException(), isNull);
      appRouter.go('/game/badges');
      await pumpReal(t, times: 6);
      expect(find.byType(BadgeCabinetScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      appRouter.go('/game/stickers');
      await pumpReal(t, times: 6);
      expect(find.byType(StickerAlbumScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      appRouter.go('/game/garage');
      await pumpReal(t, times: 6);
      expect(find.byType(GarageScreen), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('hub shows the cosmic stars, not the home stars', (t) async {
    await bootGame(t, seed: (db, kid) async {
      await db.into(db.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
              kidId: kid,
              completedAt: DateTime(2026, 11, 16),
              starsEarned: 42));
      await _stars(db, kid, 17);
    });
    expect(find.text('42'), findsOneWidget); // home shows learning stars
    await _openHub(t);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('hub-stars')),
            matching: find.text('17')),
        findsOneWidget);
    expect(find.text('42'), findsNothing);
  });

  testWidgets('"Mời bạn đua" and "Nhập mã" say "Sắp có"', (t) async {
    await bootGame(t);
    await _openHub(t);
    for (final label in ['Mời bạn đua', 'Nhập mã']) {
      await t.tap(find.text(label));
      await t.pump();
      expect(
          find.descendant(
              of: find.byType(SnackBar), matching: find.text('Sắp có')),
          findsOneWidget);
      expect(find.byType(GameHubScreen), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
    }
  });

  testWidgets('"Đua với Chíp" opens the subject picker, then a race',
      (t) async {
    await bootGame(t);
    await _openHub(t);
    await t.tap(find.text('Đua với Chíp'));
    await pumpReal(t, times: 6);
    expect(find.byType(SubjectPickerScreen), findsOneWidget);
    await t.tap(find.text('Toán'));
    await pumpReal(t, times: 8);
    expect(find.byType(RaceScreen), findsOneWidget);
  });

  testWidgets('the picker back button returns to the hub', (t) async {
    await bootGame(t);
    appRouter.go('/game/pick');
    await pumpReal(t, times: 6);
    await t.tap(find.bySemanticsLabel('Về Góc Chơi'));
    await pumpReal(t, times: 6);
    expect(find.byType(GameHubScreen), findsOneWidget);
  });

  testWidgets('hub counts new garage items until the garage is opened',
      (t) async {
    await bootGame(t, seed: (db, kid) async {
      await _stars(db, kid, 30);
      await _own(db, kid, ['rocket_blue', 'trail_rainbow', 'sticker_clap']);
    });
    await _openHub(t);
    expect(_textOf(t, 'hub-garage-new'), '2');
    expect(find.text('Có 2 món mới chờ lắp!'), findsOneWidget);
    await t.tap(find.text('Xưởng độ tên lửa'));
    await pumpReal(t, times: 6);
    expect(find.byType(GarageScreen), findsOneWidget);
    // Seeing a tab marks its items; open the trails tab too.
    await t.tap(find.byKey(const ValueKey('garage-tab-trails')));
    await pumpReal(t, times: 4);
    await t.tap(find.bySemanticsLabel('Về Góc Chơi'));
    await pumpReal(t, times: 6);
    expect(find.byType(GameHubScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-garage-new')), findsNothing);
  });

  testWidgets('achievements show per-subject numbers from stats()', (t) async {
    await bootGame(t, seed: (db, kid) async {
      await _race(db, kid, 'toan', won: true, ms: 75000, first: 9);
      await _race(db, kid, 'toan', won: true, ms: 92000, first: 8);
      await _race(db, kid, 'toan', won: false, ms: 70000, first: 5);
      await _race(db, kid, 'tiengViet', won: false, ms: 80000, first: 6);
    });
    await _openHub(t);
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('ach-tiengViet-first')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(_textOf(t, 'ach-toan-races'), '3');
    expect(_textOf(t, 'ach-toan-wins'), '2');
    expect(_textOf(t, 'ach-toan-best'), '1:15');
    expect(_textOf(t, 'ach-toan-first'), '22');
    expect(_textOf(t, 'ach-tiengViet-races'), '1');
    expect(_textOf(t, 'ach-tiengViet-wins'), '0');
    expect(_textOf(t, 'ach-tiengViet-best'), '—');
    expect(_textOf(t, 'ach-tiengViet-first'), '6');
  });

  testWidgets('badge cabinet: earned in colour with date, others grey + howTo',
      (t) async {
    await bootGame(t, seed: (db, kid) async {
      await db.into(db.gameBadges).insert(GameBadgesCompanion.insert(
          kidId: kid, badgeId: 'scholar', earnedAt: DateTime(2026, 11, 16)));
    });
    await _openHub(t);
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('ach-toan-races')), 200,
        scrollable: find.byType(Scrollable).first);
    await t.pump();
    await t.tap(find.text('Tủ huy hiệu'));
    await pumpReal(t, times: 6);
    expect(find.byType(BadgeCabinetScreen), findsOneWidget);
    expect(find.text('Đã có 1/8 huy hiệu'), findsOneWidget);

    final earned = find.byKey(const ValueKey('badge-scholar'));
    expect(find.descendant(of: earned, matching: find.text('Nhà Thông Thái')),
        findsOneWidget);
    expect(
        find.descendant(of: earned, matching: find.text('Đạt ngày 16/11/2026')),
        findsOneWidget);
    expect(find.descendant(of: earned, matching: find.byType(ColorFiltered)),
        findsNothing);

    const titles = {
      'speed_king': ('Vua Thần Tốc', 'Phá kỷ lục về đích của mình 3 lần'),
      'comet_hunter': ('Thợ Săn Sao Chổi', 'Trả lời đúng 10 câu sao chổi'),
      'pilot': ('Phi Công Chăm Chỉ', 'Đua 20 trận'),
    };
    for (final MapEntry(key: id, value: (title, howTo)) in titles.entries) {
      final tile = find.byKey(ValueKey('badge-$id'));
      await t.scrollUntilVisible(tile, 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.descendant(of: tile, matching: find.text(title)),
          findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text(howTo)),
          findsOneWidget);
      expect(find.descendant(of: tile, matching: find.byType(ColorFiltered)),
          findsOneWidget);
    }
    expect(find.textContaining('Đạt ngày'), findsOneWidget);
  });

  testWidgets('sticker album: owned stickers show, others are silhouettes',
      (t) async {
    await bootGame(t, seed: (db, kid) async {
      await _own(db, kid, ['sticker_clap']);
      await db.into(db.gameBadges).insert(GameBadgesCompanion.insert(
          kidId: kid, badgeId: 'pilot', earnedAt: DateTime(2026, 11, 16)));
    });
    appRouter.go('/game/stickers');
    await pumpReal(t, times: 6);
    expect(find.byType(StickerAlbumScreen), findsOneWidget);
    expect(find.text('Đã có 2/10 sticker'), findsOneWidget);

    Finder tile(String id) => find.byKey(ValueKey('sticker-$id'));
    for (final id in ['sticker_clap', 'sticker_wave_rocket']) {
      await t.scrollUntilVisible(tile(id), 200,
          scrollable: find.byType(Scrollable).first);
      expect(
          find.descendant(of: tile(id), matching: find.byType(ColorFiltered)),
          findsNothing);
    }
    expect(find.text('Chíp vỗ tay'), findsOneWidget);
    expect(find.text('Chíp vẫy tay trên tên lửa'), findsOneWidget);

    await t.scrollUntilVisible(tile('sticker_grad_cap'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.descendant(
            of: tile('sticker_grad_cap'), matching: find.byType(ColorFiltered)),
        findsOneWidget);
    expect(
        find.descendant(
            of: tile('sticker_grad_cap'),
            matching: find.text('Huy hiệu Nhà Thông Thái')),
        findsOneWidget);
    await t.scrollUntilVisible(tile('sticker_laugh'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.descendant(
            of: tile('sticker_laugh'),
            matching: find.text('Còn 85 sao vũ trụ')),
        findsOneWidget);
  });

  testWidgets(
      'after a race the hub shows the new stars, Thành tích, badges, '
      'stickers and "món mới"', (t) async {
    await bootGame(t, seed: (db, kid) => _stars(db, kid, 24));
    await _openHub(t);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('hub-stars')),
            matching: find.text('24')),
        findsOneWidget);
    expect(find.text('0/8 huy hiệu'), findsOneWidget);
    expect(find.text('0/10 sticker'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-garage-new')), findsNothing);

    // The hub stays mounted under the picker, the race and the result.
    await t.tap(find.text('Đua với Chíp'));
    await pumpReal(t, times: 6);
    await t.tap(find.text('Toán'));
    await pumpReal(t, times: 8);
    expect(find.byType(RaceScreen), findsOneWidget);
    await winRace(t);
    // Skip the landing cut-scene, close the scholar badge, take two gifts
    // (24 + 7 stars crosses the 25 and 30 milestones).
    await t.tap(find.byKey(const ValueKey('landing-cutscene')));
    await pumpReal(t, times: 6);
    await t.tap(find.text('Tuyệt quá!'));
    await pumpReal(t, times: 6);
    await t.tap(find.byKey(const ValueKey('offer-rocket_blue')));
    await pumpReal(t, times: 8);
    await t.tap(find.byKey(const ValueKey('offer-sticker_clap')));
    await pumpReal(t, times: 8);
    await t.ensureVisible(find.text('Về Góc Chơi'));
    await pumpReal(t);
    await t.tap(find.text('Về Góc Chơi'));
    await pumpReal(t, times: 8);

    expect(find.byType(GameHubScreen), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('hub-stars')),
            matching: find.text('31')),
        findsOneWidget);
    expect(find.text('1/8 huy hiệu'), findsOneWidget);
    // sticker_clap picked + the scholar badge's sticker.
    expect(find.text('2/10 sticker'), findsOneWidget);
    expect(_textOf(t, 'hub-garage-new'), '1');
    expect(find.text('Có 1 món mới chờ lắp!'), findsOneWidget);
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('ach-toan-first')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(_textOf(t, 'ach-toan-races'), '1');
    expect(_textOf(t, 'ach-toan-wins'), '1');
    expect(_textOf(t, 'ach-toan-first'), '8');
    expect(_textOf(t, 'ach-toan-best'), isNot('—'));
  });
}
