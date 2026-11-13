import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/home/home_screen.dart';
import 'package:funedu/features/home/kid_switcher.dart';
import 'package:funedu/features/placement/placement_screen.dart';
import 'package:funedu/profile/avatars.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/data/app_database.dart';

import 'setup_helpers.dart';

Future<void> _twoKids(AppDatabase db) async {
  final repo = KidRepository(db);
  final na = await repo.addKid(nickname: 'Na', avatar: kidAvatars[0], age: 5);
  await repo.addKid(nickname: 'Bin', avatar: kidAvatars[1], age: 4);
  await placeKid(db, na);
}

void main() {
  for (final size in const [Size(375, 667), Size(1024, 1366)]) {
    testWidgets('home greets Na; switcher opens without overflow at $size',
        (t) async {
      await pumpRealApp(t, seed: _twoKids, size: size);
      expect(find.text('Chào Na!'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('greeting-pill')));
      await settle(t);
      expect(find.byType(KidSwitcher), findsOneWidget);
      expect(find.text('Na'), findsOneWidget);
      expect(find.text('Bin'), findsOneWidget);
      expect(find.text('Thêm bé'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('switching to an unplaced kid goes to placement', (t) async {
    final db = await pumpRealApp(t, seed: _twoKids);
    await t.tap(find.byKey(const ValueKey('greeting-pill')));
    await settle(t);
    await t.tap(find.text('Bin'));
    await settle(t);
    expect(find.byType(PlacementScreen), findsOneWidget);
    expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
    final repo = KidRepository(db);
    final kids = (await t.runAsync(repo.kids))!;
    expect(await t.runAsync(repo.currentKidId),
        kids.firstWhere((k) => k.nickname == 'Bin').id);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('Thêm bé goes through the gate and adds a profile', (t) async {
    final db = await pumpRealApp(t, seed: _twoKids);
    await t.tap(find.byKey(const ValueKey('greeting-pill')));
    await settle(t);
    await t.tap(find.text('Thêm bé'));
    await settle(t);
    await passGate(t);
    expect(find.text('Tạo hồ sơ cho bé'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Su');
    await t.tap(find.byKey(const ValueKey('avatar-2')));
    await t.pump();
    await t.ensureVisible(find.text('3'));
    await t.tap(find.text('3'));
    await t.pump();
    await t.ensureVisible(find.text('Xong'));
    await t.tap(find.text('Xong'));
    await settle(t);
    expect(find.text('Su'), findsOneWidget);
    expect(find.text('Chào Na!'), findsOneWidget);
    final kids = (await t.runAsync(KidRepository(db).kids))!;
    expect(kids.map((k) => k.nickname), ['Na', 'Bin', 'Su']);
  });

  testWidgets('Thêm bé is disabled at four kids', (t) async {
    await pumpRealApp(t, seed: (db) async {
      await _twoKids(db);
      final repo = KidRepository(db);
      await repo.addKid(nickname: 'C', avatar: kidAvatars[2], age: 3);
      await repo.addKid(nickname: 'D', avatar: kidAvatars[3], age: 3);
    });
    await t.tap(find.byKey(const ValueKey('greeting-pill')));
    await settle(t);
    expect(find.text('Tối đa 4 bé'), findsOneWidget);
    expect(find.text('Thêm bé'), findsNothing);
    final button = t.widget<OutlinedButton>(
        find.byWidgetPredicate((w) => w is OutlinedButton));
    expect(button.onPressed, isNull);
  });
}
