import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/subject/english_map_screen.dart';
import 'package:funedu/features/subject/math_map_screen.dart';
import 'package:funedu/features/subject/vietnamese_map_screen.dart';
import 'package:funedu/features/subject/writing_map_screen.dart';
import 'package:funedu/progress/level_repository.dart';
import 'package:funedu/stroke/glyph.dart';
import 'package:funedu/stroke/glyph_repository.dart';

void main() {
  testWidgets('MathMapScreen never shows CircularProgressIndicator while loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<int>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mathLevelIndexProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: MathMapScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MathMapScreen), findsOneWidget);
  });

  testWidgets(
      'VietnameseMapScreen never shows CircularProgressIndicator while loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<int>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vietnameseLevelIndexProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: VietnameseMapScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(VietnameseMapScreen), findsOneWidget);
  });

  testWidgets(
      'EnglishMapScreen never shows CircularProgressIndicator while loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<int>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          englishLevelIndexProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: EnglishMapScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(EnglishMapScreen), findsOneWidget);
  });

  testWidgets(
      'PracticeScreen never shows CircularProgressIndicator while loading',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completer = Completer<Glyph>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glyphProvider('a').overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: PracticeScreen('a')),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
