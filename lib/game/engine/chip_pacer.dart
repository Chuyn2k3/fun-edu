/// Decides when Chíp advances: every 1.25 x (mean kid answer time) x slowdown,
/// never more than 2 steps ahead of the kid. Pure; time is passed in.
class ChipPacer {
  ChipPacer({
    this.initialMean = const Duration(milliseconds: 6000),
    this.slowdown = 1.0,
  });

  final Duration initialMean;
  final double slowdown;

  int _answers = 0;
  int _totalMicros = 0;
  Duration _lastStepAt = Duration.zero;

  Duration get mean => _answers == 0
      ? initialMean
      : Duration(microseconds: (_totalMicros / _answers).round());

  Duration get interval =>
      Duration(microseconds: (mean.inMicroseconds * 1.25 * slowdown).round());

  /// Records how long the kid took to answer one question correctly.
  void recordAnswer(Duration elapsed) {
    _answers++;
    _totalMicros += elapsed.inMicroseconds;
  }

  bool shouldStep(Duration now,
      {required int chipSteps, required int kidSteps}) {
    if (chipSteps >= kidSteps + 2) return false;
    return now - _lastStepAt >= interval;
  }

  /// Call when Chíp has taken a step at [now].
  void markStep(Duration now) => _lastStepAt = now;
}
