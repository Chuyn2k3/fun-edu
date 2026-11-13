import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/parent/parent_gate.dart';
import 'package:funedu/parent/parent_gate_route.dart';
import 'package:funedu/ui/widgets/primary_button.dart';
import 'package:funedu/voice/voice_lines.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

String _questionText(WidgetTester tester) {
  final text =
      tester.widget<Text>(find.byKey(const Key('parent-gate-question')));
  return text.data!;
}

/// Parses "Nhập kết quả: {a} nhân {b}" back into the product.
int _answerOf(String question) {
  final body = question.substring('Nhập kết quả: '.length);
  final parts = body.split(' nhân ');
  int num(String w) => [for (var n = 3; n <= 9; n++) n]
      .firstWhere((n) => numberToVietnamese(n) == w);
  return num(parts[0]) * num(parts[1]);
}

/// Phone-sized surface so the whole gate is on screen.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _type(WidgetTester tester, int value) async {
  for (final d in value.toString().split('')) {
    await tester.tap(find.byKey(Key('gate-key-$d')));
    await tester.pump();
  }
}

void main() {
  testWidgets('shows title, word-only question and keypad', (tester) async {
    _phone(tester);
    await tester
        .pumpWidget(_wrap(ParentGate(onPassed: () {}, random: Random(1))));
    expect(find.text('Dành cho ba mẹ'), findsOneWidget);
    final q = _questionText(tester);
    expect(q, startsWith('Nhập kết quả: '));
    expect(q, contains(' nhân '));
    expect(RegExp(r'\d').hasMatch(q), isFalse);
    for (var d = 0; d <= 9; d++) {
      expect(find.byKey(Key('gate-key-$d')), findsOneWidget);
    }
    expect(find.text('Xóa'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
  });

  testWidgets('correct answer calls onPassed once', (tester) async {
    _phone(tester);
    var passed = 0;
    await tester.pumpWidget(
        _wrap(ParentGate(onPassed: () => passed++, random: Random(1))));
    await _type(tester, _answerOf(_questionText(tester)));
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(passed, 1);
  });

  testWidgets('at 320x568 Xác nhận is tappable without scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var passed = 0;
    await tester.pumpWidget(
        _wrap(ParentGate(onPassed: () => passed++, random: Random(1))));
    await _type(tester, _answerOf(_questionText(tester)));
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(passed, 1);
  });

  testWidgets('double tap on Xác nhận after a correct answer fires once',
      (tester) async {
    _phone(tester);
    var passed = 0;
    await tester.pumpWidget(
        _wrap(ParentGate(onPassed: () => passed++, random: Random(1))));
    await _type(tester, _answerOf(_questionText(tester)));
    await tester.tap(find.text('Xác nhận'));
    await tester.tap(find.text('Xác nhận'), warnIfMissed: false);
    await tester.pump();
    expect(passed, 1);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull);
  });

  testWidgets('wrong answer shows error and changes the question',
      (tester) async {
    _phone(tester);
    var passed = 0;
    await tester.pumpWidget(
        _wrap(ParentGate(onPassed: () => passed++, random: Random(1))));
    final before = _questionText(tester);
    await _type(tester, _answerOf(before) + 1);
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(passed, 0);
    expect(find.text('Chưa đúng, thử lại nhé'), findsOneWidget);
    expect(_questionText(tester), isNot(before));
    expect(find.byKey(const Key('parent-gate-input')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('parent-gate-input'))).data,
        isNot(contains(RegExp(r'\d'))));
  });

  testWidgets(
      'Xóa deletes last digit, input capped at 3, confirm disabled '
      'when empty', (tester) async {
    _phone(tester);
    await tester
        .pumpWidget(_wrap(ParentGate(onPassed: () {}, random: Random(1))));
    String input() =>
        tester.widget<Text>(find.byKey(const Key('parent-gate-input'))).data!;
    PrimaryButton confirm() =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(confirm().onPressed, isNull);
    await tester.tap(find.text('Xác nhận'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Chưa đúng, thử lại nhé'), findsNothing);
    for (final d in ['1', '2', '3', '4']) {
      await tester.tap(find.byKey(Key('gate-key-$d')));
      await tester.pump();
    }
    expect(input(), '123');
    await tester.tap(find.text('Xóa'));
    await tester.pump();
    expect(input(), '12');
  });

  testWidgets('Đóng calls onCancel', (tester) async {
    _phone(tester);
    var cancelled = 0;
    await tester.pumpWidget(_wrap(ParentGate(
        onPassed: () {}, onCancel: () => cancelled++, random: Random(1))));
    await tester.tap(find.text('Đóng'));
    await tester.pump();
    expect(cancelled, 1);
  });

  group('showParentGate', () {
    Future<void> open(
        WidgetTester tester, void Function(Future<bool>) onF) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          ctx = c;
          return const Scaffold();
        }),
      ));
      onF(showParentGate(ctx));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('returns false on Đóng', (tester) async {
      _phone(tester);
      Future<bool>? f;
      await open(tester, (x) => f = x);
      await tester.tap(find.text('Đóng'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(await f, isFalse);
      expect(find.text('Dành cho ba mẹ'), findsNothing);
    });

    testWidgets('returns false on system back', (tester) async {
      _phone(tester);
      Future<bool>? f;
      await open(tester, (x) => f = x);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(await f, isFalse);
    });

    testWidgets('double tap on pass pops only the gate route', (tester) async {
      Future<bool>? f;
      await open(tester, (x) => f = x);
      await _type(tester, _answerOf(_questionText(tester)));
      await tester.tap(find.text('Xác nhận'));
      await tester.tap(find.text('Xác nhận'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(await f, isTrue);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Dành cho ba mẹ'), findsNothing);
    });

    testWidgets('Đóng right after a correct answer does not pop again',
        (tester) async {
      Future<bool>? f;
      await open(tester, (x) => f = x);
      await _type(tester, _answerOf(_questionText(tester)));
      await tester.tap(find.text('Xác nhận'));
      await tester.tap(find.text('Đóng'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(await f, isTrue);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Dành cho ba mẹ'), findsNothing);
    });

    testWidgets('returns true after correct answer', (tester) async {
      _phone(tester);
      Future<bool>? f;
      await open(tester, (x) => f = x);
      await _type(tester, _answerOf(_questionText(tester)));
      await tester.tap(find.text('Xác nhận'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(await f, isTrue);
      expect(find.text('Dành cho ba mẹ'), findsNothing);
    });
  });
}
