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
    this.beatKid = false,
  });

  /// Steps of the best-placed other racer (0..10).
  final int steps;
  final String name;

  /// App asset path, or empty.
  final String avatar;
  final String rocket;

  /// Someone else finished before the kid: the kid's race is over.
  final bool beatKid;
}

abstract class RaceRival {
  RivalView get view;
  Stream<RivalView> get changes;

  /// The kid's rocket climbed to [steps].
  void kidStepped(int steps);

  /// The kid left the race (pause menu, back).
  Future<void> leave();
}
