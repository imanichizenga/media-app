// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CacheEntriesTable extends CacheEntries with TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
    'used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, etag, body, size, fetchedAt, usedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(_etagMeta, etag.isAcceptableOrUnknown(data['etag']!, _etagMeta));
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('size')) {
      context.handle(_sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(_usedAtMeta, usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta));
    } else if (isInserting) {
      context.missing(_usedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      etag: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}etag'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      size: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}used_at'],
      )!,
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }
}

class CacheEntry extends DataClass implements Insertable<CacheEntry> {
  final String key;
  final String etag;
  final String body;
  final int size;
  final DateTime fetchedAt;
  final DateTime usedAt;
  const CacheEntry({
    required this.key,
    required this.etag,
    required this.body,
    required this.size,
    required this.fetchedAt,
    required this.usedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['etag'] = Variable<String>(etag);
    map['body'] = Variable<String>(body);
    map['size'] = Variable<int>(size);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['used_at'] = Variable<DateTime>(usedAt);
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      key: Value(key),
      etag: Value(etag),
      body: Value(body),
      size: Value(size),
      fetchedAt: Value(fetchedAt),
      usedAt: Value(usedAt),
    );
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      key: serializer.fromJson<String>(json['key']),
      etag: serializer.fromJson<String>(json['etag']),
      body: serializer.fromJson<String>(json['body']),
      size: serializer.fromJson<int>(json['size']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      usedAt: serializer.fromJson<DateTime>(json['usedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'etag': serializer.toJson<String>(etag),
      'body': serializer.toJson<String>(body),
      'size': serializer.toJson<int>(size),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'usedAt': serializer.toJson<DateTime>(usedAt),
    };
  }

  CacheEntry copyWith({
    String? key,
    String? etag,
    String? body,
    int? size,
    DateTime? fetchedAt,
    DateTime? usedAt,
  }) => CacheEntry(
    key: key ?? this.key,
    etag: etag ?? this.etag,
    body: body ?? this.body,
    size: size ?? this.size,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    usedAt: usedAt ?? this.usedAt,
  );
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      key: data.key.present ? data.key.value : this.key,
      etag: data.etag.present ? data.etag.value : this.etag,
      body: data.body.present ? data.body.value : this.body,
      size: data.size.present ? data.size.value : this.size,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('key: $key, ')
          ..write('etag: $etag, ')
          ..write('body: $body, ')
          ..write('size: $size, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('usedAt: $usedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, etag, body, size, fetchedAt, usedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.key == this.key &&
          other.etag == this.etag &&
          other.body == this.body &&
          other.size == this.size &&
          other.fetchedAt == this.fetchedAt &&
          other.usedAt == this.usedAt);
}

class CacheEntriesCompanion extends UpdateCompanion<CacheEntry> {
  final Value<String> key;
  final Value<String> etag;
  final Value<String> body;
  final Value<int> size;
  final Value<DateTime> fetchedAt;
  final Value<DateTime> usedAt;
  final Value<int> rowid;
  const CacheEntriesCompanion({
    this.key = const Value.absent(),
    this.etag = const Value.absent(),
    this.body = const Value.absent(),
    this.size = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String key,
    this.etag = const Value.absent(),
    required String body,
    required int size,
    required DateTime fetchedAt,
    required DateTime usedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       body = Value(body),
       size = Value(size),
       fetchedAt = Value(fetchedAt),
       usedAt = Value(usedAt);
  static Insertable<CacheEntry> custom({
    Expression<String>? key,
    Expression<String>? etag,
    Expression<String>? body,
    Expression<int>? size,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? usedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (etag != null) 'etag': etag,
      if (body != null) 'body': body,
      if (size != null) 'size': size,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (usedAt != null) 'used_at': usedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? etag,
    Value<String>? body,
    Value<int>? size,
    Value<DateTime>? fetchedAt,
    Value<DateTime>? usedAt,
    Value<int>? rowid,
  }) {
    return CacheEntriesCompanion(
      key: key ?? this.key,
      etag: etag ?? this.etag,
      body: body ?? this.body,
      size: size ?? this.size,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      usedAt: usedAt ?? this.usedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('key: $key, ')
          ..write('etag: $etag, ')
          ..write('body: $body, ')
          ..write('size: $size, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, Pref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(Insertable<Pref> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Pref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pref(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class Pref extends DataClass implements Insertable<Pref> {
  final String key;
  final String value;
  const Pref({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(key: Value(key), value: Value(value));
  }

  factory Pref.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pref(
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

  Pref copyWith({String? key, String? value}) =>
      Pref(key: key ?? this.key, value: value ?? this.value);
  Pref copyWithCompanion(PrefsCompanion data) {
    return Pref(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pref(')
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
      (other is Pref && other.key == this.key && other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<Pref> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Pref> custom({
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

  PrefsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return PrefsCompanion(
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
    return (StringBuffer('PrefsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedArticlesTable extends SavedArticles with TableInfo<$SavedArticlesTable, SavedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardMeta = const VerificationMeta('card');
  @override
  late final GeneratedColumn<String> card = GeneratedColumn<String>(
    'card',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleMeta = const VerificationMeta('article');
  @override
  late final GeneratedColumn<String> article = GeneratedColumn<String>(
    'article',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagesReadyMeta = const VerificationMeta('imagesReady');
  @override
  late final GeneratedColumn<bool> imagesReady = GeneratedColumn<bool>(
    'images_ready',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("images_ready" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [path, card, article, imagesReady, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_articles';
  @override
  VerificationContext validateIntegrity(Insertable<SavedRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('card')) {
      context.handle(_cardMeta, card.isAcceptableOrUnknown(data['card']!, _cardMeta));
    } else if (isInserting) {
      context.missing(_cardMeta);
    }
    if (data.containsKey('article')) {
      context.handle(_articleMeta, article.isAcceptableOrUnknown(data['article']!, _articleMeta));
    }
    if (data.containsKey('images_ready')) {
      context.handle(
        _imagesReadyMeta,
        imagesReady.isAcceptableOrUnknown(data['images_ready']!, _imagesReadyMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta, savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  SavedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedRow(
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      card: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}card'])!,
      article: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article'],
      ),
      imagesReady: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}images_ready'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedArticlesTable createAlias(String alias) {
    return $SavedArticlesTable(attachedDatabase, alias);
  }
}

class SavedRow extends DataClass implements Insertable<SavedRow> {
  final String path;
  final String card;
  final String? article;
  final bool imagesReady;
  final DateTime savedAt;
  const SavedRow({
    required this.path,
    required this.card,
    this.article,
    required this.imagesReady,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['card'] = Variable<String>(card);
    if (!nullToAbsent || article != null) {
      map['article'] = Variable<String>(article);
    }
    map['images_ready'] = Variable<bool>(imagesReady);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedArticlesCompanion toCompanion(bool nullToAbsent) {
    return SavedArticlesCompanion(
      path: Value(path),
      card: Value(card),
      article: article == null && nullToAbsent ? const Value.absent() : Value(article),
      imagesReady: Value(imagesReady),
      savedAt: Value(savedAt),
    );
  }

  factory SavedRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedRow(
      path: serializer.fromJson<String>(json['path']),
      card: serializer.fromJson<String>(json['card']),
      article: serializer.fromJson<String?>(json['article']),
      imagesReady: serializer.fromJson<bool>(json['imagesReady']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'card': serializer.toJson<String>(card),
      'article': serializer.toJson<String?>(article),
      'imagesReady': serializer.toJson<bool>(imagesReady),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedRow copyWith({
    String? path,
    String? card,
    Value<String?> article = const Value.absent(),
    bool? imagesReady,
    DateTime? savedAt,
  }) => SavedRow(
    path: path ?? this.path,
    card: card ?? this.card,
    article: article.present ? article.value : this.article,
    imagesReady: imagesReady ?? this.imagesReady,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedRow copyWithCompanion(SavedArticlesCompanion data) {
    return SavedRow(
      path: data.path.present ? data.path.value : this.path,
      card: data.card.present ? data.card.value : this.card,
      article: data.article.present ? data.article.value : this.article,
      imagesReady: data.imagesReady.present ? data.imagesReady.value : this.imagesReady,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedRow(')
          ..write('path: $path, ')
          ..write('card: $card, ')
          ..write('article: $article, ')
          ..write('imagesReady: $imagesReady, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, card, article, imagesReady, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedRow &&
          other.path == this.path &&
          other.card == this.card &&
          other.article == this.article &&
          other.imagesReady == this.imagesReady &&
          other.savedAt == this.savedAt);
}

class SavedArticlesCompanion extends UpdateCompanion<SavedRow> {
  final Value<String> path;
  final Value<String> card;
  final Value<String?> article;
  final Value<bool> imagesReady;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedArticlesCompanion({
    this.path = const Value.absent(),
    this.card = const Value.absent(),
    this.article = const Value.absent(),
    this.imagesReady = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedArticlesCompanion.insert({
    required String path,
    required String card,
    this.article = const Value.absent(),
    this.imagesReady = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       card = Value(card),
       savedAt = Value(savedAt);
  static Insertable<SavedRow> custom({
    Expression<String>? path,
    Expression<String>? card,
    Expression<String>? article,
    Expression<bool>? imagesReady,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (card != null) 'card': card,
      if (article != null) 'article': article,
      if (imagesReady != null) 'images_ready': imagesReady,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedArticlesCompanion copyWith({
    Value<String>? path,
    Value<String>? card,
    Value<String?>? article,
    Value<bool>? imagesReady,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedArticlesCompanion(
      path: path ?? this.path,
      card: card ?? this.card,
      article: article ?? this.article,
      imagesReady: imagesReady ?? this.imagesReady,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (card.present) {
      map['card'] = Variable<String>(card.value);
    }
    if (article.present) {
      map['article'] = Variable<String>(article.value);
    }
    if (imagesReady.present) {
      map['images_ready'] = Variable<bool>(imagesReady.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedArticlesCompanion(')
          ..write('path: $path, ')
          ..write('card: $card, ')
          ..write('article: $article, ')
          ..write('imagesReady: $imagesReady, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingHistoryTable extends ReadingHistory with TableInfo<$ReadingHistoryTable, HistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardMeta = const VerificationMeta('card');
  @override
  late final GeneratedColumn<String> card = GeneratedColumn<String>(
    'card',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentMeta = const VerificationMeta('percent');
  @override
  late final GeneratedColumn<int> percent = GeneratedColumn<int>(
    'percent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [path, card, percent, openedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('card')) {
      context.handle(_cardMeta, card.isAcceptableOrUnknown(data['card']!, _cardMeta));
    } else if (isInserting) {
      context.missing(_cardMeta);
    }
    if (data.containsKey('percent')) {
      context.handle(_percentMeta, percent.isAcceptableOrUnknown(data['percent']!, _percentMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  HistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryRow(
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      card: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}card'])!,
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percent'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
    );
  }

  @override
  $ReadingHistoryTable createAlias(String alias) {
    return $ReadingHistoryTable(attachedDatabase, alias);
  }
}

class HistoryRow extends DataClass implements Insertable<HistoryRow> {
  final String path;
  final String card;
  final int percent;
  final DateTime openedAt;
  const HistoryRow({
    required this.path,
    required this.card,
    required this.percent,
    required this.openedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['card'] = Variable<String>(card);
    map['percent'] = Variable<int>(percent);
    map['opened_at'] = Variable<DateTime>(openedAt);
    return map;
  }

  ReadingHistoryCompanion toCompanion(bool nullToAbsent) {
    return ReadingHistoryCompanion(
      path: Value(path),
      card: Value(card),
      percent: Value(percent),
      openedAt: Value(openedAt),
    );
  }

  factory HistoryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryRow(
      path: serializer.fromJson<String>(json['path']),
      card: serializer.fromJson<String>(json['card']),
      percent: serializer.fromJson<int>(json['percent']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'card': serializer.toJson<String>(card),
      'percent': serializer.toJson<int>(percent),
      'openedAt': serializer.toJson<DateTime>(openedAt),
    };
  }

  HistoryRow copyWith({String? path, String? card, int? percent, DateTime? openedAt}) => HistoryRow(
    path: path ?? this.path,
    card: card ?? this.card,
    percent: percent ?? this.percent,
    openedAt: openedAt ?? this.openedAt,
  );
  HistoryRow copyWithCompanion(ReadingHistoryCompanion data) {
    return HistoryRow(
      path: data.path.present ? data.path.value : this.path,
      card: data.card.present ? data.card.value : this.card,
      percent: data.percent.present ? data.percent.value : this.percent,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRow(')
          ..write('path: $path, ')
          ..write('card: $card, ')
          ..write('percent: $percent, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, card, percent, openedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryRow &&
          other.path == this.path &&
          other.card == this.card &&
          other.percent == this.percent &&
          other.openedAt == this.openedAt);
}

class ReadingHistoryCompanion extends UpdateCompanion<HistoryRow> {
  final Value<String> path;
  final Value<String> card;
  final Value<int> percent;
  final Value<DateTime> openedAt;
  final Value<int> rowid;
  const ReadingHistoryCompanion({
    this.path = const Value.absent(),
    this.card = const Value.absent(),
    this.percent = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingHistoryCompanion.insert({
    required String path,
    required String card,
    this.percent = const Value.absent(),
    required DateTime openedAt,
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       card = Value(card),
       openedAt = Value(openedAt);
  static Insertable<HistoryRow> custom({
    Expression<String>? path,
    Expression<String>? card,
    Expression<int>? percent,
    Expression<DateTime>? openedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (card != null) 'card': card,
      if (percent != null) 'percent': percent,
      if (openedAt != null) 'opened_at': openedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingHistoryCompanion copyWith({
    Value<String>? path,
    Value<String>? card,
    Value<int>? percent,
    Value<DateTime>? openedAt,
    Value<int>? rowid,
  }) {
    return ReadingHistoryCompanion(
      path: path ?? this.path,
      card: card ?? this.card,
      percent: percent ?? this.percent,
      openedAt: openedAt ?? this.openedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (card.present) {
      map['card'] = Variable<String>(card.value);
    }
    if (percent.present) {
      map['percent'] = Variable<int>(percent.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryCompanion(')
          ..write('path: $path, ')
          ..write('card: $card, ')
          ..write('percent: $percent, ')
          ..write('openedAt: $openedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  late final $SavedArticlesTable savedArticles = $SavedArticlesTable(this);
  late final $ReadingHistoryTable readingHistory = $ReadingHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cacheEntries,
    prefs,
    savedArticles,
    readingHistory,
  ];
}

typedef $$CacheEntriesTableCreateCompanionBuilder = CacheEntriesCompanion Function({
  required String key,
  Value<String> etag,
  required String body,
  required int size,
  required DateTime fetchedAt,
  required DateTime usedAt,
  Value<int> rowid,
});
typedef $$CacheEntriesTableUpdateCompanionBuilder = CacheEntriesCompanion Function({
  Value<String> key,
  Value<String> etag,
  Value<String> body,
  Value<int> size,
  Value<DateTime> fetchedAt,
  Value<DateTime> usedAt,
  Value<int> rowid,
});

class $$CacheEntriesTableFilterComposer extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => ColumnFilters(column));
}

class $$CacheEntriesTableOrderingComposer extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => ColumnOrderings(column));
}

class $$CacheEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);
}

class $$CacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheEntriesTable,
          CacheEntry,
          $$CacheEntriesTableFilterComposer,
          $$CacheEntriesTableOrderingComposer,
          $$CacheEntriesTableAnnotationComposer,
          $$CacheEntriesTableCreateCompanionBuilder,
          $$CacheEntriesTableUpdateCompanionBuilder,
          (CacheEntry, BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>),
          CacheEntry,
          PrefetchHooks Function()
        > {
  $$CacheEntriesTableTableManager(_$AppDatabase db, $CacheEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> etag = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime> usedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion(
                key: key,
                etag: etag,
                body: body,
                size: size,
                fetchedAt: fetchedAt,
                usedAt: usedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String> etag = const Value.absent(),
                required String body,
                required int size,
                required DateTime fetchedAt,
                required DateTime usedAt,
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion.insert(
                key: key,
                etag: etag,
                body: body,
                size: size,
                fetchedAt: fetchedAt,
                usedAt: usedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CacheEntriesTable, CacheEntry>(table),
                  BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheEntriesTable,
      CacheEntry,
      $$CacheEntriesTableFilterComposer,
      $$CacheEntriesTableOrderingComposer,
      $$CacheEntriesTableAnnotationComposer,
      $$CacheEntriesTableCreateCompanionBuilder,
      $$CacheEntriesTableUpdateCompanionBuilder,
      (CacheEntry, BaseReferences<_$AppDatabase, $CacheEntriesTable, CacheEntry>),
      CacheEntry,
      PrefetchHooks Function()
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$PrefsTableOrderingComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$PrefsTableAnnotationComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
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

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          Pref,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
          Pref,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrefsTable, Pref>(table),
                  BaseReferences<_$AppDatabase, $PrefsTable, Pref>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      Pref,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
      Pref,
      PrefetchHooks Function()
    >;
typedef $$SavedArticlesTableCreateCompanionBuilder = SavedArticlesCompanion Function({
  required String path,
  required String card,
  Value<String?> article,
  Value<bool> imagesReady,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SavedArticlesTableUpdateCompanionBuilder = SavedArticlesCompanion Function({
  Value<String> path,
  Value<String> card,
  Value<String?> article,
  Value<bool> imagesReady,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SavedArticlesTableFilterComposer extends Composer<_$AppDatabase, $SavedArticlesTable> {
  $$SavedArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get imagesReady =>
      $composableBuilder(column: $table.imagesReady, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedArticlesTableOrderingComposer extends Composer<_$AppDatabase, $SavedArticlesTable> {
  $$SavedArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get imagesReady =>
      $composableBuilder(column: $table.imagesReady, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedArticlesTableAnnotationComposer extends Composer<_$AppDatabase, $SavedArticlesTable> {
  $$SavedArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => column);

  GeneratedColumn<String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => column);

  GeneratedColumn<bool> get imagesReady =>
      $composableBuilder(column: $table.imagesReady, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedArticlesTable,
          SavedRow,
          $$SavedArticlesTableFilterComposer,
          $$SavedArticlesTableOrderingComposer,
          $$SavedArticlesTableAnnotationComposer,
          $$SavedArticlesTableCreateCompanionBuilder,
          $$SavedArticlesTableUpdateCompanionBuilder,
          (SavedRow, BaseReferences<_$AppDatabase, $SavedArticlesTable, SavedRow>),
          SavedRow,
          PrefetchHooks Function()
        > {
  $$SavedArticlesTableTableManager(_$AppDatabase db, $SavedArticlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SavedArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<String> card = const Value.absent(),
                Value<String?> article = const Value.absent(),
                Value<bool> imagesReady = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedArticlesCompanion(
                path: path,
                card: card,
                article: article,
                imagesReady: imagesReady,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required String card,
                Value<String?> article = const Value.absent(),
                Value<bool> imagesReady = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedArticlesCompanion.insert(
                path: path,
                card: card,
                article: article,
                imagesReady: imagesReady,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedArticlesTable, SavedRow>(table),
                  BaseReferences<_$AppDatabase, $SavedArticlesTable, SavedRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedArticlesTable,
      SavedRow,
      $$SavedArticlesTableFilterComposer,
      $$SavedArticlesTableOrderingComposer,
      $$SavedArticlesTableAnnotationComposer,
      $$SavedArticlesTableCreateCompanionBuilder,
      $$SavedArticlesTableUpdateCompanionBuilder,
      (SavedRow, BaseReferences<_$AppDatabase, $SavedArticlesTable, SavedRow>),
      SavedRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingHistoryTableCreateCompanionBuilder = ReadingHistoryCompanion Function({
  required String path,
  required String card,
  Value<int> percent,
  required DateTime openedAt,
  Value<int> rowid,
});
typedef $$ReadingHistoryTableUpdateCompanionBuilder = ReadingHistoryCompanion Function({
  Value<String> path,
  Value<String> card,
  Value<int> percent,
  Value<DateTime> openedAt,
  Value<int> rowid,
});

class $$ReadingHistoryTableFilterComposer extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => ColumnFilters(column));
}

class $$ReadingHistoryTableOrderingComposer extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => ColumnOrderings(column));
}

class $$ReadingHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get card =>
      $composableBuilder(column: $table.card, builder: (column) => column);

  GeneratedColumn<int> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);
}

class $$ReadingHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingHistoryTable,
          HistoryRow,
          $$ReadingHistoryTableFilterComposer,
          $$ReadingHistoryTableOrderingComposer,
          $$ReadingHistoryTableAnnotationComposer,
          $$ReadingHistoryTableCreateCompanionBuilder,
          $$ReadingHistoryTableUpdateCompanionBuilder,
          (HistoryRow, BaseReferences<_$AppDatabase, $ReadingHistoryTable, HistoryRow>),
          HistoryRow,
          PrefetchHooks Function()
        > {
  $$ReadingHistoryTableTableManager(_$AppDatabase db, $ReadingHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<String> card = const Value.absent(),
                Value<int> percent = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion(
                path: path,
                card: card,
                percent: percent,
                openedAt: openedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required String card,
                Value<int> percent = const Value.absent(),
                required DateTime openedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingHistoryCompanion.insert(
                path: path,
                card: card,
                percent: percent,
                openedAt: openedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingHistoryTable, HistoryRow>(table),
                  BaseReferences<_$AppDatabase, $ReadingHistoryTable, HistoryRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingHistoryTable,
      HistoryRow,
      $$ReadingHistoryTableFilterComposer,
      $$ReadingHistoryTableOrderingComposer,
      $$ReadingHistoryTableAnnotationComposer,
      $$ReadingHistoryTableCreateCompanionBuilder,
      $$ReadingHistoryTableUpdateCompanionBuilder,
      (HistoryRow, BaseReferences<_$AppDatabase, $ReadingHistoryTable, HistoryRow>),
      HistoryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
  $$PrefsTableTableManager get prefs => $$PrefsTableTableManager(_db, _db.prefs);
  $$SavedArticlesTableTableManager get savedArticles =>
      $$SavedArticlesTableTableManager(_db, _db.savedArticles);
  $$ReadingHistoryTableTableManager get readingHistory =>
      $$ReadingHistoryTableTableManager(_db, _db.readingHistory);
}
