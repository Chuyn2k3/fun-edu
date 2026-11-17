/// Decides when Chíp advances: dynamically paced with rubberbanding against
/// the kid's progress, never more than 1 step ahead (when chipSteps >= 2).
/// Pure; time is passed in.
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

  /// Calculates interval dynamically with rubberbanding.
  Duration intervalFor({required int chipSteps, required int kidSteps}) {
    double factor = 1.25 * slowdown;
    // If kid is ahead by 2 or more steps, Chíp speeds up by 15% to keep tension.
    if (kidSteps > chipSteps + 1) {
      factor *= 0.85;
    }
    // In the endgame (steps >= 8), Chíp slows down by 35% so kid takes the win.
    if (chipSteps >= 8) {
      factor *= 1.35;
    }
    return Duration(microseconds: (mean.inMicroseconds * factor).round());
  }

  /// Records how long the kid took to answer one question correctly.
  void recordAnswer(Duration elapsed) {
    _answers++;
    _totalMicros += elapsed.inMicroseconds;
  }

  bool shouldStep(Duration now,
      {required int chipSteps, required int kidSteps}) {
    if (chipSteps >= kidSteps + 2) return false;
    if (chipSteps >= kidSteps + 1 && chipSteps >= 2 && chipSteps < 9) {
      return false;
    }
    final needed = intervalFor(chipSteps: chipSteps, kidSteps: kidSteps);
    return now - _lastStepAt >= needed;
  }

  /// Call when Chíp has taken a step at [now].
  void markStep(Duration now) => _lastStepAt = now;
}
