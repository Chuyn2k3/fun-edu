import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/math/exercise/choice_answers.dart';
import 'package:funedu/features/math/exercise/compare_groups.dart';
import 'package:funedu/features/math/exercise/drag_number_match.dart';
import 'package:funedu/features/math/exercise/object_grid.dart';
import 'package:funedu/features/math/exercise/tap_count_board.dart';
import 'package:funedu/math/math_question.dart';
import 'package:funedu/ui/theme/tokens.dart';

Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('ChoiceAnswers', () {
    testWidgets('correct tap reports true once, even when tapped twice',
        (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(host(ChoiceAnswers(
          choices: const [2, 3, 4], answer: 3, onAnswered: log.add)));
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(log, [true]);
    });

    testWidgets('wrong then correct reports [false, true]; wrong only once',
        (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(host(ChoiceAnswers(
          choices: const [2, 3, 4], answer: 3, onAnswered: log.add)));
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(log, [false, true]);
    });

    testWidgets('resets when rebuilt with another question', (tester) async {
      final log = <bool>[];
      Widget w(int a) => host(ChoiceAnswers(
          choices: const [2, 3, 4], answer: a, onAnswered: log.add));
      await tester.pumpWidget(w(3));
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.pumpWidget(w(4));
      await tester.tap(find.text('4'));
      await tester.pump();
      expect(log, [true, true]);
    });
  });

  testWidgets('ObjectGrid lays out at most 5 per row, cells >= 56',
      (tester) async {
    await tester.pumpWidget(host(const ObjectGrid(count: 7)));
    expect(find.byType(Image), findsNWidgets(7));
    final first = tester.getTopLeft(find.byType(Image).first);
    final sixth = tester.getTopLeft(find.byType(Image).at(5));
    expect(sixth.dy, greaterThan(first.dy));
    expect(tester.getSize(find.byType(Image).first).width + 8,
        greaterThanOrEqualTo(56));
  });

  testWidgets('TapCountBoard shows order numbers on tapped objects',
      (tester) async {
    final log = <bool>[];
    await tester.pumpWidget(host(TapCountBoard(
        q: const CountQuestion(4, [3, 4, 5]), onAnswered: log.add)));
    final images = find.byType(Image);
    for (var i = 0; i < 3; i++) {
      await tester.tap(images.at(i));
      await tester.pump();
    }
    // Choice buttons show 3 and 5 as well, so look for numbers in circles.
    final circles = find.byKey(const ValueKey('count-badge'));
    expect(circles, findsNWidgets(3));
    expect(find.descendant(of: circles.at(0), matching: find.text('1')),
        findsOneWidget);
    expect(find.descendant(of: circles.at(2), matching: find.text('3')),
        findsOneWidget);
    // Re-tapping a marked object does not add a number.
    await tester.tap(images.at(0));
    await tester.pump();
    expect(circles, findsNWidgets(3));
  });

  group('CompareGroups', () {
    testWidgets('tapping the side with more is true for ask more',
        (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(host(CompareGroups(
          q: const CompareQuestion(2, 5, CompareAsk.more),
          onAnswered: log.add)));
      await tester.tap(find.byKey(const ValueKey('compare-right')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('compare-left')));
      await tester.pump();
      expect(log, [true]);
    });

    testWidgets('wrong side is false', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(host(CompareGroups(
          q: const CompareQuestion(2, 5, CompareAsk.less),
          onAnswered: log.add)));
      await tester.tap(find.byKey(const ValueKey('compare-right')));
      await tester.pump();
      expect(log, [false]);
    });
  });

  group('DragNumberMatch', () {
    testWidgets('dragging the right tile into the slot is true',
        (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(host(DragNumberMatch(
          q: const MatchQuestion(3, [2, 3, 4]), onAnswered: log.add)));
      final tile = find.byKey(const ValueKey('match-tile-3'));
      final slot = tester.getCenter(find.byKey(const ValueKey('match-slot')));
      final g = await tester.startGesture(tester.getCenter(tile));
      await g.moveTo(slot);
      await g.up();
      await tester.pump();
      expect(log, [true]);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('match-slot')),
              matching: find.text('3')),
          findsOneWidget);
    });

    testWidgets('tapping a wrong tile is false and locks', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(host(DragNumberMatch(
          q: const MatchQuestion(3, [2, 3, 4]), onAnswered: log.add)));
      await tester.tap(find.byKey(const ValueKey('match-tile-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('match-tile-3')));
      await tester.pump();
      expect(log, [false]);
    });

    testWidgets('tapping the right tile is true', (tester) async {
      final log = <bool>[];
      await tester.pumpWidget(host(DragNumberMatch(
          q: const MatchQuestion(3, [2, 3, 4]), onAnswered: log.add)));
      await tester.tap(find.byKey(const ValueKey('match-tile-3')));
      await tester.pump();
      expect(log, [true]);
    });
  });

  test('tokens sanity', () => expect(AppColors.accent, isNotNull));
}
