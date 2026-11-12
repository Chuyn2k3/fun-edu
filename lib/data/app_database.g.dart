// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StrokeAttemptsTable extends StrokeAttempts
    with TableInfo<$StrokeAttemptsTable, StrokeAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrokeAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _glyphIdMeta =
      const VerificationMeta('glyphId');
  @override
  late final GeneratedColumn<String> glyphId = GeneratedColumn<String>(
      'glyph_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _strokeIndexMeta =
      const VerificationMeta('strokeIndex');
  @override
  late final GeneratedColumn<int> strokeIndex = GeneratedColumn<int>(
      'stroke_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _okMeta = const VerificationMeta('ok');
  @override
  late final GeneratedColumn<bool> ok = GeneratedColumn<bool>(
      'ok', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ok" IN (0, 1))'));
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deviationMeta =
      const VerificationMeta('deviation');
  @override
  late final GeneratedColumn<double> deviation = GeneratedColumn<double>(
      'deviation', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<String> points = GeneratedColumn<String>(
      'points', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, glyphId, strokeIndex, ok, error, deviation, points, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stroke_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<StrokeAttempt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('glyph_id')) {
      context.handle(_glyphIdMeta,
          glyphId.isAcceptableOrUnknown(data['glyph_id']!, _glyphIdMeta));
    } else if (isInserting) {
      context.missing(_glyphIdMeta);
    }
    if (data.containsKey('stroke_index')) {
      context.handle(
          _strokeIndexMeta,
          strokeIndex.isAcceptableOrUnknown(
              data['stroke_index']!, _strokeIndexMeta));
    } else if (isInserting) {
      context.missing(_strokeIndexMeta);
    }
    if (data.containsKey('ok')) {
      context.handle(_okMeta, ok.isAcceptableOrUnknown(data['ok']!, _okMeta));
    } else if (isInserting) {
      context.missing(_okMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('deviation')) {
      context.handle(_deviationMeta,
          deviation.isAcceptableOrUnknown(data['deviation']!, _deviationMeta));
    } else if (isInserting) {
      context.missing(_deviationMeta);
    }
    if (data.containsKey('points')) {
      context.handle(_pointsMeta,
          points.isAcceptableOrUnknown(data['points']!, _pointsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StrokeAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrokeAttempt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      glyphId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}glyph_id'])!,
      strokeIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stroke_index'])!,
      ok: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ok'])!,
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      deviation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}deviation'])!,
      points: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}points']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StrokeAttemptsTable createAlias(String alias) {
    return $StrokeAttemptsTable(attachedDatabase, alias);
  }
}

class StrokeAttempt extends DataClass implements Insertable<StrokeAttempt> {
  final int id;
  final String glyphId;
  final int strokeIndex;
  final bool ok;
  final String? error;
  final double deviation;

  /// JSON array of [x, y] pairs (4 decimals) of the drawn stroke, so a false
  /// rejection can be replayed in a test.
  final String? points;
  final DateTime createdAt;
  const StrokeAttempt(
      {required this.id,
      required this.glyphId,
      required this.strokeIndex,
      required this.ok,
      this.error,
      required this.deviation,
      this.points,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['glyph_id'] = Variable<String>(glyphId);
    map['stroke_index'] = Variable<int>(strokeIndex);
    map['ok'] = Variable<bool>(ok);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['deviation'] = Variable<double>(deviation);
    if (!nullToAbsent || points != null) {
      map['points'] = Variable<String>(points);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StrokeAttemptsCompanion toCompanion(bool nullToAbsent) {
    return StrokeAttemptsCompanion(
      id: Value(id),
      glyphId: Value(glyphId),
      strokeIndex: Value(strokeIndex),
      ok: Value(ok),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      deviation: Value(deviation),
      points:
          points == null && nullToAbsent ? const Value.absent() : Value(points),
      createdAt: Value(createdAt),
    );
  }

  factory StrokeAttempt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrokeAttempt(
      id: serializer.fromJson<int>(json['id']),
      glyphId: serializer.fromJson<String>(json['glyphId']),
      strokeIndex: serializer.fromJson<int>(json['strokeIndex']),
      ok: serializer.fromJson<bool>(json['ok']),
      error: serializer.fromJson<String?>(json['error']),
      deviation: serializer.fromJson<double>(json['deviation']),
      points: serializer.fromJson<String?>(json['points']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'glyphId': serializer.toJson<String>(glyphId),
      'strokeIndex': serializer.toJson<int>(strokeIndex),
      'ok': serializer.toJson<bool>(ok),
      'error': serializer.toJson<String?>(error),
      'deviation': serializer.toJson<double>(deviation),
      'points': serializer.toJson<String?>(points),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StrokeAttempt copyWith(
          {int? id,
          String? glyphId,
          int? strokeIndex,
          bool? ok,
          Value<String?> error = const Value.absent(),
          double? deviation,
          Value<String?> points = const Value.absent(),
          DateTime? createdAt}) =>
      StrokeAttempt(
        id: id ?? this.id,
        glyphId: glyphId ?? this.glyphId,
        strokeIndex: strokeIndex ?? this.strokeIndex,
        ok: ok ?? this.ok,
        error: error.present ? error.value : this.error,
        deviation: deviation ?? this.deviation,
        points: points.present ? points.value : this.points,
        createdAt: createdAt ?? this.createdAt,
      );
  StrokeAttempt copyWithCompanion(StrokeAttemptsCompanion data) {
    return StrokeAttempt(
      id: data.id.present ? data.id.value : this.id,
      glyphId: data.glyphId.present ? data.glyphId.value : this.glyphId,
      strokeIndex:
          data.strokeIndex.present ? data.strokeIndex.value : this.strokeIndex,
      ok: data.ok.present ? data.ok.value : this.ok,
      error: data.error.present ? data.error.value : this.error,
      deviation: data.deviation.present ? data.deviation.value : this.deviation,
      points: data.points.present ? data.points.value : this.points,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrokeAttempt(')
          ..write('id: $id, ')
          ..write('glyphId: $glyphId, ')
          ..write('strokeIndex: $strokeIndex, ')
          ..write('ok: $ok, ')
          ..write('error: $error, ')
          ..write('deviation: $deviation, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, glyphId, strokeIndex, ok, error, deviation, points, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrokeAttempt &&
          other.id == this.id &&
          other.glyphId == this.glyphId &&
          other.strokeIndex == this.strokeIndex &&
          other.ok == this.ok &&
          other.error == this.error &&
          other.deviation == this.deviation &&
          other.points == this.points &&
          other.createdAt == this.createdAt);
}

class StrokeAttemptsCompanion extends UpdateCompanion<StrokeAttempt> {
  final Value<int> id;
  final Value<String> glyphId;
  final Value<int> strokeIndex;
  final Value<bool> ok;
  final Value<String?> error;
  final Value<double> deviation;
  final Value<String?> points;
  final Value<DateTime> createdAt;
  const StrokeAttemptsCompanion({
    this.id = const Value.absent(),
    this.glyphId = const Value.absent(),
    this.strokeIndex = const Value.absent(),
    this.ok = const Value.absent(),
    this.error = const Value.absent(),
    this.deviation = const Value.absent(),
    this.points = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StrokeAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String glyphId,
    required int strokeIndex,
    required bool ok,
    this.error = const Value.absent(),
    required double deviation,
    this.points = const Value.absent(),
    required DateTime createdAt,
  })  : glyphId = Value(glyphId),
        strokeIndex = Value(strokeIndex),
        ok = Value(ok),
        deviation = Value(deviation),
        createdAt = Value(createdAt);
  static Insertable<StrokeAttempt> custom({
    Expression<int>? id,
    Expression<String>? glyphId,
    Expression<int>? strokeIndex,
    Expression<bool>? ok,
    Expression<String>? error,
    Expression<double>? deviation,
    Expression<String>? points,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (glyphId != null) 'glyph_id': glyphId,
      if (strokeIndex != null) 'stroke_index': strokeIndex,
      if (ok != null) 'ok': ok,
      if (error != null) 'error': error,
      if (deviation != null) 'deviation': deviation,
      if (points != null) 'points': points,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StrokeAttemptsCompanion copyWith(
      {Value<int>? id,
      Value<String>? glyphId,
      Value<int>? strokeIndex,
      Value<bool>? ok,
      Value<String?>? error,
      Value<double>? deviation,
      Value<String?>? points,
      Value<DateTime>? createdAt}) {
    return StrokeAttemptsCompanion(
      id: id ?? this.id,
      glyphId: glyphId ?? this.glyphId,
      strokeIndex: strokeIndex ?? this.strokeIndex,
      ok: ok ?? this.ok,
      error: error ?? this.error,
      deviation: deviation ?? this.deviation,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (glyphId.present) {
      map['glyph_id'] = Variable<String>(glyphId.value);
    }
    if (strokeIndex.present) {
      map['stroke_index'] = Variable<int>(strokeIndex.value);
    }
    if (ok.present) {
      map['ok'] = Variable<bool>(ok.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (deviation.present) {
      map['deviation'] = Variable<double>(deviation.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(points.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrokeAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('glyphId: $glyphId, ')
          ..write('strokeIndex: $strokeIndex, ')
          ..write('ok: $ok, ')
          ..write('error: $error, ')
          ..write('deviation: $deviation, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GlyphProgressTable extends GlyphProgress
    with TableInfo<$GlyphProgressTable, GlyphProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GlyphProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _glyphIdMeta =
      const VerificationMeta('glyphId');
  @override
  late final GeneratedColumn<String> glyphId = GeneratedColumn<String>(
      'glyph_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completionsMeta =
      const VerificationMeta('completions');
  @override
  late final GeneratedColumn<int> completions = GeneratedColumn<int>(
      'completions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cleanCompletionsMeta =
      const VerificationMeta('cleanCompletions');
  @override
  late final GeneratedColumn<int> cleanCompletions = GeneratedColumn<int>(
      'clean_completions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPracticedAtMeta =
      const VerificationMeta('lastPracticedAt');
  @override
  late final GeneratedColumn<DateTime> lastPracticedAt =
      GeneratedColumn<DateTime>('last_practiced_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [glyphId, completions, cleanCompletions, lastPracticedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'glyph_progress';
  @override
  VerificationContext validateIntegrity(Insertable<GlyphProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('glyph_id')) {
      context.handle(_glyphIdMeta,
          glyphId.isAcceptableOrUnknown(data['glyph_id']!, _glyphIdMeta));
    } else if (isInserting) {
      context.missing(_glyphIdMeta);
    }
    if (data.containsKey('completions')) {
      context.handle(
          _completionsMeta,
          completions.isAcceptableOrUnknown(
              data['completions']!, _completionsMeta));
    }
    if (data.containsKey('clean_completions')) {
      context.handle(
          _cleanCompletionsMeta,
          cleanCompletions.isAcceptableOrUnknown(
              data['clean_completions']!, _cleanCompletionsMeta));
    }
    if (data.containsKey('last_practiced_at')) {
      context.handle(
          _lastPracticedAtMeta,
          lastPracticedAt.isAcceptableOrUnknown(
              data['last_practiced_at']!, _lastPracticedAtMeta));
    } else if (isInserting) {
      context.missing(_lastPracticedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {glyphId};
  @override
  GlyphProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlyphProgressData(
      glyphId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}glyph_id'])!,
      completions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completions'])!,
      cleanCompletions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}clean_completions'])!,
      lastPracticedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_practiced_at'])!,
    );
  }

  @override
  $GlyphProgressTable createAlias(String alias) {
    return $GlyphProgressTable(attachedDatabase, alias);
  }
}

class GlyphProgressData extends DataClass
    implements Insertable<GlyphProgressData> {
  final String glyphId;
  final int completions;

  /// Completions with at most one failed stroke.
  final int cleanCompletions;
  final DateTime lastPracticedAt;
  const GlyphProgressData(
      {required this.glyphId,
      required this.completions,
      required this.cleanCompletions,
      required this.lastPracticedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['glyph_id'] = Variable<String>(glyphId);
    map['completions'] = Variable<int>(completions);
    map['clean_completions'] = Variable<int>(cleanCompletions);
    map['last_practiced_at'] = Variable<DateTime>(lastPracticedAt);
    return map;
  }

  GlyphProgressCompanion toCompanion(bool nullToAbsent) {
    return GlyphProgressCompanion(
      glyphId: Value(glyphId),
      completions: Value(completions),
      cleanCompletions: Value(cleanCompletions),
      lastPracticedAt: Value(lastPracticedAt),
    );
  }

  factory GlyphProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GlyphProgressData(
      glyphId: serializer.fromJson<String>(json['glyphId']),
      completions: serializer.fromJson<int>(json['completions']),
      cleanCompletions: serializer.fromJson<int>(json['cleanCompletions']),
      lastPracticedAt: serializer.fromJson<DateTime>(json['lastPracticedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'glyphId': serializer.toJson<String>(glyphId),
      'completions': serializer.toJson<int>(completions),
      'cleanCompletions': serializer.toJson<int>(cleanCompletions),
      'lastPracticedAt': serializer.toJson<DateTime>(lastPracticedAt),
    };
  }

  GlyphProgressData copyWith(
          {String? glyphId,
          int? completions,
          int? cleanCompletions,
          DateTime? lastPracticedAt}) =>
      GlyphProgressData(
        glyphId: glyphId ?? this.glyphId,
        completions: completions ?? this.completions,
        cleanCompletions: cleanCompletions ?? this.cleanCompletions,
        lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      );
  GlyphProgressData copyWithCompanion(GlyphProgressCompanion data) {
    return GlyphProgressData(
      glyphId: data.glyphId.present ? data.glyphId.value : this.glyphId,
      completions:
          data.completions.present ? data.completions.value : this.completions,
      cleanCompletions: data.cleanCompletions.present
          ? data.cleanCompletions.value
          : this.cleanCompletions,
      lastPracticedAt: data.lastPracticedAt.present
          ? data.lastPracticedAt.value
          : this.lastPracticedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlyphProgressData(')
          ..write('glyphId: $glyphId, ')
          ..write('completions: $completions, ')
          ..write('cleanCompletions: $cleanCompletions, ')
          ..write('lastPracticedAt: $lastPracticedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(glyphId, completions, cleanCompletions, lastPracticedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlyphProgressData &&
          other.glyphId == this.glyphId &&
          other.completions == this.completions &&
          other.cleanCompletions == this.cleanCompletions &&
          other.lastPracticedAt == this.lastPracticedAt);
}

class GlyphProgressCompanion extends UpdateCompanion<GlyphProgressData> {
  final Value<String> glyphId;
  final Value<int> completions;
  final Value<int> cleanCompletions;
  final Value<DateTime> lastPracticedAt;
  final Value<int> rowid;
  const GlyphProgressCompanion({
    this.glyphId = const Value.absent(),
    this.completions = const Value.absent(),
    this.cleanCompletions = const Value.absent(),
    this.lastPracticedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GlyphProgressCompanion.insert({
    required String glyphId,
    this.completions = const Value.absent(),
    this.cleanCompletions = const Value.absent(),
    required DateTime lastPracticedAt,
    this.rowid = const Value.absent(),
  })  : glyphId = Value(glyphId),
        lastPracticedAt = Value(lastPracticedAt);
  static Insertable<GlyphProgressData> custom({
    Expression<String>? glyphId,
    Expression<int>? completions,
    Expression<int>? cleanCompletions,
    Expression<DateTime>? lastPracticedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (glyphId != null) 'glyph_id': glyphId,
      if (completions != null) 'completions': completions,
      if (cleanCompletions != null) 'clean_completions': cleanCompletions,
      if (lastPracticedAt != null) 'last_practiced_at': lastPracticedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GlyphProgressCompanion copyWith(
      {Value<String>? glyphId,
      Value<int>? completions,
      Value<int>? cleanCompletions,
      Value<DateTime>? lastPracticedAt,
      Value<int>? rowid}) {
    return GlyphProgressCompanion(
      glyphId: glyphId ?? this.glyphId,
      completions: completions ?? this.completions,
      cleanCompletions: cleanCompletions ?? this.cleanCompletions,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (glyphId.present) {
      map['glyph_id'] = Variable<String>(glyphId.value);
    }
    if (completions.present) {
      map['completions'] = Variable<int>(completions.value);
    }
    if (cleanCompletions.present) {
      map['clean_completions'] = Variable<int>(cleanCompletions.value);
    }
    if (lastPracticedAt.present) {
      map['last_practiced_at'] = Variable<DateTime>(lastPracticedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GlyphProgressCompanion(')
          ..write('glyphId: $glyphId, ')
          ..write('completions: $completions, ')
          ..write('cleanCompletions: $cleanCompletions, ')
          ..write('lastPracticedAt: $lastPracticedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonCompletionsTable extends LessonCompletions
    with TableInfo<$LessonCompletionsTable, LessonCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _starsEarnedMeta =
      const VerificationMeta('starsEarned');
  @override
  late final GeneratedColumn<int> starsEarned = GeneratedColumn<int>(
      'stars_earned', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, completedAt, starsEarned];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_completions';
  @override
  VerificationContext validateIntegrity(Insertable<LessonCompletion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('stars_earned')) {
      context.handle(
          _starsEarnedMeta,
          starsEarned.isAcceptableOrUnknown(
              data['stars_earned']!, _starsEarnedMeta));
    } else if (isInserting) {
      context.missing(_starsEarnedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonCompletion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
      starsEarned: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stars_earned'])!,
    );
  }

  @override
  $LessonCompletionsTable createAlias(String alias) {
    return $LessonCompletionsTable(attachedDatabase, alias);
  }
}

class LessonCompletion extends DataClass
    implements Insertable<LessonCompletion> {
  final int id;
  final DateTime completedAt;
  final int starsEarned;
  const LessonCompletion(
      {required this.id, required this.completedAt, required this.starsEarned});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['stars_earned'] = Variable<int>(starsEarned);
    return map;
  }

  LessonCompletionsCompanion toCompanion(bool nullToAbsent) {
    return LessonCompletionsCompanion(
      id: Value(id),
      completedAt: Value(completedAt),
      starsEarned: Value(starsEarned),
    );
  }

  factory LessonCompletion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonCompletion(
      id: serializer.fromJson<int>(json['id']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      starsEarned: serializer.fromJson<int>(json['starsEarned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'starsEarned': serializer.toJson<int>(starsEarned),
    };
  }

  LessonCompletion copyWith(
          {int? id, DateTime? completedAt, int? starsEarned}) =>
      LessonCompletion(
        id: id ?? this.id,
        completedAt: completedAt ?? this.completedAt,
        starsEarned: starsEarned ?? this.starsEarned,
      );
  LessonCompletion copyWithCompanion(LessonCompletionsCompanion data) {
    return LessonCompletion(
      id: data.id.present ? data.id.value : this.id,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      starsEarned:
          data.starsEarned.present ? data.starsEarned.value : this.starsEarned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonCompletion(')
          ..write('id: $id, ')
          ..write('completedAt: $completedAt, ')
          ..write('starsEarned: $starsEarned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, completedAt, starsEarned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonCompletion &&
          other.id == this.id &&
          other.completedAt == this.completedAt &&
          other.starsEarned == this.starsEarned);
}

class LessonCompletionsCompanion extends UpdateCompanion<LessonCompletion> {
  final Value<int> id;
  final Value<DateTime> completedAt;
  final Value<int> starsEarned;
  const LessonCompletionsCompanion({
    this.id = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.starsEarned = const Value.absent(),
  });
  LessonCompletionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime completedAt,
    required int starsEarned,
  })  : completedAt = Value(completedAt),
        starsEarned = Value(starsEarned);
  static Insertable<LessonCompletion> custom({
    Expression<int>? id,
    Expression<DateTime>? completedAt,
    Expression<int>? starsEarned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completedAt != null) 'completed_at': completedAt,
      if (starsEarned != null) 'stars_earned': starsEarned,
    });
  }

  LessonCompletionsCompanion copyWith(
      {Value<int>? id, Value<DateTime>? completedAt, Value<int>? starsEarned}) {
    return LessonCompletionsCompanion(
      id: id ?? this.id,
      completedAt: completedAt ?? this.completedAt,
      starsEarned: starsEarned ?? this.starsEarned,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (starsEarned.present) {
      map['stars_earned'] = Variable<int>(starsEarned.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('completedAt: $completedAt, ')
          ..write('starsEarned: $starsEarned')
          ..write(')'))
        .toString();
  }
}

class $SubjectLevelsTable extends SubjectLevels
    with TableInfo<$SubjectLevelsTable, SubjectLevel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _levelIndexMeta =
      const VerificationMeta('levelIndex');
  @override
  late final GeneratedColumn<int> levelIndex = GeneratedColumn<int>(
      'level_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _placedAtMeta =
      const VerificationMeta('placedAt');
  @override
  late final GeneratedColumn<DateTime> placedAt = GeneratedColumn<DateTime>(
      'placed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [subject, levelIndex, placedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_levels';
  @override
  VerificationContext validateIntegrity(Insertable<SubjectLevel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('level_index')) {
      context.handle(
          _levelIndexMeta,
          levelIndex.isAcceptableOrUnknown(
              data['level_index']!, _levelIndexMeta));
    } else if (isInserting) {
      context.missing(_levelIndexMeta);
    }
    if (data.containsKey('placed_at')) {
      context.handle(_placedAtMeta,
          placedAt.isAcceptableOrUnknown(data['placed_at']!, _placedAtMeta));
    } else if (isInserting) {
      context.missing(_placedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subject};
  @override
  SubjectLevel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectLevel(
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      levelIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level_index'])!,
      placedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}placed_at'])!,
    );
  }

  @override
  $SubjectLevelsTable createAlias(String alias) {
    return $SubjectLevelsTable(attachedDatabase, alias);
  }
}

class SubjectLevel extends DataClass implements Insertable<SubjectLevel> {
  final String subject;
  final int levelIndex;
  final DateTime placedAt;
  const SubjectLevel(
      {required this.subject,
      required this.levelIndex,
      required this.placedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject'] = Variable<String>(subject);
    map['level_index'] = Variable<int>(levelIndex);
    map['placed_at'] = Variable<DateTime>(placedAt);
    return map;
  }

  SubjectLevelsCompanion toCompanion(bool nullToAbsent) {
    return SubjectLevelsCompanion(
      subject: Value(subject),
      levelIndex: Value(levelIndex),
      placedAt: Value(placedAt),
    );
  }

  factory SubjectLevel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectLevel(
      subject: serializer.fromJson<String>(json['subject']),
      levelIndex: serializer.fromJson<int>(json['levelIndex']),
      placedAt: serializer.fromJson<DateTime>(json['placedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subject': serializer.toJson<String>(subject),
      'levelIndex': serializer.toJson<int>(levelIndex),
      'placedAt': serializer.toJson<DateTime>(placedAt),
    };
  }

  SubjectLevel copyWith(
          {String? subject, int? levelIndex, DateTime? placedAt}) =>
      SubjectLevel(
        subject: subject ?? this.subject,
        levelIndex: levelIndex ?? this.levelIndex,
        placedAt: placedAt ?? this.placedAt,
      );
  SubjectLevel copyWithCompanion(SubjectLevelsCompanion data) {
    return SubjectLevel(
      subject: data.subject.present ? data.subject.value : this.subject,
      levelIndex:
          data.levelIndex.present ? data.levelIndex.value : this.levelIndex,
      placedAt: data.placedAt.present ? data.placedAt.value : this.placedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectLevel(')
          ..write('subject: $subject, ')
          ..write('levelIndex: $levelIndex, ')
          ..write('placedAt: $placedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(subject, levelIndex, placedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectLevel &&
          other.subject == this.subject &&
          other.levelIndex == this.levelIndex &&
          other.placedAt == this.placedAt);
}

class SubjectLevelsCompanion extends UpdateCompanion<SubjectLevel> {
  final Value<String> subject;
  final Value<int> levelIndex;
  final Value<DateTime> placedAt;
  final Value<int> rowid;
  const SubjectLevelsCompanion({
    this.subject = const Value.absent(),
    this.levelIndex = const Value.absent(),
    this.placedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectLevelsCompanion.insert({
    required String subject,
    required int levelIndex,
    required DateTime placedAt,
    this.rowid = const Value.absent(),
  })  : subject = Value(subject),
        levelIndex = Value(levelIndex),
        placedAt = Value(placedAt);
  static Insertable<SubjectLevel> custom({
    Expression<String>? subject,
    Expression<int>? levelIndex,
    Expression<DateTime>? placedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subject != null) 'subject': subject,
      if (levelIndex != null) 'level_index': levelIndex,
      if (placedAt != null) 'placed_at': placedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectLevelsCompanion copyWith(
      {Value<String>? subject,
      Value<int>? levelIndex,
      Value<DateTime>? placedAt,
      Value<int>? rowid}) {
    return SubjectLevelsCompanion(
      subject: subject ?? this.subject,
      levelIndex: levelIndex ?? this.levelIndex,
      placedAt: placedAt ?? this.placedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (levelIndex.present) {
      map['level_index'] = Variable<int>(levelIndex.value);
    }
    if (placedAt.present) {
      map['placed_at'] = Variable<DateTime>(placedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectLevelsCompanion(')
          ..write('subject: $subject, ')
          ..write('levelIndex: $levelIndex, ')
          ..write('placedAt: $placedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StrokeAttemptsTable strokeAttempts = $StrokeAttemptsTable(this);
  late final $GlyphProgressTable glyphProgress = $GlyphProgressTable(this);
  late final $LessonCompletionsTable lessonCompletions =
      $LessonCompletionsTable(this);
  late final $SubjectLevelsTable subjectLevels = $SubjectLevelsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [strokeAttempts, glyphProgress, lessonCompletions, subjectLevels];
}

typedef $$StrokeAttemptsTableCreateCompanionBuilder = StrokeAttemptsCompanion
    Function({
  Value<int> id,
  required String glyphId,
  required int strokeIndex,
  required bool ok,
  Value<String?> error,
  required double deviation,
  Value<String?> points,
  required DateTime createdAt,
});
typedef $$StrokeAttemptsTableUpdateCompanionBuilder = StrokeAttemptsCompanion
    Function({
  Value<int> id,
  Value<String> glyphId,
  Value<int> strokeIndex,
  Value<bool> ok,
  Value<String?> error,
  Value<double> deviation,
  Value<String?> points,
  Value<DateTime> createdAt,
});

class $$StrokeAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $StrokeAttemptsTable> {
  $$StrokeAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get glyphId => $composableBuilder(
      column: $table.glyphId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strokeIndex => $composableBuilder(
      column: $table.strokeIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ok => $composableBuilder(
      column: $table.ok, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deviation => $composableBuilder(
      column: $table.deviation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get points => $composableBuilder(
      column: $table.points, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$StrokeAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $StrokeAttemptsTable> {
  $$StrokeAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get glyphId => $composableBuilder(
      column: $table.glyphId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strokeIndex => $composableBuilder(
      column: $table.strokeIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ok => $composableBuilder(
      column: $table.ok, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deviation => $composableBuilder(
      column: $table.deviation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get points => $composableBuilder(
      column: $table.points, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$StrokeAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrokeAttemptsTable> {
  $$StrokeAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get glyphId =>
      $composableBuilder(column: $table.glyphId, builder: (column) => column);

  GeneratedColumn<int> get strokeIndex => $composableBuilder(
      column: $table.strokeIndex, builder: (column) => column);

  GeneratedColumn<bool> get ok =>
      $composableBuilder(column: $table.ok, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<double> get deviation =>
      $composableBuilder(column: $table.deviation, builder: (column) => column);

  GeneratedColumn<String> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StrokeAttemptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StrokeAttemptsTable,
    StrokeAttempt,
    $$StrokeAttemptsTableFilterComposer,
    $$StrokeAttemptsTableOrderingComposer,
    $$StrokeAttemptsTableAnnotationComposer,
    $$StrokeAttemptsTableCreateCompanionBuilder,
    $$StrokeAttemptsTableUpdateCompanionBuilder,
    (
      StrokeAttempt,
      BaseReferences<_$AppDatabase, $StrokeAttemptsTable, StrokeAttempt>
    ),
    StrokeAttempt,
    PrefetchHooks Function()> {
  $$StrokeAttemptsTableTableManager(
      _$AppDatabase db, $StrokeAttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrokeAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrokeAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrokeAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> glyphId = const Value.absent(),
            Value<int> strokeIndex = const Value.absent(),
            Value<bool> ok = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<double> deviation = const Value.absent(),
            Value<String?> points = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              StrokeAttemptsCompanion(
            id: id,
            glyphId: glyphId,
            strokeIndex: strokeIndex,
            ok: ok,
            error: error,
            deviation: deviation,
            points: points,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String glyphId,
            required int strokeIndex,
            required bool ok,
            Value<String?> error = const Value.absent(),
            required double deviation,
            Value<String?> points = const Value.absent(),
            required DateTime createdAt,
          }) =>
              StrokeAttemptsCompanion.insert(
            id: id,
            glyphId: glyphId,
            strokeIndex: strokeIndex,
            ok: ok,
            error: error,
            deviation: deviation,
            points: points,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StrokeAttemptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StrokeAttemptsTable,
    StrokeAttempt,
    $$StrokeAttemptsTableFilterComposer,
    $$StrokeAttemptsTableOrderingComposer,
    $$StrokeAttemptsTableAnnotationComposer,
    $$StrokeAttemptsTableCreateCompanionBuilder,
    $$StrokeAttemptsTableUpdateCompanionBuilder,
    (
      StrokeAttempt,
      BaseReferences<_$AppDatabase, $StrokeAttemptsTable, StrokeAttempt>
    ),
    StrokeAttempt,
    PrefetchHooks Function()>;
typedef $$GlyphProgressTableCreateCompanionBuilder = GlyphProgressCompanion
    Function({
  required String glyphId,
  Value<int> completions,
  Value<int> cleanCompletions,
  required DateTime lastPracticedAt,
  Value<int> rowid,
});
typedef $$GlyphProgressTableUpdateCompanionBuilder = GlyphProgressCompanion
    Function({
  Value<String> glyphId,
  Value<int> completions,
  Value<int> cleanCompletions,
  Value<DateTime> lastPracticedAt,
  Value<int> rowid,
});

class $$GlyphProgressTableFilterComposer
    extends Composer<_$AppDatabase, $GlyphProgressTable> {
  $$GlyphProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get glyphId => $composableBuilder(
      column: $table.glyphId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completions => $composableBuilder(
      column: $table.completions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cleanCompletions => $composableBuilder(
      column: $table.cleanCompletions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPracticedAt => $composableBuilder(
      column: $table.lastPracticedAt,
      builder: (column) => ColumnFilters(column));
}

class $$GlyphProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $GlyphProgressTable> {
  $$GlyphProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get glyphId => $composableBuilder(
      column: $table.glyphId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completions => $composableBuilder(
      column: $table.completions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cleanCompletions => $composableBuilder(
      column: $table.cleanCompletions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPracticedAt => $composableBuilder(
      column: $table.lastPracticedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$GlyphProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $GlyphProgressTable> {
  $$GlyphProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get glyphId =>
      $composableBuilder(column: $table.glyphId, builder: (column) => column);

  GeneratedColumn<int> get completions => $composableBuilder(
      column: $table.completions, builder: (column) => column);

  GeneratedColumn<int> get cleanCompletions => $composableBuilder(
      column: $table.cleanCompletions, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPracticedAt => $composableBuilder(
      column: $table.lastPracticedAt, builder: (column) => column);
}

class $$GlyphProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GlyphProgressTable,
    GlyphProgressData,
    $$GlyphProgressTableFilterComposer,
    $$GlyphProgressTableOrderingComposer,
    $$GlyphProgressTableAnnotationComposer,
    $$GlyphProgressTableCreateCompanionBuilder,
    $$GlyphProgressTableUpdateCompanionBuilder,
    (
      GlyphProgressData,
      BaseReferences<_$AppDatabase, $GlyphProgressTable, GlyphProgressData>
    ),
    GlyphProgressData,
    PrefetchHooks Function()> {
  $$GlyphProgressTableTableManager(_$AppDatabase db, $GlyphProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GlyphProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GlyphProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GlyphProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> glyphId = const Value.absent(),
            Value<int> completions = const Value.absent(),
            Value<int> cleanCompletions = const Value.absent(),
            Value<DateTime> lastPracticedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GlyphProgressCompanion(
            glyphId: glyphId,
            completions: completions,
            cleanCompletions: cleanCompletions,
            lastPracticedAt: lastPracticedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String glyphId,
            Value<int> completions = const Value.absent(),
            Value<int> cleanCompletions = const Value.absent(),
            required DateTime lastPracticedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GlyphProgressCompanion.insert(
            glyphId: glyphId,
            completions: completions,
            cleanCompletions: cleanCompletions,
            lastPracticedAt: lastPracticedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GlyphProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GlyphProgressTable,
    GlyphProgressData,
    $$GlyphProgressTableFilterComposer,
    $$GlyphProgressTableOrderingComposer,
    $$GlyphProgressTableAnnotationComposer,
    $$GlyphProgressTableCreateCompanionBuilder,
    $$GlyphProgressTableUpdateCompanionBuilder,
    (
      GlyphProgressData,
      BaseReferences<_$AppDatabase, $GlyphProgressTable, GlyphProgressData>
    ),
    GlyphProgressData,
    PrefetchHooks Function()>;
typedef $$LessonCompletionsTableCreateCompanionBuilder
    = LessonCompletionsCompanion Function({
  Value<int> id,
  required DateTime completedAt,
  required int starsEarned,
});
typedef $$LessonCompletionsTableUpdateCompanionBuilder
    = LessonCompletionsCompanion Function({
  Value<int> id,
  Value<DateTime> completedAt,
  Value<int> starsEarned,
});

class $$LessonCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonCompletionsTable> {
  $$LessonCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get starsEarned => $composableBuilder(
      column: $table.starsEarned, builder: (column) => ColumnFilters(column));
}

class $$LessonCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonCompletionsTable> {
  $$LessonCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get starsEarned => $composableBuilder(
      column: $table.starsEarned, builder: (column) => ColumnOrderings(column));
}

class $$LessonCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonCompletionsTable> {
  $$LessonCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get starsEarned => $composableBuilder(
      column: $table.starsEarned, builder: (column) => column);
}

class $$LessonCompletionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonCompletionsTable,
    LessonCompletion,
    $$LessonCompletionsTableFilterComposer,
    $$LessonCompletionsTableOrderingComposer,
    $$LessonCompletionsTableAnnotationComposer,
    $$LessonCompletionsTableCreateCompanionBuilder,
    $$LessonCompletionsTableUpdateCompanionBuilder,
    (
      LessonCompletion,
      BaseReferences<_$AppDatabase, $LessonCompletionsTable, LessonCompletion>
    ),
    LessonCompletion,
    PrefetchHooks Function()> {
  $$LessonCompletionsTableTableManager(
      _$AppDatabase db, $LessonCompletionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonCompletionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<int> starsEarned = const Value.absent(),
          }) =>
              LessonCompletionsCompanion(
            id: id,
            completedAt: completedAt,
            starsEarned: starsEarned,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime completedAt,
            required int starsEarned,
          }) =>
              LessonCompletionsCompanion.insert(
            id: id,
            completedAt: completedAt,
            starsEarned: starsEarned,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LessonCompletionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonCompletionsTable,
    LessonCompletion,
    $$LessonCompletionsTableFilterComposer,
    $$LessonCompletionsTableOrderingComposer,
    $$LessonCompletionsTableAnnotationComposer,
    $$LessonCompletionsTableCreateCompanionBuilder,
    $$LessonCompletionsTableUpdateCompanionBuilder,
    (
      LessonCompletion,
      BaseReferences<_$AppDatabase, $LessonCompletionsTable, LessonCompletion>
    ),
    LessonCompletion,
    PrefetchHooks Function()>;
typedef $$SubjectLevelsTableCreateCompanionBuilder = SubjectLevelsCompanion
    Function({
  required String subject,
  required int levelIndex,
  required DateTime placedAt,
  Value<int> rowid,
});
typedef $$SubjectLevelsTableUpdateCompanionBuilder = SubjectLevelsCompanion
    Function({
  Value<String> subject,
  Value<int> levelIndex,
  Value<DateTime> placedAt,
  Value<int> rowid,
});

class $$SubjectLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectLevelsTable> {
  $$SubjectLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get levelIndex => $composableBuilder(
      column: $table.levelIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get placedAt => $composableBuilder(
      column: $table.placedAt, builder: (column) => ColumnFilters(column));
}

class $$SubjectLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectLevelsTable> {
  $$SubjectLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get levelIndex => $composableBuilder(
      column: $table.levelIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get placedAt => $composableBuilder(
      column: $table.placedAt, builder: (column) => ColumnOrderings(column));
}

class $$SubjectLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectLevelsTable> {
  $$SubjectLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get levelIndex => $composableBuilder(
      column: $table.levelIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get placedAt =>
      $composableBuilder(column: $table.placedAt, builder: (column) => column);
}

class $$SubjectLevelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubjectLevelsTable,
    SubjectLevel,
    $$SubjectLevelsTableFilterComposer,
    $$SubjectLevelsTableOrderingComposer,
    $$SubjectLevelsTableAnnotationComposer,
    $$SubjectLevelsTableCreateCompanionBuilder,
    $$SubjectLevelsTableUpdateCompanionBuilder,
    (
      SubjectLevel,
      BaseReferences<_$AppDatabase, $SubjectLevelsTable, SubjectLevel>
    ),
    SubjectLevel,
    PrefetchHooks Function()> {
  $$SubjectLevelsTableTableManager(_$AppDatabase db, $SubjectLevelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> subject = const Value.absent(),
            Value<int> levelIndex = const Value.absent(),
            Value<DateTime> placedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectLevelsCompanion(
            subject: subject,
            levelIndex: levelIndex,
            placedAt: placedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String subject,
            required int levelIndex,
            required DateTime placedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectLevelsCompanion.insert(
            subject: subject,
            levelIndex: levelIndex,
            placedAt: placedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubjectLevelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubjectLevelsTable,
    SubjectLevel,
    $$SubjectLevelsTableFilterComposer,
    $$SubjectLevelsTableOrderingComposer,
    $$SubjectLevelsTableAnnotationComposer,
    $$SubjectLevelsTableCreateCompanionBuilder,
    $$SubjectLevelsTableUpdateCompanionBuilder,
    (
      SubjectLevel,
      BaseReferences<_$AppDatabase, $SubjectLevelsTable, SubjectLevel>
    ),
    SubjectLevel,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StrokeAttemptsTableTableManager get strokeAttempts =>
      $$StrokeAttemptsTableTableManager(_db, _db.strokeAttempts);
  $$GlyphProgressTableTableManager get glyphProgress =>
      $$GlyphProgressTableTableManager(_db, _db.glyphProgress);
  $$LessonCompletionsTableTableManager get lessonCompletions =>
      $$LessonCompletionsTableTableManager(_db, _db.lessonCompletions);
  $$SubjectLevelsTableTableManager get subjectLevels =>
      $$SubjectLevelsTableTableManager(_db, _db.subjectLevels);
}
