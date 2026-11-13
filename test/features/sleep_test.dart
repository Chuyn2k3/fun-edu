import 'package:flutter/widgets.dart' show Key;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/screen_time/screen_time_service.dart';

import '../voice/fake_speaker.dart';
import 'setup_helpers.dart';
import 'package:funedu/voice/speaker.dart';

const _sleepy = 'Chíp Chíp buồn ngủ rồi. Mai mình học tiếp nhé!';

void main() {
  late AppDatabase db;
  late int kid;
  var now = DateTime(2026, 11, 13, 10);

  FakeSpeaker? speaker;

  Future<void> boot(WidgetTester t, {Duration used = Duration.zero}) async {
    now = DateTime(2026, 11, 13, 10);
    setSize(t, 375, 667);
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    appRouter.go('/');
    await t.runAsync(() async {
      final kids = KidRepository(db);
      kid = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
      await placeKid(db, kid);
      await kids.setSetting('dailyLimitMinutes.$kid', '15');
      await ScreenTimeService(db, kids, now: () => now).addUsage(kid, used);
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          screenTimeClockProvider.overrideWithValue(() => now),
          if (speaker != null) speakerProvider.overrideWithValue(speaker!),
        ],
        child: const App(),
      ),
    );
    await settle(t);
  }

  Future<void> tickAccrual(WidgetTester t, Duration d) async {
    now = now.add(d);
    await t.pump(const Duration(seconds: 15));
    await settle(t);
  }

  testWidgets('limit reached mid-screen waits for the next screen change',
      (t) async {
    await boot(t, used: const Duration(minutes: 14, seconds: 40));
    appRouter.go('/subject/viet');
    await settle(t);
    expect(find.text(_sleepy), findsNothing);

    await tickAccrual(t, const Duration(seconds: 30));
    // Over the limit now, yet the current screen is not interrupted.
    expect(find.text(_sleepy), findsNothing);

    appRouter.go('/subject/toan');
    await settle(t);
    expect(find.text(_sleepy), findsOneWidget);
  });

  testWidgets('parent gate and 15 phút bring the kid back home', (t) async {
    await boot(t, used: const Duration(minutes: 15));
    appRouter.go('/subject/viet');
    await settle(t);
    expect(find.text(_sleepy), findsOneWidget);

    await t.tap(find.text('Ba mẹ'));
    await settle(t);
    await passGate(t);
    expect(find.text('15 phút'), findsOneWidget);
    expect(find.text('30 phút'), findsOneWidget);
    await t.tap(find.text('15 phút'));
    await settle(t);

    expect(find.text(_sleepy), findsNothing);
    expect(find.text('Bài hôm nay'), findsOneWidget);
    expect(
      await t.runAsync(
          () => KidRepository(db).setting('extraMinutes.$kid.2026-11-13')),
      '15',
    );
  });

  Future<Duration> usedBy(WidgetTester t, int id) => t
      .runAsync(() => ScreenTimeService(db, KidRepository(db), now: () => now)
          .usedToday(id))
      .then((v) => v!);

  testWidgets('no usage accrues while the sleep screen is shown', (t) async {
    await boot(t, used: const Duration(minutes: 15));
    appRouter.go('/subject/viet');
    await settle(t);
    expect(find.text(_sleepy), findsOneWidget);
    now = now.add(const Duration(minutes: 10));
    await t.pump(const Duration(minutes: 10));
    await settle(t);
    expect(await usedBy(t, kid), const Duration(minutes: 15));
  });

  testWidgets('switching kid credits the old kid and re-checks the new one',
      (t) async {
    await boot(t);
    late int other;
    await t.runAsync(() async {
      other = await KidRepository(db)
          .addKid(nickname: 'Bo', avatar: kidAvatars[0], age: 6);
      await placeKid(db, other);
      await KidRepository(db).setSetting('dailyLimitMinutes.$other', '15');
      await ScreenTimeService(db, KidRepository(db), now: () => now)
          .addUsage(other, const Duration(minutes: 20));
    });
    appRouter.go('/subject/viet');
    await settle(t);
    now = now.add(const Duration(seconds: 10));
    final container = ProviderScope.containerOf(t.element(find.byType(App)));
    await t.runAsync(() => KidRepository(db).setCurrentKid(other));
    container.invalidate(currentKidIdProvider);
    await settle(t);
    expect(await usedBy(t, kid), const Duration(seconds: 10));
    expect(await usedBy(t, other), const Duration(minutes: 20));
    // The new kid is over the limit: sleep screen without a route change.
    expect(find.text(_sleepy), findsOneWidget);
  });

  testWidgets('system back is handled by the sleep screen', (t) async {
    speaker = FakeSpeaker();
    addTearDown(() => speaker = null);
    await boot(t, used: const Duration(minutes: 15));
    appRouter.go('/subject/viet');
    await settle(t);
    expect(find.text(_sleepy), findsOneWidget);
    final spokenBefore = speaker!.spoken.length;
    expect(speaker!.spoken.last, _sleepy);

    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.text(_sleepy), findsOneWidget);

    await t.tap(find.text('Ba mẹ'));
    await settle(t);
    expect(find.byKey(const Key('parent-gate-question')), findsOneWidget);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.byKey(const Key('parent-gate-question')), findsNothing);
    expect(find.text(_sleepy), findsOneWidget);

    // Nothing else spoke, and the hidden kid stack is still intact.
    expect(speaker!.spoken.length, spokenBefore);
    appRouter.go('/');
    await settle(t);
    expect(find.text(_sleepy), findsOneWidget);
  });

  testWidgets('bedtime offers no extra minutes', (t) async {
    await boot(t);
    await t.runAsync(() async {
      final kids = KidRepository(db);
      await kids.setSetting('bedtimeStart.$kid', '09:00');
      await kids.setSetting('bedtimeEnd.$kid', '11:00');
    });
    appRouter.go('/subject/viet');
    await settle(t);
    await t.tap(find.text('Ba mẹ'));
    await settle(t);
    await passGate(t);
    expect(find.text('15 phút'), findsNothing);
    expect(find.text('Đóng'), findsOneWidget);
  });

  testWidgets('bedtime shows its own line', (t) async {
    await boot(t);
    await t.runAsync(() async {
      final kids = KidRepository(db);
      await kids.setSetting('bedtimeStart.$kid', '09:00');
      await kids.setSetting('bedtimeEnd.$kid', '11:00');
    });
    appRouter.go('/subject/viet');
    await settle(t);
    expect(find.text('Đến giờ đi ngủ rồi. Chúc bé ngủ ngon!'), findsOneWidget);
  });
}
