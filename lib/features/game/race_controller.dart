import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/data/badges.dart';
import '../../game/data/game_repository.dart';
import '../../game/engine/chip_pacer.dart';
import '../../game/engine/question_source.dart';
import '../../game/engine/race.dart';
import '../../game/engine/race_question.dart';
import '../../learning/writing_ladder.dart';
import '../../progress/level_repository.dart';
import '../../progress/progress_repository.dart';
import '../../stroke/glyph_repository.dart';

/// Seeds question building; tests override it for a fixed race.
final raceRandomProvider = Provider<Random>((ref) => Random());

/// URL segment of a subject: `/game/race/toan`, `/game/race/tieng-viet`.
String subjectSlug(RaceSubject s) => switch (s) {
      RaceSubject.toan => 'toan',
      RaceSubject.tiengViet => 'tieng-viet',
    };

RaceSubject? subjectFromSlug(String slug) => switch (slug) {
      'toan' => RaceSubject.toan,
      'tieng-viet' => RaceSubject.tiengViet,
      _ => null,
    };

/// Extra of `/game/race/:subject`: whether the kid pressed "Đua lại!" on a
/// lost result (counts toward the "Không Bỏ Cuộc" badge).
class RaceArgs {
  const RaceArgs({this.retryAfterLoss = false});
  final bool retryAfterLoss;
}

/// Everything the result screen shows, handed over as the route extra.
class RaceResultArgs {
  const RaceResultArgs({
    required this.subject,
    required this.outcome,
    required this.record,
    required this.kidSteps,
    required this.rocket,
    required this.trail,
    this.luckyStarsCollected = 0,
  });

  final RaceSubject subject;
  final RaceOutcome outcome;

  /// Null when saving the race failed: nothing was stored, no stars.
  final RaceRecordResult? record;

  /// Kid's steps when the race ended (Chíp's finish, for a loss).
  final int kidSteps;
  final String rocket;
  final String trail;
  final int luckyStarsCollected;

  bool get won => outcome.won;

  /// Steps the kid still needed when Chíp landed.
  int get stepsShort => (raceLength - kidSteps).clamp(0, raceLength);

  /// Seconds faster than the previous best, at least 1, when a record.
  int? get secondsFaster {
    final r = record;
    final prev = r?.previousBest;
    if (r == null || !r.beatRecord || prev == null) return null;
    final ms = (prev - outcome.kidTime).inMilliseconds;
    return max(1, (ms / 1000).round());
  }

  List<GameBadge> get newBadges => record?.newBadges ?? const [];

  bool get saved => record != null;
}

const _letterNames = {
  'a': 'a', 'aw': 'á', 'aa': 'ớ', 'b': 'bờ', 'c': 'cờ', 'd': 'dờ', 'dd': 'đờ',
  'e': 'e', 'ee': 'ê', 'g': 'gờ', 'h': 'hờ', 'i': 'i', 'k': 'ca', 'l': 'lờ',
  'm': 'mờ', 'n': 'nờ', 'o': 'o', 'oo': 'ô', 'ow': 'ơ', 'p': 'pờ', 'q': 'quờ',
  'r': 'rờ', 's': 'sờ', 't': 'tờ', 'u': 'u', 'uw': 'ư', 'v': 'vờ', 'x': 'xờ',
  'y': 'i dài', //
};

/// What Chíp says for a glyph id when its file could not be read: the same
/// names as the glyphs' `speech` ("chữ bờ", "dấu hỏi").
String spokenNameFromId(String id) {
  if (id.startsWith('dau-')) return toneLabels[id] ?? id;
  final key = id.startsWith('chu-') ? id.substring(4) : id;
  return 'chữ ${_letterNames[key] ?? key}';
}

enum RacePhase { loading, racing, finishing, done }

/// A snapshot of the race for the screen. The engine ([Race]) lives in the
/// [RaceController], outside the widget tree, so rotation and layout
/// changes never lose it.
class RaceState {
  const RaceState({
    this.phase = RacePhase.loading,
    this.subject,
    this.questions = const [],
    this.questionIndex = 0,
    this.kidSteps = 0,
    this.chipSteps = 0,
    this.boosting = false,
    this.wrongKey,
    this.wrongSeq = 0,
    this.correctKey,
    this.rocket = 'rocket_orange',
    this.trail = 'trail_flame',
    this.slowdown = 1.0,
    this.wasRetryAfterLoss = false,
    this.paused = false,
    this.result,
  });

  final RacePhase phase;
  final RaceSubject? subject;
  final List<RaceQuestion> questions;

  /// The question on screen (lags the engine while a right answer shows).
  final int questionIndex;
  final int kidSteps;
  final int chipSteps;

  /// True after a comet question is answered right, until the next right
  /// answer; its rising edge sends the comet across the scene.
  final bool boosting;

  /// The key last pressed wrong; [wrongSeq] counts wrong presses so the
  /// same key can shake twice.
  final int? wrongKey;
  final int wrongSeq;

  /// The key just pressed right; keys are locked while it shows.
  final int? correctKey;
  final String rocket;
  final String trail;
  final double slowdown;
  final bool wasRetryAfterLoss;
  final bool paused;
  final RaceResultArgs? result;

  RaceQuestion? get current =>
      questions.isEmpty ? null : questions[questionIndex];
  String? get subjectName => subject == null ? null : subjectSlug(subject!);
  bool get won => result?.won ?? false;

  RaceState copyWith({
    RacePhase? phase,
    int? questionIndex,
    int? kidSteps,
    int? chipSteps,
    bool? boosting,
    int? Function()? wrongKey,
    int? wrongSeq,
    int? Function()? correctKey,
    bool? paused,
    RaceResultArgs? result,
  }) =>
      RaceState(
        phase: phase ?? this.phase,
        subject: subject,
        questions: questions,
        questionIndex: questionIndex ?? this.questionIndex,
        kidSteps: kidSteps ?? this.kidSteps,
        chipSteps: chipSteps ?? this.chipSteps,
        boosting: boosting ?? this.boosting,
        wrongKey: wrongKey == null ? this.wrongKey : wrongKey(),
        wrongSeq: wrongSeq ?? this.wrongSeq,
        correctKey: correctKey == null ? this.correctKey : correctKey(),
        rocket: rocket,
        trail: trail,
        slowdown: slowdown,
        wasRetryAfterLoss: wasRetryAfterLoss,
        paused: paused ?? this.paused,
        result: result ?? this.result,
      );
}

/// Owns one [Race]. The screen feeds it race time ([advance]) only while
/// the race is visible and running, and taps ([answer]). A race left before
/// the finish stores nothing; a finished one is recorded once.
class RaceController extends AutoDisposeNotifier<RaceState> {
  Race? _race;
  Duration _now = Duration.zero;
  Duration _shownAt = Duration.zero;
  bool _starting = false;
  bool _disposed = false;

  /// Race time, which only moves through [advance].
  Duration get now => _now;

  @override
  RaceState build() {
    ref.onDispose(() => _disposed = true);
    return const RaceState();
  }

  /// Loads the kid's levels and game profile and builds the questions.
  Future<void> start(RaceSubject subject, {bool retryAfterLoss = false}) async {
    if (_starting || _race != null) return;
    _starting = true;
    final repo = await ref.read(gameRepositoryProvider.future);
    final levels = await ref.read(levelRepositoryProvider.future);
    final progress = await ref.read(progressRepositoryProvider.future);
    final mathLevel = await levels.levelOf('toan') ?? 0;
    final writingStart = await levels.levelOf('viet') ?? 0;
    final stats = await progress.glyphStats();
    final speech = <String, String>{};
    if (subject == RaceSubject.tiengViet) {
      final ids = {
        ...writingLadder.where((id) => id.startsWith('chu-')),
        ...firstLetterGroup,
        ...toneIds,
      };
      for (final id in ids) {
        try {
          // Also warms the cache so the keys draw at once.
          final g = await ref.read(glyphProvider(id).future);
          speech[id] = g.spokenName;
        } catch (_) {
          // The glyph did not load: Chíp still says the letter's name.
          speech[id] = spokenNameFromId(id);
        }
      }
    }
    // Not consumed here: recordRace clears it, so a race left early keeps
    // the slower Chíp for the next try.
    final slowdown = await repo.nextSlowdown();
    final mean = await repo.meanAnswer();
    final sel = await repo.selected();
    if (_disposed) return;
    final questions = buildRaceQuestions(
      subject: subject,
      mathLevelIndex: mathLevel,
      glyphStats: stats,
      writingStartIndex: writingStart,
      speechByGlyph: speech,
      rng: ref.read(raceRandomProvider),
    );
    _race = Race(
      questions: questions,
      pacer: ChipPacer(initialMean: mean, slowdown: slowdown),
    );
    _now = Duration.zero;
    _shownAt = Duration.zero;
    state = RaceState(
      phase: RacePhase.racing,
      subject: subject,
      questions: questions,
      rocket: sel.rocket,
      trail: sel.trail,
      slowdown: slowdown,
      wasRetryAfterLoss: retryAfterLoss,
    );
  }

  /// Moves race time on by [dt]; Chíp may step.
  void advance(Duration dt) {
    final race = _race;
    if (race == null || state.phase != RacePhase.racing || state.paused) {
      return;
    }
    _now += dt;
    final before = race.chipSteps;
    race.tick(_now);
    if (race.chipSteps != before) {
      state = state.copyWith(chipSteps: race.chipSteps);
    }
    if (race.finished) _finish();
  }

  /// The kid pressed key [index]. Returns whether it was right, or null
  /// when keys are locked.
  bool? answer(int index) {
    final race = _race;
    if (race == null ||
        state.phase != RacePhase.racing ||
        state.paused ||
        state.correctKey != null) {
      return null;
    }
    final q = race.current;
    final r = race.answer(index, _now - _shownAt);
    if (!r.correct) {
      state = state.copyWith(
        wrongKey: () => index,
        wrongSeq: state.wrongSeq + 1,
      );
      return false;
    }
    state = state.copyWith(
      kidSteps: race.kidSteps,
      boosting: q.comet,
      correctKey: () => index,
      wrongKey: () => null,
    );
    if (race.finished) _finish();
    return true;
  }

  /// Shows the engine's next question after a right answer.
  void showNext() {
    final race = _race;
    if (race == null || state.phase != RacePhase.racing) return;
    if (state.correctKey == null) return;
    _shownAt = _now;
    state = state.copyWith(
      questionIndex: race.questionIndex,
      correctKey: () => null,
      wrongKey: () => null,
    );
  }

  void setPaused(bool paused) {
    if (state.phase != RacePhase.racing || state.paused == paused) return;
    state = state.copyWith(paused: paused);
  }

  Future<void> _finish() async {
    final race = _race!;
    final o = race.outcome!;
    state = state.copyWith(
      phase: RacePhase.finishing,
      kidSteps: race.kidSteps,
      chipSteps: race.chipSteps,
    );
    RaceRecordResult? record;
    try {
      final repo = await ref.read(gameRepositoryProvider.future);
      record = await repo.recordRace(
        state.subject!,
        o,
        wasRetryAfterLoss: state.wasRetryAfterLoss,
      );
    } catch (e) {
      // Never strand the kid on a finished race: show the result without
      // stars (nothing was stored).
      debugPrint('Saving the race failed: $e');
    }
    if (_disposed) return;
    // Stars, stats and badges changed: refresh every game screen (the hub
    // stays mounted under the race).
    if (record != null) ref.read(gameDataRevisionProvider.notifier).state++;
    state = state.copyWith(
      phase: RacePhase.done,
      result: RaceResultArgs(
        subject: state.subject!,
        outcome: o,
        record: record,
        kidSteps: race.kidSteps,
        rocket: state.rocket,
        trail: state.trail,
        luckyStarsCollected: o.luckyStarsCollected,
      ),
    );
  }
}

final raceControllerProvider =
    NotifierProvider.autoDispose<RaceController, RaceState>(RaceController.new);
