// Shot harness for Toán nâng cao (so-100, dong-ho, tien). Usage:
//   mkdir -p test/_shot && cp tools/shot/math_adv_shot_test.dart test/_shot/
//   flutter test test/_shot/math_adv_shot_test.dart --update-goldens; rm -rf test/_shot
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/data/app_database.dart';
import 'package:funedu/features/math/math_session_screen.dart';
import 'package:funedu/math/math_level.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/ui/theme/app_theme.dart';

void main() {
  for (final id in ['so-100', 'dong-ho', 'tien']) {
    testWidgets('shot $id', (t) async {
      await t.runAsync(() async {
        final loader = FontLoader('Nunito');
        for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
          loader.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
        }
        await loader.load();
      });
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      final db = AppDatabase(NativeDatabase.memory());
      await t.pumpWidget(ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), currentKidIdProvider.overrideWith((ref) async => 1)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: MathSessionScreen(
              level: mathLevels.firstWhere((l) => l.id == id), step: 1, totalSteps: 4,
              random: Random(id == 'tien' ? 4 : 2), onCompleted: (_, __) {}),
        ),
      ));
      for (var i = 0; i < 5; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await t.pump();
      }
      await expectLater(find.byType(MathSessionScreen), matchesGoldenFile('goldens/$id.png'));
      await db.close();
    });
  }
}
