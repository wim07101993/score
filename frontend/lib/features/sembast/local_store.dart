import 'package:score/features/sembast/database_factory_io.dart'
    if (dart.library.js_interop) 'package:score/features/sembast/database_factory_web.dart';
import 'package:sembast/sembast_memory.dart';

/// Where everything this device knows is kept between visits.
///
/// A score is read on a stage, a set is edited at a gig and a piece is put into
/// the book where the book is, and all of those are exactly where there is no
/// network. So nothing here waits on the API: what is stored is what is shown,
/// and the API is squared with it afterwards.
///
/// It is one store that works the same on a browser and on a device, so that
/// nothing above it ever has to ask which one it is on.
class LocalStore._({
  required final Database data,
  required final Future<Database> Function() openDocuments,
}) {
  /// The score files, kept apart from what is known about the scores.
  ///
  /// A MusicXML document is a few hundred kilobytes and the metadata is a few
  /// hundred bytes. The store reads a database into memory whole when it opens
  /// it, so this one is opened the first time a document is asked for rather
  /// than when the app starts: drawing the list of titles does not wait on
  /// reading every score ever downloaded. Once it is open, they are all in
  /// memory all the same.
  Future<Database> get _documents => _documentsOpened ??= openDocuments();
  Future<Database>? _documentsOpened;

  final _scores = stringMapStoreFactory.store('scores');
  final _sets = stringMapStoreFactory.store('sets');
  final _collections = stringMapStoreFactory.store('collections');
  final _settings = StoreRef<String, String>('settings');
  final _files = StoreRef<String, String>('musicxml');
  final _logs = intMapStoreFactory.store('logs');

  static Future<LocalStore> open() async {
    final data = await openDatabase('score');
    return LocalStore._(data: data, openDocuments: () => openDatabase('score_documents'));
  }

  /// A store on nothing, which is what the tests keep things in: they have
  /// neither a browser nor a device, and what they are testing is not where the
  /// bytes land.
  static Future<LocalStore> inMemory() async {
    final documents =
        newDatabaseFactoryMemory().openDatabase('score_documents');
    return LocalStore._(
      data: await newDatabaseFactoryMemory().openDatabase('score'),
      openDocuments: () => documents,
    );
  }

  // -------------------------------------------------------------------------
  // WHAT IS KNOWN ABOUT THE SCORES, THE SETS AND THE COLLECTIONS
  // -------------------------------------------------------------------------

  Future<List<Map<String, Object?>>> readScores() => _readAll(_scores);
  Future<List<Map<String, Object?>>> readSets() => _readAll(_sets);
  Future<List<Map<String, Object?>>> readCollections() =>
      _readAll(_collections);

  Future<void> writeScores(List<Map<String, Object?>> records) =>
      _writeAll(_scores, records);

  Future<void> writeSets(List<Map<String, Object?>> records) =>
      _writeAll(_sets, records);

  Future<void> writeCollections(List<Map<String, Object?>> records) =>
      _writeAll(_collections, records);

  /// Forgets every set, for a device that is handed to somebody else.
  Future<void> forgetSets() => _sets.delete(data);

  /// Forgets every collection, for a device that is handed to somebody else.
  Future<void> forgetCollections() => _collections.delete(data);

  Future<List<Map<String, Object?>>> _readAll(
      StoreRef<String, Map<String, Object?>> store) async {
    final records = await store.find(data);
    return [for (final record in records) record.value];
  }

  /// Written in one transaction, so that a device that is put to sleep halfway
  /// through a sync wakes up with either all of what arrived or none of it.
  Future<void> _writeAll(
    StoreRef<String, Map<String, Object?>> store,
    List<Map<String, Object?>> records,
  ) async {
    if (records.isEmpty) {
      return;
    }
    await data.transaction((transaction) async {
      for (final record in records) {
        await store.record('${record['id']}').put(transaction, record);
      }
    });
  }

  // -------------------------------------------------------------------------
  // THE SCORES THEMSELVES
  // -------------------------------------------------------------------------

  Future<String?> readMusicXml(String scoreId) async =>
      _files.record(scoreId).get(await _documents);

  Future<void> writeMusicXml(String scoreId, String musicXml) async =>
      _files.record(scoreId).put(await _documents, musicXml);

  Future<bool> hasMusicXml(String scoreId) async =>
      _files.record(scoreId).exists(await _documents);

  /// Forgets one score and its document, for a score the server no longer
  /// has.
  ///
  /// The document first: the two are in different databases and cannot be
  /// forgotten in one go. A device put away in between is left with a score
  /// and no document, which is still listed, and forgotten again the next
  /// time it is looked for — rather than with a document nothing lists any
  /// more, which nothing would ever look for again, and which would be shown
  /// as the score if it were ever opened by a link.
  Future<void> forgetScore(String scoreId) async {
    await _files.record(scoreId).delete(await _documents);
    await _scores.record(scoreId).delete(data);
  }

  // -------------------------------------------------------------------------
  // WHAT THE APP REMEMBERS ABOUT THIS DEVICE
  // -------------------------------------------------------------------------

  Future<String?> readSetting(String key) => _settings.record(key).get(data);

  /// Storing nothing is not the same as storing null: a key that is written
  /// with no value would be read back as the text "null" by whoever asked next.
  Future<void> writeSetting(String key, String? value) async {
    if (value == null) {
      await _settings.record(key).delete(data);
      return;
    }
    await _settings.record(key).put(data, value);
  }

  /// Forgets every setting whose key starts with [prefix]: the settings kept
  /// one per something, of which there is no list.
  Future<void> forgetSettingsStartingWith(String prefix) => _settings.delete(
        data,
        finder: Finder(
          filter: Filter.custom((record) => '${record.key}'.startsWith(prefix)),
        ),
      );

  // -------------------------------------------------------------------------
  // WHAT THE APP LOGGED
  // -------------------------------------------------------------------------

  /// Adds one log record after the ones written before it.
  Future<void> writeLog(Map<String, Object?> record) => _logs.add(data, record);

  /// Every log record kept, oldest first.
  Future<List<Map<String, Object?>>> readLogs() async {
    final records = await _logs.find(
      data,
      finder: Finder(sortOrders: [SortOrder(Field.key)]),
    );
    return [for (final record in records) record.value];
  }

  /// Forgets every log record but the last [count].
  Future<void> keepLastLogs(int count) async {
    final keys = await _logs.findKeys(
      data,
      finder: Finder(sortOrders: [SortOrder(Field.key, false)], offset: count),
    );
    await _logs.records(keys).delete(data);
  }
}
