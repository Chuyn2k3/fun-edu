import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/parent/parent_unlock.dart';
import 'package:funedu/parent/screens/parent_home.dart';
import 'package:funedu/parent/screens/privacy_screen.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/rewards/reward_repository.dart';
import 'package:funedu/screen_time/screen_time_service.dart';
import 'package:funedu/voice/speaker.dart';
import 'package:go_router/go_router.dart';

import '../features/setup_helpers.dart';

late AppDatabase db;
late int na;
late int bo;

Future<void> _pumpParent(WidgetTester t, {Size? size}) async {
  setSize(t, size?.width ?? 375, size?.height ?? 667);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const Text('trang chủ')),
    GoRoute(path: '/setup', builder: (_, __) => const Text('thiết lập')),
    GoRoute(path: '/parent', builder: (_, __) => const ParentHome()),
  ], initialLocation: '/parent');
  await t.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      parentUnlockedUntilProvider
          .overrideWith((ref) => DateTime.now().add(parentUnlockDuration)),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await settle(t);
}

Future<void> _openTab(WidgetTester t, String label) async {
  await t.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  ));
  await settle(t);
}

ProviderContainer _container(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(ParentHome)));

void main() {
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final kids = KidRepository(db);
    na = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
    bo = await kids.addKid(nickname: 'Bo', avatar: kidAvatars[1], age: 6);
  });
  tearDown(() => db.close());

  group('KidsTab', () {
    testWidgets('lists kids with age, edit and delete', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Hồ sơ');
      expect(find.text('Na'), findsWidgets);
      expect(find.text('5 tuổi'), findsOneWidget);
      expect(find.text('6 tuổi'), findsOneWidget);
      expect(find.text('Thêm bé'), findsOneWidget);
    });

    testWidgets('adds a kid', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Hồ sơ');
      await t.tap(find.text('Thêm bé'));
      await settle(t);
      await t.enterText(find.byType(TextField), 'Mít');
      await t.ensureVisible(find.byKey(const ValueKey('avatar-2')));
      await t.tap(find.byKey(const ValueKey('avatar-2')));
      await t.ensureVisible(find.text('4'));
      await t.tap(find.text('4'));
      await t.pump();
      await t.ensureVisible(find.text('Xong'));
      await t.tap(find.text('Xong'));
      await settle(t);
      final kids = await t.runAsync(() => KidRepository(db).kids());
      expect(kids!.map((k) => k.nickname), ['Na', 'Bo', 'Mít']);
      expect(find.text('4 tuổi'), findsOneWidget);
    });

    testWidgets('edits a kid with the form prefilled', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Hồ sơ');
      await t.tap(find.byKey(ValueKey('edit-$bo')));
      await settle(t);
      expect(find.text('Sửa hồ sơ'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Bo'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Bơ');
      await t.ensureVisible(find.text('Xong'));
      await t.tap(find.text('Xong'));
      await settle(t);
      final kid = (await t.runAsync(() => KidRepository(db).kids()))!.last;
      expect((kid.nickname, kid.avatar, kid.age), ('Bơ', kidAvatars[1], 6));
      expect(find.text('Bơ'), findsWidgets);
    });

    testWidgets('delete asks first, then removes the kid', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Hồ sơ');
      await t.tap(find.byKey(ValueKey('delete-$bo')));
      await settle(t);
      expect(find.text('Xóa hồ sơ Bo? Toàn bộ tiến độ của bé sẽ mất.'),
          findsOneWidget);
      await t.tap(find.text('Hủy'));
      await settle(t);
      expect(await t.runAsync(() => KidRepository(db).kids()), hasLength(2));
      await t.tap(find.byKey(ValueKey('delete-$bo')));
      await settle(t);
      await t.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Xóa')));
      await settle(t);
      final kids = await t.runAsync(() => KidRepository(db).kids());
      expect(kids!.map((k) => k.nickname), ['Na']);
    });

    testWidgets('deleting the last kid goes to setup', (t) async {
      await _pumpParent(t);
      await t.runAsync(() => KidRepository(db).deleteKid(bo));
      _container(t).invalidate(kidsProvider);
      await settle(t);
      await _openTab(t, 'Hồ sơ');
      await t.tap(find.byKey(ValueKey('delete-$na')));
      await settle(t);
      await t.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Xóa')));
      await settle(t);
      expect(find.text('thiết lập'), findsOneWidget);
    });

    testWidgets('four kids disable adding', (t) async {
      final kids = KidRepository(db);
      await kids.addKid(nickname: 'C', avatar: kidAvatars[2], age: 5);
      await kids.addKid(nickname: 'D', avatar: kidAvatars[3], age: 5);
      await _pumpParent(t);
      await _openTab(t, 'Hồ sơ');
      expect(find.text('Tối đa 4 bé'), findsOneWidget);
      expect(find.text('Thêm bé'), findsNothing);
      final button = t.widget<OutlinedButton>(
          find.byWidgetPredicate((w) => w is OutlinedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('TimeTab', () {
    testWidgets('changing the limit to 60 reaches ScreenTimeService',
        (t) async {
      await ScreenTimeService(db, KidRepository(db))
          .addUsage(na, const Duration(minutes: 7));
      await _pumpParent(t);
      await _openTab(t, 'Thời gian');
      expect(find.text('45 phút'), findsOneWidget);
      expect(find.text('Hôm nay đã dùng 7 phút'), findsOneWidget);
      final handle = t.ensureSemantics();
      final node = t.getSemantics(find.byType(Slider));
      t.binding.renderViews.first.owner!.semanticsOwner!
          .performAction(node.id, SemanticsAction.increase);
      await settle(t);
      handle.dispose();
      expect(find.text('60 phút'), findsOneWidget);
      final service = ScreenTimeService(db, KidRepository(db));
      expect(await t.runAsync(() => service.dailyLimitMinutes(na)), 60);
      expect(await t.runAsync(() => service.dailyLimitMinutes(bo)), 45);
    });

    testWidgets('the slider snaps to 15 minutes in 15..180', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Thời gian');
      final s = t.widget<Slider>(find.byType(Slider));
      expect((s.min, s.max, s.divisions), (15, 180, 11));
    });

    testWidgets('bedtime toggles on with Bắt đầu / Kết thúc and off again',
        (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Thời gian');
      expect(find.text('Bắt đầu'), findsNothing);
      await t.tap(find.byType(Switch));
      await settle(t);
      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.text('Kết thúc'), findsOneWidget);
      final kids = KidRepository(db);
      expect(await t.runAsync(() => kids.setting(bedtimeStartKey(na))),
          '20:30');
      expect(await t.runAsync(() => kids.setting(bedtimeEndKey(na))), '06:30');
      // Pick a new start time: the dial opens in 24h format; OK keeps it.
      await t.tap(find.text('20:30'));
      await settle(t);
      expect(find.text('Xong'), findsOneWidget);
      await t.tap(find.text('Xong'));
      await settle(t);
      expect(find.text('20:30'), findsOneWidget);
      await t.tap(find.byType(Switch));
      await settle(t);
      expect(find.text('Bắt đầu'), findsNothing);
      expect(await t.runAsync(() => kids.setting(bedtimeStartKey(na))), isNull);
    });
  });

  group('RewardsTab', () {
    testWidgets('a reward with enough stars can be given, stars stay',
        (t) async {
      await db.into(db.lessonCompletions).insert(
            LessonCompletionsCompanion.insert(
              kidId: na,
              completedAt: DateTime.now(),
              starsEarned: 12,
            ),
          );
      await _pumpParent(t);
      await _openTab(t, 'Phần thưởng');
      await t.enterText(find.byType(TextField), 'Đi công viên');
      await t.pump();
      await t.ensureVisible(find.text('Thêm phần thưởng'));
      await t.tap(find.text('Thêm phần thưởng'));
      await settle(t);
      expect(find.text('Đi công viên'), findsOneWidget);
      expect(find.text('12/10 sao'), findsOneWidget);
      final give = find.widgetWithText(FilledButton, 'Đã thưởng');
      expect(t.widget<FilledButton>(give).onPressed, isNotNull);
      await t.ensureVisible(give);
      await t.tap(give);
      await settle(t);
      expect(find.widgetWithText(FilledButton, 'Đã thưởng'), findsNothing);
      expect(find.text('Đã thưởng'), findsOneWidget); // section heading
      expect(find.text('Đi công viên'), findsOneWidget);
      final r = RewardRepository(db);
      expect((await t.runAsync(() => r.list(na)))!.single.redeemedAt,
          isNotNull);
      expect(await t.runAsync(() => r.totalStars(na)), 12);
    });

    testWidgets('not enough stars keeps the button off', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Phần thưởng');
      expect(find.text('Ví dụ: Đi công viên'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Ăn kem');
      await t.pump();
      await t.ensureVisible(find.text('Thêm phần thưởng'));
      await t.tap(find.text('Thêm phần thưởng'));
      await settle(t);
      expect(find.text('0/10 sao'), findsOneWidget);
      final give = find.widgetWithText(FilledButton, 'Đã thưởng');
      expect(t.widget<FilledButton>(give).onPressed, isNull);
    });
  });

  group('SettingsTab', () {
    testWidgets('turning Giọng đọc off silences the speaker', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Cài đặt');
      expect(_container(t).read(speakerProvider), isNot(isA<SilentSpeaker>()));
      await t.tap(find.byType(Switch));
      await settle(t);
      expect(await t.runAsync(() => KidRepository(db).setting('voiceEnabled')),
          'false');
      expect(_container(t).read(speakerProvider), isA<SilentSpeaker>());
    });

    testWidgets('redo placement clears only the selected kid', (t) async {
      await placeKid(db, na);
      await placeKid(db, bo);
      await _pumpParent(t);
      await _openTab(t, 'Cài đặt');
      await t.tap(find.text('Bo'));
      await settle(t);
      await t.tap(find.text('Làm lại bài xếp cấp cho Bo'));
      await settle(t);
      expect(await t.runAsync(() => LevelRepository(db, kidId: bo).isPlaced()),
          isFalse);
      expect(await t.runAsync(() => LevelRepository(db, kidId: na).isPlaced()),
          isTrue);
    });

    testWidgets('privacy policy opens', (t) async {
      await _pumpParent(t);
      await _openTab(t, 'Cài đặt');
      await t.tap(find.text('Chính sách quyền riêng tư'));
      await settle(t);
      expect(find.byType(PrivacyScreen), findsOneWidget);
    });

    testWidgets('delete everything needs XÓA typed exactly', (t) async {
      await pumpRealApp(t, seed: (db) async {
        final id = await KidRepository(db)
            .addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
        await placeKid(db, id);
      });
      await t.tap(find.bySemanticsLabel('Góc ba mẹ'));
      await settle(t);
      await passGate(t);
      await _openTab(t, 'Cài đặt');
      await t.tap(find.text('Xóa toàn bộ dữ liệu'));
      await settle(t);
      FilledButton confirm() => t.widget<FilledButton>(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Xóa hết')));
      expect(confirm().onPressed, isNull);
      await t.enterText(find.byType(TextField), 'xóa');
      await t.pump();
      expect(confirm().onPressed, isNull);
      await t.enterText(find.byType(TextField), 'XÓA');
      await t.pump();
      expect(confirm().onPressed, isNotNull);
      await t.tap(find.widgetWithText(FilledButton, 'Xóa hết'));
      await settle(t);
      // The fresh-install flow starts with the parent gate, then consent.
      expect(find.text('Dành cho ba mẹ'), findsOneWidget);
      await t.tap(find.text('Tôi là ba mẹ'));
      await settle(t);
      await passGate(t);
      expect(find.text('Chào ba mẹ!'), findsOneWidget);
    });
  });

  testWidgets('home shows the pending reward pill', (t) async {
    await db.into(db.lessonCompletions).insert(
          LessonCompletionsCompanion.insert(
            kidId: na,
            completedAt: DateTime.now(),
            starsEarned: 4,
          ),
        );
    await RewardRepository(db).add(na, 'Đi công viên', 10);
    setSize(t, 375, 667);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ]);
    await t.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await settle(t);
    expect(find.text('4/10 sao: Đi công viên'), findsOneWidget);
  });

  testWidgets('privacy policy has its sections and contact placeholder',
      (t) async {
    setSize(t, 375, 667);
    await t.pumpWidget(const MaterialApp(home: PrivacyScreen()));
    for (final s in [
      'Chúng tôi thu thập gì',
      'Dữ liệu lưu ở đâu',
      'Chúng tôi không làm gì',
      'Quyền của ba mẹ',
      'Căn cứ pháp lý',
      'Liên hệ',
    ]) {
      await t.scrollUntilVisible(find.text(s), 200);
      expect(find.text(s), findsOneWidget);
    }
    await t.scrollUntilVisible(find.textContaining('[EMAIL LIÊN HỆ]'), 200);
    expect(find.textContaining('[EMAIL LIÊN HỆ]'), findsOneWidget);
    expect(find.textContaining('Nghị định 13/2023/NĐ-CP'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets('no overflow on any tab at $size', (t) async {
      await RewardRepository(db).add(na, 'Một phần thưởng có tên rất dài, dài lắm', 50);
      await _pumpParent(t, size: size);
      for (final tab in ['Hồ sơ', 'Thời gian', 'Phần thưởng', 'Cài đặt']) {
        await _openTab(t, tab);
        expect(t.takeException(), isNull, reason: tab);
      }
      await _openTab(t, 'Thời gian');
      await t.tap(find.byType(Switch));
      await settle(t);
      expect(t.takeException(), isNull);
    });
  }
}
