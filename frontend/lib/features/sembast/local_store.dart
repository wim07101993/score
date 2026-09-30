import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:score/features/auth/oidc_api.dart' show UserInfo;
import 'package:score/features/sembast/database_factory_io.dart'
    if (dart.library.js_interop) 'package:score/features/sembast/database_factory_web.dart';
import 'package:score/features/sembast/legacy_store.dart';
import 'package:score/features/sembast/legacy_store_io.dart'
    if (dart.library.js_interop) 'package:score/features/sembast/legacy_store_web.dart';
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
class LocalStore {
  LocalStore._(
    this._data,
    this._openDocuments,
  );

  final Database _data;

  /// The score files, kept apart from what is known about the scores.
  ///
  /// A MusicXML document is a few hundred kilobytes and the metadata is a few
  /// hundred bytes. The store reads a database into memory whole when it opens
  /// it, so this one is opened the first time a document is asked for rather
  /// than when the app starts: drawing the list of titles does not wait on
  /// reading every score ever downloaded. Once it is open, they are all in
  /// memory all the same.
  Future<Database> get _documents => _documentsOpened ??= _openDocuments();
  final Future<Database> Function() _openDocuments;
  Future<Database>? _documentsOpened;

  final _scores = stringMapStoreFactory.store('scores');
  final _sets = stringMapStoreFactory.store('sets');
  final _collections = stringMapStoreFactory.store('collections');
  final _settings = StoreRef<String, String>('settings');
  final _files = StoreRef<String, String>('musicxml');

  static Future<LocalStore> open() async {
    final data = await openDatabase('score');
    final store =
        LocalStore._(data, () => openDatabase('score_documents'));
    await store.bringOverLegacyData();
    return store;
  }

  /// Set once what the app before this one kept has been brought over.
  static const _legacyDataBroughtOver = 'legacy_data_brought_over';

  /// Set once the collections the app before this one kept have been brought
  /// over.
  ///
  /// They have a mark of their own because they were brought over later than
  /// the rest: a browser that already ran an earlier build of this app has the
  /// first mark set, and would otherwise never look for its collections at
  /// all. Everything else is not read again on their account — a score this app
  /// has since let go of is not one to bring back.
  static const _legacyCollectionsBroughtOver =
      'legacy_collections_brought_over';

  /// Set once what the app before this one had been told to prefer — light or
  /// dark, how the page was lit, who was signed in — has been brought over.
  ///
  /// A mark of its own for the same reason the collections have one: a browser
  /// that ran an earlier build has the other two set, and a player who set the
  /// old app to dark would otherwise open this one on a white page for good.
  static const _legacyPreferencesBroughtOver =
      'legacy_preferences_brought_over';

  /// The settings the preferences are brought over into, named as the parts of
  /// this app that read them name them.
  static const _themeModeKey = 'theme_mode';
  static const _pageLookLightKey = 'page_look_light';
  static const _pageLookDarkKey = 'page_look_dark';
  static const _userInfoKey = 'app_user_info';

  /// What the server's clock says a record was synced at when all that is known
  /// is that it was: the same moment the repositories record for a set or a
  /// collection that was read by itself rather than listed in a pull.
  static final _syncedAtSomePoint = DateTime.utc(1970).toIso8601String();

  /// Brings over, once, what the app that was there before this one kept in
  /// this browser.
  ///
  /// Without it, a player who upgrades opens the app to find the scores they
  /// had downloaded for tonight gone, and the set they edited at the last gig
  /// — or the piece they put into the book — without a network gone with the
  /// edit it still owed the server. What was owed comes over with the record
  /// it is owed about, because the old app kept the two together: the queue is
  /// part of the record, and is sent at the next sync like any other.
  ///
  /// A record that is here already is left as it is: whatever this app wrote
  /// is newer than anything the old one did. So is a setting: one this app has
  /// been told is the reader's choice since, and the old one's is not asked
  /// about. When the reading fails it is not marked as done, so it is tried
  /// again the next time the app starts.
  ///
  /// [read] is where it is read from, which is the browser everywhere but in
  /// the tests.
  @visibleForTesting
  Future<void> bringOverLegacyData({
    Future<LegacyData?> Function() read = readLegacyData,
  }) async {
    final everything = await readSetting(_legacyDataBroughtOver) == null;
    final collections =
        await readSetting(_legacyCollectionsBroughtOver) == null;
    final preferences =
        await readSetting(_legacyPreferencesBroughtOver) == null;
    if (!everything && !collections && !preferences) {
      return;
    }

    try {
      final legacy = await read();
      if (legacy != null) {
        await _data.transaction((transaction) async {
          for (final (store, records) in [
            if (everything) (_scores, legacy.scores.map(_legacyScore)),
            if (everything) (_sets, legacy.sets.map(_legacySetOrCollection)),
            if (collections)
              (_collections, legacy.collections.map(_legacySetOrCollection)),
          ]) {
            for (final record in records) {
              final ref = store.record('${record['id']}');
              if (!await ref.exists(transaction)) {
                await ref.put(transaction, record);
              }
            }
          }

          if (preferences) {
            for (final (key, value) in [
              (_themeModeKey, _legacyThemeMode(legacy.themeMode)),
              (_pageLookLightKey, legacy.pageLookLight),
              (_pageLookDarkKey, legacy.pageLookDark),
              (_userInfoKey, _legacyUserInfo(legacy.userInfo)),
            ]) {
              final ref = _settings.record(key);
              if (value != null && !await ref.exists(transaction)) {
                await ref.put(transaction, value);
              }
            }
          }
        });
        if (everything) {
          await (await _documents).transaction((transaction) async {
            for (final MapEntry(key: scoreId, value: musicXml)
                in legacy.musicXml.entries) {
              final ref = _files.record(scoreId);
              if (!await ref.exists(transaction)) {
                await ref.put(transaction, musicXml);
              }
            }
          });
        }
      }
    } catch (error) {
      debugPrint('could not bring over what was kept before: $error');
      return;
    }

    final now = DateTime.now().toIso8601String();
    await writeSetting(_legacyDataBroughtOver, now);
    await writeSetting(_legacyCollectionsBroughtOver, now);
    await writeSetting(_legacyPreferencesBroughtOver, now);
  }

  /// A score as the old app kept it, without the two moments it read off this
  /// device's clock.
  ///
  /// This app takes `last_synced_at` for where the server's clock stood at the
  /// end of the last change window, and asks for changes from there: a device
  /// whose clock ran ahead would have a watermark past uploads the server had
  /// yet to make, and never hear of them. Without one, the next sync lists
  /// every score once and records a watermark off the server's own clock.
  ///
  /// It takes `last_fetched_file_at` for the version of the document that is
  /// held, and compares it with when the server last changed the score: a clock
  /// that ran ahead would make an old document look current for good. Without
  /// one, that full listing checks every document that is held and fetches it
  /// again, once, since no version recorded is taken to be one that can be out
  /// of date.
  static Map<String, Object?> _legacyScore(Map<String, Object?> record) => {
        ...record,
      }
        ..remove('last_synced_at')
        ..remove('last_fetched_file_at');

  /// A set or a collection as the old app kept it, with the moment it was last
  /// synced put back to the start of time.
  ///
  /// The old app read that moment off this device's clock too, and this app
  /// asks for changes from the latest of them, so it cannot stay. But it cannot
  /// go either: a set or a collection with no such moment is one the server
  /// has never heard of, and one like that is deleted without telling the
  /// server and never has its songs sent. The start of time says what the
  /// record needs to say — the server has it — and asks for everything once, so
  /// that the next pull records a watermark off the server's own clock. One the
  /// server never had keeps its nothing.
  static Map<String, Object?> _legacySetOrCollection(
    Map<String, Object?> record,
  ) =>
      record['last_synced_at'] == null
          ? record
          : {...record, 'last_synced_at': _syncedAtSomePoint};

  /// The old app only ever kept `light` or `dark`, and nothing for following
  /// the system, which is what this app keeps too. Anything else is a key it
  /// never meant to write, and following the system is what that reads as
  /// anyway.
  static String? _legacyThemeMode(String? stored) =>
      stored == 'light' || stored == 'dark' ? stored : null;

  /// The user as the old app kept them, if this app can read them back.
  ///
  /// The old app wrote the same fields this one does — `name`, `subject`,
  /// `email`, `roles`, `claims` and `rolesKey` — but it took the roles from
  /// whatever the provider sent, where this app only ever keeps a map of them.
  /// One this app would fail to read back would be a device with a signed-in
  /// user it cannot start with; so it is read back here first, and left behind
  /// if it cannot be.
  static String? _legacyUserInfo(String? stored) {
    if (stored == null) {
      return null;
    }
    try {
      final json = jsonDecode(stored);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      UserInfo.fromJson(json);
      return stored;
    } catch (error) {
      debugPrint('could not bring over who was signed in before: $error');
      return null;
    }
  }

  /// A store on nothing, which is what the tests keep things in: they have
  /// neither a browser nor a device, and what they are testing is not where the
  /// bytes land.
  static Future<LocalStore> inMemory() async {
    final documents =
        newDatabaseFactoryMemory().openDatabase('score_documents');
    return LocalStore._(
      await newDatabaseFactoryMemory().openDatabase('score'),
      () => documents,
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

  Future<String?> readMusicXml(String scoreId) async =>
      _files.record(scoreId).get(await _documents);

  Future<void> writeMusicXml(String scoreId, String musicXml) async =>
      _files.record(scoreId).put(await _documents, musicXml);

  Future<bool> hasMusicXml(String scoreId) async =>
      _files.record(scoreId).exists(await _documents);

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

  /// Forgets every setting whose key starts with [prefix]: the settings kept
  /// one per something, of which there is no list.
  Future<void> forgetSettingsStartingWith(String prefix) => _settings.delete(
        _data,
        finder: Finder(
          filter: Filter.custom((record) => '${record.key}'.startsWith(prefix)),
        ),
      );
}
