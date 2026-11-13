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
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
  List<GeneratedColumn> get $columns => [
        id,
        kidId,
        glyphId,
        strokeIndex,
        ok,
        error,
        deviation,
        points,
        createdAt
      ];
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
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
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
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
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
  final int kidId;
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
      required this.kidId,
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
    map['kid_id'] = Variable<int>(kidId);
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
      kidId: Value(kidId),
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
      kidId: serializer.fromJson<int>(json['kidId']),
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
      'kidId': serializer.toJson<int>(kidId),
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
          int? kidId,
          String? glyphId,
          int? strokeIndex,
          bool? ok,
          Value<String?> error = const Value.absent(),
          double? deviation,
          Value<String?> points = const Value.absent(),
          DateTime? createdAt}) =>
      StrokeAttempt(
        id: id ?? this.id,
        kidId: kidId ?? this.kidId,
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
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
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
          ..write('kidId: $kidId, ')
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
      id, kidId, glyphId, strokeIndex, ok, error, deviation, points, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrokeAttempt &&
          other.id == this.id &&
          other.kidId == this.kidId &&
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
  final Value<int> kidId;
  final Value<String> glyphId;
  final Value<int> strokeIndex;
  final Value<bool> ok;
  final Value<String?> error;
  final Value<double> deviation;
  final Value<String?> points;
  final Value<DateTime> createdAt;
  const StrokeAttemptsCompanion({
    this.id = const Value.absent(),
    this.kidId = const Value.absent(),
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
    required int kidId,
    required String glyphId,
    required int strokeIndex,
    required bool ok,
    this.error = const Value.absent(),
    required double deviation,
    this.points = const Value.absent(),
    required DateTime createdAt,
  })  : kidId = Value(kidId),
        glyphId = Value(glyphId),
        strokeIndex = Value(strokeIndex),
        ok = Value(ok),
        deviation = Value(deviation),
        createdAt = Value(createdAt);
  static Insertable<StrokeAttempt> custom({
    Expression<int>? id,
    Expression<int>? kidId,
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
      if (kidId != null) 'kid_id': kidId,
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
      Value<int>? kidId,
      Value<String>? glyphId,
      Value<int>? strokeIndex,
      Value<bool>? ok,
      Value<String?>? error,
      Value<double>? deviation,
      Value<String?>? points,
      Value<DateTime>? createdAt}) {
    return StrokeAttemptsCompanion(
      id: id ?? this.id,
      kidId: kidId ?? this.kidId,
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
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
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
          ..write('kidId: $kidId, ')
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
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
      [kidId, glyphId, completions, cleanCompletions, lastPracticedAt];
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
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
    }
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
  Set<GeneratedColumn> get $primaryKey => {kidId, glyphId};
  @override
  GlyphProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlyphProgressData(
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
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
  final int kidId;
  final String glyphId;
  final int completions;

  /// Completions with at most one failed stroke.
  final int cleanCompletions;
  final DateTime lastPracticedAt;
  const GlyphProgressData(
      {required this.kidId,
      required this.glyphId,
      required this.completions,
      required this.cleanCompletions,
      required this.lastPracticedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kid_id'] = Variable<int>(kidId);
    map['glyph_id'] = Variable<String>(glyphId);
    map['completions'] = Variable<int>(completions);
    map['clean_completions'] = Variable<int>(cleanCompletions);
    map['last_practiced_at'] = Variable<DateTime>(lastPracticedAt);
    return map;
  }

  GlyphProgressCompanion toCompanion(bool nullToAbsent) {
    return GlyphProgressCompanion(
      kidId: Value(kidId),
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
      kidId: serializer.fromJson<int>(json['kidId']),
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
      'kidId': serializer.toJson<int>(kidId),
      'glyphId': serializer.toJson<String>(glyphId),
      'completions': serializer.toJson<int>(completions),
      'cleanCompletions': serializer.toJson<int>(cleanCompletions),
      'lastPracticedAt': serializer.toJson<DateTime>(lastPracticedAt),
    };
  }

  GlyphProgressData copyWith(
          {int? kidId,
          String? glyphId,
          int? completions,
          int? cleanCompletions,
          DateTime? lastPracticedAt}) =>
      GlyphProgressData(
        kidId: kidId ?? this.kidId,
        glyphId: glyphId ?? this.glyphId,
        completions: completions ?? this.completions,
        cleanCompletions: cleanCompletions ?? this.cleanCompletions,
        lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      );
  GlyphProgressData copyWithCompanion(GlyphProgressCompanion data) {
    return GlyphProgressData(
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
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
          ..write('kidId: $kidId, ')
          ..write('glyphId: $glyphId, ')
          ..write('completions: $completions, ')
          ..write('cleanCompletions: $cleanCompletions, ')
          ..write('lastPracticedAt: $lastPracticedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      kidId, glyphId, completions, cleanCompletions, lastPracticedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlyphProgressData &&
          other.kidId == this.kidId &&
          other.glyphId == this.glyphId &&
          other.completions == this.completions &&
          other.cleanCompletions == this.cleanCompletions &&
          other.lastPracticedAt == this.lastPracticedAt);
}

class GlyphProgressCompanion extends UpdateCompanion<GlyphProgressData> {
  final Value<int> kidId;
  final Value<String> glyphId;
  final Value<int> completions;
  final Value<int> cleanCompletions;
  final Value<DateTime> lastPracticedAt;
  final Value<int> rowid;
  const GlyphProgressCompanion({
    this.kidId = const Value.absent(),
    this.glyphId = const Value.absent(),
    this.completions = const Value.absent(),
    this.cleanCompletions = const Value.absent(),
    this.lastPracticedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GlyphProgressCompanion.insert({
    required int kidId,
    required String glyphId,
    this.completions = const Value.absent(),
    this.cleanCompletions = const Value.absent(),
    required DateTime lastPracticedAt,
    this.rowid = const Value.absent(),
  })  : kidId = Value(kidId),
        glyphId = Value(glyphId),
        lastPracticedAt = Value(lastPracticedAt);
  static Insertable<GlyphProgressData> custom({
    Expression<int>? kidId,
    Expression<String>? glyphId,
    Expression<int>? completions,
    Expression<int>? cleanCompletions,
    Expression<DateTime>? lastPracticedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kidId != null) 'kid_id': kidId,
      if (glyphId != null) 'glyph_id': glyphId,
      if (completions != null) 'completions': completions,
      if (cleanCompletions != null) 'clean_completions': cleanCompletions,
      if (lastPracticedAt != null) 'last_practiced_at': lastPracticedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GlyphProgressCompanion copyWith(
      {Value<int>? kidId,
      Value<String>? glyphId,
      Value<int>? completions,
      Value<int>? cleanCompletions,
      Value<DateTime>? lastPracticedAt,
      Value<int>? rowid}) {
    return GlyphProgressCompanion(
      kidId: kidId ?? this.kidId,
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
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
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
          ..write('kidId: $kidId, ')
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
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
  List<GeneratedColumn> get $columns => [id, kidId, completedAt, starsEarned];
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
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
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
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
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
  final int kidId;
  final DateTime completedAt;
  final int starsEarned;
  const LessonCompletion(
      {required this.id,
      required this.kidId,
      required this.completedAt,
      required this.starsEarned});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kid_id'] = Variable<int>(kidId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['stars_earned'] = Variable<int>(starsEarned);
    return map;
  }

  LessonCompletionsCompanion toCompanion(bool nullToAbsent) {
    return LessonCompletionsCompanion(
      id: Value(id),
      kidId: Value(kidId),
      completedAt: Value(completedAt),
      starsEarned: Value(starsEarned),
    );
  }

  factory LessonCompletion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonCompletion(
      id: serializer.fromJson<int>(json['id']),
      kidId: serializer.fromJson<int>(json['kidId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      starsEarned: serializer.fromJson<int>(json['starsEarned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kidId': serializer.toJson<int>(kidId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'starsEarned': serializer.toJson<int>(starsEarned),
    };
  }

  LessonCompletion copyWith(
          {int? id, int? kidId, DateTime? completedAt, int? starsEarned}) =>
      LessonCompletion(
        id: id ?? this.id,
        kidId: kidId ?? this.kidId,
        completedAt: completedAt ?? this.completedAt,
        starsEarned: starsEarned ?? this.starsEarned,
      );
  LessonCompletion copyWithCompanion(LessonCompletionsCompanion data) {
    return LessonCompletion(
      id: data.id.present ? data.id.value : this.id,
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
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
          ..write('kidId: $kidId, ')
          ..write('completedAt: $completedAt, ')
          ..write('starsEarned: $starsEarned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kidId, completedAt, starsEarned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonCompletion &&
          other.id == this.id &&
          other.kidId == this.kidId &&
          other.completedAt == this.completedAt &&
          other.starsEarned == this.starsEarned);
}

class LessonCompletionsCompanion extends UpdateCompanion<LessonCompletion> {
  final Value<int> id;
  final Value<int> kidId;
  final Value<DateTime> completedAt;
  final Value<int> starsEarned;
  const LessonCompletionsCompanion({
    this.id = const Value.absent(),
    this.kidId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.starsEarned = const Value.absent(),
  });
  LessonCompletionsCompanion.insert({
    this.id = const Value.absent(),
    required int kidId,
    required DateTime completedAt,
    required int starsEarned,
  })  : kidId = Value(kidId),
        completedAt = Value(completedAt),
        starsEarned = Value(starsEarned);
  static Insertable<LessonCompletion> custom({
    Expression<int>? id,
    Expression<int>? kidId,
    Expression<DateTime>? completedAt,
    Expression<int>? starsEarned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kidId != null) 'kid_id': kidId,
      if (completedAt != null) 'completed_at': completedAt,
      if (starsEarned != null) 'stars_earned': starsEarned,
    });
  }

  LessonCompletionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? kidId,
      Value<DateTime>? completedAt,
      Value<int>? starsEarned}) {
    return LessonCompletionsCompanion(
      id: id ?? this.id,
      kidId: kidId ?? this.kidId,
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
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
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
          ..write('kidId: $kidId, ')
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
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
  List<GeneratedColumn> get $columns => [kidId, subject, levelIndex, placedAt];
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
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
    }
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
  Set<GeneratedColumn> get $primaryKey => {kidId, subject};
  @override
  SubjectLevel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectLevel(
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
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
  final int kidId;
  final String subject;
  final int levelIndex;
  final DateTime placedAt;
  const SubjectLevel(
      {required this.kidId,
      required this.subject,
      required this.levelIndex,
      required this.placedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kid_id'] = Variable<int>(kidId);
    map['subject'] = Variable<String>(subject);
    map['level_index'] = Variable<int>(levelIndex);
    map['placed_at'] = Variable<DateTime>(placedAt);
    return map;
  }

  SubjectLevelsCompanion toCompanion(bool nullToAbsent) {
    return SubjectLevelsCompanion(
      kidId: Value(kidId),
      subject: Value(subject),
      levelIndex: Value(levelIndex),
      placedAt: Value(placedAt),
    );
  }

  factory SubjectLevel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectLevel(
      kidId: serializer.fromJson<int>(json['kidId']),
      subject: serializer.fromJson<String>(json['subject']),
      levelIndex: serializer.fromJson<int>(json['levelIndex']),
      placedAt: serializer.fromJson<DateTime>(json['placedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kidId': serializer.toJson<int>(kidId),
      'subject': serializer.toJson<String>(subject),
      'levelIndex': serializer.toJson<int>(levelIndex),
      'placedAt': serializer.toJson<DateTime>(placedAt),
    };
  }

  SubjectLevel copyWith(
          {int? kidId, String? subject, int? levelIndex, DateTime? placedAt}) =>
      SubjectLevel(
        kidId: kidId ?? this.kidId,
        subject: subject ?? this.subject,
        levelIndex: levelIndex ?? this.levelIndex,
        placedAt: placedAt ?? this.placedAt,
      );
  SubjectLevel copyWithCompanion(SubjectLevelsCompanion data) {
    return SubjectLevel(
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      subject: data.subject.present ? data.subject.value : this.subject,
      levelIndex:
          data.levelIndex.present ? data.levelIndex.value : this.levelIndex,
      placedAt: data.placedAt.present ? data.placedAt.value : this.placedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectLevel(')
          ..write('kidId: $kidId, ')
          ..write('subject: $subject, ')
          ..write('levelIndex: $levelIndex, ')
          ..write('placedAt: $placedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kidId, subject, levelIndex, placedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectLevel &&
          other.kidId == this.kidId &&
          other.subject == this.subject &&
          other.levelIndex == this.levelIndex &&
          other.placedAt == this.placedAt);
}

class SubjectLevelsCompanion extends UpdateCompanion<SubjectLevel> {
  final Value<int> kidId;
  final Value<String> subject;
  final Value<int> levelIndex;
  final Value<DateTime> placedAt;
  final Value<int> rowid;
  const SubjectLevelsCompanion({
    this.kidId = const Value.absent(),
    this.subject = const Value.absent(),
    this.levelIndex = const Value.absent(),
    this.placedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectLevelsCompanion.insert({
    required int kidId,
    required String subject,
    required int levelIndex,
    required DateTime placedAt,
    this.rowid = const Value.absent(),
  })  : kidId = Value(kidId),
        subject = Value(subject),
        levelIndex = Value(levelIndex),
        placedAt = Value(placedAt);
  static Insertable<SubjectLevel> custom({
    Expression<int>? kidId,
    Expression<String>? subject,
    Expression<int>? levelIndex,
    Expression<DateTime>? placedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kidId != null) 'kid_id': kidId,
      if (subject != null) 'subject': subject,
      if (levelIndex != null) 'level_index': levelIndex,
      if (placedAt != null) 'placed_at': placedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectLevelsCompanion copyWith(
      {Value<int>? kidId,
      Value<String>? subject,
      Value<int>? levelIndex,
      Value<DateTime>? placedAt,
      Value<int>? rowid}) {
    return SubjectLevelsCompanion(
      kidId: kidId ?? this.kidId,
      subject: subject ?? this.subject,
      levelIndex: levelIndex ?? this.levelIndex,
      placedAt: placedAt ?? this.placedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
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
          ..write('kidId: $kidId, ')
          ..write('subject: $subject, ')
          ..write('levelIndex: $levelIndex, ')
          ..write('placedAt: $placedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KidProfilesTable extends KidProfiles
    with TableInfo<$KidProfilesTable, KidProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KidProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nicknameMeta =
      const VerificationMeta('nickname');
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
      'nickname', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
      'avatar', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, nickname, avatar, age, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kid_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<KidProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nickname')) {
      context.handle(_nicknameMeta,
          nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta));
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(_avatarMeta,
          avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta));
    } else if (isInserting) {
      context.missing(_avatarMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    } else if (isInserting) {
      context.missing(_ageMeta);
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
  KidProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KidProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nickname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nickname'])!,
      avatar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar'])!,
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $KidProfilesTable createAlias(String alias) {
    return $KidProfilesTable(attachedDatabase, alias);
  }
}

class KidProfile extends DataClass implements Insertable<KidProfile> {
  final int id;
  final String nickname;
  final String avatar;
  final int age;
  final DateTime createdAt;
  const KidProfile(
      {required this.id,
      required this.nickname,
      required this.avatar,
      required this.age,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nickname'] = Variable<String>(nickname);
    map['avatar'] = Variable<String>(avatar);
    map['age'] = Variable<int>(age);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  KidProfilesCompanion toCompanion(bool nullToAbsent) {
    return KidProfilesCompanion(
      id: Value(id),
      nickname: Value(nickname),
      avatar: Value(avatar),
      age: Value(age),
      createdAt: Value(createdAt),
    );
  }

  factory KidProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KidProfile(
      id: serializer.fromJson<int>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      avatar: serializer.fromJson<String>(json['avatar']),
      age: serializer.fromJson<int>(json['age']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nickname': serializer.toJson<String>(nickname),
      'avatar': serializer.toJson<String>(avatar),
      'age': serializer.toJson<int>(age),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  KidProfile copyWith(
          {int? id,
          String? nickname,
          String? avatar,
          int? age,
          DateTime? createdAt}) =>
      KidProfile(
        id: id ?? this.id,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        age: age ?? this.age,
        createdAt: createdAt ?? this.createdAt,
      );
  KidProfile copyWithCompanion(KidProfilesCompanion data) {
    return KidProfile(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      age: data.age.present ? data.age.value : this.age,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KidProfile(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('age: $age, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nickname, avatar, age, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KidProfile &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.avatar == this.avatar &&
          other.age == this.age &&
          other.createdAt == this.createdAt);
}

class KidProfilesCompanion extends UpdateCompanion<KidProfile> {
  final Value<int> id;
  final Value<String> nickname;
  final Value<String> avatar;
  final Value<int> age;
  final Value<DateTime> createdAt;
  const KidProfilesCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatar = const Value.absent(),
    this.age = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  KidProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String nickname,
    required String avatar,
    required int age,
    required DateTime createdAt,
  })  : nickname = Value(nickname),
        avatar = Value(avatar),
        age = Value(age),
        createdAt = Value(createdAt);
  static Insertable<KidProfile> custom({
    Expression<int>? id,
    Expression<String>? nickname,
    Expression<String>? avatar,
    Expression<int>? age,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (age != null) 'age': age,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  KidProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? nickname,
      Value<String>? avatar,
      Value<int>? age,
      Value<DateTime>? createdAt}) {
    return KidProfilesCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KidProfilesCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('age: $age, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) => AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyUsageTable extends DailyUsage
    with TableInfo<$DailyUsageTable, DailyUsageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyUsageTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
      'day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _secondsMeta =
      const VerificationMeta('seconds');
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
      'seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [kidId, day, seconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_usage';
  @override
  VerificationContext validateIntegrity(Insertable<DailyUsageData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(_secondsMeta,
          seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kidId, day};
  @override
  DailyUsageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyUsageData(
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      seconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seconds'])!,
    );
  }

  @override
  $DailyUsageTable createAlias(String alias) {
    return $DailyUsageTable(attachedDatabase, alias);
  }
}

class DailyUsageData extends DataClass implements Insertable<DailyUsageData> {
  final int kidId;

  /// Local date as `yyyy-MM-dd`.
  final String day;
  final int seconds;
  const DailyUsageData(
      {required this.kidId, required this.day, required this.seconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kid_id'] = Variable<int>(kidId);
    map['day'] = Variable<String>(day);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  DailyUsageCompanion toCompanion(bool nullToAbsent) {
    return DailyUsageCompanion(
      kidId: Value(kidId),
      day: Value(day),
      seconds: Value(seconds),
    );
  }

  factory DailyUsageData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyUsageData(
      kidId: serializer.fromJson<int>(json['kidId']),
      day: serializer.fromJson<String>(json['day']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kidId': serializer.toJson<int>(kidId),
      'day': serializer.toJson<String>(day),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  DailyUsageData copyWith({int? kidId, String? day, int? seconds}) =>
      DailyUsageData(
        kidId: kidId ?? this.kidId,
        day: day ?? this.day,
        seconds: seconds ?? this.seconds,
      );
  DailyUsageData copyWithCompanion(DailyUsageCompanion data) {
    return DailyUsageData(
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      day: data.day.present ? data.day.value : this.day,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyUsageData(')
          ..write('kidId: $kidId, ')
          ..write('day: $day, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kidId, day, seconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyUsageData &&
          other.kidId == this.kidId &&
          other.day == this.day &&
          other.seconds == this.seconds);
}

class DailyUsageCompanion extends UpdateCompanion<DailyUsageData> {
  final Value<int> kidId;
  final Value<String> day;
  final Value<int> seconds;
  final Value<int> rowid;
  const DailyUsageCompanion({
    this.kidId = const Value.absent(),
    this.day = const Value.absent(),
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyUsageCompanion.insert({
    required int kidId,
    required String day,
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : kidId = Value(kidId),
        day = Value(day);
  static Insertable<DailyUsageData> custom({
    Expression<int>? kidId,
    Expression<String>? day,
    Expression<int>? seconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kidId != null) 'kid_id': kidId,
      if (day != null) 'day': day,
      if (seconds != null) 'seconds': seconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyUsageCompanion copyWith(
      {Value<int>? kidId,
      Value<String>? day,
      Value<int>? seconds,
      Value<int>? rowid}) {
    return DailyUsageCompanion(
      kidId: kidId ?? this.kidId,
      day: day ?? this.day,
      seconds: seconds ?? this.seconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyUsageCompanion(')
          ..write('kidId: $kidId, ')
          ..write('day: $day, ')
          ..write('seconds: $seconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RealRewardsTable extends RealRewards
    with TableInfo<$RealRewardsTable, RealReward> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RealRewardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _starsNeededMeta =
      const VerificationMeta('starsNeeded');
  @override
  late final GeneratedColumn<int> starsNeeded = GeneratedColumn<int>(
      'stars_needed', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _redeemedAtMeta =
      const VerificationMeta('redeemedAt');
  @override
  late final GeneratedColumn<DateTime> redeemedAt = GeneratedColumn<DateTime>(
      'redeemed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, kidId, title, starsNeeded, createdAt, redeemedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'real_rewards';
  @override
  VerificationContext validateIntegrity(Insertable<RealReward> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('stars_needed')) {
      context.handle(
          _starsNeededMeta,
          starsNeeded.isAcceptableOrUnknown(
              data['stars_needed']!, _starsNeededMeta));
    } else if (isInserting) {
      context.missing(_starsNeededMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('redeemed_at')) {
      context.handle(
          _redeemedAtMeta,
          redeemedAt.isAcceptableOrUnknown(
              data['redeemed_at']!, _redeemedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RealReward map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RealReward(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      starsNeeded: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stars_needed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      redeemedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}redeemed_at']),
    );
  }

  @override
  $RealRewardsTable createAlias(String alias) {
    return $RealRewardsTable(attachedDatabase, alias);
  }
}

class RealReward extends DataClass implements Insertable<RealReward> {
  final int id;
  final int kidId;
  final String title;
  final int starsNeeded;
  final DateTime createdAt;
  final DateTime? redeemedAt;
  const RealReward(
      {required this.id,
      required this.kidId,
      required this.title,
      required this.starsNeeded,
      required this.createdAt,
      this.redeemedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kid_id'] = Variable<int>(kidId);
    map['title'] = Variable<String>(title);
    map['stars_needed'] = Variable<int>(starsNeeded);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || redeemedAt != null) {
      map['redeemed_at'] = Variable<DateTime>(redeemedAt);
    }
    return map;
  }

  RealRewardsCompanion toCompanion(bool nullToAbsent) {
    return RealRewardsCompanion(
      id: Value(id),
      kidId: Value(kidId),
      title: Value(title),
      starsNeeded: Value(starsNeeded),
      createdAt: Value(createdAt),
      redeemedAt: redeemedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(redeemedAt),
    );
  }

  factory RealReward.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RealReward(
      id: serializer.fromJson<int>(json['id']),
      kidId: serializer.fromJson<int>(json['kidId']),
      title: serializer.fromJson<String>(json['title']),
      starsNeeded: serializer.fromJson<int>(json['starsNeeded']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      redeemedAt: serializer.fromJson<DateTime?>(json['redeemedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kidId': serializer.toJson<int>(kidId),
      'title': serializer.toJson<String>(title),
      'starsNeeded': serializer.toJson<int>(starsNeeded),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'redeemedAt': serializer.toJson<DateTime?>(redeemedAt),
    };
  }

  RealReward copyWith(
          {int? id,
          int? kidId,
          String? title,
          int? starsNeeded,
          DateTime? createdAt,
          Value<DateTime?> redeemedAt = const Value.absent()}) =>
      RealReward(
        id: id ?? this.id,
        kidId: kidId ?? this.kidId,
        title: title ?? this.title,
        starsNeeded: starsNeeded ?? this.starsNeeded,
        createdAt: createdAt ?? this.createdAt,
        redeemedAt: redeemedAt.present ? redeemedAt.value : this.redeemedAt,
      );
  RealReward copyWithCompanion(RealRewardsCompanion data) {
    return RealReward(
      id: data.id.present ? data.id.value : this.id,
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      title: data.title.present ? data.title.value : this.title,
      starsNeeded:
          data.starsNeeded.present ? data.starsNeeded.value : this.starsNeeded,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      redeemedAt:
          data.redeemedAt.present ? data.redeemedAt.value : this.redeemedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RealReward(')
          ..write('id: $id, ')
          ..write('kidId: $kidId, ')
          ..write('title: $title, ')
          ..write('starsNeeded: $starsNeeded, ')
          ..write('createdAt: $createdAt, ')
          ..write('redeemedAt: $redeemedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kidId, title, starsNeeded, createdAt, redeemedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RealReward &&
          other.id == this.id &&
          other.kidId == this.kidId &&
          other.title == this.title &&
          other.starsNeeded == this.starsNeeded &&
          other.createdAt == this.createdAt &&
          other.redeemedAt == this.redeemedAt);
}

class RealRewardsCompanion extends UpdateCompanion<RealReward> {
  final Value<int> id;
  final Value<int> kidId;
  final Value<String> title;
  final Value<int> starsNeeded;
  final Value<DateTime> createdAt;
  final Value<DateTime?> redeemedAt;
  const RealRewardsCompanion({
    this.id = const Value.absent(),
    this.kidId = const Value.absent(),
    this.title = const Value.absent(),
    this.starsNeeded = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.redeemedAt = const Value.absent(),
  });
  RealRewardsCompanion.insert({
    this.id = const Value.absent(),
    required int kidId,
    required String title,
    required int starsNeeded,
    required DateTime createdAt,
    this.redeemedAt = const Value.absent(),
  })  : kidId = Value(kidId),
        title = Value(title),
        starsNeeded = Value(starsNeeded),
        createdAt = Value(createdAt);
  static Insertable<RealReward> custom({
    Expression<int>? id,
    Expression<int>? kidId,
    Expression<String>? title,
    Expression<int>? starsNeeded,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? redeemedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kidId != null) 'kid_id': kidId,
      if (title != null) 'title': title,
      if (starsNeeded != null) 'stars_needed': starsNeeded,
      if (createdAt != null) 'created_at': createdAt,
      if (redeemedAt != null) 'redeemed_at': redeemedAt,
    });
  }

  RealRewardsCompanion copyWith(
      {Value<int>? id,
      Value<int>? kidId,
      Value<String>? title,
      Value<int>? starsNeeded,
      Value<DateTime>? createdAt,
      Value<DateTime?>? redeemedAt}) {
    return RealRewardsCompanion(
      id: id ?? this.id,
      kidId: kidId ?? this.kidId,
      title: title ?? this.title,
      starsNeeded: starsNeeded ?? this.starsNeeded,
      createdAt: createdAt ?? this.createdAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (starsNeeded.present) {
      map['stars_needed'] = Variable<int>(starsNeeded.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (redeemedAt.present) {
      map['redeemed_at'] = Variable<DateTime>(redeemedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RealRewardsCompanion(')
          ..write('id: $id, ')
          ..write('kidId: $kidId, ')
          ..write('title: $title, ')
          ..write('starsNeeded: $starsNeeded, ')
          ..write('createdAt: $createdAt, ')
          ..write('redeemedAt: $redeemedAt')
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
  late final $KidProfilesTable kidProfiles = $KidProfilesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $DailyUsageTable dailyUsage = $DailyUsageTable(this);
  late final $RealRewardsTable realRewards = $RealRewardsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        strokeAttempts,
        glyphProgress,
        lessonCompletions,
        subjectLevels,
        kidProfiles,
        appSettings,
        dailyUsage,
        realRewards
      ];
}

typedef $$StrokeAttemptsTableCreateCompanionBuilder = StrokeAttemptsCompanion
    Function({
  Value<int> id,
  required int kidId,
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
  Value<int> kidId,
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

  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

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
            Value<int> kidId = const Value.absent(),
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
            kidId: kidId,
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
            required int kidId,
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
            kidId: kidId,
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
  required int kidId,
  required String glyphId,
  Value<int> completions,
  Value<int> cleanCompletions,
  required DateTime lastPracticedAt,
  Value<int> rowid,
});
typedef $$GlyphProgressTableUpdateCompanionBuilder = GlyphProgressCompanion
    Function({
  Value<int> kidId,
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
  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

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
  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

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
  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

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
            Value<int> kidId = const Value.absent(),
            Value<String> glyphId = const Value.absent(),
            Value<int> completions = const Value.absent(),
            Value<int> cleanCompletions = const Value.absent(),
            Value<DateTime> lastPracticedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GlyphProgressCompanion(
            kidId: kidId,
            glyphId: glyphId,
            completions: completions,
            cleanCompletions: cleanCompletions,
            lastPracticedAt: lastPracticedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int kidId,
            required String glyphId,
            Value<int> completions = const Value.absent(),
            Value<int> cleanCompletions = const Value.absent(),
            required DateTime lastPracticedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GlyphProgressCompanion.insert(
            kidId: kidId,
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
  required int kidId,
  required DateTime completedAt,
  required int starsEarned,
});
typedef $$LessonCompletionsTableUpdateCompanionBuilder
    = LessonCompletionsCompanion Function({
  Value<int> id,
  Value<int> kidId,
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

  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

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
            Value<int> kidId = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<int> starsEarned = const Value.absent(),
          }) =>
              LessonCompletionsCompanion(
            id: id,
            kidId: kidId,
            completedAt: completedAt,
            starsEarned: starsEarned,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int kidId,
            required DateTime completedAt,
            required int starsEarned,
          }) =>
              LessonCompletionsCompanion.insert(
            id: id,
            kidId: kidId,
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
  required int kidId,
  required String subject,
  required int levelIndex,
  required DateTime placedAt,
  Value<int> rowid,
});
typedef $$SubjectLevelsTableUpdateCompanionBuilder = SubjectLevelsCompanion
    Function({
  Value<int> kidId,
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
  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

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
  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

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
  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

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
            Value<int> kidId = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<int> levelIndex = const Value.absent(),
            Value<DateTime> placedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectLevelsCompanion(
            kidId: kidId,
            subject: subject,
            levelIndex: levelIndex,
            placedAt: placedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int kidId,
            required String subject,
            required int levelIndex,
            required DateTime placedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectLevelsCompanion.insert(
            kidId: kidId,
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
typedef $$KidProfilesTableCreateCompanionBuilder = KidProfilesCompanion
    Function({
  Value<int> id,
  required String nickname,
  required String avatar,
  required int age,
  required DateTime createdAt,
});
typedef $$KidProfilesTableUpdateCompanionBuilder = KidProfilesCompanion
    Function({
  Value<int> id,
  Value<String> nickname,
  Value<String> avatar,
  Value<int> age,
  Value<DateTime> createdAt,
});

class $$KidProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $KidProfilesTable> {
  $$KidProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nickname => $composableBuilder(
      column: $table.nickname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatar => $composableBuilder(
      column: $table.avatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$KidProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $KidProfilesTable> {
  $$KidProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nickname => $composableBuilder(
      column: $table.nickname, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatar => $composableBuilder(
      column: $table.avatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$KidProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KidProfilesTable> {
  $$KidProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$KidProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KidProfilesTable,
    KidProfile,
    $$KidProfilesTableFilterComposer,
    $$KidProfilesTableOrderingComposer,
    $$KidProfilesTableAnnotationComposer,
    $$KidProfilesTableCreateCompanionBuilder,
    $$KidProfilesTableUpdateCompanionBuilder,
    (KidProfile, BaseReferences<_$AppDatabase, $KidProfilesTable, KidProfile>),
    KidProfile,
    PrefetchHooks Function()> {
  $$KidProfilesTableTableManager(_$AppDatabase db, $KidProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KidProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KidProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KidProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nickname = const Value.absent(),
            Value<String> avatar = const Value.absent(),
            Value<int> age = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              KidProfilesCompanion(
            id: id,
            nickname: nickname,
            avatar: avatar,
            age: age,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nickname,
            required String avatar,
            required int age,
            required DateTime createdAt,
          }) =>
              KidProfilesCompanion.insert(
            id: id,
            nickname: nickname,
            avatar: avatar,
            age: age,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KidProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KidProfilesTable,
    KidProfile,
    $$KidProfilesTableFilterComposer,
    $$KidProfilesTableOrderingComposer,
    $$KidProfilesTableAnnotationComposer,
    $$KidProfilesTableCreateCompanionBuilder,
    $$KidProfilesTableUpdateCompanionBuilder,
    (KidProfile, BaseReferences<_$AppDatabase, $KidProfilesTable, KidProfile>),
    KidProfile,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$DailyUsageTableCreateCompanionBuilder = DailyUsageCompanion Function({
  required int kidId,
  required String day,
  Value<int> seconds,
  Value<int> rowid,
});
typedef $$DailyUsageTableUpdateCompanionBuilder = DailyUsageCompanion Function({
  Value<int> kidId,
  Value<String> day,
  Value<int> seconds,
  Value<int> rowid,
});

class $$DailyUsageTableFilterComposer
    extends Composer<_$AppDatabase, $DailyUsageTable> {
  $$DailyUsageTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seconds => $composableBuilder(
      column: $table.seconds, builder: (column) => ColumnFilters(column));
}

class $$DailyUsageTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyUsageTable> {
  $$DailyUsageTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seconds => $composableBuilder(
      column: $table.seconds, builder: (column) => ColumnOrderings(column));
}

class $$DailyUsageTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyUsageTable> {
  $$DailyUsageTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);
}

class $$DailyUsageTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyUsageTable,
    DailyUsageData,
    $$DailyUsageTableFilterComposer,
    $$DailyUsageTableOrderingComposer,
    $$DailyUsageTableAnnotationComposer,
    $$DailyUsageTableCreateCompanionBuilder,
    $$DailyUsageTableUpdateCompanionBuilder,
    (
      DailyUsageData,
      BaseReferences<_$AppDatabase, $DailyUsageTable, DailyUsageData>
    ),
    DailyUsageData,
    PrefetchHooks Function()> {
  $$DailyUsageTableTableManager(_$AppDatabase db, $DailyUsageTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyUsageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyUsageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyUsageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> kidId = const Value.absent(),
            Value<String> day = const Value.absent(),
            Value<int> seconds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyUsageCompanion(
            kidId: kidId,
            day: day,
            seconds: seconds,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int kidId,
            required String day,
            Value<int> seconds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyUsageCompanion.insert(
            kidId: kidId,
            day: day,
            seconds: seconds,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyUsageTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyUsageTable,
    DailyUsageData,
    $$DailyUsageTableFilterComposer,
    $$DailyUsageTableOrderingComposer,
    $$DailyUsageTableAnnotationComposer,
    $$DailyUsageTableCreateCompanionBuilder,
    $$DailyUsageTableUpdateCompanionBuilder,
    (
      DailyUsageData,
      BaseReferences<_$AppDatabase, $DailyUsageTable, DailyUsageData>
    ),
    DailyUsageData,
    PrefetchHooks Function()>;
typedef $$RealRewardsTableCreateCompanionBuilder = RealRewardsCompanion
    Function({
  Value<int> id,
  required int kidId,
  required String title,
  required int starsNeeded,
  required DateTime createdAt,
  Value<DateTime?> redeemedAt,
});
typedef $$RealRewardsTableUpdateCompanionBuilder = RealRewardsCompanion
    Function({
  Value<int> id,
  Value<int> kidId,
  Value<String> title,
  Value<int> starsNeeded,
  Value<DateTime> createdAt,
  Value<DateTime?> redeemedAt,
});

class $$RealRewardsTableFilterComposer
    extends Composer<_$AppDatabase, $RealRewardsTable> {
  $$RealRewardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get starsNeeded => $composableBuilder(
      column: $table.starsNeeded, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get redeemedAt => $composableBuilder(
      column: $table.redeemedAt, builder: (column) => ColumnFilters(column));
}

class $$RealRewardsTableOrderingComposer
    extends Composer<_$AppDatabase, $RealRewardsTable> {
  $$RealRewardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get starsNeeded => $composableBuilder(
      column: $table.starsNeeded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get redeemedAt => $composableBuilder(
      column: $table.redeemedAt, builder: (column) => ColumnOrderings(column));
}

class $$RealRewardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RealRewardsTable> {
  $$RealRewardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get starsNeeded => $composableBuilder(
      column: $table.starsNeeded, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get redeemedAt => $composableBuilder(
      column: $table.redeemedAt, builder: (column) => column);
}

class $$RealRewardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RealRewardsTable,
    RealReward,
    $$RealRewardsTableFilterComposer,
    $$RealRewardsTableOrderingComposer,
    $$RealRewardsTableAnnotationComposer,
    $$RealRewardsTableCreateCompanionBuilder,
    $$RealRewardsTableUpdateCompanionBuilder,
    (RealReward, BaseReferences<_$AppDatabase, $RealRewardsTable, RealReward>),
    RealReward,
    PrefetchHooks Function()> {
  $$RealRewardsTableTableManager(_$AppDatabase db, $RealRewardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RealRewardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RealRewardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RealRewardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> kidId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> starsNeeded = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> redeemedAt = const Value.absent(),
          }) =>
              RealRewardsCompanion(
            id: id,
            kidId: kidId,
            title: title,
            starsNeeded: starsNeeded,
            createdAt: createdAt,
            redeemedAt: redeemedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int kidId,
            required String title,
            required int starsNeeded,
            required DateTime createdAt,
            Value<DateTime?> redeemedAt = const Value.absent(),
          }) =>
              RealRewardsCompanion.insert(
            id: id,
            kidId: kidId,
            title: title,
            starsNeeded: starsNeeded,
            createdAt: createdAt,
            redeemedAt: redeemedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RealRewardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RealRewardsTable,
    RealReward,
    $$RealRewardsTableFilterComposer,
    $$RealRewardsTableOrderingComposer,
    $$RealRewardsTableAnnotationComposer,
    $$RealRewardsTableCreateCompanionBuilder,
    $$RealRewardsTableUpdateCompanionBuilder,
    (RealReward, BaseReferences<_$AppDatabase, $RealRewardsTable, RealReward>),
    RealReward,
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
  $$KidProfilesTableTableManager get kidProfiles =>
      $$KidProfilesTableTableManager(_db, _db.kidProfiles);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$DailyUsageTableTableManager get dailyUsage =>
      $$DailyUsageTableTableManager(_db, _db.dailyUsage);
  $$RealRewardsTableTableManager get realRewards =>
      $$RealRewardsTableTableManager(_db, _db.realRewards);
}
