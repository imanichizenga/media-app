import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Answers of the API, as they came. What the app shows first on every start.
class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get etag => text().withDefault(const Constant(''))();
  TextColumn get body => text()();
  IntColumn get size => integer()();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get usedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Small settings, read once before the first frame.
class Prefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Articles the reader kept, whole: they open without a connection. Moves into the account in M4.
@DataClassName('SavedRow')
class SavedArticles extends Table {
  TextColumn get path => text()();
  TextColumn get card => text()();
  TextColumn get article => text().nullable()();
  BoolColumn get imagesReady => boolean().withDefault(const Constant(false))();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

@DataClassName('HistoryRow')
class ReadingHistory extends Table {
  TextColumn get path => text()();
  TextColumn get card => text()();
  IntColumn get percent => integer().withDefault(const Constant(0))();
  DateTimeColumn get openedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {path};
}

@DriftDatabase(tables: [CacheEntries, Prefs, SavedArticles, ReadingHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'news'));

  @override
  int get schemaVersion => 1;

  // ---- preferences ----
  Future<Map<String, String>> allPrefs() async => {
    for (final row in await select(prefs).get()) row.key: row.value,
  };
  Future<void> putPref(String key, String value) =>
      into(prefs).insertOnConflictUpdate(PrefsCompanion.insert(key: key, value: value));

  // ---- cache ----
  Future<CacheEntry?> cached(String key) =>
      (select(cacheEntries)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<void> store(String key, String etag, String body) async {
    final now = DateTime.now();
    await into(cacheEntries).insertOnConflictUpdate(
      CacheEntriesCompanion.insert(
        key: key,
        etag: Value(etag),
        body: body,
        size: body.length,
        fetchedAt: now,
        usedAt: now,
      ),
    );
  }

  /// Still good: the server said so.
  Future<void> touch(String key) => (update(cacheEntries)..where((t) => t.key.equals(key))).write(
    CacheEntriesCompanion(fetchedAt: Value(DateTime.now()), usedAt: Value(DateTime.now())),
  );

  /// Oldest first, until what is left fits. Saved articles live elsewhere and are never evicted.
  Future<int> evict({required int maxBytes, required Duration maxAge}) => transaction(() async {
    var gone = await (delete(
      cacheEntries,
    )..where((t) => t.usedAt.isSmallerThanValue(DateTime.now().subtract(maxAge)))).go();
    final rows =
        await (selectOnly(cacheEntries)
              ..addColumns([cacheEntries.key, cacheEntries.size])
              ..orderBy([OrderingTerm.desc(cacheEntries.usedAt)]))
            .get();
    var total = 0;
    for (final row in rows) {
      total += row.read(cacheEntries.size)!;
      if (total > maxBytes) {
        gone += await (delete(
          cacheEntries,
        )..where((t) => t.key.equals(row.read(cacheEntries.key)!))).go();
      }
    }
    return gone;
  });

  Future<void> clearCache() => delete(cacheEntries).go();

  // ---- saved ----
  Stream<List<SavedRow>> watchSaved() =>
      (select(savedArticles)..orderBy([(t) => OrderingTerm.desc(t.savedAt)])).watch();
  Future<SavedRow?> saved(String path) =>
      (select(savedArticles)..where((t) => t.path.equals(path))).getSingleOrNull();
  Future<void> putSaved(SavedArticlesCompanion row) =>
      into(savedArticles).insertOnConflictUpdate(row);
  Future<void> completeSaved(String path, {String? article, bool? imagesReady}) =>
      (update(savedArticles)..where((t) => t.path.equals(path))).write(
        SavedArticlesCompanion(
          article: article == null ? const Value.absent() : Value(article),
          imagesReady: imagesReady == null ? const Value.absent() : Value(imagesReady),
        ),
      );
  Future<void> unsave(String path) =>
      (delete(savedArticles)..where((t) => t.path.equals(path))).go();

  // ---- history ----
  static const historyLimit = 200;
  Stream<List<HistoryRow>> watchHistory() =>
      (select(readingHistory)
            ..orderBy([(t) => OrderingTerm.desc(t.openedAt)])
            ..limit(historyLimit))
          .watch();
  Future<void> opened(String path, String card) async {
    await into(readingHistory).insert(
      ReadingHistoryCompanion.insert(path: path, card: card, openedAt: DateTime.now()),
      onConflict: DoUpdate(
        (_) => ReadingHistoryCompanion(card: Value(card), openedAt: Value(DateTime.now())),
      ),
    );
    await customStatement(
      'DELETE FROM reading_history WHERE path NOT IN '
      '(SELECT path FROM reading_history ORDER BY opened_at DESC LIMIT $historyLimit)',
    );
  }

  Future<void> readTo(String path, int percent) => customUpdate(
    'UPDATE reading_history SET percent = MAX(percent, ?) WHERE path = ?',
    variables: [Variable.withInt(percent), Variable.withString(path)],
    updates: {readingHistory},
  );
  Future<void> clearHistory() => delete(readingHistory).go();
}
