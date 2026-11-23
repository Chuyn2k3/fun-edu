import 'package:drift/drift.dart';

/// One row per finished race (abandoned races are never stored).
/// [subject] is 'toan' or 'tiengViet'; [kidTimeMs] counts as a finish time
/// only when [won]. Indexed by kid and time: a synced race is found by that pair.
@TableIndex(name: 'race_results_kid_time_idx', columns: {#kidId, #finishedAt})
class RaceResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kidId => integer()();
  TextColumn get subject => text()();
  DateTimeColumn get finishedAt => dateTime()();
  BoolColumn get won => boolean()();
  IntColumn get kidTimeMs => integer()();
  IntColumn get firstTryCorrect => integer()();
  IntColumn get cometsFirstTry => integer()();
  IntColumn get stars => integer()();
}

/// Per-kid game state: cosmic stars (never spent), selected items, pacing.
class GameProfile extends Table {
  IntColumn get kidId => integer()();
  IntColumn get cosmicStars => integer().withDefault(const Constant(0))();
  TextColumn get selectedRocket =>
      text().withDefault(const Constant('rocket_orange'))();
  TextColumn get selectedTrail =>
      text().withDefault(const Constant('trail_flame'))();
  IntColumn get meanAnswerMs => integer().withDefault(const Constant(6000))();
  BoolColumn get slowNextRace =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get retryAfterLossPending =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {kidId};
}

/// Items picked from milestone offers (starters are implicit).
class GameItems extends Table {
  IntColumn get kidId => integer()();
  TextColumn get itemId => text()();

  @override
  Set<Column> get primaryKey => {kidId, itemId};
}

@DataClassName('GameBadgeRow')
class GameBadges extends Table {
  IntColumn get kidId => integer()();
  TextColumn get badgeId => text()();
  DateTimeColumn get earnedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kidId, badgeId};
}

/// Badge progress counters keyed by name.
class GameCounters extends Table {
  IntColumn get kidId => integer()();
  TextColumn get key => text()();
  IntColumn get value => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {kidId, key};
}
