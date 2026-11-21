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
  /// rejection can be replayed in a test. Old glyphs (no ruling) use the
  /// glyph's own [0,1] square; letters and tone marks are stored in *window*
  /// coordinates, so replay them against `glyph.inWindow()`.
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, nickname, avatar, age, createdAt, uuid];
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
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
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
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid']),
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

  /// Stable id across devices for online sync (v8). Set for every kid; null
  /// only in the instant between the v8 column add and its backfill.
  final String? uuid;
  const KidProfile(
      {required this.id,
      required this.nickname,
      required this.avatar,
      required this.age,
      required this.createdAt,
      this.uuid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nickname'] = Variable<String>(nickname);
    map['avatar'] = Variable<String>(avatar);
    map['age'] = Variable<int>(age);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || uuid != null) {
      map['uuid'] = Variable<String>(uuid);
    }
    return map;
  }

  KidProfilesCompanion toCompanion(bool nullToAbsent) {
    return KidProfilesCompanion(
      id: Value(id),
      nickname: Value(nickname),
      avatar: Value(avatar),
      age: Value(age),
      createdAt: Value(createdAt),
      uuid: uuid == null && nullToAbsent ? const Value.absent() : Value(uuid),
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
      uuid: serializer.fromJson<String?>(json['uuid']),
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
      'uuid': serializer.toJson<String?>(uuid),
    };
  }

  KidProfile copyWith(
          {int? id,
          String? nickname,
          String? avatar,
          int? age,
          DateTime? createdAt,
          Value<String?> uuid = const Value.absent()}) =>
      KidProfile(
        id: id ?? this.id,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        age: age ?? this.age,
        createdAt: createdAt ?? this.createdAt,
        uuid: uuid.present ? uuid.value : this.uuid,
      );
  KidProfile copyWithCompanion(KidProfilesCompanion data) {
    return KidProfile(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      age: data.age.present ? data.age.value : this.age,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KidProfile(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('age: $age, ')
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nickname, avatar, age, createdAt, uuid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KidProfile &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.avatar == this.avatar &&
          other.age == this.age &&
          other.createdAt == this.createdAt &&
          other.uuid == this.uuid);
}

class KidProfilesCompanion extends UpdateCompanion<KidProfile> {
  final Value<int> id;
  final Value<String> nickname;
  final Value<String> avatar;
  final Value<int> age;
  final Value<DateTime> createdAt;
  final Value<String?> uuid;
  const KidProfilesCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatar = const Value.absent(),
    this.age = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uuid = const Value.absent(),
  });
  KidProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String nickname,
    required String avatar,
    required int age,
    required DateTime createdAt,
    this.uuid = const Value.absent(),
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
    Expression<String>? uuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (age != null) 'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (uuid != null) 'uuid': uuid,
    });
  }

  KidProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? nickname,
      Value<String>? avatar,
      Value<int>? age,
      Value<DateTime>? createdAt,
      Value<String?>? uuid}) {
    return KidProfilesCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      uuid: uuid ?? this.uuid,
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
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('uuid: $uuid')
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

class $RaceResultsTable extends RaceResults
    with TableInfo<$RaceResultsTable, RaceResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RaceResultsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _finishedAtMeta =
      const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
      'finished_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _wonMeta = const VerificationMeta('won');
  @override
  late final GeneratedColumn<bool> won = GeneratedColumn<bool>(
      'won', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("won" IN (0, 1))'));
  static const VerificationMeta _kidTimeMsMeta =
      const VerificationMeta('kidTimeMs');
  @override
  late final GeneratedColumn<int> kidTimeMs = GeneratedColumn<int>(
      'kid_time_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _firstTryCorrectMeta =
      const VerificationMeta('firstTryCorrect');
  @override
  late final GeneratedColumn<int> firstTryCorrect = GeneratedColumn<int>(
      'first_try_correct', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cometsFirstTryMeta =
      const VerificationMeta('cometsFirstTry');
  @override
  late final GeneratedColumn<int> cometsFirstTry = GeneratedColumn<int>(
      'comets_first_try', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
      'stars', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kidId,
        subject,
        finishedAt,
        won,
        kidTimeMs,
        firstTryCorrect,
        cometsFirstTry,
        stars
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'race_results';
  @override
  VerificationContext validateIntegrity(Insertable<RaceResult> instance,
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
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
          _finishedAtMeta,
          finishedAt.isAcceptableOrUnknown(
              data['finished_at']!, _finishedAtMeta));
    } else if (isInserting) {
      context.missing(_finishedAtMeta);
    }
    if (data.containsKey('won')) {
      context.handle(
          _wonMeta, won.isAcceptableOrUnknown(data['won']!, _wonMeta));
    } else if (isInserting) {
      context.missing(_wonMeta);
    }
    if (data.containsKey('kid_time_ms')) {
      context.handle(
          _kidTimeMsMeta,
          kidTimeMs.isAcceptableOrUnknown(
              data['kid_time_ms']!, _kidTimeMsMeta));
    } else if (isInserting) {
      context.missing(_kidTimeMsMeta);
    }
    if (data.containsKey('first_try_correct')) {
      context.handle(
          _firstTryCorrectMeta,
          firstTryCorrect.isAcceptableOrUnknown(
              data['first_try_correct']!, _firstTryCorrectMeta));
    } else if (isInserting) {
      context.missing(_firstTryCorrectMeta);
    }
    if (data.containsKey('comets_first_try')) {
      context.handle(
          _cometsFirstTryMeta,
          cometsFirstTry.isAcceptableOrUnknown(
              data['comets_first_try']!, _cometsFirstTryMeta));
    } else if (isInserting) {
      context.missing(_cometsFirstTryMeta);
    }
    if (data.containsKey('stars')) {
      context.handle(
          _starsMeta, stars.isAcceptableOrUnknown(data['stars']!, _starsMeta));
    } else if (isInserting) {
      context.missing(_starsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RaceResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RaceResult(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      finishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}finished_at'])!,
      won: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}won'])!,
      kidTimeMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_time_ms'])!,
      firstTryCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}first_try_correct'])!,
      cometsFirstTry: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comets_first_try'])!,
      stars: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stars'])!,
    );
  }

  @override
  $RaceResultsTable createAlias(String alias) {
    return $RaceResultsTable(attachedDatabase, alias);
  }
}

class RaceResult extends DataClass implements Insertable<RaceResult> {
  final int id;
  final int kidId;
  final String subject;
  final DateTime finishedAt;
  final bool won;
  final int kidTimeMs;
  final int firstTryCorrect;
  final int cometsFirstTry;
  final int stars;
  const RaceResult(
      {required this.id,
      required this.kidId,
      required this.subject,
      required this.finishedAt,
      required this.won,
      required this.kidTimeMs,
      required this.firstTryCorrect,
      required this.cometsFirstTry,
      required this.stars});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kid_id'] = Variable<int>(kidId);
    map['subject'] = Variable<String>(subject);
    map['finished_at'] = Variable<DateTime>(finishedAt);
    map['won'] = Variable<bool>(won);
    map['kid_time_ms'] = Variable<int>(kidTimeMs);
    map['first_try_correct'] = Variable<int>(firstTryCorrect);
    map['comets_first_try'] = Variable<int>(cometsFirstTry);
    map['stars'] = Variable<int>(stars);
    return map;
  }

  RaceResultsCompanion toCompanion(bool nullToAbsent) {
    return RaceResultsCompanion(
      id: Value(id),
      kidId: Value(kidId),
      subject: Value(subject),
      finishedAt: Value(finishedAt),
      won: Value(won),
      kidTimeMs: Value(kidTimeMs),
      firstTryCorrect: Value(firstTryCorrect),
      cometsFirstTry: Value(cometsFirstTry),
      stars: Value(stars),
    );
  }

  factory RaceResult.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RaceResult(
      id: serializer.fromJson<int>(json['id']),
      kidId: serializer.fromJson<int>(json['kidId']),
      subject: serializer.fromJson<String>(json['subject']),
      finishedAt: serializer.fromJson<DateTime>(json['finishedAt']),
      won: serializer.fromJson<bool>(json['won']),
      kidTimeMs: serializer.fromJson<int>(json['kidTimeMs']),
      firstTryCorrect: serializer.fromJson<int>(json['firstTryCorrect']),
      cometsFirstTry: serializer.fromJson<int>(json['cometsFirstTry']),
      stars: serializer.fromJson<int>(json['stars']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kidId': serializer.toJson<int>(kidId),
      'subject': serializer.toJson<String>(subject),
      'finishedAt': serializer.toJson<DateTime>(finishedAt),
      'won': serializer.toJson<bool>(won),
      'kidTimeMs': serializer.toJson<int>(kidTimeMs),
      'firstTryCorrect': serializer.toJson<int>(firstTryCorrect),
      'cometsFirstTry': serializer.toJson<int>(cometsFirstTry),
      'stars': serializer.toJson<int>(stars),
    };
  }

  RaceResult copyWith(
          {int? id,
          int? kidId,
          String? subject,
          DateTime? finishedAt,
          bool? won,
          int? kidTimeMs,
          int? firstTryCorrect,
          int? cometsFirstTry,
          int? stars}) =>
      RaceResult(
        id: id ?? this.id,
        kidId: kidId ?? this.kidId,
        subject: subject ?? this.subject,
        finishedAt: finishedAt ?? this.finishedAt,
        won: won ?? this.won,
        kidTimeMs: kidTimeMs ?? this.kidTimeMs,
        firstTryCorrect: firstTryCorrect ?? this.firstTryCorrect,
        cometsFirstTry: cometsFirstTry ?? this.cometsFirstTry,
        stars: stars ?? this.stars,
      );
  RaceResult copyWithCompanion(RaceResultsCompanion data) {
    return RaceResult(
      id: data.id.present ? data.id.value : this.id,
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      subject: data.subject.present ? data.subject.value : this.subject,
      finishedAt:
          data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
      won: data.won.present ? data.won.value : this.won,
      kidTimeMs: data.kidTimeMs.present ? data.kidTimeMs.value : this.kidTimeMs,
      firstTryCorrect: data.firstTryCorrect.present
          ? data.firstTryCorrect.value
          : this.firstTryCorrect,
      cometsFirstTry: data.cometsFirstTry.present
          ? data.cometsFirstTry.value
          : this.cometsFirstTry,
      stars: data.stars.present ? data.stars.value : this.stars,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RaceResult(')
          ..write('id: $id, ')
          ..write('kidId: $kidId, ')
          ..write('subject: $subject, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('won: $won, ')
          ..write('kidTimeMs: $kidTimeMs, ')
          ..write('firstTryCorrect: $firstTryCorrect, ')
          ..write('cometsFirstTry: $cometsFirstTry, ')
          ..write('stars: $stars')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kidId, subject, finishedAt, won,
      kidTimeMs, firstTryCorrect, cometsFirstTry, stars);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RaceResult &&
          other.id == this.id &&
          other.kidId == this.kidId &&
          other.subject == this.subject &&
          other.finishedAt == this.finishedAt &&
          other.won == this.won &&
          other.kidTimeMs == this.kidTimeMs &&
          other.firstTryCorrect == this.firstTryCorrect &&
          other.cometsFirstTry == this.cometsFirstTry &&
          other.stars == this.stars);
}

class RaceResultsCompanion extends UpdateCompanion<RaceResult> {
  final Value<int> id;
  final Value<int> kidId;
  final Value<String> subject;
  final Value<DateTime> finishedAt;
  final Value<bool> won;
  final Value<int> kidTimeMs;
  final Value<int> firstTryCorrect;
  final Value<int> cometsFirstTry;
  final Value<int> stars;
  const RaceResultsCompanion({
    this.id = const Value.absent(),
    this.kidId = const Value.absent(),
    this.subject = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.won = const Value.absent(),
    this.kidTimeMs = const Value.absent(),
    this.firstTryCorrect = const Value.absent(),
    this.cometsFirstTry = const Value.absent(),
    this.stars = const Value.absent(),
  });
  RaceResultsCompanion.insert({
    this.id = const Value.absent(),
    required int kidId,
    required String subject,
    required DateTime finishedAt,
    required bool won,
    required int kidTimeMs,
    required int firstTryCorrect,
    required int cometsFirstTry,
    required int stars,
  })  : kidId = Value(kidId),
        subject = Value(subject),
        finishedAt = Value(finishedAt),
        won = Value(won),
        kidTimeMs = Value(kidTimeMs),
        firstTryCorrect = Value(firstTryCorrect),
        cometsFirstTry = Value(cometsFirstTry),
        stars = Value(stars);
  static Insertable<RaceResult> custom({
    Expression<int>? id,
    Expression<int>? kidId,
    Expression<String>? subject,
    Expression<DateTime>? finishedAt,
    Expression<bool>? won,
    Expression<int>? kidTimeMs,
    Expression<int>? firstTryCorrect,
    Expression<int>? cometsFirstTry,
    Expression<int>? stars,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kidId != null) 'kid_id': kidId,
      if (subject != null) 'subject': subject,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (won != null) 'won': won,
      if (kidTimeMs != null) 'kid_time_ms': kidTimeMs,
      if (firstTryCorrect != null) 'first_try_correct': firstTryCorrect,
      if (cometsFirstTry != null) 'comets_first_try': cometsFirstTry,
      if (stars != null) 'stars': stars,
    });
  }

  RaceResultsCompanion copyWith(
      {Value<int>? id,
      Value<int>? kidId,
      Value<String>? subject,
      Value<DateTime>? finishedAt,
      Value<bool>? won,
      Value<int>? kidTimeMs,
      Value<int>? firstTryCorrect,
      Value<int>? cometsFirstTry,
      Value<int>? stars}) {
    return RaceResultsCompanion(
      id: id ?? this.id,
      kidId: kidId ?? this.kidId,
      subject: subject ?? this.subject,
      finishedAt: finishedAt ?? this.finishedAt,
      won: won ?? this.won,
      kidTimeMs: kidTimeMs ?? this.kidTimeMs,
      firstTryCorrect: firstTryCorrect ?? this.firstTryCorrect,
      cometsFirstTry: cometsFirstTry ?? this.cometsFirstTry,
      stars: stars ?? this.stars,
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
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (won.present) {
      map['won'] = Variable<bool>(won.value);
    }
    if (kidTimeMs.present) {
      map['kid_time_ms'] = Variable<int>(kidTimeMs.value);
    }
    if (firstTryCorrect.present) {
      map['first_try_correct'] = Variable<int>(firstTryCorrect.value);
    }
    if (cometsFirstTry.present) {
      map['comets_first_try'] = Variable<int>(cometsFirstTry.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RaceResultsCompanion(')
          ..write('id: $id, ')
          ..write('kidId: $kidId, ')
          ..write('subject: $subject, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('won: $won, ')
          ..write('kidTimeMs: $kidTimeMs, ')
          ..write('firstTryCorrect: $firstTryCorrect, ')
          ..write('cometsFirstTry: $cometsFirstTry, ')
          ..write('stars: $stars')
          ..write(')'))
        .toString();
  }
}

class $GameProfileTable extends GameProfile
    with TableInfo<$GameProfileTable, GameProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cosmicStarsMeta =
      const VerificationMeta('cosmicStars');
  @override
  late final GeneratedColumn<int> cosmicStars = GeneratedColumn<int>(
      'cosmic_stars', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _selectedRocketMeta =
      const VerificationMeta('selectedRocket');
  @override
  late final GeneratedColumn<String> selectedRocket = GeneratedColumn<String>(
      'selected_rocket', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('rocket_orange'));
  static const VerificationMeta _selectedTrailMeta =
      const VerificationMeta('selectedTrail');
  @override
  late final GeneratedColumn<String> selectedTrail = GeneratedColumn<String>(
      'selected_trail', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('trail_flame'));
  static const VerificationMeta _meanAnswerMsMeta =
      const VerificationMeta('meanAnswerMs');
  @override
  late final GeneratedColumn<int> meanAnswerMs = GeneratedColumn<int>(
      'mean_answer_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(6000));
  static const VerificationMeta _slowNextRaceMeta =
      const VerificationMeta('slowNextRace');
  @override
  late final GeneratedColumn<bool> slowNextRace = GeneratedColumn<bool>(
      'slow_next_race', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("slow_next_race" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _retryAfterLossPendingMeta =
      const VerificationMeta('retryAfterLossPending');
  @override
  late final GeneratedColumn<bool> retryAfterLossPending =
      GeneratedColumn<bool>('retry_after_loss_pending', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("retry_after_loss_pending" IN (0, 1))'),
          defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        kidId,
        cosmicStars,
        selectedRocket,
        selectedTrail,
        meanAnswerMs,
        slowNextRace,
        retryAfterLossPending
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_profile';
  @override
  VerificationContext validateIntegrity(Insertable<GameProfileData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    }
    if (data.containsKey('cosmic_stars')) {
      context.handle(
          _cosmicStarsMeta,
          cosmicStars.isAcceptableOrUnknown(
              data['cosmic_stars']!, _cosmicStarsMeta));
    }
    if (data.containsKey('selected_rocket')) {
      context.handle(
          _selectedRocketMeta,
          selectedRocket.isAcceptableOrUnknown(
              data['selected_rocket']!, _selectedRocketMeta));
    }
    if (data.containsKey('selected_trail')) {
      context.handle(
          _selectedTrailMeta,
          selectedTrail.isAcceptableOrUnknown(
              data['selected_trail']!, _selectedTrailMeta));
    }
    if (data.containsKey('mean_answer_ms')) {
      context.handle(
          _meanAnswerMsMeta,
          meanAnswerMs.isAcceptableOrUnknown(
              data['mean_answer_ms']!, _meanAnswerMsMeta));
    }
    if (data.containsKey('slow_next_race')) {
      context.handle(
          _slowNextRaceMeta,
          slowNextRace.isAcceptableOrUnknown(
              data['slow_next_race']!, _slowNextRaceMeta));
    }
    if (data.containsKey('retry_after_loss_pending')) {
      context.handle(
          _retryAfterLossPendingMeta,
          retryAfterLossPending.isAcceptableOrUnknown(
              data['retry_after_loss_pending']!, _retryAfterLossPendingMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kidId};
  @override
  GameProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameProfileData(
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
      cosmicStars: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cosmic_stars'])!,
      selectedRocket: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}selected_rocket'])!,
      selectedTrail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}selected_trail'])!,
      meanAnswerMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mean_answer_ms'])!,
      slowNextRace: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}slow_next_race'])!,
      retryAfterLossPending: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}retry_after_loss_pending'])!,
    );
  }

  @override
  $GameProfileTable createAlias(String alias) {
    return $GameProfileTable(attachedDatabase, alias);
  }
}

class GameProfileData extends DataClass implements Insertable<GameProfileData> {
  final int kidId;
  final int cosmicStars;
  final String selectedRocket;
  final String selectedTrail;
  final int meanAnswerMs;
  final bool slowNextRace;
  final bool retryAfterLossPending;
  const GameProfileData(
      {required this.kidId,
      required this.cosmicStars,
      required this.selectedRocket,
      required this.selectedTrail,
      required this.meanAnswerMs,
      required this.slowNextRace,
      required this.retryAfterLossPending});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kid_id'] = Variable<int>(kidId);
    map['cosmic_stars'] = Variable<int>(cosmicStars);
    map['selected_rocket'] = Variable<String>(selectedRocket);
    map['selected_trail'] = Variable<String>(selectedTrail);
    map['mean_answer_ms'] = Variable<int>(meanAnswerMs);
    map['slow_next_race'] = Variable<bool>(slowNextRace);
    map['retry_after_loss_pending'] = Variable<bool>(retryAfterLossPending);
    return map;
  }

  GameProfileCompanion toCompanion(bool nullToAbsent) {
    return GameProfileCompanion(
      kidId: Value(kidId),
      cosmicStars: Value(cosmicStars),
      selectedRocket: Value(selectedRocket),
      selectedTrail: Value(selectedTrail),
      meanAnswerMs: Value(meanAnswerMs),
      slowNextRace: Value(slowNextRace),
      retryAfterLossPending: Value(retryAfterLossPending),
    );
  }

  factory GameProfileData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameProfileData(
      kidId: serializer.fromJson<int>(json['kidId']),
      cosmicStars: serializer.fromJson<int>(json['cosmicStars']),
      selectedRocket: serializer.fromJson<String>(json['selectedRocket']),
      selectedTrail: serializer.fromJson<String>(json['selectedTrail']),
      meanAnswerMs: serializer.fromJson<int>(json['meanAnswerMs']),
      slowNextRace: serializer.fromJson<bool>(json['slowNextRace']),
      retryAfterLossPending:
          serializer.fromJson<bool>(json['retryAfterLossPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kidId': serializer.toJson<int>(kidId),
      'cosmicStars': serializer.toJson<int>(cosmicStars),
      'selectedRocket': serializer.toJson<String>(selectedRocket),
      'selectedTrail': serializer.toJson<String>(selectedTrail),
      'meanAnswerMs': serializer.toJson<int>(meanAnswerMs),
      'slowNextRace': serializer.toJson<bool>(slowNextRace),
      'retryAfterLossPending': serializer.toJson<bool>(retryAfterLossPending),
    };
  }

  GameProfileData copyWith(
          {int? kidId,
          int? cosmicStars,
          String? selectedRocket,
          String? selectedTrail,
          int? meanAnswerMs,
          bool? slowNextRace,
          bool? retryAfterLossPending}) =>
      GameProfileData(
        kidId: kidId ?? this.kidId,
        cosmicStars: cosmicStars ?? this.cosmicStars,
        selectedRocket: selectedRocket ?? this.selectedRocket,
        selectedTrail: selectedTrail ?? this.selectedTrail,
        meanAnswerMs: meanAnswerMs ?? this.meanAnswerMs,
        slowNextRace: slowNextRace ?? this.slowNextRace,
        retryAfterLossPending:
            retryAfterLossPending ?? this.retryAfterLossPending,
      );
  GameProfileData copyWithCompanion(GameProfileCompanion data) {
    return GameProfileData(
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      cosmicStars:
          data.cosmicStars.present ? data.cosmicStars.value : this.cosmicStars,
      selectedRocket: data.selectedRocket.present
          ? data.selectedRocket.value
          : this.selectedRocket,
      selectedTrail: data.selectedTrail.present
          ? data.selectedTrail.value
          : this.selectedTrail,
      meanAnswerMs: data.meanAnswerMs.present
          ? data.meanAnswerMs.value
          : this.meanAnswerMs,
      slowNextRace: data.slowNextRace.present
          ? data.slowNextRace.value
          : this.slowNextRace,
      retryAfterLossPending: data.retryAfterLossPending.present
          ? data.retryAfterLossPending.value
          : this.retryAfterLossPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameProfileData(')
          ..write('kidId: $kidId, ')
          ..write('cosmicStars: $cosmicStars, ')
          ..write('selectedRocket: $selectedRocket, ')
          ..write('selectedTrail: $selectedTrail, ')
          ..write('meanAnswerMs: $meanAnswerMs, ')
          ..write('slowNextRace: $slowNextRace, ')
          ..write('retryAfterLossPending: $retryAfterLossPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kidId, cosmicStars, selectedRocket,
      selectedTrail, meanAnswerMs, slowNextRace, retryAfterLossPending);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameProfileData &&
          other.kidId == this.kidId &&
          other.cosmicStars == this.cosmicStars &&
          other.selectedRocket == this.selectedRocket &&
          other.selectedTrail == this.selectedTrail &&
          other.meanAnswerMs == this.meanAnswerMs &&
          other.slowNextRace == this.slowNextRace &&
          other.retryAfterLossPending == this.retryAfterLossPending);
}

class GameProfileCompanion extends UpdateCompanion<GameProfileData> {
  final Value<int> kidId;
  final Value<int> cosmicStars;
  final Value<String> selectedRocket;
  final Value<String> selectedTrail;
  final Value<int> meanAnswerMs;
  final Value<bool> slowNextRace;
  final Value<bool> retryAfterLossPending;
  const GameProfileCompanion({
    this.kidId = const Value.absent(),
    this.cosmicStars = const Value.absent(),
    this.selectedRocket = const Value.absent(),
    this.selectedTrail = const Value.absent(),
    this.meanAnswerMs = const Value.absent(),
    this.slowNextRace = const Value.absent(),
    this.retryAfterLossPending = const Value.absent(),
  });
  GameProfileCompanion.insert({
    this.kidId = const Value.absent(),
    this.cosmicStars = const Value.absent(),
    this.selectedRocket = const Value.absent(),
    this.selectedTrail = const Value.absent(),
    this.meanAnswerMs = const Value.absent(),
    this.slowNextRace = const Value.absent(),
    this.retryAfterLossPending = const Value.absent(),
  });
  static Insertable<GameProfileData> custom({
    Expression<int>? kidId,
    Expression<int>? cosmicStars,
    Expression<String>? selectedRocket,
    Expression<String>? selectedTrail,
    Expression<int>? meanAnswerMs,
    Expression<bool>? slowNextRace,
    Expression<bool>? retryAfterLossPending,
  }) {
    return RawValuesInsertable({
      if (kidId != null) 'kid_id': kidId,
      if (cosmicStars != null) 'cosmic_stars': cosmicStars,
      if (selectedRocket != null) 'selected_rocket': selectedRocket,
      if (selectedTrail != null) 'selected_trail': selectedTrail,
      if (meanAnswerMs != null) 'mean_answer_ms': meanAnswerMs,
      if (slowNextRace != null) 'slow_next_race': slowNextRace,
      if (retryAfterLossPending != null)
        'retry_after_loss_pending': retryAfterLossPending,
    });
  }

  GameProfileCompanion copyWith(
      {Value<int>? kidId,
      Value<int>? cosmicStars,
      Value<String>? selectedRocket,
      Value<String>? selectedTrail,
      Value<int>? meanAnswerMs,
      Value<bool>? slowNextRace,
      Value<bool>? retryAfterLossPending}) {
    return GameProfileCompanion(
      kidId: kidId ?? this.kidId,
      cosmicStars: cosmicStars ?? this.cosmicStars,
      selectedRocket: selectedRocket ?? this.selectedRocket,
      selectedTrail: selectedTrail ?? this.selectedTrail,
      meanAnswerMs: meanAnswerMs ?? this.meanAnswerMs,
      slowNextRace: slowNextRace ?? this.slowNextRace,
      retryAfterLossPending:
          retryAfterLossPending ?? this.retryAfterLossPending,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
    if (cosmicStars.present) {
      map['cosmic_stars'] = Variable<int>(cosmicStars.value);
    }
    if (selectedRocket.present) {
      map['selected_rocket'] = Variable<String>(selectedRocket.value);
    }
    if (selectedTrail.present) {
      map['selected_trail'] = Variable<String>(selectedTrail.value);
    }
    if (meanAnswerMs.present) {
      map['mean_answer_ms'] = Variable<int>(meanAnswerMs.value);
    }
    if (slowNextRace.present) {
      map['slow_next_race'] = Variable<bool>(slowNextRace.value);
    }
    if (retryAfterLossPending.present) {
      map['retry_after_loss_pending'] =
          Variable<bool>(retryAfterLossPending.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameProfileCompanion(')
          ..write('kidId: $kidId, ')
          ..write('cosmicStars: $cosmicStars, ')
          ..write('selectedRocket: $selectedRocket, ')
          ..write('selectedTrail: $selectedTrail, ')
          ..write('meanAnswerMs: $meanAnswerMs, ')
          ..write('slowNextRace: $slowNextRace, ')
          ..write('retryAfterLossPending: $retryAfterLossPending')
          ..write(')'))
        .toString();
  }
}

class $GameItemsTable extends GameItems
    with TableInfo<$GameItemsTable, GameItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [kidId, itemId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_items';
  @override
  VerificationContext validateIntegrity(Insertable<GameItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kidId, itemId};
  @override
  GameItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameItem(
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
    );
  }

  @override
  $GameItemsTable createAlias(String alias) {
    return $GameItemsTable(attachedDatabase, alias);
  }
}

class GameItem extends DataClass implements Insertable<GameItem> {
  final int kidId;
  final String itemId;
  const GameItem({required this.kidId, required this.itemId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kid_id'] = Variable<int>(kidId);
    map['item_id'] = Variable<String>(itemId);
    return map;
  }

  GameItemsCompanion toCompanion(bool nullToAbsent) {
    return GameItemsCompanion(
      kidId: Value(kidId),
      itemId: Value(itemId),
    );
  }

  factory GameItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameItem(
      kidId: serializer.fromJson<int>(json['kidId']),
      itemId: serializer.fromJson<String>(json['itemId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kidId': serializer.toJson<int>(kidId),
      'itemId': serializer.toJson<String>(itemId),
    };
  }

  GameItem copyWith({int? kidId, String? itemId}) => GameItem(
        kidId: kidId ?? this.kidId,
        itemId: itemId ?? this.itemId,
      );
  GameItem copyWithCompanion(GameItemsCompanion data) {
    return GameItem(
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameItem(')
          ..write('kidId: $kidId, ')
          ..write('itemId: $itemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kidId, itemId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameItem &&
          other.kidId == this.kidId &&
          other.itemId == this.itemId);
}

class GameItemsCompanion extends UpdateCompanion<GameItem> {
  final Value<int> kidId;
  final Value<String> itemId;
  final Value<int> rowid;
  const GameItemsCompanion({
    this.kidId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameItemsCompanion.insert({
    required int kidId,
    required String itemId,
    this.rowid = const Value.absent(),
  })  : kidId = Value(kidId),
        itemId = Value(itemId);
  static Insertable<GameItem> custom({
    Expression<int>? kidId,
    Expression<String>? itemId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kidId != null) 'kid_id': kidId,
      if (itemId != null) 'item_id': itemId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameItemsCompanion copyWith(
      {Value<int>? kidId, Value<String>? itemId, Value<int>? rowid}) {
    return GameItemsCompanion(
      kidId: kidId ?? this.kidId,
      itemId: itemId ?? this.itemId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameItemsCompanion(')
          ..write('kidId: $kidId, ')
          ..write('itemId: $itemId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameBadgesTable extends GameBadges
    with TableInfo<$GameBadgesTable, GameBadgeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameBadgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _badgeIdMeta =
      const VerificationMeta('badgeId');
  @override
  late final GeneratedColumn<String> badgeId = GeneratedColumn<String>(
      'badge_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _earnedAtMeta =
      const VerificationMeta('earnedAt');
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
      'earned_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [kidId, badgeId, earnedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_badges';
  @override
  VerificationContext validateIntegrity(Insertable<GameBadgeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
    }
    if (data.containsKey('badge_id')) {
      context.handle(_badgeIdMeta,
          badgeId.isAcceptableOrUnknown(data['badge_id']!, _badgeIdMeta));
    } else if (isInserting) {
      context.missing(_badgeIdMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(_earnedAtMeta,
          earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta));
    } else if (isInserting) {
      context.missing(_earnedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kidId, badgeId};
  @override
  GameBadgeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameBadgeRow(
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
      badgeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}badge_id'])!,
      earnedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}earned_at'])!,
    );
  }

  @override
  $GameBadgesTable createAlias(String alias) {
    return $GameBadgesTable(attachedDatabase, alias);
  }
}

class GameBadgeRow extends DataClass implements Insertable<GameBadgeRow> {
  final int kidId;
  final String badgeId;
  final DateTime earnedAt;
  const GameBadgeRow(
      {required this.kidId, required this.badgeId, required this.earnedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kid_id'] = Variable<int>(kidId);
    map['badge_id'] = Variable<String>(badgeId);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    return map;
  }

  GameBadgesCompanion toCompanion(bool nullToAbsent) {
    return GameBadgesCompanion(
      kidId: Value(kidId),
      badgeId: Value(badgeId),
      earnedAt: Value(earnedAt),
    );
  }

  factory GameBadgeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameBadgeRow(
      kidId: serializer.fromJson<int>(json['kidId']),
      badgeId: serializer.fromJson<String>(json['badgeId']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kidId': serializer.toJson<int>(kidId),
      'badgeId': serializer.toJson<String>(badgeId),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
    };
  }

  GameBadgeRow copyWith({int? kidId, String? badgeId, DateTime? earnedAt}) =>
      GameBadgeRow(
        kidId: kidId ?? this.kidId,
        badgeId: badgeId ?? this.badgeId,
        earnedAt: earnedAt ?? this.earnedAt,
      );
  GameBadgeRow copyWithCompanion(GameBadgesCompanion data) {
    return GameBadgeRow(
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      badgeId: data.badgeId.present ? data.badgeId.value : this.badgeId,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameBadgeRow(')
          ..write('kidId: $kidId, ')
          ..write('badgeId: $badgeId, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kidId, badgeId, earnedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameBadgeRow &&
          other.kidId == this.kidId &&
          other.badgeId == this.badgeId &&
          other.earnedAt == this.earnedAt);
}

class GameBadgesCompanion extends UpdateCompanion<GameBadgeRow> {
  final Value<int> kidId;
  final Value<String> badgeId;
  final Value<DateTime> earnedAt;
  final Value<int> rowid;
  const GameBadgesCompanion({
    this.kidId = const Value.absent(),
    this.badgeId = const Value.absent(),
    this.earnedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameBadgesCompanion.insert({
    required int kidId,
    required String badgeId,
    required DateTime earnedAt,
    this.rowid = const Value.absent(),
  })  : kidId = Value(kidId),
        badgeId = Value(badgeId),
        earnedAt = Value(earnedAt);
  static Insertable<GameBadgeRow> custom({
    Expression<int>? kidId,
    Expression<String>? badgeId,
    Expression<DateTime>? earnedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kidId != null) 'kid_id': kidId,
      if (badgeId != null) 'badge_id': badgeId,
      if (earnedAt != null) 'earned_at': earnedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameBadgesCompanion copyWith(
      {Value<int>? kidId,
      Value<String>? badgeId,
      Value<DateTime>? earnedAt,
      Value<int>? rowid}) {
    return GameBadgesCompanion(
      kidId: kidId ?? this.kidId,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
    if (badgeId.present) {
      map['badge_id'] = Variable<String>(badgeId.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameBadgesCompanion(')
          ..write('kidId: $kidId, ')
          ..write('badgeId: $badgeId, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameCountersTable extends GameCounters
    with TableInfo<$GameCountersTable, GameCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kidIdMeta = const VerificationMeta('kidId');
  @override
  late final GeneratedColumn<int> kidId = GeneratedColumn<int>(
      'kid_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
      'value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [kidId, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_counters';
  @override
  VerificationContext validateIntegrity(Insertable<GameCounter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kid_id')) {
      context.handle(
          _kidIdMeta, kidId.isAcceptableOrUnknown(data['kid_id']!, _kidIdMeta));
    } else if (isInserting) {
      context.missing(_kidIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kidId, key};
  @override
  GameCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameCounter(
      kidId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kid_id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $GameCountersTable createAlias(String alias) {
    return $GameCountersTable(attachedDatabase, alias);
  }
}

class GameCounter extends DataClass implements Insertable<GameCounter> {
  final int kidId;
  final String key;
  final int value;
  const GameCounter(
      {required this.kidId, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kid_id'] = Variable<int>(kidId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<int>(value);
    return map;
  }

  GameCountersCompanion toCompanion(bool nullToAbsent) {
    return GameCountersCompanion(
      kidId: Value(kidId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory GameCounter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameCounter(
      kidId: serializer.fromJson<int>(json['kidId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kidId': serializer.toJson<int>(kidId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<int>(value),
    };
  }

  GameCounter copyWith({int? kidId, String? key, int? value}) => GameCounter(
        kidId: kidId ?? this.kidId,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  GameCounter copyWithCompanion(GameCountersCompanion data) {
    return GameCounter(
      kidId: data.kidId.present ? data.kidId.value : this.kidId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameCounter(')
          ..write('kidId: $kidId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kidId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameCounter &&
          other.kidId == this.kidId &&
          other.key == this.key &&
          other.value == this.value);
}

class GameCountersCompanion extends UpdateCompanion<GameCounter> {
  final Value<int> kidId;
  final Value<String> key;
  final Value<int> value;
  final Value<int> rowid;
  const GameCountersCompanion({
    this.kidId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameCountersCompanion.insert({
    required int kidId,
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : kidId = Value(kidId),
        key = Value(key);
  static Insertable<GameCounter> custom({
    Expression<int>? kidId,
    Expression<String>? key,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kidId != null) 'kid_id': kidId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameCountersCompanion copyWith(
      {Value<int>? kidId,
      Value<String>? key,
      Value<int>? value,
      Value<int>? rowid}) {
    return GameCountersCompanion(
      kidId: kidId ?? this.kidId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kidId.present) {
      map['kid_id'] = Variable<int>(kidId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameCountersCompanion(')
          ..write('kidId: $kidId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedRecordsTable extends SyncedRecords
    with TableInfo<$SyncedRecordsTable, SyncedRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, version, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synced_records';
  @override
  VerificationContext validateIntegrity(Insertable<SyncedRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncedRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedRecord(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json']),
    );
  }

  @override
  $SyncedRecordsTable createAlias(String alias) {
    return $SyncedRecordsTable(attachedDatabase, alias);
  }
}

class SyncedRecord extends DataClass implements Insertable<SyncedRecord> {
  final String key;
  final int version;

  /// Canonical JSON (sorted keys) of the payload last sent or received; null
  /// for a tombstone or a record this device deliberately does not hold.
  final String? payloadJson;
  const SyncedRecord(
      {required this.key, required this.version, this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    return map;
  }

  SyncedRecordsCompanion toCompanion(bool nullToAbsent) {
    return SyncedRecordsCompanion(
      key: Value(key),
      version: Value(version),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
    );
  }

  factory SyncedRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedRecord(
      key: serializer.fromJson<String>(json['key']),
      version: serializer.fromJson<int>(json['version']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'version': serializer.toJson<int>(version),
      'payloadJson': serializer.toJson<String?>(payloadJson),
    };
  }

  SyncedRecord copyWith(
          {String? key,
          int? version,
          Value<String?> payloadJson = const Value.absent()}) =>
      SyncedRecord(
        key: key ?? this.key,
        version: version ?? this.version,
        payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
      );
  SyncedRecord copyWithCompanion(SyncedRecordsCompanion data) {
    return SyncedRecord(
      key: data.key.present ? data.key.value : this.key,
      version: data.version.present ? data.version.value : this.version,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedRecord(')
          ..write('key: $key, ')
          ..write('version: $version, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, version, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedRecord &&
          other.key == this.key &&
          other.version == this.version &&
          other.payloadJson == this.payloadJson);
}

class SyncedRecordsCompanion extends UpdateCompanion<SyncedRecord> {
  final Value<String> key;
  final Value<int> version;
  final Value<String?> payloadJson;
  final Value<int> rowid;
  const SyncedRecordsCompanion({
    this.key = const Value.absent(),
    this.version = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedRecordsCompanion.insert({
    required String key,
    required int version,
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        version = Value(version);
  static Insertable<SyncedRecord> custom({
    Expression<String>? key,
    Expression<int>? version,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (version != null) 'version': version,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedRecordsCompanion copyWith(
      {Value<String>? key,
      Value<int>? version,
      Value<String?>? payloadJson,
      Value<int>? rowid}) {
    return SyncedRecordsCompanion(
      key: key ?? this.key,
      version: version ?? this.version,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedRecordsCompanion(')
          ..write('key: $key, ')
          ..write('version: $version, ')
          ..write('payloadJson: $payloadJson, ')
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
  late final $KidProfilesTable kidProfiles = $KidProfilesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $DailyUsageTable dailyUsage = $DailyUsageTable(this);
  late final $RealRewardsTable realRewards = $RealRewardsTable(this);
  late final $RaceResultsTable raceResults = $RaceResultsTable(this);
  late final $GameProfileTable gameProfile = $GameProfileTable(this);
  late final $GameItemsTable gameItems = $GameItemsTable(this);
  late final $GameBadgesTable gameBadges = $GameBadgesTable(this);
  late final $GameCountersTable gameCounters = $GameCountersTable(this);
  late final $SyncedRecordsTable syncedRecords = $SyncedRecordsTable(this);
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
        realRewards,
        raceResults,
        gameProfile,
        gameItems,
        gameBadges,
        gameCounters,
        syncedRecords
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
  Value<String?> uuid,
});
typedef $$KidProfilesTableUpdateCompanionBuilder = KidProfilesCompanion
    Function({
  Value<int> id,
  Value<String> nickname,
  Value<String> avatar,
  Value<int> age,
  Value<DateTime> createdAt,
  Value<String?> uuid,
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

  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);
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
            Value<String?> uuid = const Value.absent(),
          }) =>
              KidProfilesCompanion(
            id: id,
            nickname: nickname,
            avatar: avatar,
            age: age,
            createdAt: createdAt,
            uuid: uuid,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nickname,
            required String avatar,
            required int age,
            required DateTime createdAt,
            Value<String?> uuid = const Value.absent(),
          }) =>
              KidProfilesCompanion.insert(
            id: id,
            nickname: nickname,
            avatar: avatar,
            age: age,
            createdAt: createdAt,
            uuid: uuid,
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
typedef $$RaceResultsTableCreateCompanionBuilder = RaceResultsCompanion
    Function({
  Value<int> id,
  required int kidId,
  required String subject,
  required DateTime finishedAt,
  required bool won,
  required int kidTimeMs,
  required int firstTryCorrect,
  required int cometsFirstTry,
  required int stars,
});
typedef $$RaceResultsTableUpdateCompanionBuilder = RaceResultsCompanion
    Function({
  Value<int> id,
  Value<int> kidId,
  Value<String> subject,
  Value<DateTime> finishedAt,
  Value<bool> won,
  Value<int> kidTimeMs,
  Value<int> firstTryCorrect,
  Value<int> cometsFirstTry,
  Value<int> stars,
});

class $$RaceResultsTableFilterComposer
    extends Composer<_$AppDatabase, $RaceResultsTable> {
  $$RaceResultsTableFilterComposer({
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

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get won => $composableBuilder(
      column: $table.won, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kidTimeMs => $composableBuilder(
      column: $table.kidTimeMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get firstTryCorrect => $composableBuilder(
      column: $table.firstTryCorrect,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cometsFirstTry => $composableBuilder(
      column: $table.cometsFirstTry,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stars => $composableBuilder(
      column: $table.stars, builder: (column) => ColumnFilters(column));
}

class $$RaceResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $RaceResultsTable> {
  $$RaceResultsTableOrderingComposer({
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

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get won => $composableBuilder(
      column: $table.won, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kidTimeMs => $composableBuilder(
      column: $table.kidTimeMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get firstTryCorrect => $composableBuilder(
      column: $table.firstTryCorrect,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cometsFirstTry => $composableBuilder(
      column: $table.cometsFirstTry,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stars => $composableBuilder(
      column: $table.stars, builder: (column) => ColumnOrderings(column));
}

class $$RaceResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RaceResultsTable> {
  $$RaceResultsTableAnnotationComposer({
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

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => column);

  GeneratedColumn<bool> get won =>
      $composableBuilder(column: $table.won, builder: (column) => column);

  GeneratedColumn<int> get kidTimeMs =>
      $composableBuilder(column: $table.kidTimeMs, builder: (column) => column);

  GeneratedColumn<int> get firstTryCorrect => $composableBuilder(
      column: $table.firstTryCorrect, builder: (column) => column);

  GeneratedColumn<int> get cometsFirstTry => $composableBuilder(
      column: $table.cometsFirstTry, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);
}

class $$RaceResultsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RaceResultsTable,
    RaceResult,
    $$RaceResultsTableFilterComposer,
    $$RaceResultsTableOrderingComposer,
    $$RaceResultsTableAnnotationComposer,
    $$RaceResultsTableCreateCompanionBuilder,
    $$RaceResultsTableUpdateCompanionBuilder,
    (RaceResult, BaseReferences<_$AppDatabase, $RaceResultsTable, RaceResult>),
    RaceResult,
    PrefetchHooks Function()> {
  $$RaceResultsTableTableManager(_$AppDatabase db, $RaceResultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RaceResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RaceResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RaceResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> kidId = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<DateTime> finishedAt = const Value.absent(),
            Value<bool> won = const Value.absent(),
            Value<int> kidTimeMs = const Value.absent(),
            Value<int> firstTryCorrect = const Value.absent(),
            Value<int> cometsFirstTry = const Value.absent(),
            Value<int> stars = const Value.absent(),
          }) =>
              RaceResultsCompanion(
            id: id,
            kidId: kidId,
            subject: subject,
            finishedAt: finishedAt,
            won: won,
            kidTimeMs: kidTimeMs,
            firstTryCorrect: firstTryCorrect,
            cometsFirstTry: cometsFirstTry,
            stars: stars,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int kidId,
            required String subject,
            required DateTime finishedAt,
            required bool won,
            required int kidTimeMs,
            required int firstTryCorrect,
            required int cometsFirstTry,
            required int stars,
          }) =>
              RaceResultsCompanion.insert(
            id: id,
            kidId: kidId,
            subject: subject,
            finishedAt: finishedAt,
            won: won,
            kidTimeMs: kidTimeMs,
            firstTryCorrect: firstTryCorrect,
            cometsFirstTry: cometsFirstTry,
            stars: stars,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RaceResultsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RaceResultsTable,
    RaceResult,
    $$RaceResultsTableFilterComposer,
    $$RaceResultsTableOrderingComposer,
    $$RaceResultsTableAnnotationComposer,
    $$RaceResultsTableCreateCompanionBuilder,
    $$RaceResultsTableUpdateCompanionBuilder,
    (RaceResult, BaseReferences<_$AppDatabase, $RaceResultsTable, RaceResult>),
    RaceResult,
    PrefetchHooks Function()>;
typedef $$GameProfileTableCreateCompanionBuilder = GameProfileCompanion
    Function({
  Value<int> kidId,
  Value<int> cosmicStars,
  Value<String> selectedRocket,
  Value<String> selectedTrail,
  Value<int> meanAnswerMs,
  Value<bool> slowNextRace,
  Value<bool> retryAfterLossPending,
});
typedef $$GameProfileTableUpdateCompanionBuilder = GameProfileCompanion
    Function({
  Value<int> kidId,
  Value<int> cosmicStars,
  Value<String> selectedRocket,
  Value<String> selectedTrail,
  Value<int> meanAnswerMs,
  Value<bool> slowNextRace,
  Value<bool> retryAfterLossPending,
});

class $$GameProfileTableFilterComposer
    extends Composer<_$AppDatabase, $GameProfileTable> {
  $$GameProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cosmicStars => $composableBuilder(
      column: $table.cosmicStars, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectedRocket => $composableBuilder(
      column: $table.selectedRocket,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectedTrail => $composableBuilder(
      column: $table.selectedTrail, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get meanAnswerMs => $composableBuilder(
      column: $table.meanAnswerMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get slowNextRace => $composableBuilder(
      column: $table.slowNextRace, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get retryAfterLossPending => $composableBuilder(
      column: $table.retryAfterLossPending,
      builder: (column) => ColumnFilters(column));
}

class $$GameProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $GameProfileTable> {
  $$GameProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cosmicStars => $composableBuilder(
      column: $table.cosmicStars, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectedRocket => $composableBuilder(
      column: $table.selectedRocket,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectedTrail => $composableBuilder(
      column: $table.selectedTrail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get meanAnswerMs => $composableBuilder(
      column: $table.meanAnswerMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get slowNextRace => $composableBuilder(
      column: $table.slowNextRace,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get retryAfterLossPending => $composableBuilder(
      column: $table.retryAfterLossPending,
      builder: (column) => ColumnOrderings(column));
}

class $$GameProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameProfileTable> {
  $$GameProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

  GeneratedColumn<int> get cosmicStars => $composableBuilder(
      column: $table.cosmicStars, builder: (column) => column);

  GeneratedColumn<String> get selectedRocket => $composableBuilder(
      column: $table.selectedRocket, builder: (column) => column);

  GeneratedColumn<String> get selectedTrail => $composableBuilder(
      column: $table.selectedTrail, builder: (column) => column);

  GeneratedColumn<int> get meanAnswerMs => $composableBuilder(
      column: $table.meanAnswerMs, builder: (column) => column);

  GeneratedColumn<bool> get slowNextRace => $composableBuilder(
      column: $table.slowNextRace, builder: (column) => column);

  GeneratedColumn<bool> get retryAfterLossPending => $composableBuilder(
      column: $table.retryAfterLossPending, builder: (column) => column);
}

class $$GameProfileTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GameProfileTable,
    GameProfileData,
    $$GameProfileTableFilterComposer,
    $$GameProfileTableOrderingComposer,
    $$GameProfileTableAnnotationComposer,
    $$GameProfileTableCreateCompanionBuilder,
    $$GameProfileTableUpdateCompanionBuilder,
    (
      GameProfileData,
      BaseReferences<_$AppDatabase, $GameProfileTable, GameProfileData>
    ),
    GameProfileData,
    PrefetchHooks Function()> {
  $$GameProfileTableTableManager(_$AppDatabase db, $GameProfileTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> kidId = const Value.absent(),
            Value<int> cosmicStars = const Value.absent(),
            Value<String> selectedRocket = const Value.absent(),
            Value<String> selectedTrail = const Value.absent(),
            Value<int> meanAnswerMs = const Value.absent(),
            Value<bool> slowNextRace = const Value.absent(),
            Value<bool> retryAfterLossPending = const Value.absent(),
          }) =>
              GameProfileCompanion(
            kidId: kidId,
            cosmicStars: cosmicStars,
            selectedRocket: selectedRocket,
            selectedTrail: selectedTrail,
            meanAnswerMs: meanAnswerMs,
            slowNextRace: slowNextRace,
            retryAfterLossPending: retryAfterLossPending,
          ),
          createCompanionCallback: ({
            Value<int> kidId = const Value.absent(),
            Value<int> cosmicStars = const Value.absent(),
            Value<String> selectedRocket = const Value.absent(),
            Value<String> selectedTrail = const Value.absent(),
            Value<int> meanAnswerMs = const Value.absent(),
            Value<bool> slowNextRace = const Value.absent(),
            Value<bool> retryAfterLossPending = const Value.absent(),
          }) =>
              GameProfileCompanion.insert(
            kidId: kidId,
            cosmicStars: cosmicStars,
            selectedRocket: selectedRocket,
            selectedTrail: selectedTrail,
            meanAnswerMs: meanAnswerMs,
            slowNextRace: slowNextRace,
            retryAfterLossPending: retryAfterLossPending,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GameProfileTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GameProfileTable,
    GameProfileData,
    $$GameProfileTableFilterComposer,
    $$GameProfileTableOrderingComposer,
    $$GameProfileTableAnnotationComposer,
    $$GameProfileTableCreateCompanionBuilder,
    $$GameProfileTableUpdateCompanionBuilder,
    (
      GameProfileData,
      BaseReferences<_$AppDatabase, $GameProfileTable, GameProfileData>
    ),
    GameProfileData,
    PrefetchHooks Function()>;
typedef $$GameItemsTableCreateCompanionBuilder = GameItemsCompanion Function({
  required int kidId,
  required String itemId,
  Value<int> rowid,
});
typedef $$GameItemsTableUpdateCompanionBuilder = GameItemsCompanion Function({
  Value<int> kidId,
  Value<String> itemId,
  Value<int> rowid,
});

class $$GameItemsTableFilterComposer
    extends Composer<_$AppDatabase, $GameItemsTable> {
  $$GameItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));
}

class $$GameItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameItemsTable> {
  $$GameItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));
}

class $$GameItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameItemsTable> {
  $$GameItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);
}

class $$GameItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GameItemsTable,
    GameItem,
    $$GameItemsTableFilterComposer,
    $$GameItemsTableOrderingComposer,
    $$GameItemsTableAnnotationComposer,
    $$GameItemsTableCreateCompanionBuilder,
    $$GameItemsTableUpdateCompanionBuilder,
    (GameItem, BaseReferences<_$AppDatabase, $GameItemsTable, GameItem>),
    GameItem,
    PrefetchHooks Function()> {
  $$GameItemsTableTableManager(_$AppDatabase db, $GameItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> kidId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GameItemsCompanion(
            kidId: kidId,
            itemId: itemId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int kidId,
            required String itemId,
            Value<int> rowid = const Value.absent(),
          }) =>
              GameItemsCompanion.insert(
            kidId: kidId,
            itemId: itemId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GameItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GameItemsTable,
    GameItem,
    $$GameItemsTableFilterComposer,
    $$GameItemsTableOrderingComposer,
    $$GameItemsTableAnnotationComposer,
    $$GameItemsTableCreateCompanionBuilder,
    $$GameItemsTableUpdateCompanionBuilder,
    (GameItem, BaseReferences<_$AppDatabase, $GameItemsTable, GameItem>),
    GameItem,
    PrefetchHooks Function()>;
typedef $$GameBadgesTableCreateCompanionBuilder = GameBadgesCompanion Function({
  required int kidId,
  required String badgeId,
  required DateTime earnedAt,
  Value<int> rowid,
});
typedef $$GameBadgesTableUpdateCompanionBuilder = GameBadgesCompanion Function({
  Value<int> kidId,
  Value<String> badgeId,
  Value<DateTime> earnedAt,
  Value<int> rowid,
});

class $$GameBadgesTableFilterComposer
    extends Composer<_$AppDatabase, $GameBadgesTable> {
  $$GameBadgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get badgeId => $composableBuilder(
      column: $table.badgeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
      column: $table.earnedAt, builder: (column) => ColumnFilters(column));
}

class $$GameBadgesTableOrderingComposer
    extends Composer<_$AppDatabase, $GameBadgesTable> {
  $$GameBadgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get badgeId => $composableBuilder(
      column: $table.badgeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
      column: $table.earnedAt, builder: (column) => ColumnOrderings(column));
}

class $$GameBadgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameBadgesTable> {
  $$GameBadgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

  GeneratedColumn<String> get badgeId =>
      $composableBuilder(column: $table.badgeId, builder: (column) => column);

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);
}

class $$GameBadgesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GameBadgesTable,
    GameBadgeRow,
    $$GameBadgesTableFilterComposer,
    $$GameBadgesTableOrderingComposer,
    $$GameBadgesTableAnnotationComposer,
    $$GameBadgesTableCreateCompanionBuilder,
    $$GameBadgesTableUpdateCompanionBuilder,
    (
      GameBadgeRow,
      BaseReferences<_$AppDatabase, $GameBadgesTable, GameBadgeRow>
    ),
    GameBadgeRow,
    PrefetchHooks Function()> {
  $$GameBadgesTableTableManager(_$AppDatabase db, $GameBadgesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameBadgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameBadgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameBadgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> kidId = const Value.absent(),
            Value<String> badgeId = const Value.absent(),
            Value<DateTime> earnedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GameBadgesCompanion(
            kidId: kidId,
            badgeId: badgeId,
            earnedAt: earnedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int kidId,
            required String badgeId,
            required DateTime earnedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GameBadgesCompanion.insert(
            kidId: kidId,
            badgeId: badgeId,
            earnedAt: earnedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GameBadgesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GameBadgesTable,
    GameBadgeRow,
    $$GameBadgesTableFilterComposer,
    $$GameBadgesTableOrderingComposer,
    $$GameBadgesTableAnnotationComposer,
    $$GameBadgesTableCreateCompanionBuilder,
    $$GameBadgesTableUpdateCompanionBuilder,
    (
      GameBadgeRow,
      BaseReferences<_$AppDatabase, $GameBadgesTable, GameBadgeRow>
    ),
    GameBadgeRow,
    PrefetchHooks Function()>;
typedef $$GameCountersTableCreateCompanionBuilder = GameCountersCompanion
    Function({
  required int kidId,
  required String key,
  Value<int> value,
  Value<int> rowid,
});
typedef $$GameCountersTableUpdateCompanionBuilder = GameCountersCompanion
    Function({
  Value<int> kidId,
  Value<String> key,
  Value<int> value,
  Value<int> rowid,
});

class $$GameCountersTableFilterComposer
    extends Composer<_$AppDatabase, $GameCountersTable> {
  $$GameCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$GameCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $GameCountersTable> {
  $$GameCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get kidId => $composableBuilder(
      column: $table.kidId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$GameCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameCountersTable> {
  $$GameCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get kidId =>
      $composableBuilder(column: $table.kidId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$GameCountersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GameCountersTable,
    GameCounter,
    $$GameCountersTableFilterComposer,
    $$GameCountersTableOrderingComposer,
    $$GameCountersTableAnnotationComposer,
    $$GameCountersTableCreateCompanionBuilder,
    $$GameCountersTableUpdateCompanionBuilder,
    (
      GameCounter,
      BaseReferences<_$AppDatabase, $GameCountersTable, GameCounter>
    ),
    GameCounter,
    PrefetchHooks Function()> {
  $$GameCountersTableTableManager(_$AppDatabase db, $GameCountersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> kidId = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<int> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GameCountersCompanion(
            kidId: kidId,
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int kidId,
            required String key,
            Value<int> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GameCountersCompanion.insert(
            kidId: kidId,
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

typedef $$GameCountersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GameCountersTable,
    GameCounter,
    $$GameCountersTableFilterComposer,
    $$GameCountersTableOrderingComposer,
    $$GameCountersTableAnnotationComposer,
    $$GameCountersTableCreateCompanionBuilder,
    $$GameCountersTableUpdateCompanionBuilder,
    (
      GameCounter,
      BaseReferences<_$AppDatabase, $GameCountersTable, GameCounter>
    ),
    GameCounter,
    PrefetchHooks Function()>;
typedef $$SyncedRecordsTableCreateCompanionBuilder = SyncedRecordsCompanion
    Function({
  required String key,
  required int version,
  Value<String?> payloadJson,
  Value<int> rowid,
});
typedef $$SyncedRecordsTableUpdateCompanionBuilder = SyncedRecordsCompanion
    Function({
  Value<String> key,
  Value<int> version,
  Value<String?> payloadJson,
  Value<int> rowid,
});

class $$SyncedRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncedRecordsTable> {
  $$SyncedRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));
}

class $$SyncedRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncedRecordsTable> {
  $$SyncedRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));
}

class $$SyncedRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncedRecordsTable> {
  $$SyncedRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);
}

class $$SyncedRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncedRecordsTable,
    SyncedRecord,
    $$SyncedRecordsTableFilterComposer,
    $$SyncedRecordsTableOrderingComposer,
    $$SyncedRecordsTableAnnotationComposer,
    $$SyncedRecordsTableCreateCompanionBuilder,
    $$SyncedRecordsTableUpdateCompanionBuilder,
    (
      SyncedRecord,
      BaseReferences<_$AppDatabase, $SyncedRecordsTable, SyncedRecord>
    ),
    SyncedRecord,
    PrefetchHooks Function()> {
  $$SyncedRecordsTableTableManager(_$AppDatabase db, $SyncedRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String?> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncedRecordsCompanion(
            key: key,
            version: version,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required int version,
            Value<String?> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncedRecordsCompanion.insert(
            key: key,
            version: version,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncedRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncedRecordsTable,
    SyncedRecord,
    $$SyncedRecordsTableFilterComposer,
    $$SyncedRecordsTableOrderingComposer,
    $$SyncedRecordsTableAnnotationComposer,
    $$SyncedRecordsTableCreateCompanionBuilder,
    $$SyncedRecordsTableUpdateCompanionBuilder,
    (
      SyncedRecord,
      BaseReferences<_$AppDatabase, $SyncedRecordsTable, SyncedRecord>
    ),
    SyncedRecord,
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
  $$RaceResultsTableTableManager get raceResults =>
      $$RaceResultsTableTableManager(_db, _db.raceResults);
  $$GameProfileTableTableManager get gameProfile =>
      $$GameProfileTableTableManager(_db, _db.gameProfile);
  $$GameItemsTableTableManager get gameItems =>
      $$GameItemsTableTableManager(_db, _db.gameItems);
  $$GameBadgesTableTableManager get gameBadges =>
      $$GameBadgesTableTableManager(_db, _db.gameBadges);
  $$GameCountersTableTableManager get gameCounters =>
      $$GameCountersTableTableManager(_db, _db.gameCounters);
  $$SyncedRecordsTableTableManager get syncedRecords =>
      $$SyncedRecordsTableTableManager(_db, _db.syncedRecords);
}
