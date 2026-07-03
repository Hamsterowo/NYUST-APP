// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CourseDetailCacheTableTable extends CourseDetailCacheTable
    with TableInfo<$CourseDetailCacheTableTable, CourseDetailCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseDetailCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, dataJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_detail_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseDetailCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CourseDetailCacheTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseDetailCacheTableData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CourseDetailCacheTableTable createAlias(String alias) {
    return $CourseDetailCacheTableTable(attachedDatabase, alias);
  }
}

class CourseDetailCacheTableData extends DataClass
    implements Insertable<CourseDetailCacheTableData> {
  final String cacheKey;
  final String dataJson;
  final DateTime updatedAt;
  const CourseDetailCacheTableData({
    required this.cacheKey,
    required this.dataJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['data_json'] = Variable<String>(dataJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CourseDetailCacheTableCompanion toCompanion(bool nullToAbsent) {
    return CourseDetailCacheTableCompanion(
      cacheKey: Value(cacheKey),
      dataJson: Value(dataJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CourseDetailCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseDetailCacheTableData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'dataJson': serializer.toJson<String>(dataJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CourseDetailCacheTableData copyWith({
    String? cacheKey,
    String? dataJson,
    DateTime? updatedAt,
  }) => CourseDetailCacheTableData(
    cacheKey: cacheKey ?? this.cacheKey,
    dataJson: dataJson ?? this.dataJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CourseDetailCacheTableData copyWithCompanion(
    CourseDetailCacheTableCompanion data,
  ) {
    return CourseDetailCacheTableData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseDetailCacheTableData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, dataJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseDetailCacheTableData &&
          other.cacheKey == this.cacheKey &&
          other.dataJson == this.dataJson &&
          other.updatedAt == this.updatedAt);
}

class CourseDetailCacheTableCompanion
    extends UpdateCompanion<CourseDetailCacheTableData> {
  final Value<String> cacheKey;
  final Value<String> dataJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CourseDetailCacheTableCompanion({
    this.cacheKey = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseDetailCacheTableCompanion.insert({
    required String cacheKey,
    required String dataJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       dataJson = Value(dataJson),
       updatedAt = Value(updatedAt);
  static Insertable<CourseDetailCacheTableData> custom({
    Expression<String>? cacheKey,
    Expression<String>? dataJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (dataJson != null) 'data_json': dataJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseDetailCacheTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? dataJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CourseDetailCacheTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      dataJson: dataJson ?? this.dataJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseDetailCacheTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarCacheTableTable extends CalendarCacheTable
    with TableInfo<$CalendarCacheTableTable, CalendarCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, dataJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CalendarCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarCacheTableData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CalendarCacheTableTable createAlias(String alias) {
    return $CalendarCacheTableTable(attachedDatabase, alias);
  }
}

class CalendarCacheTableData extends DataClass
    implements Insertable<CalendarCacheTableData> {
  final String cacheKey;
  final String dataJson;
  final DateTime updatedAt;
  const CalendarCacheTableData({
    required this.cacheKey,
    required this.dataJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['data_json'] = Variable<String>(dataJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarCacheTableCompanion toCompanion(bool nullToAbsent) {
    return CalendarCacheTableCompanion(
      cacheKey: Value(cacheKey),
      dataJson: Value(dataJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarCacheTableData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'dataJson': serializer.toJson<String>(dataJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarCacheTableData copyWith({
    String? cacheKey,
    String? dataJson,
    DateTime? updatedAt,
  }) => CalendarCacheTableData(
    cacheKey: cacheKey ?? this.cacheKey,
    dataJson: dataJson ?? this.dataJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CalendarCacheTableData copyWithCompanion(CalendarCacheTableCompanion data) {
    return CalendarCacheTableData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarCacheTableData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, dataJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarCacheTableData &&
          other.cacheKey == this.cacheKey &&
          other.dataJson == this.dataJson &&
          other.updatedAt == this.updatedAt);
}

class CalendarCacheTableCompanion
    extends UpdateCompanion<CalendarCacheTableData> {
  final Value<String> cacheKey;
  final Value<String> dataJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalendarCacheTableCompanion({
    this.cacheKey = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarCacheTableCompanion.insert({
    required String cacheKey,
    required String dataJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       dataJson = Value(dataJson),
       updatedAt = Value(updatedAt);
  static Insertable<CalendarCacheTableData> custom({
    Expression<String>? cacheKey,
    Expression<String>? dataJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (dataJson != null) 'data_json': dataJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarCacheTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? dataJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CalendarCacheTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      dataJson: dataJson ?? this.dataJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarCacheTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CourseDetailCacheTableTable courseDetailCacheTable =
      $CourseDetailCacheTableTable(this);
  late final $CalendarCacheTableTable calendarCacheTable =
      $CalendarCacheTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    courseDetailCacheTable,
    calendarCacheTable,
  ];
}

typedef $$CourseDetailCacheTableTableCreateCompanionBuilder =
    CourseDetailCacheTableCompanion Function({
      required String cacheKey,
      required String dataJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CourseDetailCacheTableTableUpdateCompanionBuilder =
    CourseDetailCacheTableCompanion Function({
      Value<String> cacheKey,
      Value<String> dataJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CourseDetailCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $CourseDetailCacheTableTable> {
  $$CourseDetailCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CourseDetailCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseDetailCacheTableTable> {
  $$CourseDetailCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CourseDetailCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseDetailCacheTableTable> {
  $$CourseDetailCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CourseDetailCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseDetailCacheTableTable,
          CourseDetailCacheTableData,
          $$CourseDetailCacheTableTableFilterComposer,
          $$CourseDetailCacheTableTableOrderingComposer,
          $$CourseDetailCacheTableTableAnnotationComposer,
          $$CourseDetailCacheTableTableCreateCompanionBuilder,
          $$CourseDetailCacheTableTableUpdateCompanionBuilder,
          (
            CourseDetailCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $CourseDetailCacheTableTable,
              CourseDetailCacheTableData
            >,
          ),
          CourseDetailCacheTableData,
          PrefetchHooks Function()
        > {
  $$CourseDetailCacheTableTableTableManager(
    _$AppDatabase db,
    $CourseDetailCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseDetailCacheTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CourseDetailCacheTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CourseDetailCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseDetailCacheTableCompanion(
                cacheKey: cacheKey,
                dataJson: dataJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String dataJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CourseDetailCacheTableCompanion.insert(
                cacheKey: cacheKey,
                dataJson: dataJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CourseDetailCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseDetailCacheTableTable,
      CourseDetailCacheTableData,
      $$CourseDetailCacheTableTableFilterComposer,
      $$CourseDetailCacheTableTableOrderingComposer,
      $$CourseDetailCacheTableTableAnnotationComposer,
      $$CourseDetailCacheTableTableCreateCompanionBuilder,
      $$CourseDetailCacheTableTableUpdateCompanionBuilder,
      (
        CourseDetailCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $CourseDetailCacheTableTable,
          CourseDetailCacheTableData
        >,
      ),
      CourseDetailCacheTableData,
      PrefetchHooks Function()
    >;
typedef $$CalendarCacheTableTableCreateCompanionBuilder =
    CalendarCacheTableCompanion Function({
      required String cacheKey,
      required String dataJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CalendarCacheTableTableUpdateCompanionBuilder =
    CalendarCacheTableCompanion Function({
      Value<String> cacheKey,
      Value<String> dataJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CalendarCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarCacheTableTable> {
  $$CalendarCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarCacheTableTable> {
  $$CalendarCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarCacheTableTable> {
  $$CalendarCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CalendarCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarCacheTableTable,
          CalendarCacheTableData,
          $$CalendarCacheTableTableFilterComposer,
          $$CalendarCacheTableTableOrderingComposer,
          $$CalendarCacheTableTableAnnotationComposer,
          $$CalendarCacheTableTableCreateCompanionBuilder,
          $$CalendarCacheTableTableUpdateCompanionBuilder,
          (
            CalendarCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $CalendarCacheTableTable,
              CalendarCacheTableData
            >,
          ),
          CalendarCacheTableData,
          PrefetchHooks Function()
        > {
  $$CalendarCacheTableTableTableManager(
    _$AppDatabase db,
    $CalendarCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarCacheTableCompanion(
                cacheKey: cacheKey,
                dataJson: dataJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String dataJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CalendarCacheTableCompanion.insert(
                cacheKey: cacheKey,
                dataJson: dataJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarCacheTableTable,
      CalendarCacheTableData,
      $$CalendarCacheTableTableFilterComposer,
      $$CalendarCacheTableTableOrderingComposer,
      $$CalendarCacheTableTableAnnotationComposer,
      $$CalendarCacheTableTableCreateCompanionBuilder,
      $$CalendarCacheTableTableUpdateCompanionBuilder,
      (
        CalendarCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $CalendarCacheTableTable,
          CalendarCacheTableData
        >,
      ),
      CalendarCacheTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CourseDetailCacheTableTableTableManager get courseDetailCacheTable =>
      $$CourseDetailCacheTableTableTableManager(
        _db,
        _db.courseDetailCacheTable,
      );
  $$CalendarCacheTableTableTableManager get calendarCacheTable =>
      $$CalendarCacheTableTableTableManager(_db, _db.calendarCacheTable);
}
