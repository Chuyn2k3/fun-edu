import 'dart:async';

import '../../features/game/race_rival.dart';
import 'room_controller.dart';

/// The friend racing the kid, read from the live room: the best-placed
/// other kid (finished ones by rank, then the most steps).
class OnlineRival implements RaceRival {
  OnlineRival(this._room, RoomState initial) : _view = viewOf(initial);

  final RoomController _room;
  final _changes = StreamController<RivalView>.broadcast();
  RivalView _view;

  static RivalView viewOf(RoomState s) {
    final others = [...s.others]..sort((a, b) {
        final ar = a.rank ?? 99, br = b.rank ?? 99;
        return ar != br ? ar - br : b.steps - a.steps;
      });
    final me = s.me;
    final best = others.firstOrNull;
    return RivalView(
      steps: best?.steps ?? 0,
      name: best?.name ?? '',
      avatar: best?.avatar ?? '',
      rocket: best?.rocket ?? 'rocket_blue',
      beatKid: me != null && me.rank == null && others.any((p) => p.rank != null),
    );
  }

  /// Called by the screen on every room change.
  void update(RoomState s) {
    _view = viewOf(s);
    _changes.add(_view);
  }

  @override
  RivalView get view => _view;

  @override
  Stream<RivalView> get changes => _changes.stream;

  @override
  void kidStepped(int steps) => _room.step(steps);

  @override
  Future<void> leave() => _room.leave();

  Future<void> dispose() => _changes.close();
}
