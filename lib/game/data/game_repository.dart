import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../profile/kid_repository.dart';
import '../engine/race.dart';
import '../engine/race_question.dart';
import '../engine/rewards.dart';
import 'badges.dart';
import 'reward_pool.dart';

typedef Clock = DateTime Function();

const _kRecords = 'records_beaten';
const _kComets = 'comets_first_try';
const _kRetry = 'retry_after_loss';
const _kWins = 'wins';
const _kMath = 'math_correct';
const _kViet = 'tv_correct';
const _kRaces = 'races';
const _kOnlineRaces = 'online_races';
const _kOnlineWins = 'online_wins';
const _kOnlineBig = 'online_big';
const _kStickersSent = 'stickers_sent';
const _kSinceRare = 'online_since_rare';

/// Counter key marking a garage item as seen (value 1). Reuses the per-kid
/// key/value counters table so "new item" needs no schema change.
String _seenKey(String itemId) => 'seen:$itemId';

bool _isGarageItem(String id) =>
    id.startsWith('rocket_') || id.startsWith('trail_');

const double _slowdownFactor = 1.15;
const int _defaultMeanMs = 6000;

/// What one online race gave the kid.
class OnlineRaceRecord {
  const OnlineRaceRecord({
    required this.starsEarned,
    required this.totalStars,
    required this.milestonesCrossed,
    required this.newBadges,
    this.rareSticker,
  });

  final int starsEarned;
  final int totalStars;
  final List<int> milestonesCrossed;
  final List<GameBadge> newBadges;

  /// The rare sticker that dropped, if any.
  final String? rareSticker;
}

class RaceRecordResult {
  const RaceRecordResult({
    required this.starsEarned,
    required this.beatRecord,
    required this.previousBest,
    required this.totalStars,
    required this.milestonesCrossed,
    required this.newBadges,
  });

  final int starsEarned;
  final bool beatRecord;

  /// Best previous won time of this subject, if any.
  final Duration? previousBest;
  final int totalStars;
  final List<int> milestonesCrossed;
  final List<GameBadge> newBadges;
}

class GameStats {
  const GameStats({
    required this.races,
    required this.wins,
    required this.bestTime,
    required this.firstTryCorrect,
  });

  final int races;
  final int wins;
  final Duration? bestTime;
  final int firstTryCorrect;
}

class GameSummary {
  const GameSummary({
    required this.totalStars,
    required this.hasOffer,
    required this.badgeCount,
    required this.rocket,
    required this.trail,
  });

  final int totalStars;
  final bool hasOffer;
  final int badgeCount;
  final String rocket;
  final String trail;
}

String _subjectKey(RaceSubject s) => s.name;

/// Game data of one kid. Entirely separate from the learning tables: it never
/// reads or writes lesson, level, glyph or usage rows. With a null [kidId]
/// reads return empty values and writes throw [StateError].
class GameRepository {
  GameRepository(this._db, {required this.kidId, Clock now = DateTime.now})
      : _now = now;

  final AppDatabase _db;
  final int? kidId;
  final Clock _now;

  int _requireKid() => kidId ?? (throw StateError('No kid profile selected'));

  Future<GameProfileData?> _profile(int kid) => (_db.select(_db.gameProfile)
        ..where((t) => t.kidId.equals(kid)))
      .getSingleOrNull();

  Future<int> _counter(int kid, String key) async {
    final row = await (_db.select(_db.gameCounters)
          ..where((t) => t.kidId.equals(kid) & t.key.equals(key)))
        .getSingleOrNull();
    return row?.value ?? 0;
  }

  Future<void> _setCounter(int kid, String key, int value) =>
      _db.into(_db.gameCounters).insertOnConflictUpdate(
            GameCountersCompanion.insert(
              kidId: kid,
              key: key,
              value: Value(value),
            ),
          );

  Future<Set<String>> _ownedOf(int kid) async {
    final rows = await (_db.select(_db.gameItems)
          ..where((t) => t.kidId.equals(kid)))
        .get();
    return {...starterItems, ...rows.map((r) => r.itemId)};
  }

  Future<RaceRecordResult> recordRace(
    RaceSubject subject,
    RaceOutcome o, {
    required bool wasRetryAfterLoss,
  }) async {
    final kid = _requireKid();
    return _db.transaction(() async {
      final key = _subjectKey(subject);
      final profile = await _profile(kid);
      final before = profile?.cosmicStars ?? 0;

      final wonTimes = await (_db.select(_db.raceResults)
            ..where((t) =>
                t.kidId.equals(kid) & t.subject.equals(key) & t.won.equals(true)))
          .get();
      Duration? previousBest;
      for (final r in wonTimes) {
        final d = Duration(milliseconds: r.kidTimeMs);
        if (previousBest == null || d < previousBest) previousBest = d;
      }
      final beatRecord =
          o.won && previousBest != null && o.kidTime < previousBest;
      final baseStars = cosmicStarsFor(o, beatRecord: beatRecord);
      final stars = baseStars + o.luckyStarsCollected;
      final total = before + stars;

      await _db.into(_db.raceResults).insert(
            RaceResultsCompanion.insert(
              kidId: kid,
              subject: key,
              finishedAt: _now(),
              won: o.won,
              kidTimeMs: o.kidTime.inMilliseconds,
              firstTryCorrect: o.firstTryCorrect,
              cometsFirstTry: o.cometsFirstTry,
              stars: stars,
            ),
          );

      // Running mean of per-race mean answer time: kidTime sums only the
      // correctly answered questions, so divide by how many there were.
      final racesBefore = await _counter(kid, _kRaces);
      final raceMean = (o.kidTime.inMilliseconds / max(1, o.answered))
          .clamp(1500, 15000)
          .toDouble();
      final oldMean = (profile?.meanAnswerMs ?? _defaultMeanMs).toDouble();
      final newMean = racesBefore == 0
          ? raceMean
          : (oldMean * racesBefore + raceMean) / (racesBefore + 1);

      await _db.into(_db.gameProfile).insertOnConflictUpdate(
            GameProfileCompanion(
              kidId: Value(kid),
              cosmicStars: Value(total),
              selectedRocket: Value(profile?.selectedRocket ?? 'rocket_orange'),
              selectedTrail: Value(profile?.selectedTrail ?? 'trail_flame'),
              meanAnswerMs: Value(newMean.round()),
              slowNextRace: Value(!o.won),
              retryAfterLossPending: Value(!o.won),
            ),
          );

      Future<int> bump(String k, int by) async {
        final v = await _counter(kid, k) + by;
        await _setCounter(kid, k, v);
        return v;
      }

      final races = await bump(_kRaces, 1);
      final wins = await bump(_kWins, o.won ? 1 : 0);
      final comets = await bump(_kComets, o.cometsFirstTry);
      final records = await bump(_kRecords, beatRecord ? 1 : 0);
      final retries = await bump(_kRetry, wasRetryAfterLoss ? 1 : 0);
      final math = await bump(
          _kMath, subject == RaceSubject.toan ? o.firstTryCorrect : 0);
      final viet = await bump(
          _kViet, subject == RaceSubject.tiengViet ? o.firstTryCorrect : 0);

      final reached = <GameBadge>{
        if (records >= 3) GameBadge.speedKing,
        // Comets end a perfect race after 8 questions: "all correct on the
        // first try" = won with no question missed.
        if (o.won && o.missed.isEmpty && o.firstTryCorrect > 0)
          GameBadge.scholar,
        if (comets >= 10) GameBadge.cometHunter,
        if (retries >= 3) GameBadge.neverGiveUp,
        if (wins >= 5) GameBadge.chipBuddy,
        if (math >= 50) GameBadge.mathWhiz,
        if (viet >= 50) GameBadge.letterMaster,
        if (races >= 20) GameBadge.pilot,
      };
      final have = await badges();
      final fresh = [
        for (final b in GameBadge.values)
          if (reached.contains(b) && !have.contains(b)) b,
      ];
      for (final b in fresh) {
        await _db.into(_db.gameBadges).insert(
              GameBadgesCompanion.insert(
                kidId: kid,
                badgeId: b.id,
                earnedAt: _now(),
              ),
            );
      }

      return RaceRecordResult(
        starsEarned: stars,
        beatRecord: beatRecord,
        previousBest: previousBest,
        totalStars: total,
        milestonesCrossed: milestonesBetween(before, total),
        newBadges: fresh,
      );
    });
  }

  /// A race in an online room. Stars for everyone who raced (more for the
  /// first places), the online badges and maybe a rare sticker. Chíp's
  /// pacing, best times and the Chíp badges are left alone: the row is
  /// stored under `online:<subject>` so the Chíp stats never count it.
  Future<OnlineRaceRecord> recordOnlineRace(
    RaceSubject subject,
    RaceOutcome o, {
    required int? rank,
    required int players,
    required Random rng,
  }) async {
    final kid = _requireKid();
    return _db.transaction(() async {
      final profile = await _profile(kid);
      final before = profile?.cosmicStars ?? 0;
      final stars = onlineCosmicStarsFor(o, rank: rank) + o.luckyStarsCollected;
      final total = before + stars;
      await _db.into(_db.raceResults).insert(
            RaceResultsCompanion.insert(
              kidId: kid,
              subject: 'online:${_subjectKey(subject)}',
              finishedAt: _now(),
              won: rank == 1,
              kidTimeMs: o.kidTime.inMilliseconds,
              firstTryCorrect: o.firstTryCorrect,
              cometsFirstTry: o.cometsFirstTry,
              stars: stars,
            ),
          );
      await _db.into(_db.gameProfile).insertOnConflictUpdate(
            GameProfileCompanion(
              kidId: Value(kid),
              cosmicStars: Value(total),
              selectedRocket: Value(profile?.selectedRocket ?? 'rocket_orange'),
              selectedTrail: Value(profile?.selectedTrail ?? 'trail_flame'),
              meanAnswerMs: Value(profile?.meanAnswerMs ?? _defaultMeanMs),
              slowNextRace: Value(profile?.slowNextRace ?? false),
              retryAfterLossPending: Value(profile?.retryAfterLossPending ?? false),
            ),
          );

      Future<int> bump(String k, int by) async {
        final v = await _counter(kid, k) + by;
        await _setCounter(kid, k, v);
        return v;
      }

      final races = await bump(_kOnlineRaces, 1);
      final wins = await bump(_kOnlineWins, rank == 1 ? 1 : 0);
      final big = await bump(_kOnlineBig, players >= 4 ? 1 : 0);
      final cheers = await _counter(kid, _kStickersSent);
      final reached = <GameBadge>{
        if (races >= 5) GameBadge.friendRacer,
        if (wins >= 3) GameBadge.friendChampion,
        if (big >= 1) GameBadge.bigRace,
        if (cheers >= 20) GameBadge.cheerleader,
      };
      final have = await badges();
      final fresh = [
        for (final b in GameBadge.values)
          if (reached.contains(b) && !have.contains(b)) b,
      ];
      for (final b in fresh) {
        await _db.into(_db.gameBadges).insert(
              GameBadgesCompanion.insert(kidId: kid, badgeId: b.id, earnedAt: _now()),
            );
      }

      final owned = await _ownedOf(kid);
      final since = await _counter(kid, _kSinceRare);
      final rare = rareStickerDrop(
          owned: owned, racesWithoutRare: since, rank: rank, rng: rng);
      if (rare != null) {
        await _db.into(_db.gameItems).insertOnConflictUpdate(
              GameItemsCompanion.insert(kidId: kid, itemId: rare),
            );
      }
      await _setCounter(kid, _kSinceRare, rare == null ? since + 1 : 0);

      return OnlineRaceRecord(
        starsEarned: stars,
        totalStars: total,
        milestonesCrossed: milestonesBetween(before, total),
        newBadges: fresh,
        rareSticker: rare,
      );
    });
  }

  /// A cheer sticker sent to a friend (counts toward "Cổ Vũ Nhiệt Tình").
  Future<void> countStickerSent() async {
    final kid = kidId;
    if (kid == null) return;
    await _setCounter(kid, _kStickersSent, await _counter(kid, _kStickersSent) + 1);
  }

  Future<int> totalStars() async {
    final kid = kidId;
    if (kid == null) return 0;
    return (await _profile(kid))?.cosmicStars ?? 0;
  }

  /// The offer waiting for the kid (first two unowned pool items), or empty.
  /// Milestones reached minus items already picked = offers still pending.
  Future<List<String>> pendingOffer() async {
    final kid = kidId;
    if (kid == null) return const [];
    final owned = await _ownedOf(kid);
    final picked = owned.difference(starterItems).length;
    final reached = milestonesBetween(0, await totalStars()).length;
    if (reached <= picked) return const [];
    return nextOffer(owned);
  }

  /// Takes [itemId] from the current offer; throws [StateError] otherwise.
  Future<void> pick(String itemId) async {
    final kid = _requireKid();
    await _db.transaction(() async {
      if (!(await pendingOffer()).contains(itemId)) {
        throw StateError('$itemId is not on offer');
      }
      await _db.into(_db.gameItems).insert(
            GameItemsCompanion.insert(kidId: kid, itemId: itemId),
          );
    });
  }

  Future<Set<String>> owned() async {
    final kid = kidId;
    if (kid == null) return {...starterItems};
    return _ownedOf(kid);
  }

  /// Equips owned items; throws [StateError] for an item the kid lacks,
  /// or [ArgumentError] if an item kind does not match its slot.
  /// Equipped items count as seen.
  Future<void> select({String? rocket, String? trail}) async {
    final kid = _requireKid();
    final have = await _ownedOf(kid);
    for (final id in [rocket, trail]) {
      if (id != null && !have.contains(id)) {
        throw StateError('$id is not owned');
      }
    }
    if (rocket != null && !rocket.startsWith('rocket_')) {
      throw ArgumentError.value(rocket, 'rocket', 'Must be a rocket item');
    }
    if (trail != null && !trail.startsWith('trail_')) {
      throw ArgumentError.value(trail, 'trail', 'Must be a trail item');
    }
    await _db.transaction(() async {
      await markSeen([if (rocket != null) rocket, if (trail != null) trail]);
      final p = await _profile(kid);
      await _db.into(_db.gameProfile).insertOnConflictUpdate(
            GameProfileCompanion(
              kidId: Value(kid),
              cosmicStars: Value(p?.cosmicStars ?? 0),
              selectedRocket: Value(rocket ?? p?.selectedRocket ?? 'rocket_orange'),
              selectedTrail: Value(trail ?? p?.selectedTrail ?? 'trail_flame'),
              meanAnswerMs: Value(p?.meanAnswerMs ?? _defaultMeanMs),
              slowNextRace: Value(p?.slowNextRace ?? false),
              retryAfterLossPending: Value(p?.retryAfterLossPending ?? false),
            ),
          );
    });
  }

  Future<({String rocket, String trail})> selected() async {
    final kid = kidId;
    final p = kid == null ? null : await _profile(kid);
    return (
      rocket: p?.selectedRocket ?? 'rocket_orange',
      trail: p?.selectedTrail ?? 'trail_flame',
    );
  }

  Future<GameStats> stats(RaceSubject s) async {
    final kid = kidId;
    if (kid == null) {
      return const GameStats(
          races: 0, wins: 0, bestTime: null, firstTryCorrect: 0);
    }
    final rows = await (_db.select(_db.raceResults)
          ..where((t) => t.kidId.equals(kid) & t.subject.equals(_subjectKey(s))))
        .get();
    Duration? best;
    var wins = 0;
    var first = 0;
    for (final r in rows) {
      first += r.firstTryCorrect;
      if (!r.won) continue;
      wins++;
      final d = Duration(milliseconds: r.kidTimeMs);
      if (best == null || d < best) best = d;
    }
    return GameStats(
      races: rows.length,
      wins: wins,
      bestTime: best,
      firstTryCorrect: first,
    );
  }

  Future<Set<GameBadge>> badges() async {
    final kid = kidId;
    if (kid == null) return {};
    final rows = await (_db.select(_db.gameBadges)
          ..where((t) => t.kidId.equals(kid)))
        .get();
    return {
      for (final r in rows)
        if (GameBadge.byId(r.badgeId) case final b?) b,
    };
  }

  /// When each earned badge was earned.
  Future<Map<GameBadge, DateTime>> badgeDates() async {
    final kid = kidId;
    if (kid == null) return {};
    final rows = await (_db.select(_db.gameBadges)
          ..where((t) => t.kidId.equals(kid)))
        .get();
    return {
      for (final r in rows)
        if (GameBadge.byId(r.badgeId) case final b?) b: r.earnedAt,
    };
  }

  /// Owned rockets and trails (not starters, not stickers) the kid has not
  /// seen in the garage nor equipped yet: the "Xưởng độ" badge count.
  Future<Set<String>> newGarageItems() async {
    final kid = kidId;
    if (kid == null) return {};
    final picked = (await _ownedOf(kid))
        .difference(starterItems)
        .where(_isGarageItem)
        .toList();
    if (picked.isEmpty) return {};
    final seen = await (_db.select(_db.gameCounters)
          ..where((t) =>
              t.kidId.equals(kid) &
              t.key.isIn([for (final id in picked) _seenKey(id)])))
        .get();
    final seenKeys = {
      for (final r in seen)
        if (r.value > 0) r.key
    };
    return {
      for (final id in picked)
        if (!seenKeys.contains(_seenKey(id))) id,
    };
  }

  /// Marks garage items as seen (the garage showed them).
  Future<void> markSeen(Iterable<String> itemIds) async {
    final kid = kidId;
    if (kid == null) return;
    final ids = itemIds.toList();
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      for (final id in ids) {
        await _setCounter(kid, _seenKey(id), 1);
      }
    });
  }

  Future<Duration> meanAnswer() async {
    final kid = kidId;
    final p = kid == null ? null : await _profile(kid);
    return Duration(milliseconds: p?.meanAnswerMs ?? _defaultMeanMs);
  }

  /// 1.15 when the last race was lost, else 1.0. Does not change anything.
  Future<double> nextSlowdown() async {
    final kid = kidId;
    final p = kid == null ? null : await _profile(kid);
    return (p?.slowNextRace ?? false) ? _slowdownFactor : 1.0;
  }

  /// Like [nextSlowdown] but clears the flag, so only one race is slowed.
  Future<double> consumeSlowdown() async {
    final kid = kidId;
    if (kid == null) return 1.0;
    final v = await nextSlowdown();
    if (v != 1.0) {
      await (_db.update(_db.gameProfile)..where((t) => t.kidId.equals(kid)))
          .write(const GameProfileCompanion(slowNextRace: Value(false)));
    }
    return v;
  }
}

/// Bumped after every write to a kid's game data (a race recorded, a gift
/// picked, a rocket or trail equipped). Every game read provider watches it,
/// so screens that stay mounted under a race (the Góc Chơi hub) refresh.
final gameDataRevisionProvider = StateProvider<int>((ref) => 0);

final gameRepositoryProvider = FutureProvider<GameRepository>((ref) async {
  final kid = await ref.watch(currentKidIdProvider.future);
  return GameRepository(ref.watch(databaseProvider), kidId: kid);
});

final gameSummaryProvider = FutureProvider<GameSummary>((ref) async {
  ref.watch(gameDataRevisionProvider);
  final repo = await ref.watch(gameRepositoryProvider.future);
  final sel = await repo.selected();
  return GameSummary(
    totalStars: await repo.totalStars(),
    hasOffer: (await repo.pendingOffer()).isNotEmpty,
    badgeCount: (await repo.badges()).length,
    rocket: sel.rocket,
    trail: sel.trail,
  );
});
