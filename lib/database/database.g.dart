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

class $CacheMetaTable extends CacheMeta
    with TableInfo<$CacheMetaTable, CacheMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _datasetKeyMeta = const VerificationMeta(
    'datasetKey',
  );
  @override
  late final GeneratedColumn<String> datasetKey = GeneratedColumn<String>(
    'dataset_key',
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
  List<GeneratedColumn> get $columns => [datasetKey, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dataset_key')) {
      context.handle(
        _datasetKeyMeta,
        datasetKey.isAcceptableOrUnknown(data['dataset_key']!, _datasetKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetKeyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {datasetKey};
  @override
  CacheMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetaData(
      datasetKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_key'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CacheMetaTable createAlias(String alias) {
    return $CacheMetaTable(attachedDatabase, alias);
  }
}

class CacheMetaData extends DataClass implements Insertable<CacheMetaData> {
  final String datasetKey;
  final DateTime updatedAt;
  const CacheMetaData({required this.datasetKey, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dataset_key'] = Variable<String>(datasetKey);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CacheMetaCompanion toCompanion(bool nullToAbsent) {
    return CacheMetaCompanion(
      datasetKey: Value(datasetKey),
      updatedAt: Value(updatedAt),
    );
  }

  factory CacheMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetaData(
      datasetKey: serializer.fromJson<String>(json['datasetKey']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'datasetKey': serializer.toJson<String>(datasetKey),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CacheMetaData copyWith({String? datasetKey, DateTime? updatedAt}) =>
      CacheMetaData(
        datasetKey: datasetKey ?? this.datasetKey,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CacheMetaData copyWithCompanion(CacheMetaCompanion data) {
    return CacheMetaData(
      datasetKey: data.datasetKey.present
          ? data.datasetKey.value
          : this.datasetKey,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetaData(')
          ..write('datasetKey: $datasetKey, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(datasetKey, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheMetaData &&
          other.datasetKey == this.datasetKey &&
          other.updatedAt == this.updatedAt);
}

class CacheMetaCompanion extends UpdateCompanion<CacheMetaData> {
  final Value<String> datasetKey;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CacheMetaCompanion({
    this.datasetKey = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheMetaCompanion.insert({
    required String datasetKey,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : datasetKey = Value(datasetKey),
       updatedAt = Value(updatedAt);
  static Insertable<CacheMetaData> custom({
    Expression<String>? datasetKey,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (datasetKey != null) 'dataset_key': datasetKey,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheMetaCompanion copyWith({
    Value<String>? datasetKey,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CacheMetaCompanion(
      datasetKey: datasetKey ?? this.datasetKey,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (datasetKey.present) {
      map['dataset_key'] = Variable<String>(datasetKey.value);
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
    return (StringBuffer('CacheMetaCompanion(')
          ..write('datasetKey: $datasetKey, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GradesSemestersTable extends GradesSemesters
    with TableInfo<$GradesSemestersTable, GradesSemester> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradesSemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _academicYearMeta = const VerificationMeta(
    'academicYear',
  );
  @override
  late final GeneratedColumn<int> academicYear = GeneratedColumn<int>(
    'academic_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<int> semester = GeneratedColumn<int>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _semesterTitleMeta = const VerificationMeta(
    'semesterTitle',
  );
  @override
  late final GeneratedColumn<String> semesterTitle = GeneratedColumn<String>(
    'semester_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _averageScoreMeta = const VerificationMeta(
    'averageScore',
  );
  @override
  late final GeneratedColumn<String> averageScore = GeneratedColumn<String>(
    'average_score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<String> rank = GeneratedColumn<String>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _gpaMeta = const VerificationMeta('gpa');
  @override
  late final GeneratedColumn<String> gpa = GeneratedColumn<String>(
    'gpa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _conductMeta = const VerificationMeta(
    'conduct',
  );
  @override
  late final GeneratedColumn<String> conduct = GeneratedColumn<String>(
    'conduct',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _attemptedCreditsMeta = const VerificationMeta(
    'attemptedCredits',
  );
  @override
  late final GeneratedColumn<String> attemptedCredits = GeneratedColumn<String>(
    'attempted_credits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _earnedCreditsMeta = const VerificationMeta(
    'earnedCredits',
  );
  @override
  late final GeneratedColumn<String> earnedCredits = GeneratedColumn<String>(
    'earned_credits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    academicYear,
    semester,
    sortOrder,
    semesterTitle,
    averageScore,
    rank,
    gpa,
    conduct,
    attemptedCredits,
    earnedCredits,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grades_semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<GradesSemester> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('academic_year')) {
      context.handle(
        _academicYearMeta,
        academicYear.isAcceptableOrUnknown(
          data['academic_year']!,
          _academicYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_academicYearMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('semester_title')) {
      context.handle(
        _semesterTitleMeta,
        semesterTitle.isAcceptableOrUnknown(
          data['semester_title']!,
          _semesterTitleMeta,
        ),
      );
    }
    if (data.containsKey('average_score')) {
      context.handle(
        _averageScoreMeta,
        averageScore.isAcceptableOrUnknown(
          data['average_score']!,
          _averageScoreMeta,
        ),
      );
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    if (data.containsKey('gpa')) {
      context.handle(
        _gpaMeta,
        gpa.isAcceptableOrUnknown(data['gpa']!, _gpaMeta),
      );
    }
    if (data.containsKey('conduct')) {
      context.handle(
        _conductMeta,
        conduct.isAcceptableOrUnknown(data['conduct']!, _conductMeta),
      );
    }
    if (data.containsKey('attempted_credits')) {
      context.handle(
        _attemptedCreditsMeta,
        attemptedCredits.isAcceptableOrUnknown(
          data['attempted_credits']!,
          _attemptedCreditsMeta,
        ),
      );
    }
    if (data.containsKey('earned_credits')) {
      context.handle(
        _earnedCreditsMeta,
        earnedCredits.isAcceptableOrUnknown(
          data['earned_credits']!,
          _earnedCreditsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {academicYear, semester};
  @override
  GradesSemester map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradesSemester(
      academicYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}academic_year'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      semesterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_title'],
      )!,
      averageScore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}average_score'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rank'],
      )!,
      gpa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gpa'],
      )!,
      conduct: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conduct'],
      )!,
      attemptedCredits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempted_credits'],
      )!,
      earnedCredits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earned_credits'],
      )!,
    );
  }

  @override
  $GradesSemestersTable createAlias(String alias) {
    return $GradesSemestersTable(attachedDatabase, alias);
  }
}

class GradesSemester extends DataClass implements Insertable<GradesSemester> {
  final int academicYear;
  final int semester;

  /// 於 grades 陣列中的原始順序，重建時用來還原顯示順序。
  final int sortOrder;
  final String semesterTitle;
  final String averageScore;
  final String rank;
  final String gpa;
  final String conduct;
  final String attemptedCredits;
  final String earnedCredits;
  const GradesSemester({
    required this.academicYear,
    required this.semester,
    required this.sortOrder,
    required this.semesterTitle,
    required this.averageScore,
    required this.rank,
    required this.gpa,
    required this.conduct,
    required this.attemptedCredits,
    required this.earnedCredits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['academic_year'] = Variable<int>(academicYear);
    map['semester'] = Variable<int>(semester);
    map['sort_order'] = Variable<int>(sortOrder);
    map['semester_title'] = Variable<String>(semesterTitle);
    map['average_score'] = Variable<String>(averageScore);
    map['rank'] = Variable<String>(rank);
    map['gpa'] = Variable<String>(gpa);
    map['conduct'] = Variable<String>(conduct);
    map['attempted_credits'] = Variable<String>(attemptedCredits);
    map['earned_credits'] = Variable<String>(earnedCredits);
    return map;
  }

  GradesSemestersCompanion toCompanion(bool nullToAbsent) {
    return GradesSemestersCompanion(
      academicYear: Value(academicYear),
      semester: Value(semester),
      sortOrder: Value(sortOrder),
      semesterTitle: Value(semesterTitle),
      averageScore: Value(averageScore),
      rank: Value(rank),
      gpa: Value(gpa),
      conduct: Value(conduct),
      attemptedCredits: Value(attemptedCredits),
      earnedCredits: Value(earnedCredits),
    );
  }

  factory GradesSemester.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradesSemester(
      academicYear: serializer.fromJson<int>(json['academicYear']),
      semester: serializer.fromJson<int>(json['semester']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      semesterTitle: serializer.fromJson<String>(json['semesterTitle']),
      averageScore: serializer.fromJson<String>(json['averageScore']),
      rank: serializer.fromJson<String>(json['rank']),
      gpa: serializer.fromJson<String>(json['gpa']),
      conduct: serializer.fromJson<String>(json['conduct']),
      attemptedCredits: serializer.fromJson<String>(json['attemptedCredits']),
      earnedCredits: serializer.fromJson<String>(json['earnedCredits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'academicYear': serializer.toJson<int>(academicYear),
      'semester': serializer.toJson<int>(semester),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'semesterTitle': serializer.toJson<String>(semesterTitle),
      'averageScore': serializer.toJson<String>(averageScore),
      'rank': serializer.toJson<String>(rank),
      'gpa': serializer.toJson<String>(gpa),
      'conduct': serializer.toJson<String>(conduct),
      'attemptedCredits': serializer.toJson<String>(attemptedCredits),
      'earnedCredits': serializer.toJson<String>(earnedCredits),
    };
  }

  GradesSemester copyWith({
    int? academicYear,
    int? semester,
    int? sortOrder,
    String? semesterTitle,
    String? averageScore,
    String? rank,
    String? gpa,
    String? conduct,
    String? attemptedCredits,
    String? earnedCredits,
  }) => GradesSemester(
    academicYear: academicYear ?? this.academicYear,
    semester: semester ?? this.semester,
    sortOrder: sortOrder ?? this.sortOrder,
    semesterTitle: semesterTitle ?? this.semesterTitle,
    averageScore: averageScore ?? this.averageScore,
    rank: rank ?? this.rank,
    gpa: gpa ?? this.gpa,
    conduct: conduct ?? this.conduct,
    attemptedCredits: attemptedCredits ?? this.attemptedCredits,
    earnedCredits: earnedCredits ?? this.earnedCredits,
  );
  GradesSemester copyWithCompanion(GradesSemestersCompanion data) {
    return GradesSemester(
      academicYear: data.academicYear.present
          ? data.academicYear.value
          : this.academicYear,
      semester: data.semester.present ? data.semester.value : this.semester,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      semesterTitle: data.semesterTitle.present
          ? data.semesterTitle.value
          : this.semesterTitle,
      averageScore: data.averageScore.present
          ? data.averageScore.value
          : this.averageScore,
      rank: data.rank.present ? data.rank.value : this.rank,
      gpa: data.gpa.present ? data.gpa.value : this.gpa,
      conduct: data.conduct.present ? data.conduct.value : this.conduct,
      attemptedCredits: data.attemptedCredits.present
          ? data.attemptedCredits.value
          : this.attemptedCredits,
      earnedCredits: data.earnedCredits.present
          ? data.earnedCredits.value
          : this.earnedCredits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradesSemester(')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('semesterTitle: $semesterTitle, ')
          ..write('averageScore: $averageScore, ')
          ..write('rank: $rank, ')
          ..write('gpa: $gpa, ')
          ..write('conduct: $conduct, ')
          ..write('attemptedCredits: $attemptedCredits, ')
          ..write('earnedCredits: $earnedCredits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    academicYear,
    semester,
    sortOrder,
    semesterTitle,
    averageScore,
    rank,
    gpa,
    conduct,
    attemptedCredits,
    earnedCredits,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradesSemester &&
          other.academicYear == this.academicYear &&
          other.semester == this.semester &&
          other.sortOrder == this.sortOrder &&
          other.semesterTitle == this.semesterTitle &&
          other.averageScore == this.averageScore &&
          other.rank == this.rank &&
          other.gpa == this.gpa &&
          other.conduct == this.conduct &&
          other.attemptedCredits == this.attemptedCredits &&
          other.earnedCredits == this.earnedCredits);
}

class GradesSemestersCompanion extends UpdateCompanion<GradesSemester> {
  final Value<int> academicYear;
  final Value<int> semester;
  final Value<int> sortOrder;
  final Value<String> semesterTitle;
  final Value<String> averageScore;
  final Value<String> rank;
  final Value<String> gpa;
  final Value<String> conduct;
  final Value<String> attemptedCredits;
  final Value<String> earnedCredits;
  final Value<int> rowid;
  const GradesSemestersCompanion({
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.semesterTitle = const Value.absent(),
    this.averageScore = const Value.absent(),
    this.rank = const Value.absent(),
    this.gpa = const Value.absent(),
    this.conduct = const Value.absent(),
    this.attemptedCredits = const Value.absent(),
    this.earnedCredits = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GradesSemestersCompanion.insert({
    required int academicYear,
    required int semester,
    this.sortOrder = const Value.absent(),
    this.semesterTitle = const Value.absent(),
    this.averageScore = const Value.absent(),
    this.rank = const Value.absent(),
    this.gpa = const Value.absent(),
    this.conduct = const Value.absent(),
    this.attemptedCredits = const Value.absent(),
    this.earnedCredits = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : academicYear = Value(academicYear),
       semester = Value(semester);
  static Insertable<GradesSemester> custom({
    Expression<int>? academicYear,
    Expression<int>? semester,
    Expression<int>? sortOrder,
    Expression<String>? semesterTitle,
    Expression<String>? averageScore,
    Expression<String>? rank,
    Expression<String>? gpa,
    Expression<String>? conduct,
    Expression<String>? attemptedCredits,
    Expression<String>? earnedCredits,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (academicYear != null) 'academic_year': academicYear,
      if (semester != null) 'semester': semester,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (semesterTitle != null) 'semester_title': semesterTitle,
      if (averageScore != null) 'average_score': averageScore,
      if (rank != null) 'rank': rank,
      if (gpa != null) 'gpa': gpa,
      if (conduct != null) 'conduct': conduct,
      if (attemptedCredits != null) 'attempted_credits': attemptedCredits,
      if (earnedCredits != null) 'earned_credits': earnedCredits,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GradesSemestersCompanion copyWith({
    Value<int>? academicYear,
    Value<int>? semester,
    Value<int>? sortOrder,
    Value<String>? semesterTitle,
    Value<String>? averageScore,
    Value<String>? rank,
    Value<String>? gpa,
    Value<String>? conduct,
    Value<String>? attemptedCredits,
    Value<String>? earnedCredits,
    Value<int>? rowid,
  }) {
    return GradesSemestersCompanion(
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      sortOrder: sortOrder ?? this.sortOrder,
      semesterTitle: semesterTitle ?? this.semesterTitle,
      averageScore: averageScore ?? this.averageScore,
      rank: rank ?? this.rank,
      gpa: gpa ?? this.gpa,
      conduct: conduct ?? this.conduct,
      attemptedCredits: attemptedCredits ?? this.attemptedCredits,
      earnedCredits: earnedCredits ?? this.earnedCredits,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (academicYear.present) {
      map['academic_year'] = Variable<int>(academicYear.value);
    }
    if (semester.present) {
      map['semester'] = Variable<int>(semester.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (semesterTitle.present) {
      map['semester_title'] = Variable<String>(semesterTitle.value);
    }
    if (averageScore.present) {
      map['average_score'] = Variable<String>(averageScore.value);
    }
    if (rank.present) {
      map['rank'] = Variable<String>(rank.value);
    }
    if (gpa.present) {
      map['gpa'] = Variable<String>(gpa.value);
    }
    if (conduct.present) {
      map['conduct'] = Variable<String>(conduct.value);
    }
    if (attemptedCredits.present) {
      map['attempted_credits'] = Variable<String>(attemptedCredits.value);
    }
    if (earnedCredits.present) {
      map['earned_credits'] = Variable<String>(earnedCredits.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradesSemestersCompanion(')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('semesterTitle: $semesterTitle, ')
          ..write('averageScore: $averageScore, ')
          ..write('rank: $rank, ')
          ..write('gpa: $gpa, ')
          ..write('conduct: $conduct, ')
          ..write('attemptedCredits: $attemptedCredits, ')
          ..write('earnedCredits: $earnedCredits, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GradesCoursesTable extends GradesCourses
    with TableInfo<$GradesCoursesTable, GradesCourse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradesCoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _academicYearMeta = const VerificationMeta(
    'academicYear',
  );
  @override
  late final GeneratedColumn<int> academicYear = GeneratedColumn<int>(
    'academic_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<int> semester = GeneratedColumn<int>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _courseNoMeta = const VerificationMeta(
    'courseNo',
  );
  @override
  late final GeneratedColumn<String> courseNo = GeneratedColumn<String>(
    'course_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creditsMeta = const VerificationMeta(
    'credits',
  );
  @override
  late final GeneratedColumn<String> credits = GeneratedColumn<String>(
    'credits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syllabusUrlMeta = const VerificationMeta(
    'syllabusUrl',
  );
  @override
  late final GeneratedColumn<String> syllabusUrl = GeneratedColumn<String>(
    'syllabus_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    academicYear,
    semester,
    sortOrder,
    code,
    courseNo,
    name,
    nameEn,
    type,
    credits,
    score,
    syllabusUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grades_courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<GradesCourse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('academic_year')) {
      context.handle(
        _academicYearMeta,
        academicYear.isAcceptableOrUnknown(
          data['academic_year']!,
          _academicYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_academicYearMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('course_no')) {
      context.handle(
        _courseNoMeta,
        courseNo.isAcceptableOrUnknown(data['course_no']!, _courseNoMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('credits')) {
      context.handle(
        _creditsMeta,
        credits.isAcceptableOrUnknown(data['credits']!, _creditsMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('syllabus_url')) {
      context.handle(
        _syllabusUrlMeta,
        syllabusUrl.isAcceptableOrUnknown(
          data['syllabus_url']!,
          _syllabusUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GradesCourse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradesCourse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      academicYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}academic_year'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      courseNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_no'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      credits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credits'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score'],
      )!,
      syllabusUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}syllabus_url'],
      )!,
    );
  }

  @override
  $GradesCoursesTable createAlias(String alias) {
    return $GradesCoursesTable(attachedDatabase, alias);
  }
}

class GradesCourse extends DataClass implements Insertable<GradesCourse> {
  final int id;
  final int academicYear;
  final int semester;

  /// 於該學期 courses 陣列中的原始順序。
  final int sortOrder;
  final String code;
  final String courseNo;
  final String name;
  final String nameEn;
  final String type;
  final String credits;
  final String score;
  final String syllabusUrl;
  const GradesCourse({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.sortOrder,
    required this.code,
    required this.courseNo,
    required this.name,
    required this.nameEn,
    required this.type,
    required this.credits,
    required this.score,
    required this.syllabusUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['academic_year'] = Variable<int>(academicYear);
    map['semester'] = Variable<int>(semester);
    map['sort_order'] = Variable<int>(sortOrder);
    map['code'] = Variable<String>(code);
    map['course_no'] = Variable<String>(courseNo);
    map['name'] = Variable<String>(name);
    map['name_en'] = Variable<String>(nameEn);
    map['type'] = Variable<String>(type);
    map['credits'] = Variable<String>(credits);
    map['score'] = Variable<String>(score);
    map['syllabus_url'] = Variable<String>(syllabusUrl);
    return map;
  }

  GradesCoursesCompanion toCompanion(bool nullToAbsent) {
    return GradesCoursesCompanion(
      id: Value(id),
      academicYear: Value(academicYear),
      semester: Value(semester),
      sortOrder: Value(sortOrder),
      code: Value(code),
      courseNo: Value(courseNo),
      name: Value(name),
      nameEn: Value(nameEn),
      type: Value(type),
      credits: Value(credits),
      score: Value(score),
      syllabusUrl: Value(syllabusUrl),
    );
  }

  factory GradesCourse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradesCourse(
      id: serializer.fromJson<int>(json['id']),
      academicYear: serializer.fromJson<int>(json['academicYear']),
      semester: serializer.fromJson<int>(json['semester']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      code: serializer.fromJson<String>(json['code']),
      courseNo: serializer.fromJson<String>(json['courseNo']),
      name: serializer.fromJson<String>(json['name']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      type: serializer.fromJson<String>(json['type']),
      credits: serializer.fromJson<String>(json['credits']),
      score: serializer.fromJson<String>(json['score']),
      syllabusUrl: serializer.fromJson<String>(json['syllabusUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'academicYear': serializer.toJson<int>(academicYear),
      'semester': serializer.toJson<int>(semester),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'code': serializer.toJson<String>(code),
      'courseNo': serializer.toJson<String>(courseNo),
      'name': serializer.toJson<String>(name),
      'nameEn': serializer.toJson<String>(nameEn),
      'type': serializer.toJson<String>(type),
      'credits': serializer.toJson<String>(credits),
      'score': serializer.toJson<String>(score),
      'syllabusUrl': serializer.toJson<String>(syllabusUrl),
    };
  }

  GradesCourse copyWith({
    int? id,
    int? academicYear,
    int? semester,
    int? sortOrder,
    String? code,
    String? courseNo,
    String? name,
    String? nameEn,
    String? type,
    String? credits,
    String? score,
    String? syllabusUrl,
  }) => GradesCourse(
    id: id ?? this.id,
    academicYear: academicYear ?? this.academicYear,
    semester: semester ?? this.semester,
    sortOrder: sortOrder ?? this.sortOrder,
    code: code ?? this.code,
    courseNo: courseNo ?? this.courseNo,
    name: name ?? this.name,
    nameEn: nameEn ?? this.nameEn,
    type: type ?? this.type,
    credits: credits ?? this.credits,
    score: score ?? this.score,
    syllabusUrl: syllabusUrl ?? this.syllabusUrl,
  );
  GradesCourse copyWithCompanion(GradesCoursesCompanion data) {
    return GradesCourse(
      id: data.id.present ? data.id.value : this.id,
      academicYear: data.academicYear.present
          ? data.academicYear.value
          : this.academicYear,
      semester: data.semester.present ? data.semester.value : this.semester,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      code: data.code.present ? data.code.value : this.code,
      courseNo: data.courseNo.present ? data.courseNo.value : this.courseNo,
      name: data.name.present ? data.name.value : this.name,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      type: data.type.present ? data.type.value : this.type,
      credits: data.credits.present ? data.credits.value : this.credits,
      score: data.score.present ? data.score.value : this.score,
      syllabusUrl: data.syllabusUrl.present
          ? data.syllabusUrl.value
          : this.syllabusUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradesCourse(')
          ..write('id: $id, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('code: $code, ')
          ..write('courseNo: $courseNo, ')
          ..write('name: $name, ')
          ..write('nameEn: $nameEn, ')
          ..write('type: $type, ')
          ..write('credits: $credits, ')
          ..write('score: $score, ')
          ..write('syllabusUrl: $syllabusUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    academicYear,
    semester,
    sortOrder,
    code,
    courseNo,
    name,
    nameEn,
    type,
    credits,
    score,
    syllabusUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradesCourse &&
          other.id == this.id &&
          other.academicYear == this.academicYear &&
          other.semester == this.semester &&
          other.sortOrder == this.sortOrder &&
          other.code == this.code &&
          other.courseNo == this.courseNo &&
          other.name == this.name &&
          other.nameEn == this.nameEn &&
          other.type == this.type &&
          other.credits == this.credits &&
          other.score == this.score &&
          other.syllabusUrl == this.syllabusUrl);
}

class GradesCoursesCompanion extends UpdateCompanion<GradesCourse> {
  final Value<int> id;
  final Value<int> academicYear;
  final Value<int> semester;
  final Value<int> sortOrder;
  final Value<String> code;
  final Value<String> courseNo;
  final Value<String> name;
  final Value<String> nameEn;
  final Value<String> type;
  final Value<String> credits;
  final Value<String> score;
  final Value<String> syllabusUrl;
  const GradesCoursesCompanion({
    this.id = const Value.absent(),
    this.academicYear = const Value.absent(),
    this.semester = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.code = const Value.absent(),
    this.courseNo = const Value.absent(),
    this.name = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.type = const Value.absent(),
    this.credits = const Value.absent(),
    this.score = const Value.absent(),
    this.syllabusUrl = const Value.absent(),
  });
  GradesCoursesCompanion.insert({
    this.id = const Value.absent(),
    required int academicYear,
    required int semester,
    this.sortOrder = const Value.absent(),
    this.code = const Value.absent(),
    this.courseNo = const Value.absent(),
    this.name = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.type = const Value.absent(),
    this.credits = const Value.absent(),
    this.score = const Value.absent(),
    this.syllabusUrl = const Value.absent(),
  }) : academicYear = Value(academicYear),
       semester = Value(semester);
  static Insertable<GradesCourse> custom({
    Expression<int>? id,
    Expression<int>? academicYear,
    Expression<int>? semester,
    Expression<int>? sortOrder,
    Expression<String>? code,
    Expression<String>? courseNo,
    Expression<String>? name,
    Expression<String>? nameEn,
    Expression<String>? type,
    Expression<String>? credits,
    Expression<String>? score,
    Expression<String>? syllabusUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (academicYear != null) 'academic_year': academicYear,
      if (semester != null) 'semester': semester,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (code != null) 'code': code,
      if (courseNo != null) 'course_no': courseNo,
      if (name != null) 'name': name,
      if (nameEn != null) 'name_en': nameEn,
      if (type != null) 'type': type,
      if (credits != null) 'credits': credits,
      if (score != null) 'score': score,
      if (syllabusUrl != null) 'syllabus_url': syllabusUrl,
    });
  }

  GradesCoursesCompanion copyWith({
    Value<int>? id,
    Value<int>? academicYear,
    Value<int>? semester,
    Value<int>? sortOrder,
    Value<String>? code,
    Value<String>? courseNo,
    Value<String>? name,
    Value<String>? nameEn,
    Value<String>? type,
    Value<String>? credits,
    Value<String>? score,
    Value<String>? syllabusUrl,
  }) {
    return GradesCoursesCompanion(
      id: id ?? this.id,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      sortOrder: sortOrder ?? this.sortOrder,
      code: code ?? this.code,
      courseNo: courseNo ?? this.courseNo,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      type: type ?? this.type,
      credits: credits ?? this.credits,
      score: score ?? this.score,
      syllabusUrl: syllabusUrl ?? this.syllabusUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (academicYear.present) {
      map['academic_year'] = Variable<int>(academicYear.value);
    }
    if (semester.present) {
      map['semester'] = Variable<int>(semester.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (courseNo.present) {
      map['course_no'] = Variable<String>(courseNo.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (credits.present) {
      map['credits'] = Variable<String>(credits.value);
    }
    if (score.present) {
      map['score'] = Variable<String>(score.value);
    }
    if (syllabusUrl.present) {
      map['syllabus_url'] = Variable<String>(syllabusUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradesCoursesCompanion(')
          ..write('id: $id, ')
          ..write('academicYear: $academicYear, ')
          ..write('semester: $semester, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('code: $code, ')
          ..write('courseNo: $courseNo, ')
          ..write('name: $name, ')
          ..write('nameEn: $nameEn, ')
          ..write('type: $type, ')
          ..write('credits: $credits, ')
          ..write('score: $score, ')
          ..write('syllabusUrl: $syllabusUrl')
          ..write(')'))
        .toString();
  }
}

class $GradesCumulativeTable extends GradesCumulative
    with TableInfo<$GradesCumulativeTable, GradesCumulativeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradesCumulativeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptedCreditsMeta = const VerificationMeta(
    'attemptedCredits',
  );
  @override
  late final GeneratedColumn<String> attemptedCredits = GeneratedColumn<String>(
    'attempted_credits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _earnedCreditsMeta = const VerificationMeta(
    'earnedCredits',
  );
  @override
  late final GeneratedColumn<String> earnedCredits = GeneratedColumn<String>(
    'earned_credits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _averageMeta = const VerificationMeta(
    'average',
  );
  @override
  late final GeneratedColumn<String> average = GeneratedColumn<String>(
    'average',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<String> rank = GeneratedColumn<String>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _totalStudentsMeta = const VerificationMeta(
    'totalStudents',
  );
  @override
  late final GeneratedColumn<String> totalStudents = GeneratedColumn<String>(
    'total_students',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _gpaMeta = const VerificationMeta('gpa');
  @override
  late final GeneratedColumn<String> gpa = GeneratedColumn<String>(
    'gpa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    attemptedCredits,
    earnedCredits,
    average,
    rank,
    totalStudents,
    gpa,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grades_cumulative';
  @override
  VerificationContext validateIntegrity(
    Insertable<GradesCumulativeData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('attempted_credits')) {
      context.handle(
        _attemptedCreditsMeta,
        attemptedCredits.isAcceptableOrUnknown(
          data['attempted_credits']!,
          _attemptedCreditsMeta,
        ),
      );
    }
    if (data.containsKey('earned_credits')) {
      context.handle(
        _earnedCreditsMeta,
        earnedCredits.isAcceptableOrUnknown(
          data['earned_credits']!,
          _earnedCreditsMeta,
        ),
      );
    }
    if (data.containsKey('average')) {
      context.handle(
        _averageMeta,
        average.isAcceptableOrUnknown(data['average']!, _averageMeta),
      );
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    if (data.containsKey('total_students')) {
      context.handle(
        _totalStudentsMeta,
        totalStudents.isAcceptableOrUnknown(
          data['total_students']!,
          _totalStudentsMeta,
        ),
      );
    }
    if (data.containsKey('gpa')) {
      context.handle(
        _gpaMeta,
        gpa.isAcceptableOrUnknown(data['gpa']!, _gpaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GradesCumulativeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradesCumulativeData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      attemptedCredits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempted_credits'],
      )!,
      earnedCredits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earned_credits'],
      )!,
      average: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}average'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rank'],
      )!,
      totalStudents: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}total_students'],
      )!,
      gpa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gpa'],
      )!,
    );
  }

  @override
  $GradesCumulativeTable createAlias(String alias) {
    return $GradesCumulativeTable(attachedDatabase, alias);
  }
}

class GradesCumulativeData extends DataClass
    implements Insertable<GradesCumulativeData> {
  final int id;
  final String attemptedCredits;
  final String earnedCredits;
  final String average;
  final String rank;
  final String totalStudents;
  final String gpa;
  const GradesCumulativeData({
    required this.id,
    required this.attemptedCredits,
    required this.earnedCredits,
    required this.average,
    required this.rank,
    required this.totalStudents,
    required this.gpa,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['attempted_credits'] = Variable<String>(attemptedCredits);
    map['earned_credits'] = Variable<String>(earnedCredits);
    map['average'] = Variable<String>(average);
    map['rank'] = Variable<String>(rank);
    map['total_students'] = Variable<String>(totalStudents);
    map['gpa'] = Variable<String>(gpa);
    return map;
  }

  GradesCumulativeCompanion toCompanion(bool nullToAbsent) {
    return GradesCumulativeCompanion(
      id: Value(id),
      attemptedCredits: Value(attemptedCredits),
      earnedCredits: Value(earnedCredits),
      average: Value(average),
      rank: Value(rank),
      totalStudents: Value(totalStudents),
      gpa: Value(gpa),
    );
  }

  factory GradesCumulativeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradesCumulativeData(
      id: serializer.fromJson<int>(json['id']),
      attemptedCredits: serializer.fromJson<String>(json['attemptedCredits']),
      earnedCredits: serializer.fromJson<String>(json['earnedCredits']),
      average: serializer.fromJson<String>(json['average']),
      rank: serializer.fromJson<String>(json['rank']),
      totalStudents: serializer.fromJson<String>(json['totalStudents']),
      gpa: serializer.fromJson<String>(json['gpa']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'attemptedCredits': serializer.toJson<String>(attemptedCredits),
      'earnedCredits': serializer.toJson<String>(earnedCredits),
      'average': serializer.toJson<String>(average),
      'rank': serializer.toJson<String>(rank),
      'totalStudents': serializer.toJson<String>(totalStudents),
      'gpa': serializer.toJson<String>(gpa),
    };
  }

  GradesCumulativeData copyWith({
    int? id,
    String? attemptedCredits,
    String? earnedCredits,
    String? average,
    String? rank,
    String? totalStudents,
    String? gpa,
  }) => GradesCumulativeData(
    id: id ?? this.id,
    attemptedCredits: attemptedCredits ?? this.attemptedCredits,
    earnedCredits: earnedCredits ?? this.earnedCredits,
    average: average ?? this.average,
    rank: rank ?? this.rank,
    totalStudents: totalStudents ?? this.totalStudents,
    gpa: gpa ?? this.gpa,
  );
  GradesCumulativeData copyWithCompanion(GradesCumulativeCompanion data) {
    return GradesCumulativeData(
      id: data.id.present ? data.id.value : this.id,
      attemptedCredits: data.attemptedCredits.present
          ? data.attemptedCredits.value
          : this.attemptedCredits,
      earnedCredits: data.earnedCredits.present
          ? data.earnedCredits.value
          : this.earnedCredits,
      average: data.average.present ? data.average.value : this.average,
      rank: data.rank.present ? data.rank.value : this.rank,
      totalStudents: data.totalStudents.present
          ? data.totalStudents.value
          : this.totalStudents,
      gpa: data.gpa.present ? data.gpa.value : this.gpa,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradesCumulativeData(')
          ..write('id: $id, ')
          ..write('attemptedCredits: $attemptedCredits, ')
          ..write('earnedCredits: $earnedCredits, ')
          ..write('average: $average, ')
          ..write('rank: $rank, ')
          ..write('totalStudents: $totalStudents, ')
          ..write('gpa: $gpa')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    attemptedCredits,
    earnedCredits,
    average,
    rank,
    totalStudents,
    gpa,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradesCumulativeData &&
          other.id == this.id &&
          other.attemptedCredits == this.attemptedCredits &&
          other.earnedCredits == this.earnedCredits &&
          other.average == this.average &&
          other.rank == this.rank &&
          other.totalStudents == this.totalStudents &&
          other.gpa == this.gpa);
}

class GradesCumulativeCompanion extends UpdateCompanion<GradesCumulativeData> {
  final Value<int> id;
  final Value<String> attemptedCredits;
  final Value<String> earnedCredits;
  final Value<String> average;
  final Value<String> rank;
  final Value<String> totalStudents;
  final Value<String> gpa;
  const GradesCumulativeCompanion({
    this.id = const Value.absent(),
    this.attemptedCredits = const Value.absent(),
    this.earnedCredits = const Value.absent(),
    this.average = const Value.absent(),
    this.rank = const Value.absent(),
    this.totalStudents = const Value.absent(),
    this.gpa = const Value.absent(),
  });
  GradesCumulativeCompanion.insert({
    this.id = const Value.absent(),
    this.attemptedCredits = const Value.absent(),
    this.earnedCredits = const Value.absent(),
    this.average = const Value.absent(),
    this.rank = const Value.absent(),
    this.totalStudents = const Value.absent(),
    this.gpa = const Value.absent(),
  });
  static Insertable<GradesCumulativeData> custom({
    Expression<int>? id,
    Expression<String>? attemptedCredits,
    Expression<String>? earnedCredits,
    Expression<String>? average,
    Expression<String>? rank,
    Expression<String>? totalStudents,
    Expression<String>? gpa,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attemptedCredits != null) 'attempted_credits': attemptedCredits,
      if (earnedCredits != null) 'earned_credits': earnedCredits,
      if (average != null) 'average': average,
      if (rank != null) 'rank': rank,
      if (totalStudents != null) 'total_students': totalStudents,
      if (gpa != null) 'gpa': gpa,
    });
  }

  GradesCumulativeCompanion copyWith({
    Value<int>? id,
    Value<String>? attemptedCredits,
    Value<String>? earnedCredits,
    Value<String>? average,
    Value<String>? rank,
    Value<String>? totalStudents,
    Value<String>? gpa,
  }) {
    return GradesCumulativeCompanion(
      id: id ?? this.id,
      attemptedCredits: attemptedCredits ?? this.attemptedCredits,
      earnedCredits: earnedCredits ?? this.earnedCredits,
      average: average ?? this.average,
      rank: rank ?? this.rank,
      totalStudents: totalStudents ?? this.totalStudents,
      gpa: gpa ?? this.gpa,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (attemptedCredits.present) {
      map['attempted_credits'] = Variable<String>(attemptedCredits.value);
    }
    if (earnedCredits.present) {
      map['earned_credits'] = Variable<String>(earnedCredits.value);
    }
    if (average.present) {
      map['average'] = Variable<String>(average.value);
    }
    if (rank.present) {
      map['rank'] = Variable<String>(rank.value);
    }
    if (totalStudents.present) {
      map['total_students'] = Variable<String>(totalStudents.value);
    }
    if (gpa.present) {
      map['gpa'] = Variable<String>(gpa.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradesCumulativeCompanion(')
          ..write('id: $id, ')
          ..write('attemptedCredits: $attemptedCredits, ')
          ..write('earnedCredits: $earnedCredits, ')
          ..write('average: $average, ')
          ..write('rank: $rank, ')
          ..write('totalStudents: $totalStudents, ')
          ..write('gpa: $gpa')
          ..write(')'))
        .toString();
  }
}

class $ScheduleCoursesTable extends ScheduleCourses
    with TableInfo<$ScheduleCoursesTable, ScheduleCourse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleCoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _semesterCourseNoMeta = const VerificationMeta(
    'semesterCourseNo',
  );
  @override
  late final GeneratedColumn<String> semesterCourseNo = GeneratedColumn<String>(
    'semester_course_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deptCourseNoMeta = const VerificationMeta(
    'deptCourseNo',
  );
  @override
  late final GeneratedColumn<String> deptCourseNo = GeneratedColumn<String>(
    'dept_course_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _courseClassMeta = const VerificationMeta(
    'courseClass',
  );
  @override
  late final GeneratedColumn<String> courseClass = GeneratedColumn<String>(
    'course_class',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _classTypeMeta = const VerificationMeta(
    'classType',
  );
  @override
  late final GeneratedColumn<String> classType = GeneratedColumn<String>(
    'class_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _requiredTypeMeta = const VerificationMeta(
    'requiredType',
  );
  @override
  late final GeneratedColumn<String> requiredType = GeneratedColumn<String>(
    'required_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creditsMeta = const VerificationMeta(
    'credits',
  );
  @override
  late final GeneratedColumn<String> credits = GeneratedColumn<String>(
    'credits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _timeRoomStrMeta = const VerificationMeta(
    'timeRoomStr',
  );
  @override
  late final GeneratedColumn<String> timeRoomStr = GeneratedColumn<String>(
    'time_room_str',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<String> weekday = GeneratedColumn<String>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _timesJsonMeta = const VerificationMeta(
    'timesJson',
  );
  @override
  late final GeneratedColumn<String> timesJson = GeneratedColumn<String>(
    'times_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syllabusUrlMeta = const VerificationMeta(
    'syllabusUrl',
  );
  @override
  late final GeneratedColumn<String> syllabusUrl = GeneratedColumn<String>(
    'syllabus_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _courseNoMeta = const VerificationMeta(
    'courseNo',
  );
  @override
  late final GeneratedColumn<String> courseNo = GeneratedColumn<String>(
    'course_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sortOrder,
    semesterCourseNo,
    deptCourseNo,
    name,
    nameEn,
    courseClass,
    classType,
    requiredType,
    credits,
    timeRoomStr,
    teacher,
    remark,
    weekday,
    timesJson,
    room,
    syllabusUrl,
    year,
    semester,
    courseNo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleCourse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('semester_course_no')) {
      context.handle(
        _semesterCourseNoMeta,
        semesterCourseNo.isAcceptableOrUnknown(
          data['semester_course_no']!,
          _semesterCourseNoMeta,
        ),
      );
    }
    if (data.containsKey('dept_course_no')) {
      context.handle(
        _deptCourseNoMeta,
        deptCourseNo.isAcceptableOrUnknown(
          data['dept_course_no']!,
          _deptCourseNoMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('course_class')) {
      context.handle(
        _courseClassMeta,
        courseClass.isAcceptableOrUnknown(
          data['course_class']!,
          _courseClassMeta,
        ),
      );
    }
    if (data.containsKey('class_type')) {
      context.handle(
        _classTypeMeta,
        classType.isAcceptableOrUnknown(data['class_type']!, _classTypeMeta),
      );
    }
    if (data.containsKey('required_type')) {
      context.handle(
        _requiredTypeMeta,
        requiredType.isAcceptableOrUnknown(
          data['required_type']!,
          _requiredTypeMeta,
        ),
      );
    }
    if (data.containsKey('credits')) {
      context.handle(
        _creditsMeta,
        credits.isAcceptableOrUnknown(data['credits']!, _creditsMeta),
      );
    }
    if (data.containsKey('time_room_str')) {
      context.handle(
        _timeRoomStrMeta,
        timeRoomStr.isAcceptableOrUnknown(
          data['time_room_str']!,
          _timeRoomStrMeta,
        ),
      );
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('times_json')) {
      context.handle(
        _timesJsonMeta,
        timesJson.isAcceptableOrUnknown(data['times_json']!, _timesJsonMeta),
      );
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    }
    if (data.containsKey('syllabus_url')) {
      context.handle(
        _syllabusUrlMeta,
        syllabusUrl.isAcceptableOrUnknown(
          data['syllabus_url']!,
          _syllabusUrlMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    }
    if (data.containsKey('course_no')) {
      context.handle(
        _courseNoMeta,
        courseNo.isAcceptableOrUnknown(data['course_no']!, _courseNoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleCourse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleCourse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      semesterCourseNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester_course_no'],
      )!,
      deptCourseNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dept_course_no'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      courseClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_class'],
      )!,
      classType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_type'],
      )!,
      requiredType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_type'],
      )!,
      credits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credits'],
      )!,
      timeRoomStr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_room_str'],
      )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      )!,
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekday'],
      )!,
      timesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times_json'],
      )!,
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      )!,
      syllabusUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}syllabus_url'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester'],
      )!,
      courseNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_no'],
      )!,
    );
  }

  @override
  $ScheduleCoursesTable createAlias(String alias) {
    return $ScheduleCoursesTable(attachedDatabase, alias);
  }
}

class ScheduleCourse extends DataClass implements Insertable<ScheduleCourse> {
  final int id;

  /// 於 schedule 陣列中的原始順序。
  final int sortOrder;
  final String semesterCourseNo;
  final String deptCourseNo;
  final String name;
  final String nameEn;
  final String courseClass;
  final String classType;
  final String requiredType;
  final String credits;
  final String timeRoomStr;
  final String teacher;
  final String remark;
  final String weekday;

  /// times 陣列以 JSON 字串儲存。
  final String timesJson;
  final String room;
  final String syllabusUrl;
  final String year;
  final String semester;
  final String courseNo;
  const ScheduleCourse({
    required this.id,
    required this.sortOrder,
    required this.semesterCourseNo,
    required this.deptCourseNo,
    required this.name,
    required this.nameEn,
    required this.courseClass,
    required this.classType,
    required this.requiredType,
    required this.credits,
    required this.timeRoomStr,
    required this.teacher,
    required this.remark,
    required this.weekday,
    required this.timesJson,
    required this.room,
    required this.syllabusUrl,
    required this.year,
    required this.semester,
    required this.courseNo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sort_order'] = Variable<int>(sortOrder);
    map['semester_course_no'] = Variable<String>(semesterCourseNo);
    map['dept_course_no'] = Variable<String>(deptCourseNo);
    map['name'] = Variable<String>(name);
    map['name_en'] = Variable<String>(nameEn);
    map['course_class'] = Variable<String>(courseClass);
    map['class_type'] = Variable<String>(classType);
    map['required_type'] = Variable<String>(requiredType);
    map['credits'] = Variable<String>(credits);
    map['time_room_str'] = Variable<String>(timeRoomStr);
    map['teacher'] = Variable<String>(teacher);
    map['remark'] = Variable<String>(remark);
    map['weekday'] = Variable<String>(weekday);
    map['times_json'] = Variable<String>(timesJson);
    map['room'] = Variable<String>(room);
    map['syllabus_url'] = Variable<String>(syllabusUrl);
    map['year'] = Variable<String>(year);
    map['semester'] = Variable<String>(semester);
    map['course_no'] = Variable<String>(courseNo);
    return map;
  }

  ScheduleCoursesCompanion toCompanion(bool nullToAbsent) {
    return ScheduleCoursesCompanion(
      id: Value(id),
      sortOrder: Value(sortOrder),
      semesterCourseNo: Value(semesterCourseNo),
      deptCourseNo: Value(deptCourseNo),
      name: Value(name),
      nameEn: Value(nameEn),
      courseClass: Value(courseClass),
      classType: Value(classType),
      requiredType: Value(requiredType),
      credits: Value(credits),
      timeRoomStr: Value(timeRoomStr),
      teacher: Value(teacher),
      remark: Value(remark),
      weekday: Value(weekday),
      timesJson: Value(timesJson),
      room: Value(room),
      syllabusUrl: Value(syllabusUrl),
      year: Value(year),
      semester: Value(semester),
      courseNo: Value(courseNo),
    );
  }

  factory ScheduleCourse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleCourse(
      id: serializer.fromJson<int>(json['id']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      semesterCourseNo: serializer.fromJson<String>(json['semesterCourseNo']),
      deptCourseNo: serializer.fromJson<String>(json['deptCourseNo']),
      name: serializer.fromJson<String>(json['name']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      courseClass: serializer.fromJson<String>(json['courseClass']),
      classType: serializer.fromJson<String>(json['classType']),
      requiredType: serializer.fromJson<String>(json['requiredType']),
      credits: serializer.fromJson<String>(json['credits']),
      timeRoomStr: serializer.fromJson<String>(json['timeRoomStr']),
      teacher: serializer.fromJson<String>(json['teacher']),
      remark: serializer.fromJson<String>(json['remark']),
      weekday: serializer.fromJson<String>(json['weekday']),
      timesJson: serializer.fromJson<String>(json['timesJson']),
      room: serializer.fromJson<String>(json['room']),
      syllabusUrl: serializer.fromJson<String>(json['syllabusUrl']),
      year: serializer.fromJson<String>(json['year']),
      semester: serializer.fromJson<String>(json['semester']),
      courseNo: serializer.fromJson<String>(json['courseNo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'semesterCourseNo': serializer.toJson<String>(semesterCourseNo),
      'deptCourseNo': serializer.toJson<String>(deptCourseNo),
      'name': serializer.toJson<String>(name),
      'nameEn': serializer.toJson<String>(nameEn),
      'courseClass': serializer.toJson<String>(courseClass),
      'classType': serializer.toJson<String>(classType),
      'requiredType': serializer.toJson<String>(requiredType),
      'credits': serializer.toJson<String>(credits),
      'timeRoomStr': serializer.toJson<String>(timeRoomStr),
      'teacher': serializer.toJson<String>(teacher),
      'remark': serializer.toJson<String>(remark),
      'weekday': serializer.toJson<String>(weekday),
      'timesJson': serializer.toJson<String>(timesJson),
      'room': serializer.toJson<String>(room),
      'syllabusUrl': serializer.toJson<String>(syllabusUrl),
      'year': serializer.toJson<String>(year),
      'semester': serializer.toJson<String>(semester),
      'courseNo': serializer.toJson<String>(courseNo),
    };
  }

  ScheduleCourse copyWith({
    int? id,
    int? sortOrder,
    String? semesterCourseNo,
    String? deptCourseNo,
    String? name,
    String? nameEn,
    String? courseClass,
    String? classType,
    String? requiredType,
    String? credits,
    String? timeRoomStr,
    String? teacher,
    String? remark,
    String? weekday,
    String? timesJson,
    String? room,
    String? syllabusUrl,
    String? year,
    String? semester,
    String? courseNo,
  }) => ScheduleCourse(
    id: id ?? this.id,
    sortOrder: sortOrder ?? this.sortOrder,
    semesterCourseNo: semesterCourseNo ?? this.semesterCourseNo,
    deptCourseNo: deptCourseNo ?? this.deptCourseNo,
    name: name ?? this.name,
    nameEn: nameEn ?? this.nameEn,
    courseClass: courseClass ?? this.courseClass,
    classType: classType ?? this.classType,
    requiredType: requiredType ?? this.requiredType,
    credits: credits ?? this.credits,
    timeRoomStr: timeRoomStr ?? this.timeRoomStr,
    teacher: teacher ?? this.teacher,
    remark: remark ?? this.remark,
    weekday: weekday ?? this.weekday,
    timesJson: timesJson ?? this.timesJson,
    room: room ?? this.room,
    syllabusUrl: syllabusUrl ?? this.syllabusUrl,
    year: year ?? this.year,
    semester: semester ?? this.semester,
    courseNo: courseNo ?? this.courseNo,
  );
  ScheduleCourse copyWithCompanion(ScheduleCoursesCompanion data) {
    return ScheduleCourse(
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      semesterCourseNo: data.semesterCourseNo.present
          ? data.semesterCourseNo.value
          : this.semesterCourseNo,
      deptCourseNo: data.deptCourseNo.present
          ? data.deptCourseNo.value
          : this.deptCourseNo,
      name: data.name.present ? data.name.value : this.name,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      courseClass: data.courseClass.present
          ? data.courseClass.value
          : this.courseClass,
      classType: data.classType.present ? data.classType.value : this.classType,
      requiredType: data.requiredType.present
          ? data.requiredType.value
          : this.requiredType,
      credits: data.credits.present ? data.credits.value : this.credits,
      timeRoomStr: data.timeRoomStr.present
          ? data.timeRoomStr.value
          : this.timeRoomStr,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      remark: data.remark.present ? data.remark.value : this.remark,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      timesJson: data.timesJson.present ? data.timesJson.value : this.timesJson,
      room: data.room.present ? data.room.value : this.room,
      syllabusUrl: data.syllabusUrl.present
          ? data.syllabusUrl.value
          : this.syllabusUrl,
      year: data.year.present ? data.year.value : this.year,
      semester: data.semester.present ? data.semester.value : this.semester,
      courseNo: data.courseNo.present ? data.courseNo.value : this.courseNo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleCourse(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('semesterCourseNo: $semesterCourseNo, ')
          ..write('deptCourseNo: $deptCourseNo, ')
          ..write('name: $name, ')
          ..write('nameEn: $nameEn, ')
          ..write('courseClass: $courseClass, ')
          ..write('classType: $classType, ')
          ..write('requiredType: $requiredType, ')
          ..write('credits: $credits, ')
          ..write('timeRoomStr: $timeRoomStr, ')
          ..write('teacher: $teacher, ')
          ..write('remark: $remark, ')
          ..write('weekday: $weekday, ')
          ..write('timesJson: $timesJson, ')
          ..write('room: $room, ')
          ..write('syllabusUrl: $syllabusUrl, ')
          ..write('year: $year, ')
          ..write('semester: $semester, ')
          ..write('courseNo: $courseNo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sortOrder,
    semesterCourseNo,
    deptCourseNo,
    name,
    nameEn,
    courseClass,
    classType,
    requiredType,
    credits,
    timeRoomStr,
    teacher,
    remark,
    weekday,
    timesJson,
    room,
    syllabusUrl,
    year,
    semester,
    courseNo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleCourse &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder &&
          other.semesterCourseNo == this.semesterCourseNo &&
          other.deptCourseNo == this.deptCourseNo &&
          other.name == this.name &&
          other.nameEn == this.nameEn &&
          other.courseClass == this.courseClass &&
          other.classType == this.classType &&
          other.requiredType == this.requiredType &&
          other.credits == this.credits &&
          other.timeRoomStr == this.timeRoomStr &&
          other.teacher == this.teacher &&
          other.remark == this.remark &&
          other.weekday == this.weekday &&
          other.timesJson == this.timesJson &&
          other.room == this.room &&
          other.syllabusUrl == this.syllabusUrl &&
          other.year == this.year &&
          other.semester == this.semester &&
          other.courseNo == this.courseNo);
}

class ScheduleCoursesCompanion extends UpdateCompanion<ScheduleCourse> {
  final Value<int> id;
  final Value<int> sortOrder;
  final Value<String> semesterCourseNo;
  final Value<String> deptCourseNo;
  final Value<String> name;
  final Value<String> nameEn;
  final Value<String> courseClass;
  final Value<String> classType;
  final Value<String> requiredType;
  final Value<String> credits;
  final Value<String> timeRoomStr;
  final Value<String> teacher;
  final Value<String> remark;
  final Value<String> weekday;
  final Value<String> timesJson;
  final Value<String> room;
  final Value<String> syllabusUrl;
  final Value<String> year;
  final Value<String> semester;
  final Value<String> courseNo;
  const ScheduleCoursesCompanion({
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.semesterCourseNo = const Value.absent(),
    this.deptCourseNo = const Value.absent(),
    this.name = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.courseClass = const Value.absent(),
    this.classType = const Value.absent(),
    this.requiredType = const Value.absent(),
    this.credits = const Value.absent(),
    this.timeRoomStr = const Value.absent(),
    this.teacher = const Value.absent(),
    this.remark = const Value.absent(),
    this.weekday = const Value.absent(),
    this.timesJson = const Value.absent(),
    this.room = const Value.absent(),
    this.syllabusUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.semester = const Value.absent(),
    this.courseNo = const Value.absent(),
  });
  ScheduleCoursesCompanion.insert({
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.semesterCourseNo = const Value.absent(),
    this.deptCourseNo = const Value.absent(),
    this.name = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.courseClass = const Value.absent(),
    this.classType = const Value.absent(),
    this.requiredType = const Value.absent(),
    this.credits = const Value.absent(),
    this.timeRoomStr = const Value.absent(),
    this.teacher = const Value.absent(),
    this.remark = const Value.absent(),
    this.weekday = const Value.absent(),
    this.timesJson = const Value.absent(),
    this.room = const Value.absent(),
    this.syllabusUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.semester = const Value.absent(),
    this.courseNo = const Value.absent(),
  });
  static Insertable<ScheduleCourse> custom({
    Expression<int>? id,
    Expression<int>? sortOrder,
    Expression<String>? semesterCourseNo,
    Expression<String>? deptCourseNo,
    Expression<String>? name,
    Expression<String>? nameEn,
    Expression<String>? courseClass,
    Expression<String>? classType,
    Expression<String>? requiredType,
    Expression<String>? credits,
    Expression<String>? timeRoomStr,
    Expression<String>? teacher,
    Expression<String>? remark,
    Expression<String>? weekday,
    Expression<String>? timesJson,
    Expression<String>? room,
    Expression<String>? syllabusUrl,
    Expression<String>? year,
    Expression<String>? semester,
    Expression<String>? courseNo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (semesterCourseNo != null) 'semester_course_no': semesterCourseNo,
      if (deptCourseNo != null) 'dept_course_no': deptCourseNo,
      if (name != null) 'name': name,
      if (nameEn != null) 'name_en': nameEn,
      if (courseClass != null) 'course_class': courseClass,
      if (classType != null) 'class_type': classType,
      if (requiredType != null) 'required_type': requiredType,
      if (credits != null) 'credits': credits,
      if (timeRoomStr != null) 'time_room_str': timeRoomStr,
      if (teacher != null) 'teacher': teacher,
      if (remark != null) 'remark': remark,
      if (weekday != null) 'weekday': weekday,
      if (timesJson != null) 'times_json': timesJson,
      if (room != null) 'room': room,
      if (syllabusUrl != null) 'syllabus_url': syllabusUrl,
      if (year != null) 'year': year,
      if (semester != null) 'semester': semester,
      if (courseNo != null) 'course_no': courseNo,
    });
  }

  ScheduleCoursesCompanion copyWith({
    Value<int>? id,
    Value<int>? sortOrder,
    Value<String>? semesterCourseNo,
    Value<String>? deptCourseNo,
    Value<String>? name,
    Value<String>? nameEn,
    Value<String>? courseClass,
    Value<String>? classType,
    Value<String>? requiredType,
    Value<String>? credits,
    Value<String>? timeRoomStr,
    Value<String>? teacher,
    Value<String>? remark,
    Value<String>? weekday,
    Value<String>? timesJson,
    Value<String>? room,
    Value<String>? syllabusUrl,
    Value<String>? year,
    Value<String>? semester,
    Value<String>? courseNo,
  }) {
    return ScheduleCoursesCompanion(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      semesterCourseNo: semesterCourseNo ?? this.semesterCourseNo,
      deptCourseNo: deptCourseNo ?? this.deptCourseNo,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      courseClass: courseClass ?? this.courseClass,
      classType: classType ?? this.classType,
      requiredType: requiredType ?? this.requiredType,
      credits: credits ?? this.credits,
      timeRoomStr: timeRoomStr ?? this.timeRoomStr,
      teacher: teacher ?? this.teacher,
      remark: remark ?? this.remark,
      weekday: weekday ?? this.weekday,
      timesJson: timesJson ?? this.timesJson,
      room: room ?? this.room,
      syllabusUrl: syllabusUrl ?? this.syllabusUrl,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      courseNo: courseNo ?? this.courseNo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (semesterCourseNo.present) {
      map['semester_course_no'] = Variable<String>(semesterCourseNo.value);
    }
    if (deptCourseNo.present) {
      map['dept_course_no'] = Variable<String>(deptCourseNo.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (courseClass.present) {
      map['course_class'] = Variable<String>(courseClass.value);
    }
    if (classType.present) {
      map['class_type'] = Variable<String>(classType.value);
    }
    if (requiredType.present) {
      map['required_type'] = Variable<String>(requiredType.value);
    }
    if (credits.present) {
      map['credits'] = Variable<String>(credits.value);
    }
    if (timeRoomStr.present) {
      map['time_room_str'] = Variable<String>(timeRoomStr.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<String>(weekday.value);
    }
    if (timesJson.present) {
      map['times_json'] = Variable<String>(timesJson.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (syllabusUrl.present) {
      map['syllabus_url'] = Variable<String>(syllabusUrl.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (courseNo.present) {
      map['course_no'] = Variable<String>(courseNo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleCoursesCompanion(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('semesterCourseNo: $semesterCourseNo, ')
          ..write('deptCourseNo: $deptCourseNo, ')
          ..write('name: $name, ')
          ..write('nameEn: $nameEn, ')
          ..write('courseClass: $courseClass, ')
          ..write('classType: $classType, ')
          ..write('requiredType: $requiredType, ')
          ..write('credits: $credits, ')
          ..write('timeRoomStr: $timeRoomStr, ')
          ..write('teacher: $teacher, ')
          ..write('remark: $remark, ')
          ..write('weekday: $weekday, ')
          ..write('timesJson: $timesJson, ')
          ..write('room: $room, ')
          ..write('syllabusUrl: $syllabusUrl, ')
          ..write('year: $year, ')
          ..write('semester: $semester, ')
          ..write('courseNo: $courseNo')
          ..write(')'))
        .toString();
  }
}

class $GraduationInfoTable extends GraduationInfo
    with TableInfo<$GraduationInfoTable, GraduationInfoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraduationInfoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCreditsMeta = const VerificationMeta(
    'totalCredits',
  );
  @override
  late final GeneratedColumn<String> totalCredits = GeneratedColumn<String>(
    'total_credits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _englishThresholdMeta = const VerificationMeta(
    'englishThreshold',
  );
  @override
  late final GeneratedColumn<String> englishThreshold = GeneratedColumn<String>(
    'english_threshold',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _internshipThresholdMeta =
      const VerificationMeta('internshipThreshold');
  @override
  late final GeneratedColumn<String> internshipThreshold =
      GeneratedColumn<String>(
        'internship_threshold',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _missingCoursesTextMeta =
      const VerificationMeta('missingCoursesText');
  @override
  late final GeneratedColumn<String> missingCoursesText =
      GeneratedColumn<String>(
        'missing_courses_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalCredits,
    englishThreshold,
    internshipThreshold,
    missingCoursesText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graduation_info';
  @override
  VerificationContext validateIntegrity(
    Insertable<GraduationInfoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('total_credits')) {
      context.handle(
        _totalCreditsMeta,
        totalCredits.isAcceptableOrUnknown(
          data['total_credits']!,
          _totalCreditsMeta,
        ),
      );
    }
    if (data.containsKey('english_threshold')) {
      context.handle(
        _englishThresholdMeta,
        englishThreshold.isAcceptableOrUnknown(
          data['english_threshold']!,
          _englishThresholdMeta,
        ),
      );
    }
    if (data.containsKey('internship_threshold')) {
      context.handle(
        _internshipThresholdMeta,
        internshipThreshold.isAcceptableOrUnknown(
          data['internship_threshold']!,
          _internshipThresholdMeta,
        ),
      );
    }
    if (data.containsKey('missing_courses_text')) {
      context.handle(
        _missingCoursesTextMeta,
        missingCoursesText.isAcceptableOrUnknown(
          data['missing_courses_text']!,
          _missingCoursesTextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GraduationInfoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraduationInfoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      totalCredits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}total_credits'],
      )!,
      englishThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_threshold'],
      )!,
      internshipThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internship_threshold'],
      )!,
      missingCoursesText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_courses_text'],
      )!,
    );
  }

  @override
  $GraduationInfoTable createAlias(String alias) {
    return $GraduationInfoTable(attachedDatabase, alias);
  }
}

class GraduationInfoData extends DataClass
    implements Insertable<GraduationInfoData> {
  final int id;
  final String totalCredits;
  final String englishThreshold;
  final String internshipThreshold;
  final String missingCoursesText;
  const GraduationInfoData({
    required this.id,
    required this.totalCredits,
    required this.englishThreshold,
    required this.internshipThreshold,
    required this.missingCoursesText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['total_credits'] = Variable<String>(totalCredits);
    map['english_threshold'] = Variable<String>(englishThreshold);
    map['internship_threshold'] = Variable<String>(internshipThreshold);
    map['missing_courses_text'] = Variable<String>(missingCoursesText);
    return map;
  }

  GraduationInfoCompanion toCompanion(bool nullToAbsent) {
    return GraduationInfoCompanion(
      id: Value(id),
      totalCredits: Value(totalCredits),
      englishThreshold: Value(englishThreshold),
      internshipThreshold: Value(internshipThreshold),
      missingCoursesText: Value(missingCoursesText),
    );
  }

  factory GraduationInfoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraduationInfoData(
      id: serializer.fromJson<int>(json['id']),
      totalCredits: serializer.fromJson<String>(json['totalCredits']),
      englishThreshold: serializer.fromJson<String>(json['englishThreshold']),
      internshipThreshold: serializer.fromJson<String>(
        json['internshipThreshold'],
      ),
      missingCoursesText: serializer.fromJson<String>(
        json['missingCoursesText'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'totalCredits': serializer.toJson<String>(totalCredits),
      'englishThreshold': serializer.toJson<String>(englishThreshold),
      'internshipThreshold': serializer.toJson<String>(internshipThreshold),
      'missingCoursesText': serializer.toJson<String>(missingCoursesText),
    };
  }

  GraduationInfoData copyWith({
    int? id,
    String? totalCredits,
    String? englishThreshold,
    String? internshipThreshold,
    String? missingCoursesText,
  }) => GraduationInfoData(
    id: id ?? this.id,
    totalCredits: totalCredits ?? this.totalCredits,
    englishThreshold: englishThreshold ?? this.englishThreshold,
    internshipThreshold: internshipThreshold ?? this.internshipThreshold,
    missingCoursesText: missingCoursesText ?? this.missingCoursesText,
  );
  GraduationInfoData copyWithCompanion(GraduationInfoCompanion data) {
    return GraduationInfoData(
      id: data.id.present ? data.id.value : this.id,
      totalCredits: data.totalCredits.present
          ? data.totalCredits.value
          : this.totalCredits,
      englishThreshold: data.englishThreshold.present
          ? data.englishThreshold.value
          : this.englishThreshold,
      internshipThreshold: data.internshipThreshold.present
          ? data.internshipThreshold.value
          : this.internshipThreshold,
      missingCoursesText: data.missingCoursesText.present
          ? data.missingCoursesText.value
          : this.missingCoursesText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraduationInfoData(')
          ..write('id: $id, ')
          ..write('totalCredits: $totalCredits, ')
          ..write('englishThreshold: $englishThreshold, ')
          ..write('internshipThreshold: $internshipThreshold, ')
          ..write('missingCoursesText: $missingCoursesText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    totalCredits,
    englishThreshold,
    internshipThreshold,
    missingCoursesText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraduationInfoData &&
          other.id == this.id &&
          other.totalCredits == this.totalCredits &&
          other.englishThreshold == this.englishThreshold &&
          other.internshipThreshold == this.internshipThreshold &&
          other.missingCoursesText == this.missingCoursesText);
}

class GraduationInfoCompanion extends UpdateCompanion<GraduationInfoData> {
  final Value<int> id;
  final Value<String> totalCredits;
  final Value<String> englishThreshold;
  final Value<String> internshipThreshold;
  final Value<String> missingCoursesText;
  const GraduationInfoCompanion({
    this.id = const Value.absent(),
    this.totalCredits = const Value.absent(),
    this.englishThreshold = const Value.absent(),
    this.internshipThreshold = const Value.absent(),
    this.missingCoursesText = const Value.absent(),
  });
  GraduationInfoCompanion.insert({
    this.id = const Value.absent(),
    this.totalCredits = const Value.absent(),
    this.englishThreshold = const Value.absent(),
    this.internshipThreshold = const Value.absent(),
    this.missingCoursesText = const Value.absent(),
  });
  static Insertable<GraduationInfoData> custom({
    Expression<int>? id,
    Expression<String>? totalCredits,
    Expression<String>? englishThreshold,
    Expression<String>? internshipThreshold,
    Expression<String>? missingCoursesText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalCredits != null) 'total_credits': totalCredits,
      if (englishThreshold != null) 'english_threshold': englishThreshold,
      if (internshipThreshold != null)
        'internship_threshold': internshipThreshold,
      if (missingCoursesText != null)
        'missing_courses_text': missingCoursesText,
    });
  }

  GraduationInfoCompanion copyWith({
    Value<int>? id,
    Value<String>? totalCredits,
    Value<String>? englishThreshold,
    Value<String>? internshipThreshold,
    Value<String>? missingCoursesText,
  }) {
    return GraduationInfoCompanion(
      id: id ?? this.id,
      totalCredits: totalCredits ?? this.totalCredits,
      englishThreshold: englishThreshold ?? this.englishThreshold,
      internshipThreshold: internshipThreshold ?? this.internshipThreshold,
      missingCoursesText: missingCoursesText ?? this.missingCoursesText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (totalCredits.present) {
      map['total_credits'] = Variable<String>(totalCredits.value);
    }
    if (englishThreshold.present) {
      map['english_threshold'] = Variable<String>(englishThreshold.value);
    }
    if (internshipThreshold.present) {
      map['internship_threshold'] = Variable<String>(internshipThreshold.value);
    }
    if (missingCoursesText.present) {
      map['missing_courses_text'] = Variable<String>(missingCoursesText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraduationInfoCompanion(')
          ..write('id: $id, ')
          ..write('totalCredits: $totalCredits, ')
          ..write('englishThreshold: $englishThreshold, ')
          ..write('internshipThreshold: $internshipThreshold, ')
          ..write('missingCoursesText: $missingCoursesText')
          ..write(')'))
        .toString();
  }
}

class $GraduationCreditsTable extends GraduationCredits
    with TableInfo<$GraduationCreditsTable, GraduationCredit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraduationCreditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [groupName, category, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graduation_credits';
  @override
  VerificationContext validateIntegrity(
    Insertable<GraduationCredit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_groupNameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupName, category};
  @override
  GraduationCredit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraduationCredit(
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $GraduationCreditsTable createAlias(String alias) {
    return $GraduationCreditsTable(attachedDatabase, alias);
  }
}

class GraduationCredit extends DataClass
    implements Insertable<GraduationCredit> {
  final String groupName;
  final String category;
  final String value;
  const GraduationCredit({
    required this.groupName,
    required this.category,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_name'] = Variable<String>(groupName);
    map['category'] = Variable<String>(category);
    map['value'] = Variable<String>(value);
    return map;
  }

  GraduationCreditsCompanion toCompanion(bool nullToAbsent) {
    return GraduationCreditsCompanion(
      groupName: Value(groupName),
      category: Value(category),
      value: Value(value),
    );
  }

  factory GraduationCredit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraduationCredit(
      groupName: serializer.fromJson<String>(json['groupName']),
      category: serializer.fromJson<String>(json['category']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupName': serializer.toJson<String>(groupName),
      'category': serializer.toJson<String>(category),
      'value': serializer.toJson<String>(value),
    };
  }

  GraduationCredit copyWith({
    String? groupName,
    String? category,
    String? value,
  }) => GraduationCredit(
    groupName: groupName ?? this.groupName,
    category: category ?? this.category,
    value: value ?? this.value,
  );
  GraduationCredit copyWithCompanion(GraduationCreditsCompanion data) {
    return GraduationCredit(
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      category: data.category.present ? data.category.value : this.category,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraduationCredit(')
          ..write('groupName: $groupName, ')
          ..write('category: $category, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupName, category, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraduationCredit &&
          other.groupName == this.groupName &&
          other.category == this.category &&
          other.value == this.value);
}

class GraduationCreditsCompanion extends UpdateCompanion<GraduationCredit> {
  final Value<String> groupName;
  final Value<String> category;
  final Value<String> value;
  final Value<int> rowid;
  const GraduationCreditsCompanion({
    this.groupName = const Value.absent(),
    this.category = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraduationCreditsCompanion.insert({
    required String groupName,
    required String category,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupName = Value(groupName),
       category = Value(category);
  static Insertable<GraduationCredit> custom({
    Expression<String>? groupName,
    Expression<String>? category,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupName != null) 'group_name': groupName,
      if (category != null) 'category': category,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraduationCreditsCompanion copyWith({
    Value<String>? groupName,
    Value<String>? category,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return GraduationCreditsCompanion(
      groupName: groupName ?? this.groupName,
      category: category ?? this.category,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
    return (StringBuffer('GraduationCreditsCompanion(')
          ..write('groupName: $groupName, ')
          ..write('category: $category, ')
          ..write('value: $value, ')
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
  late final $CacheMetaTable cacheMeta = $CacheMetaTable(this);
  late final $GradesSemestersTable gradesSemesters = $GradesSemestersTable(
    this,
  );
  late final $GradesCoursesTable gradesCourses = $GradesCoursesTable(this);
  late final $GradesCumulativeTable gradesCumulative = $GradesCumulativeTable(
    this,
  );
  late final $ScheduleCoursesTable scheduleCourses = $ScheduleCoursesTable(
    this,
  );
  late final $GraduationInfoTable graduationInfo = $GraduationInfoTable(this);
  late final $GraduationCreditsTable graduationCredits =
      $GraduationCreditsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    courseDetailCacheTable,
    calendarCacheTable,
    cacheMeta,
    gradesSemesters,
    gradesCourses,
    gradesCumulative,
    scheduleCourses,
    graduationInfo,
    graduationCredits,
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
typedef $$CacheMetaTableCreateCompanionBuilder =
    CacheMetaCompanion Function({
      required String datasetKey,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CacheMetaTableUpdateCompanionBuilder =
    CacheMetaCompanion Function({
      Value<String> datasetKey,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CacheMetaTableFilterComposer
    extends Composer<_$AppDatabase, $CacheMetaTable> {
  $$CacheMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get datasetKey => $composableBuilder(
    column: $table.datasetKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheMetaTable> {
  $$CacheMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get datasetKey => $composableBuilder(
    column: $table.datasetKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheMetaTable> {
  $$CacheMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get datasetKey => $composableBuilder(
    column: $table.datasetKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CacheMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheMetaTable,
          CacheMetaData,
          $$CacheMetaTableFilterComposer,
          $$CacheMetaTableOrderingComposer,
          $$CacheMetaTableAnnotationComposer,
          $$CacheMetaTableCreateCompanionBuilder,
          $$CacheMetaTableUpdateCompanionBuilder,
          (
            CacheMetaData,
            BaseReferences<_$AppDatabase, $CacheMetaTable, CacheMetaData>,
          ),
          CacheMetaData,
          PrefetchHooks Function()
        > {
  $$CacheMetaTableTableManager(_$AppDatabase db, $CacheMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> datasetKey = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheMetaCompanion(
                datasetKey: datasetKey,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String datasetKey,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CacheMetaCompanion.insert(
                datasetKey: datasetKey,
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

typedef $$CacheMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheMetaTable,
      CacheMetaData,
      $$CacheMetaTableFilterComposer,
      $$CacheMetaTableOrderingComposer,
      $$CacheMetaTableAnnotationComposer,
      $$CacheMetaTableCreateCompanionBuilder,
      $$CacheMetaTableUpdateCompanionBuilder,
      (
        CacheMetaData,
        BaseReferences<_$AppDatabase, $CacheMetaTable, CacheMetaData>,
      ),
      CacheMetaData,
      PrefetchHooks Function()
    >;
typedef $$GradesSemestersTableCreateCompanionBuilder =
    GradesSemestersCompanion Function({
      required int academicYear,
      required int semester,
      Value<int> sortOrder,
      Value<String> semesterTitle,
      Value<String> averageScore,
      Value<String> rank,
      Value<String> gpa,
      Value<String> conduct,
      Value<String> attemptedCredits,
      Value<String> earnedCredits,
      Value<int> rowid,
    });
typedef $$GradesSemestersTableUpdateCompanionBuilder =
    GradesSemestersCompanion Function({
      Value<int> academicYear,
      Value<int> semester,
      Value<int> sortOrder,
      Value<String> semesterTitle,
      Value<String> averageScore,
      Value<String> rank,
      Value<String> gpa,
      Value<String> conduct,
      Value<String> attemptedCredits,
      Value<String> earnedCredits,
      Value<int> rowid,
    });

class $$GradesSemestersTableFilterComposer
    extends Composer<_$AppDatabase, $GradesSemestersTable> {
  $$GradesSemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semesterTitle => $composableBuilder(
    column: $table.semesterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gpa => $composableBuilder(
    column: $table.gpa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conduct => $composableBuilder(
    column: $table.conduct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attemptedCredits => $composableBuilder(
    column: $table.attemptedCredits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnedCredits => $composableBuilder(
    column: $table.earnedCredits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GradesSemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $GradesSemestersTable> {
  $$GradesSemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semesterTitle => $composableBuilder(
    column: $table.semesterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gpa => $composableBuilder(
    column: $table.gpa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conduct => $composableBuilder(
    column: $table.conduct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attemptedCredits => $composableBuilder(
    column: $table.attemptedCredits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnedCredits => $composableBuilder(
    column: $table.earnedCredits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GradesSemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradesSemestersTable> {
  $$GradesSemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get semesterTitle => $composableBuilder(
    column: $table.semesterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get gpa =>
      $composableBuilder(column: $table.gpa, builder: (column) => column);

  GeneratedColumn<String> get conduct =>
      $composableBuilder(column: $table.conduct, builder: (column) => column);

  GeneratedColumn<String> get attemptedCredits => $composableBuilder(
    column: $table.attemptedCredits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earnedCredits => $composableBuilder(
    column: $table.earnedCredits,
    builder: (column) => column,
  );
}

class $$GradesSemestersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GradesSemestersTable,
          GradesSemester,
          $$GradesSemestersTableFilterComposer,
          $$GradesSemestersTableOrderingComposer,
          $$GradesSemestersTableAnnotationComposer,
          $$GradesSemestersTableCreateCompanionBuilder,
          $$GradesSemestersTableUpdateCompanionBuilder,
          (
            GradesSemester,
            BaseReferences<
              _$AppDatabase,
              $GradesSemestersTable,
              GradesSemester
            >,
          ),
          GradesSemester,
          PrefetchHooks Function()
        > {
  $$GradesSemestersTableTableManager(
    _$AppDatabase db,
    $GradesSemestersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradesSemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradesSemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradesSemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> academicYear = const Value.absent(),
                Value<int> semester = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> semesterTitle = const Value.absent(),
                Value<String> averageScore = const Value.absent(),
                Value<String> rank = const Value.absent(),
                Value<String> gpa = const Value.absent(),
                Value<String> conduct = const Value.absent(),
                Value<String> attemptedCredits = const Value.absent(),
                Value<String> earnedCredits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GradesSemestersCompanion(
                academicYear: academicYear,
                semester: semester,
                sortOrder: sortOrder,
                semesterTitle: semesterTitle,
                averageScore: averageScore,
                rank: rank,
                gpa: gpa,
                conduct: conduct,
                attemptedCredits: attemptedCredits,
                earnedCredits: earnedCredits,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int academicYear,
                required int semester,
                Value<int> sortOrder = const Value.absent(),
                Value<String> semesterTitle = const Value.absent(),
                Value<String> averageScore = const Value.absent(),
                Value<String> rank = const Value.absent(),
                Value<String> gpa = const Value.absent(),
                Value<String> conduct = const Value.absent(),
                Value<String> attemptedCredits = const Value.absent(),
                Value<String> earnedCredits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GradesSemestersCompanion.insert(
                academicYear: academicYear,
                semester: semester,
                sortOrder: sortOrder,
                semesterTitle: semesterTitle,
                averageScore: averageScore,
                rank: rank,
                gpa: gpa,
                conduct: conduct,
                attemptedCredits: attemptedCredits,
                earnedCredits: earnedCredits,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GradesSemestersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GradesSemestersTable,
      GradesSemester,
      $$GradesSemestersTableFilterComposer,
      $$GradesSemestersTableOrderingComposer,
      $$GradesSemestersTableAnnotationComposer,
      $$GradesSemestersTableCreateCompanionBuilder,
      $$GradesSemestersTableUpdateCompanionBuilder,
      (
        GradesSemester,
        BaseReferences<_$AppDatabase, $GradesSemestersTable, GradesSemester>,
      ),
      GradesSemester,
      PrefetchHooks Function()
    >;
typedef $$GradesCoursesTableCreateCompanionBuilder =
    GradesCoursesCompanion Function({
      Value<int> id,
      required int academicYear,
      required int semester,
      Value<int> sortOrder,
      Value<String> code,
      Value<String> courseNo,
      Value<String> name,
      Value<String> nameEn,
      Value<String> type,
      Value<String> credits,
      Value<String> score,
      Value<String> syllabusUrl,
    });
typedef $$GradesCoursesTableUpdateCompanionBuilder =
    GradesCoursesCompanion Function({
      Value<int> id,
      Value<int> academicYear,
      Value<int> semester,
      Value<int> sortOrder,
      Value<String> code,
      Value<String> courseNo,
      Value<String> name,
      Value<String> nameEn,
      Value<String> type,
      Value<String> credits,
      Value<String> score,
      Value<String> syllabusUrl,
    });

class $$GradesCoursesTableFilterComposer
    extends Composer<_$AppDatabase, $GradesCoursesTable> {
  $$GradesCoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseNo => $composableBuilder(
    column: $table.courseNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credits => $composableBuilder(
    column: $table.credits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syllabusUrl => $composableBuilder(
    column: $table.syllabusUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GradesCoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $GradesCoursesTable> {
  $$GradesCoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseNo => $composableBuilder(
    column: $table.courseNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credits => $composableBuilder(
    column: $table.credits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syllabusUrl => $composableBuilder(
    column: $table.syllabusUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GradesCoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradesCoursesTable> {
  $$GradesCoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get academicYear => $composableBuilder(
    column: $table.academicYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get courseNo =>
      $composableBuilder(column: $table.courseNo, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get credits =>
      $composableBuilder(column: $table.credits, builder: (column) => column);

  GeneratedColumn<String> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get syllabusUrl => $composableBuilder(
    column: $table.syllabusUrl,
    builder: (column) => column,
  );
}

class $$GradesCoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GradesCoursesTable,
          GradesCourse,
          $$GradesCoursesTableFilterComposer,
          $$GradesCoursesTableOrderingComposer,
          $$GradesCoursesTableAnnotationComposer,
          $$GradesCoursesTableCreateCompanionBuilder,
          $$GradesCoursesTableUpdateCompanionBuilder,
          (
            GradesCourse,
            BaseReferences<_$AppDatabase, $GradesCoursesTable, GradesCourse>,
          ),
          GradesCourse,
          PrefetchHooks Function()
        > {
  $$GradesCoursesTableTableManager(_$AppDatabase db, $GradesCoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradesCoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradesCoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradesCoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> academicYear = const Value.absent(),
                Value<int> semester = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> courseNo = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> credits = const Value.absent(),
                Value<String> score = const Value.absent(),
                Value<String> syllabusUrl = const Value.absent(),
              }) => GradesCoursesCompanion(
                id: id,
                academicYear: academicYear,
                semester: semester,
                sortOrder: sortOrder,
                code: code,
                courseNo: courseNo,
                name: name,
                nameEn: nameEn,
                type: type,
                credits: credits,
                score: score,
                syllabusUrl: syllabusUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int academicYear,
                required int semester,
                Value<int> sortOrder = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> courseNo = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> credits = const Value.absent(),
                Value<String> score = const Value.absent(),
                Value<String> syllabusUrl = const Value.absent(),
              }) => GradesCoursesCompanion.insert(
                id: id,
                academicYear: academicYear,
                semester: semester,
                sortOrder: sortOrder,
                code: code,
                courseNo: courseNo,
                name: name,
                nameEn: nameEn,
                type: type,
                credits: credits,
                score: score,
                syllabusUrl: syllabusUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GradesCoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GradesCoursesTable,
      GradesCourse,
      $$GradesCoursesTableFilterComposer,
      $$GradesCoursesTableOrderingComposer,
      $$GradesCoursesTableAnnotationComposer,
      $$GradesCoursesTableCreateCompanionBuilder,
      $$GradesCoursesTableUpdateCompanionBuilder,
      (
        GradesCourse,
        BaseReferences<_$AppDatabase, $GradesCoursesTable, GradesCourse>,
      ),
      GradesCourse,
      PrefetchHooks Function()
    >;
typedef $$GradesCumulativeTableCreateCompanionBuilder =
    GradesCumulativeCompanion Function({
      Value<int> id,
      Value<String> attemptedCredits,
      Value<String> earnedCredits,
      Value<String> average,
      Value<String> rank,
      Value<String> totalStudents,
      Value<String> gpa,
    });
typedef $$GradesCumulativeTableUpdateCompanionBuilder =
    GradesCumulativeCompanion Function({
      Value<int> id,
      Value<String> attemptedCredits,
      Value<String> earnedCredits,
      Value<String> average,
      Value<String> rank,
      Value<String> totalStudents,
      Value<String> gpa,
    });

class $$GradesCumulativeTableFilterComposer
    extends Composer<_$AppDatabase, $GradesCumulativeTable> {
  $$GradesCumulativeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attemptedCredits => $composableBuilder(
    column: $table.attemptedCredits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnedCredits => $composableBuilder(
    column: $table.earnedCredits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get average => $composableBuilder(
    column: $table.average,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get totalStudents => $composableBuilder(
    column: $table.totalStudents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gpa => $composableBuilder(
    column: $table.gpa,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GradesCumulativeTableOrderingComposer
    extends Composer<_$AppDatabase, $GradesCumulativeTable> {
  $$GradesCumulativeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attemptedCredits => $composableBuilder(
    column: $table.attemptedCredits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnedCredits => $composableBuilder(
    column: $table.earnedCredits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get average => $composableBuilder(
    column: $table.average,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalStudents => $composableBuilder(
    column: $table.totalStudents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gpa => $composableBuilder(
    column: $table.gpa,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GradesCumulativeTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradesCumulativeTable> {
  $$GradesCumulativeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get attemptedCredits => $composableBuilder(
    column: $table.attemptedCredits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earnedCredits => $composableBuilder(
    column: $table.earnedCredits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get average =>
      $composableBuilder(column: $table.average, builder: (column) => column);

  GeneratedColumn<String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get totalStudents => $composableBuilder(
    column: $table.totalStudents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gpa =>
      $composableBuilder(column: $table.gpa, builder: (column) => column);
}

class $$GradesCumulativeTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GradesCumulativeTable,
          GradesCumulativeData,
          $$GradesCumulativeTableFilterComposer,
          $$GradesCumulativeTableOrderingComposer,
          $$GradesCumulativeTableAnnotationComposer,
          $$GradesCumulativeTableCreateCompanionBuilder,
          $$GradesCumulativeTableUpdateCompanionBuilder,
          (
            GradesCumulativeData,
            BaseReferences<
              _$AppDatabase,
              $GradesCumulativeTable,
              GradesCumulativeData
            >,
          ),
          GradesCumulativeData,
          PrefetchHooks Function()
        > {
  $$GradesCumulativeTableTableManager(
    _$AppDatabase db,
    $GradesCumulativeTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradesCumulativeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradesCumulativeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradesCumulativeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> attemptedCredits = const Value.absent(),
                Value<String> earnedCredits = const Value.absent(),
                Value<String> average = const Value.absent(),
                Value<String> rank = const Value.absent(),
                Value<String> totalStudents = const Value.absent(),
                Value<String> gpa = const Value.absent(),
              }) => GradesCumulativeCompanion(
                id: id,
                attemptedCredits: attemptedCredits,
                earnedCredits: earnedCredits,
                average: average,
                rank: rank,
                totalStudents: totalStudents,
                gpa: gpa,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> attemptedCredits = const Value.absent(),
                Value<String> earnedCredits = const Value.absent(),
                Value<String> average = const Value.absent(),
                Value<String> rank = const Value.absent(),
                Value<String> totalStudents = const Value.absent(),
                Value<String> gpa = const Value.absent(),
              }) => GradesCumulativeCompanion.insert(
                id: id,
                attemptedCredits: attemptedCredits,
                earnedCredits: earnedCredits,
                average: average,
                rank: rank,
                totalStudents: totalStudents,
                gpa: gpa,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GradesCumulativeTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GradesCumulativeTable,
      GradesCumulativeData,
      $$GradesCumulativeTableFilterComposer,
      $$GradesCumulativeTableOrderingComposer,
      $$GradesCumulativeTableAnnotationComposer,
      $$GradesCumulativeTableCreateCompanionBuilder,
      $$GradesCumulativeTableUpdateCompanionBuilder,
      (
        GradesCumulativeData,
        BaseReferences<
          _$AppDatabase,
          $GradesCumulativeTable,
          GradesCumulativeData
        >,
      ),
      GradesCumulativeData,
      PrefetchHooks Function()
    >;
typedef $$ScheduleCoursesTableCreateCompanionBuilder =
    ScheduleCoursesCompanion Function({
      Value<int> id,
      Value<int> sortOrder,
      Value<String> semesterCourseNo,
      Value<String> deptCourseNo,
      Value<String> name,
      Value<String> nameEn,
      Value<String> courseClass,
      Value<String> classType,
      Value<String> requiredType,
      Value<String> credits,
      Value<String> timeRoomStr,
      Value<String> teacher,
      Value<String> remark,
      Value<String> weekday,
      Value<String> timesJson,
      Value<String> room,
      Value<String> syllabusUrl,
      Value<String> year,
      Value<String> semester,
      Value<String> courseNo,
    });
typedef $$ScheduleCoursesTableUpdateCompanionBuilder =
    ScheduleCoursesCompanion Function({
      Value<int> id,
      Value<int> sortOrder,
      Value<String> semesterCourseNo,
      Value<String> deptCourseNo,
      Value<String> name,
      Value<String> nameEn,
      Value<String> courseClass,
      Value<String> classType,
      Value<String> requiredType,
      Value<String> credits,
      Value<String> timeRoomStr,
      Value<String> teacher,
      Value<String> remark,
      Value<String> weekday,
      Value<String> timesJson,
      Value<String> room,
      Value<String> syllabusUrl,
      Value<String> year,
      Value<String> semester,
      Value<String> courseNo,
    });

class $$ScheduleCoursesTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleCoursesTable> {
  $$ScheduleCoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semesterCourseNo => $composableBuilder(
    column: $table.semesterCourseNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deptCourseNo => $composableBuilder(
    column: $table.deptCourseNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseClass => $composableBuilder(
    column: $table.courseClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classType => $composableBuilder(
    column: $table.classType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredType => $composableBuilder(
    column: $table.requiredType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credits => $composableBuilder(
    column: $table.credits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeRoomStr => $composableBuilder(
    column: $table.timeRoomStr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timesJson => $composableBuilder(
    column: $table.timesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syllabusUrl => $composableBuilder(
    column: $table.syllabusUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseNo => $composableBuilder(
    column: $table.courseNo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduleCoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleCoursesTable> {
  $$ScheduleCoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semesterCourseNo => $composableBuilder(
    column: $table.semesterCourseNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deptCourseNo => $composableBuilder(
    column: $table.deptCourseNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseClass => $composableBuilder(
    column: $table.courseClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classType => $composableBuilder(
    column: $table.classType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredType => $composableBuilder(
    column: $table.requiredType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credits => $composableBuilder(
    column: $table.credits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeRoomStr => $composableBuilder(
    column: $table.timeRoomStr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timesJson => $composableBuilder(
    column: $table.timesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syllabusUrl => $composableBuilder(
    column: $table.syllabusUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseNo => $composableBuilder(
    column: $table.courseNo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduleCoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleCoursesTable> {
  $$ScheduleCoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get semesterCourseNo => $composableBuilder(
    column: $table.semesterCourseNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deptCourseNo => $composableBuilder(
    column: $table.deptCourseNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get courseClass => $composableBuilder(
    column: $table.courseClass,
    builder: (column) => column,
  );

  GeneratedColumn<String> get classType =>
      $composableBuilder(column: $table.classType, builder: (column) => column);

  GeneratedColumn<String> get requiredType => $composableBuilder(
    column: $table.requiredType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get credits =>
      $composableBuilder(column: $table.credits, builder: (column) => column);

  GeneratedColumn<String> get timeRoomStr => $composableBuilder(
    column: $table.timeRoomStr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<String> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get timesJson =>
      $composableBuilder(column: $table.timesJson, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get syllabusUrl => $composableBuilder(
    column: $table.syllabusUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<String> get courseNo =>
      $composableBuilder(column: $table.courseNo, builder: (column) => column);
}

class $$ScheduleCoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleCoursesTable,
          ScheduleCourse,
          $$ScheduleCoursesTableFilterComposer,
          $$ScheduleCoursesTableOrderingComposer,
          $$ScheduleCoursesTableAnnotationComposer,
          $$ScheduleCoursesTableCreateCompanionBuilder,
          $$ScheduleCoursesTableUpdateCompanionBuilder,
          (
            ScheduleCourse,
            BaseReferences<
              _$AppDatabase,
              $ScheduleCoursesTable,
              ScheduleCourse
            >,
          ),
          ScheduleCourse,
          PrefetchHooks Function()
        > {
  $$ScheduleCoursesTableTableManager(
    _$AppDatabase db,
    $ScheduleCoursesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleCoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleCoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleCoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> semesterCourseNo = const Value.absent(),
                Value<String> deptCourseNo = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> courseClass = const Value.absent(),
                Value<String> classType = const Value.absent(),
                Value<String> requiredType = const Value.absent(),
                Value<String> credits = const Value.absent(),
                Value<String> timeRoomStr = const Value.absent(),
                Value<String> teacher = const Value.absent(),
                Value<String> remark = const Value.absent(),
                Value<String> weekday = const Value.absent(),
                Value<String> timesJson = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<String> syllabusUrl = const Value.absent(),
                Value<String> year = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<String> courseNo = const Value.absent(),
              }) => ScheduleCoursesCompanion(
                id: id,
                sortOrder: sortOrder,
                semesterCourseNo: semesterCourseNo,
                deptCourseNo: deptCourseNo,
                name: name,
                nameEn: nameEn,
                courseClass: courseClass,
                classType: classType,
                requiredType: requiredType,
                credits: credits,
                timeRoomStr: timeRoomStr,
                teacher: teacher,
                remark: remark,
                weekday: weekday,
                timesJson: timesJson,
                room: room,
                syllabusUrl: syllabusUrl,
                year: year,
                semester: semester,
                courseNo: courseNo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> semesterCourseNo = const Value.absent(),
                Value<String> deptCourseNo = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> courseClass = const Value.absent(),
                Value<String> classType = const Value.absent(),
                Value<String> requiredType = const Value.absent(),
                Value<String> credits = const Value.absent(),
                Value<String> timeRoomStr = const Value.absent(),
                Value<String> teacher = const Value.absent(),
                Value<String> remark = const Value.absent(),
                Value<String> weekday = const Value.absent(),
                Value<String> timesJson = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<String> syllabusUrl = const Value.absent(),
                Value<String> year = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<String> courseNo = const Value.absent(),
              }) => ScheduleCoursesCompanion.insert(
                id: id,
                sortOrder: sortOrder,
                semesterCourseNo: semesterCourseNo,
                deptCourseNo: deptCourseNo,
                name: name,
                nameEn: nameEn,
                courseClass: courseClass,
                classType: classType,
                requiredType: requiredType,
                credits: credits,
                timeRoomStr: timeRoomStr,
                teacher: teacher,
                remark: remark,
                weekday: weekday,
                timesJson: timesJson,
                room: room,
                syllabusUrl: syllabusUrl,
                year: year,
                semester: semester,
                courseNo: courseNo,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduleCoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleCoursesTable,
      ScheduleCourse,
      $$ScheduleCoursesTableFilterComposer,
      $$ScheduleCoursesTableOrderingComposer,
      $$ScheduleCoursesTableAnnotationComposer,
      $$ScheduleCoursesTableCreateCompanionBuilder,
      $$ScheduleCoursesTableUpdateCompanionBuilder,
      (
        ScheduleCourse,
        BaseReferences<_$AppDatabase, $ScheduleCoursesTable, ScheduleCourse>,
      ),
      ScheduleCourse,
      PrefetchHooks Function()
    >;
typedef $$GraduationInfoTableCreateCompanionBuilder =
    GraduationInfoCompanion Function({
      Value<int> id,
      Value<String> totalCredits,
      Value<String> englishThreshold,
      Value<String> internshipThreshold,
      Value<String> missingCoursesText,
    });
typedef $$GraduationInfoTableUpdateCompanionBuilder =
    GraduationInfoCompanion Function({
      Value<int> id,
      Value<String> totalCredits,
      Value<String> englishThreshold,
      Value<String> internshipThreshold,
      Value<String> missingCoursesText,
    });

class $$GraduationInfoTableFilterComposer
    extends Composer<_$AppDatabase, $GraduationInfoTable> {
  $$GraduationInfoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get totalCredits => $composableBuilder(
    column: $table.totalCredits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishThreshold => $composableBuilder(
    column: $table.englishThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internshipThreshold => $composableBuilder(
    column: $table.internshipThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingCoursesText => $composableBuilder(
    column: $table.missingCoursesText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GraduationInfoTableOrderingComposer
    extends Composer<_$AppDatabase, $GraduationInfoTable> {
  $$GraduationInfoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalCredits => $composableBuilder(
    column: $table.totalCredits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishThreshold => $composableBuilder(
    column: $table.englishThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internshipThreshold => $composableBuilder(
    column: $table.internshipThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingCoursesText => $composableBuilder(
    column: $table.missingCoursesText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GraduationInfoTableAnnotationComposer
    extends Composer<_$AppDatabase, $GraduationInfoTable> {
  $$GraduationInfoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get totalCredits => $composableBuilder(
    column: $table.totalCredits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishThreshold => $composableBuilder(
    column: $table.englishThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<String> get internshipThreshold => $composableBuilder(
    column: $table.internshipThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingCoursesText => $composableBuilder(
    column: $table.missingCoursesText,
    builder: (column) => column,
  );
}

class $$GraduationInfoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GraduationInfoTable,
          GraduationInfoData,
          $$GraduationInfoTableFilterComposer,
          $$GraduationInfoTableOrderingComposer,
          $$GraduationInfoTableAnnotationComposer,
          $$GraduationInfoTableCreateCompanionBuilder,
          $$GraduationInfoTableUpdateCompanionBuilder,
          (
            GraduationInfoData,
            BaseReferences<
              _$AppDatabase,
              $GraduationInfoTable,
              GraduationInfoData
            >,
          ),
          GraduationInfoData,
          PrefetchHooks Function()
        > {
  $$GraduationInfoTableTableManager(
    _$AppDatabase db,
    $GraduationInfoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraduationInfoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraduationInfoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraduationInfoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> totalCredits = const Value.absent(),
                Value<String> englishThreshold = const Value.absent(),
                Value<String> internshipThreshold = const Value.absent(),
                Value<String> missingCoursesText = const Value.absent(),
              }) => GraduationInfoCompanion(
                id: id,
                totalCredits: totalCredits,
                englishThreshold: englishThreshold,
                internshipThreshold: internshipThreshold,
                missingCoursesText: missingCoursesText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> totalCredits = const Value.absent(),
                Value<String> englishThreshold = const Value.absent(),
                Value<String> internshipThreshold = const Value.absent(),
                Value<String> missingCoursesText = const Value.absent(),
              }) => GraduationInfoCompanion.insert(
                id: id,
                totalCredits: totalCredits,
                englishThreshold: englishThreshold,
                internshipThreshold: internshipThreshold,
                missingCoursesText: missingCoursesText,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GraduationInfoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GraduationInfoTable,
      GraduationInfoData,
      $$GraduationInfoTableFilterComposer,
      $$GraduationInfoTableOrderingComposer,
      $$GraduationInfoTableAnnotationComposer,
      $$GraduationInfoTableCreateCompanionBuilder,
      $$GraduationInfoTableUpdateCompanionBuilder,
      (
        GraduationInfoData,
        BaseReferences<_$AppDatabase, $GraduationInfoTable, GraduationInfoData>,
      ),
      GraduationInfoData,
      PrefetchHooks Function()
    >;
typedef $$GraduationCreditsTableCreateCompanionBuilder =
    GraduationCreditsCompanion Function({
      required String groupName,
      required String category,
      Value<String> value,
      Value<int> rowid,
    });
typedef $$GraduationCreditsTableUpdateCompanionBuilder =
    GraduationCreditsCompanion Function({
      Value<String> groupName,
      Value<String> category,
      Value<String> value,
      Value<int> rowid,
    });

class $$GraduationCreditsTableFilterComposer
    extends Composer<_$AppDatabase, $GraduationCreditsTable> {
  $$GraduationCreditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GraduationCreditsTableOrderingComposer
    extends Composer<_$AppDatabase, $GraduationCreditsTable> {
  $$GraduationCreditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GraduationCreditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GraduationCreditsTable> {
  $$GraduationCreditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$GraduationCreditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GraduationCreditsTable,
          GraduationCredit,
          $$GraduationCreditsTableFilterComposer,
          $$GraduationCreditsTableOrderingComposer,
          $$GraduationCreditsTableAnnotationComposer,
          $$GraduationCreditsTableCreateCompanionBuilder,
          $$GraduationCreditsTableUpdateCompanionBuilder,
          (
            GraduationCredit,
            BaseReferences<
              _$AppDatabase,
              $GraduationCreditsTable,
              GraduationCredit
            >,
          ),
          GraduationCredit,
          PrefetchHooks Function()
        > {
  $$GraduationCreditsTableTableManager(
    _$AppDatabase db,
    $GraduationCreditsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraduationCreditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraduationCreditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraduationCreditsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> groupName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GraduationCreditsCompanion(
                groupName: groupName,
                category: category,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupName,
                required String category,
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GraduationCreditsCompanion.insert(
                groupName: groupName,
                category: category,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GraduationCreditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GraduationCreditsTable,
      GraduationCredit,
      $$GraduationCreditsTableFilterComposer,
      $$GraduationCreditsTableOrderingComposer,
      $$GraduationCreditsTableAnnotationComposer,
      $$GraduationCreditsTableCreateCompanionBuilder,
      $$GraduationCreditsTableUpdateCompanionBuilder,
      (
        GraduationCredit,
        BaseReferences<
          _$AppDatabase,
          $GraduationCreditsTable,
          GraduationCredit
        >,
      ),
      GraduationCredit,
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
  $$CacheMetaTableTableManager get cacheMeta =>
      $$CacheMetaTableTableManager(_db, _db.cacheMeta);
  $$GradesSemestersTableTableManager get gradesSemesters =>
      $$GradesSemestersTableTableManager(_db, _db.gradesSemesters);
  $$GradesCoursesTableTableManager get gradesCourses =>
      $$GradesCoursesTableTableManager(_db, _db.gradesCourses);
  $$GradesCumulativeTableTableManager get gradesCumulative =>
      $$GradesCumulativeTableTableManager(_db, _db.gradesCumulative);
  $$ScheduleCoursesTableTableManager get scheduleCourses =>
      $$ScheduleCoursesTableTableManager(_db, _db.scheduleCourses);
  $$GraduationInfoTableTableManager get graduationInfo =>
      $$GraduationInfoTableTableManager(_db, _db.graduationInfo);
  $$GraduationCreditsTableTableManager get graduationCredits =>
      $$GraduationCreditsTableTableManager(_db, _db.graduationCredits);
}
