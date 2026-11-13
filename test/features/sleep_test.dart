import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/screen_time/screen_time_service.dart';

import 'setup_helpers.dart';

const _sleepy = 'Chíp Chíp buồn ngủ rồi. Mai mình học tiếp nhé!';

void main() {
  late AppDatabase db;
  late int kid;
  var now = DateTime(2026, 11, 13, 10);

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
