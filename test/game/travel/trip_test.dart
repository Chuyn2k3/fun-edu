import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/engine/race_question.dart';
import 'package:funedu/game/travel/trip.dart';

void main() {
  test('thirty stops from Hồ Gươm to Thác Niagara, four steps apart', () {
    expect(tripStops.length, 30);
    expect(tripStops.first.id, 'ho-guom');
    expect(tripStops.last.id, 'thac-niagara');
    expect(tripLength, 120);
    expect(tripStopStep(0), 4);
    expect(tripStopStep(29), 120);
  });

  test('postcards follow the clamped step', () {
    expect(tripPostcards(0), 0);
    expect(tripPostcards(3), 0);
    expect(tripPostcards(4), 1);
    expect(tripPostcards(119), 29);
    expect(tripPostcards(120), 30);
    expect(tripPostcards(500), 30);
    expect(tripPostcards(-5), 0);
    expect(tripClamp(500), 120);
    expect(tripClamp(-1), 0);
  });

  test('new stops between two steps', () {
    expect(tripNewStops(3, 9).map((s) => s.id), ['ho-guom', 'vinh-ha-long']);
    expect(tripNewStops(120, 130), isEmpty);
  });

  test('steps per answer', () {
    expect(tripStepsFor(firstTry: true), 2);
    expect(tripStepsFor(firstTry: false), 1);
  });

  test('hops split at stops and stop at the end', () {
    expect(tripHops(3, 2), [1, 1]);
    expect(tripHops(0, 2), [2]);
    expect(tripHops(2, 2), [2]);
    expect(tripHops(119, 2), [1]);
    expect(tripHops(120, 2), isEmpty);
  });

  test('ten questions, math on even slots, no comets', () {
    final qs = buildTripQuestions(
      mathLevelIndex: 0,
      glyphStats: const {},
      writingStartIndex: 0,
      speechByGlyph: const {},
      rng: Random(1),
    );
    expect(qs.length, 10);
    for (var i = 0; i < 10; i++) {
      expect(qs[i] is MathRaceQuestion, i.isEven, reason: '$i');
      expect(qs[i].comet, isFalse);
    }
  });
}
