import 'package:flutter/foundation.dart' show debugPrint;
import 'package:score/features/sembast/database_factory_io.dart'
    if (dart.library.js_interop) 'package:score/features/sembast/database_factory_web.dart';
import 'package:score/features/sembast/legacy_store_io.dart'
    if (dart.library.js_interop) 'package:score/features/sembast/legacy_store_web.dart';
import 'package:sembast/sembast_memory.dart';

/// Where everything this device knows is kept between visits.
///
/// A score is read on a stage and a set is edited at a gig, and both of those
/// are exactly where there is no network. So nothing here waits on the API:
/// what is stored is what is shown, and the API is squared with it afterwards.
///
/// It is one store that works the same on a browser and on a device, so that
/// nothing above it ever has to ask which one it is on.
class LocalStore {
  LocalStore._(
    this._data,
    this._documents,
  );

  final Database _data;

  /// The score files, kept apart from what is known about the scores.
  ///
  /// A MusicXML document is a few hundred kilobytes and the metadata is a few
  /// hundred bytes, so keeping them together would mean reading every score
  /// ever downloaded into memory to draw a list of their titles.
  final Database _documents;

  final _scores = stringMapStoreFactory.store('scores');
  final _sets = stringMapStoreFactory.store('sets');
  final _settings = StoreRef<String, String>('settings');
  final _files = StoreRef<String, String>('musicxml');

  static Future<LocalStore> open() async {
    final data = await openDatabase('score');
    final documents = await openDatabase('score_documents');
    final store = LocalStore._(data, documents);
    await store._bringOverLegacyData();
    return store;
  }

  /// Set once what the app before this one kept has been brought over.
  static const _legacyDataBroughtOver = 'legacy_data_brought_over';

  /// Brings over, once, what the app that was there before this one kept in
  /// this browser.
  ///
  /// Without it, a player who upgrades opens the app to find the scores they
  /// had downloaded for tonight gone, and the set they edited at the last gig
  /// without a network gone with the edit it still owed the server.
  ///
  /// A record that is here already is left as it is: whatever this app wrote
  /// is newer than anything the old one did. When the reading fails it is not
  /// marked as done, so it is tried again the next time the app starts.
  Future<void> _bringOverLegacyData() async {
    if (await readSetting(_legacyDataBroughtOver) != null) {
      return;
    }

    try {
      final legacy = await readLegacyData();
      if (legacy != null) {
        await _data.transaction((transaction) async {
          for (final (store, records) in [
            (_scores, legacy.scores),
            (_sets, legacy.sets),
          ]) {
            for (final record in records) {
              final ref = store.record('${record['id']}');
              if (!await ref.exists(transaction)) {
                await ref.put(transaction, record);
              }
            }
          }
        });
        await _documents.transaction((transaction) async {
          for (final MapEntry(key: scoreId, value: musicXml)
              in legacy.musicXml.entries) {
            final ref = _files.record(scoreId);
            if (!await ref.exists(transaction)) {
              await ref.put(transaction, musicXml);
            }
          }
        });
      }
    } catch (error) {
      debugPrint('could not bring over what was kept before: $error');
      return;
    }

    await writeSetting(
        _legacyDataBroughtOver, DateTime.now().toIso8601String());
  }

  /// A store on nothing, which is what the tests keep things in: they have
  /// neither a browser nor a device, and what they are testing is not where the
  /// bytes land.
  static Future<LocalStore> inMemory() async => LocalStore._(
        await newDatabaseFactoryMemory().openDatabase('score'),
        await newDatabaseFactoryMemory().openDatabase('score_documents'),
      );

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
