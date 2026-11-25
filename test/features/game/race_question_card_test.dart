import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/game/race_question_card.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/math/math_question.dart';

final _q = MathRaceQuestion(
    const ArithmeticQuestion(3, 2, true, [4, 5, 6]), const [4, 5, 6]);

void main() {
  testWidgets('card renders a math question without a race controller',
      (t) async {
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: RaceQuestionCard(question: _q, onListen: () {})),
      ),
    ));
    expect(find.text('3 + 2 = ?'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('listen button calls back', (t) async {
    var heard = 0;
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
            body: RaceQuestionCard(question: _q, onListen: () => heard++)),
      ),
    ));
    await t.tap(find.byKey(const ValueKey('listen')));
    await t.pump();
    expect(heard, 1);
  });

  test('key semantics', () {
    expect(raceKeySemantics(_q, 1), '5');
  });
}
