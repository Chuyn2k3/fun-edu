import 'dart:async';

/// One racer in an online room, for the standings strip.
class RacerStanding {
  const RacerStanding({
    required this.name,
    required this.avatar,
    required this.steps,
    this.rank,
    this.isYou = false,
    this.connected = true,
    this.away = false,
    this.left = false,
  });

  final String name;
  final String avatar;
  final int steps;
  final int? rank;
  final bool isYou;
  final bool connected;
  final bool away;
  final bool left;
}

/// The rocket racing the kid when it is not Chíp: a friend in an online
/// room. The race screen and controller only see this interface; the
/// network side lives in `lib/online/room/`.
class RivalView {
  const RivalView({
    required this.steps,
    required this.name,
    required this.avatar,
    required this.rocket,
    this.myRank,
    this.roomOver = false,
    this.players = 2,
    this.standings = const [],
    this.rivalAway = false,
    this.endReason,
    this.networkLost = false,
  });

  /// Everyone in the room (the kid included), in room order.
  final List<RacerStanding> standings;

  /// Steps of the best-placed other racer (0..10).
  final int steps;
  final String name;

  /// App asset path, or empty.
  final String avatar;
  final String rocket;

  /// The kid's finish position once the room has given it.
  final int? myRank;

  /// The room ended (everyone in, time up) while the kid was still flying:
  /// the kid's race is over where they stand.
  final bool roomOver;

  /// Kids who started the race (for the "Cuộc Đua Lớn" badge).
  final int players;

  /// True when the leading rival is temporarily disconnected within grace.
  final bool rivalAway;

  /// Room completion reason (e.g. `'others_left'`), or null.
  final String? endReason;

  /// True when the local player dropped past the 20 s reconnect limit.
  final bool networkLost;
}

abstract class RaceRival {
  RivalView get view;
  Stream<RivalView> get changes;

  /// The kid's rocket climbed to [steps].
  void kidStepped(int steps);

  /// The kid left the race (pause menu, back).
  Future<void> leave();
}
