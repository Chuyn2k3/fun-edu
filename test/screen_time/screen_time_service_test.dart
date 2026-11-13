import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/screen_time/screen_time_service.dart';

void main() {
  late AppDatabase db;
  late KidRepository kids;
  late ScreenTimeService service;
  late int kid;
  var now = DateTime(2026, 11, 13, 10);

  setUp(() async {
    now = DateTime(2026, 11, 13, 10);
    db = AppDatabase(NativeDatabase.memory());
    kids = KidRepository(db);
    service = ScreenTimeService(db, kids, now: () => now);
    kid = await kids.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
  });
  tearDown(() => db.close());

  test('44 minutes is ok, 45 minutes reaches the default limit', () async {
    await service.addUsage(kid, const Duration(minutes: 44));
    expect(await service.status(kid), ScreenTimeStatus.ok);
    await service.addUsage(kid, const Duration(minutes: 1));
    expect(await service.usedToday(kid), const Duration(minutes: 45));
    expect(await service.status(kid), ScreenTimeStatus.limitReached);
  });

  test('usage adds up across calls and a new day starts fresh', () async {
    await service.addUsage(kid, const Duration(minutes: 30));
    await service.addUsage(kid, const Duration(minutes: 20));
    expect(await service.status(kid), ScreenTimeStatus.limitReached);
    now = DateTime(2026, 11, 14, 8);
    expect(await service.usedToday(kid), Duration.zero);
    expect(await service.status(kid), ScreenTimeStatus.ok);
  });

  test('usage of one kid does not count for another', () async {
    final other =
        await kids.addKid(nickname: 'Bo', avatar: kidAvatars[0], age: 6);
    await service.addUsage(kid, const Duration(minutes: 50));
    expect(await service.status(other), ScreenTimeStatus.ok);
  });

  test('the limit is read per kid', () async {
    await kids.setSetting('dailyLimitMinutes.$kid', '15');
    await service.addUsage(kid, const Duration(minutes: 15));
    expect(await service.status(kid), ScreenTimeStatus.limitReached);
  });

  test('granting extra minutes lifts the limit until 60', () async {
    await service.addUsage(kid, const Duration(minutes: 45));
    await service.grantExtra(kid, 15);
    expect(await kids.setting('extraMinutes.$kid.2026-11-13'), '15');
    expect(await service.status(kid), ScreenTimeStatus.ok);
    await service.addUsage(kid, const Duration(minutes: 14));
    expect(await service.status(kid), ScreenTimeStatus.ok);
    await service.addUsage(kid, const Duration(minutes: 1));
    expect(await service.status(kid), ScreenTimeStatus.limitReached);
    await service.grantExtra(kid, 30);
    expect(await kids.setting('extraMinutes.$kid.2026-11-13'), '45');
    expect(await service.status(kid), ScreenTimeStatus.ok);
  });

  test('extra minutes apply to that day only', () async {
    await service.grantExtra(kid, 15);
    now = DateTime(2026, 11, 14, 10);
    await service.addUsage(kid, const Duration(minutes: 45));
    expect(await service.status(kid), ScreenTimeStatus.limitReached);
  });

  group('bedtime 20:30-06:00', () {
    setUp(() async {
      await kids.setSetting('bedtimeStart.$kid', '20:30');
      await kids.setSetting('bedtimeEnd.$kid', '06:00');
    });

    Future<ScreenTimeStatus> at(int h, int m) {
      now = DateTime(2026, 11, 13, h, m);
      return service.status(kid);
    }

    test('21:00 and 05:59 are bedtime', () async {
      expect(await at(21, 0), ScreenTimeStatus.bedtime);
      expect(await at(5, 59), ScreenTimeStatus.bedtime);
      expect(await at(20, 30), ScreenTimeStatus.bedtime);
    });

    test('06:00 and 12:00 are ok', () async {
      expect(await at(6, 0), ScreenTimeStatus.ok);
      expect(await at(12, 0), ScreenTimeStatus.ok);
      expect(await at(20, 29), ScreenTimeStatus.ok);
    });
  });

  test('a same-day bedtime window works too', () async {
    await kids.setSetting('bedtimeStart.$kid', '13:00');
    await kids.setSetting('bedtimeEnd.$kid', '14:00');
    now = DateTime(2026, 11, 13, 13, 30);
    expect(await service.status(kid), ScreenTimeStatus.bedtime);
    now = DateTime(2026, 11, 13, 14, 0);
    expect(await service.status(kid), ScreenTimeStatus.ok);
  });
}
