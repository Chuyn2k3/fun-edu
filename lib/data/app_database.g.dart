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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StrokeAttemptsTable strokeAttempts = $StrokeAttemptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [strokeAttempts];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StrokeAttemptsTableTableManager get strokeAttempts =>
      $$StrokeAttemptsTableTableManager(_db, _db.strokeAttempts);
}
