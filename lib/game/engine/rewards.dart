import 'race.dart';

/// Cosmic stars for one finished race: win 5 / lose 3, +1 per comet answered
/// correctly on the first try, +2 for beating the kid's own best time.
int cosmicStarsFor(RaceOutcome o, {required bool beatRecord}) =>
    (o.won ? 5 : 3) + o.cometsFirstTry + (beatRecord ? 2 : 0);

/// Cosmic stars for a race with friends: everyone who races earns stars.
/// 1st 7, 2nd 5, 3rd/4th 4, not finished 3; +1 per first-try comet.
int onlineCosmicStarsFor(RaceOutcome o, {required int? rank}) =>
    switch (rank) {
      1 => 7,
      2 => 5,
      null => 3,
      _ => 4,
    } +
    o.cometsFirstTry;
