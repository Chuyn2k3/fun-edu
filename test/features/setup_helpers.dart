import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/router.dart';
import 'package:funedu/voice/voice_lines.dart';

void setSize(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// Drift needs the real event loop; fake-zone continuations need pumps.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump();
  }
  await t.pumpAndSettle();
}

/// Boots the real [App] on an in-memory database; [seed] runs before launch.
Future<AppDatabase> pumpRealApp(
  WidgetTester t, {
  Future<void> Function(AppDatabase db)? seed,
  Size size = const Size(375, 667),
}) async {
  setSize(t, size.width, size.height);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  appRouter.go('/');
  if (seed != null) await t.runAsync(() => seed(db));
  await t.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const App(),
    ),
  );
  await settle(t);
  return db;
}

Future<void> placeKid(AppDatabase db, int kidId) async {
  final r = LevelRepository(db, kidId: kidId);
  await r.setLevel('viet', 0);
  await r.setLevel('toan', 0);
}

/// Reads the parent gate's word question and types the right answer.
Future<void> passGate(WidgetTester t) async {
  final q = t
      .widget<Text>(find.byKey(const Key('parent-gate-question')))
      .data!
      .substring('Nhập kết quả: '.length);
  int num(String w) => [for (var n = 3; n <= 9; n++) n]
      .firstWhere((n) => numberToVietnamese(n) == w);
  final parts = q.split(' nhân ');
  final answer = num(parts[0]) * num(parts[1]);
  for (final d in '$answer'.split('')) {
    await t.tap(find.byKey(Key('gate-key-$d')));
    await t.pump();
  }
  await t.tap(find.text('Xác nhận'));
  await settle(t);
}
