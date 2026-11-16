import 'chip_pacer.dart';
import 'race_question.dart';

const int raceLength = 10;

class RaceOutcome {
  const RaceOutcome({
    required this.won,
    required this.kidTime,
    required this.firstTryCorrect,
    required this.cometsFirstTry,
    required this.missed,
  });

  final bool won;

  /// Sum of the kid's time on each answered question (race time if won).
  final Duration kidTime;
  final int firstTryCorrect;
  final int cometsFirstTry;

  /// Questions the kid got wrong at least once, in order.
  final List<RaceQuestion> missed;
}

class AnswerResult {
  const AnswerResult({
    required this.correct,
    required this.gained,
    required this.firstTry,
    required this.finished,
  });

  final bool correct;
  final int gained;

  /// True when this was the kid's first attempt at the question.
  final bool firstTry;
  final bool finished;
}

class Race {
  Race({required this.questions, required this.pacer});

  final List<RaceQuestion> questions;
  final ChipPacer pacer;

  int kidSteps = 0;
  int chipSteps = 0;
  int questionIndex = 0;
  RaceOutcome? outcome;

  bool _triedCurrent = false;
  Duration _kidTime = Duration.zero;
  int _firstTryCorrect = 0;
  int _cometsFirstTry = 0;
  final List<RaceQuestion> _missed = [];

  bool get finished => outcome != null;
  RaceQuestion get current => questions[questionIndex];

  /// [elapsed] is how long the question has been on screen (wrong tries
  /// included).
  AnswerResult answer(int choiceIndex, Duration elapsed) {
    if (finished) throw StateError('race is finished');
    final q = current;
    final firstTry = !_triedCurrent;
    if (choiceIndex != q.correctIndex) {
      if (firstTry) _missed.add(q);
      _triedCurrent = true;
      return AnswerResult(
          correct: false, gained: 0, firstTry: firstTry, finished: false);
    }
    final gained = q.comet ? 2 : 1;
    kidSteps = (kidSteps + gained).clamp(0, raceLength);
    _kidTime += elapsed;
    pacer.recordAnswer(elapsed);
    if (firstTry) {
      _firstTryCorrect++;
      if (q.comet) _cometsFirstTry++;
    }
    _triedCurrent = false;
    if (kidSteps >= raceLength) {
      _finish(won: true);
    } else if (questionIndex < questions.length - 1) {
      questionIndex++;
    } else {
      // Out of questions short of the line (cannot happen with 10 questions
      // and +1 each); treat as a loss rather than hang.
      _finish(won: false);
    }
    return AnswerResult(
        correct: true, gained: gained, firstTry: firstTry, finished: finished);
  }

  /// Advances Chíp. [now] is the time since the race started.
  void tick(Duration now) {
    if (finished) return;
    if (!pacer.shouldStep(now, chipSteps: chipSteps, kidSteps: kidSteps)) {
      return;
    }
    chipSteps++;
    pacer.markStep(now);
    if (chipSteps >= raceLength) _finish(won: false);
  }

  void _finish({required bool won}) {
    outcome = RaceOutcome(
      won: won,
      kidTime: _kidTime,
      firstTryCorrect: _firstTryCorrect,
      cometsFirstTry: _cometsFirstTry,
      missed: List.unmodifiable(_missed),
    );
  }
}
