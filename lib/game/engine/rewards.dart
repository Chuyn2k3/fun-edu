import 'race.dart';

/// Cosmic stars for one finished race: win 5 / lose 3, +1 per comet answered
/// correctly on the first try, +2 for beating the kid's own best time.
int cosmicStarsFor(RaceOutcome o, {required bool beatRecord}) =>
    (o.won ? 5 : 3) + o.cometsFirstTry + (beatRecord ? 2 : 0);
