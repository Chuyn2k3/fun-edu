import 'dart:async';

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
  });

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
}

abstract class RaceRival {
  RivalView get view;
  Stream<RivalView> get changes;

  /// The kid's rocket climbed to [steps].
  void kidStepped(int steps);

  /// The kid left the race (pause menu, back).
  Future<void> leave();
}
