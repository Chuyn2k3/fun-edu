import 'dart:math';

import '../../explore/geography_level.dart';
import '../../progress/progress_repository.dart';
import '../engine/question_source.dart';
import '../engine/race_question.dart';

/// Steps between two stops on Chíp's trip.
const int tripStepsPerStop = 4;

/// The stops of the trip: the geography landmarks (levels 4–9), in order.
/// Levels 1–3 (scenery, weather, symbols) are not places to visit.
final List<GeoItem> tripStops = [
  for (final level in geographyLevels.skip(3)) ...level.items,
];

/// Length of the whole trip in steps (the last stop is the finish).
int get tripLength => tripStops.length * tripStepsPerStop;

/// Step at which stop [stopIndex] (0-based) is reached.
int tripStopStep(int stopIndex) => (stopIndex + 1) * tripStepsPerStop;

/// A stored step kept on the trip. After a sync the stored counter can be
/// above [tripLength] (two devices' steps added up); never write this back.
int tripClamp(int raw) => raw.clamp(0, tripLength).toInt();

/// Number of postcards earned at [step].
int tripPostcards(int step) => tripClamp(step) ~/ tripStepsPerStop;

/// Stops reached when moving from [from] to [to].
List<GeoItem> tripNewStops(int from, int to) => tripStops
    .sublist(tripPostcards(from), max(tripPostcards(from), tripPostcards(to)));

/// Steps for a right answer: 2 on the first try, 1 after a wrong pick.
int tripStepsFor({required bool firstTry}) => firstTry ? 2 : 1;

/// One move of [steps] from [from] split into hops that end at each stop
/// crossed, so the screen can pause there. Never goes past [tripLength].
List<int> tripHops(int from, int steps) {
  final start = tripClamp(from);
  final int end = min(start + max(steps, 0), tripLength);
  final hops = <int>[];
  var at = start;
  while (at < end) {
    final nextStop = (at ~/ tripStepsPerStop + 1) * tripStepsPerStop;
    final int to = min(nextStop, end);
    hops.add(to - at);
    at = to;
  }
  return hops;
}

/// Ten questions at the kid's levels: math on even slots, Vietnamese on odd
/// ones, never comets.
List<RaceQuestion> buildTripQuestions({
  required int mathLevelIndex,
  required Map<String, GlyphStat> glyphStats,
  required int writingStartIndex,
  required Map<String, String> speechByGlyph,
  required Random rng,
}) {
  List<RaceQuestion> half(RaceSubject s) => buildRaceQuestions(
        subject: s,
        mathLevelIndex: mathLevelIndex,
        glyphStats: glyphStats,
        writingStartIndex: writingStartIndex,
        speechByGlyph: speechByGlyph,
        rng: rng,
        count: 5,
      );
  final math = half(RaceSubject.toan);
  final viet = half(RaceSubject.tiengViet);
  return [
    for (var i = 0; i < 5; i++) ...[
      math[i].withComet(false),
      viet[i].withComet(false),
    ],
  ];
}
