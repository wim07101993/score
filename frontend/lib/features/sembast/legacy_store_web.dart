import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:score/features/sembast/legacy_store.dart';
import 'package:web/web.dart';

/// Reads what the app that was there before this one kept in this browser.
///
/// It kept what is known about the scores, the sets and the collections in
/// IndexedDB databases of their own — `scores`, `sets` and `collections`, each
/// with one store by the same name — and the score files in the Origin Private
/// File System, one `scores_<id>.musicxml` per score. What a set or a
/// collection still owed the server was kept on the record itself, so it comes
/// over with it. None of it is removed: if this app has to be rolled back, the
/// old one finds its things where it left them.
Future<LegacyData?> readLegacyData() async {
  final scores = await _readAll('scores', 'scores');
  final sets = await _readAll('sets', 'sets');
  final collections = await _readAll('collections', 'collections');
  if (scores.isEmpty && sets.isEmpty && collections.isEmpty) {
    return null;
  }

  final musicXml = <String, String>{};
  final directory = await _privateDirectory();
  if (directory != null) {
    for (final score in scores) {
      final id = '${score['id']}';
      final file = await _readFile(directory, 'scores_$id.musicxml');
      if (file != null) {
        musicXml[id] = file;
      }
    }
  }

  return LegacyData(
    scores: scores,
    sets: sets,
    collections: collections,
    musicXml: musicXml,
  );
}

/// Every record in one store of one database, or none when the database was
/// never made.
///
/// Opening a database that is not there makes it, and this is not the place
/// to leave empty databases behind; so a database that turns out to need
/// making is not made.
Future<List<Map<String, Object?>>> _readAll(
    String databaseName, String storeName) async {
  final opened = Completer<IDBDatabase?>();
  final request = window.indexedDB.open(databaseName, 1);
  request.onupgradeneeded = ((Event _) {
    request.transaction?.abort();
  }).toJS;
  request.onsuccess = ((Event _) {
    opened.complete(request.result! as IDBDatabase);
  }).toJS;
  request.onerror = ((Event event) {
    // An aborted upgrade lands here too, which is the database not existing.
    event.preventDefault();
    if (!opened.isCompleted) opened.complete(null);
  }).toJS;

  final database = await opened.future;
  if (database == null) {
    return const [];
  }

  try {
    if (!database.objectStoreNames.contains(storeName)) {
      return const [];
    }
    final read = Completer<JSAny?>();
    final getAll = database
        .transaction(storeName.toJS)
        .objectStore(storeName)
        .getAll();
    getAll.onsuccess = ((Event _) => read.complete(getAll.result)).toJS;
    getAll.onerror = ((Event _) => read.completeError(
        getAll.error ?? 'reading $databaseName.$storeName failed')).toJS;

    final records = await read.future;
    if (records == null) {
      return const [];
    }
    return [
      for (final record in (records as JSArray<JSAny?>).toDart)
        if (_asJson(record) case final json?) json,
    ];
  } finally {
    database.close();
  }
}

/// A record as the JSON this app keeps its own in.
///
/// The old app stored its moments as `Date` objects, which JSON writes as the
/// same ISO strings this app does; going through it is what makes the two
/// agree.
Map<String, Object?>? _asJson(JSAny? record) {
  try {
    final json = (globalContext['JSON']! as JSObject)
        .callMethod<JSString>('stringify'.toJS, record)
        .toDart;
    return (jsonDecode(json) as Map).cast<String, Object?>();
  } catch (error) {
    debugPrint('could not bring over a record from before: $error');
    return null;
  }
}

Future<FileSystemDirectoryHandle?> _privateDirectory() async {
  try {
    return await window.navigator.storage.getDirectory().toDart;
  } catch (error) {
    debugPrint('could not open the files kept from before: $error');
    return null;
  }
}

/// The text of a file, or null when there is no such file.
Future<String?> _readFile(
    FileSystemDirectoryHandle directory, String name) async {
  try {
    final handle = await directory.getFileHandle(name).toDart;
    final file = await handle.getFile().toDart;
    return (await file.text().toDart).toDart;
  } catch (_) {
    return null;
  }
}
