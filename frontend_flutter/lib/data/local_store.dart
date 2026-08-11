import 'package:sembast/sembast_memory.dart';

import 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';

/// Where everything this device knows is kept between visits.
///
/// A score is read on a stage and a set is edited at a gig, and both of those
/// are exactly where there is no network. So nothing here waits on the API:
/// what is stored is what is shown, and the API is squared with it afterwards.
///
/// It is one store that works the same on a browser and on a device, so that
/// nothing above it ever has to ask which one it is on.
class LocalStore {
  LocalStore._(this._data, this._documents);

  final Database _data;

  /// The score files, kept apart from what is known about the scores.
  ///
  /// A MusicXML document is a few hundred kilobytes and the metadata is a few
  /// hundred bytes, so keeping them together would mean reading every score
  /// ever downloaded into memory to draw a list of their titles.
  final Database _documents;

  static Future<LocalStore> open() async {
    final data = await openDatabase('score');
    final documents = await openDatabase('score_documents');
    return LocalStore._(data, documents);
  }

  /// A store on nothing, which is what the tests keep things in: they have
  /// neither a browser nor a device, and what they are testing is not where the
  /// bytes land.
  static Future<LocalStore> inMemory() async => LocalStore._(
        await newDatabaseFactoryMemory().openDatabase('score'),
        await newDatabaseFactoryMemory().openDatabase('score_documents'),
      );

  final _scores = stringMapStoreFactory.store('scores');
  final _sets = stringMapStoreFactory.store('sets');
  final _settings = StoreRef<String, String>('settings');
  final _files = StoreRef<String, String>('musicxml');

  // -------------------------------------------------------------------------
  // WHAT IS KNOWN ABOUT THE SCORES AND THE SETS
  // -------------------------------------------------------------------------

  Future<List<Map<String, Object?>>> readScores() => _readAll(_scores);
  Future<List<Map<String, Object?>>> readSets() => _readAll(_sets);

  Future<void> writeScores(List<Map<String, Object?>> records) =>
      _writeAll(_scores, records);

  Future<void> writeSets(List<Map<String, Object?>> records) =>
      _writeAll(_sets, records);

  Future<List<Map<String, Object?>>> _readAll(
      StoreRef<String, Map<String, Object?>> store) async {
    final records = await store.find(_data);
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
    await _data.transaction((transaction) async {
      for (final record in records) {
        await store.record('${record['id']}').put(transaction, record);
      }
    });
  }

  // -------------------------------------------------------------------------
  // THE SCORES THEMSELVES
  // -------------------------------------------------------------------------

  Future<String?> readMusicXml(String scoreId) =>
      _files.record(scoreId).get(_documents);

  Future<void> writeMusicXml(String scoreId, String musicXml) =>
      _files.record(scoreId).put(_documents, musicXml);

  Future<bool> hasMusicXml(String scoreId) =>
      _files.record(scoreId).exists(_documents);

  // -------------------------------------------------------------------------
  // WHAT THE APP REMEMBERS ABOUT THIS DEVICE
  // -------------------------------------------------------------------------

  Future<String?> readSetting(String key) => _settings.record(key).get(_data);

  /// Storing nothing is not the same as storing null: a key that is written
  /// with no value would be read back as the text "null" by whoever asked next.
  Future<void> writeSetting(String key, String? value) async {
    if (value == null) {
      await _settings.record(key).delete(_data);
      return;
    }
    await _settings.record(key).put(_data, value);
  }
}
