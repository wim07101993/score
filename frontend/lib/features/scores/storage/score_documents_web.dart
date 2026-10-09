import 'dart:js_interop';

import 'package:score/features/scores/storage/score_documents.dart';
import 'package:web/web.dart' as web;

Future<ScoreDocuments> openScoreDocuments() async {
  final storage = web.window.navigator.storage;
  // Asked to keep what is here even when the browser runs short of room: a
  // score that was downloaded for tonight and is cleared away before the gig
  // is the very thing this app exists to prevent. The browser may say no, in
  // which case they are kept the way everything else of the site is.
  try {
    await storage.persist().toDart;
  } catch (_) {
    // Not every browser asks, and not asking is not a reason to keep nothing.
  }
  final root = await storage.getDirectory().toDart;
  final directory = await root
      .getDirectoryHandle(
        'scores',
        web.FileSystemGetDirectoryOptions(create: true),
      )
      .toDart;
  return OriginScoreDocuments(directory: directory);
}

class OriginScoreDocuments({
  required final web.FileSystemDirectoryHandle directory,
}) implements ScoreDocuments {
  Future<web.FileSystemFileHandle?> _handle(String scoreId) async {
    try {
      return await directory.getFileHandle(scoreDocumentName(scoreId)).toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> read(String scoreId) async {
    final handle = await _handle(scoreId);
    if (handle == null) {
      return null;
    }
    final file = await handle.getFile().toDart;
    return (await file.text().toDart).toDart;
  }

  @override
  Future<void> write(String scoreId, String musicXml) async {
    final handle = await directory
        .getFileHandle(
          scoreDocumentName(scoreId),
          web.FileSystemGetFileOptions(create: true),
        )
        .toDart;
    final writable = await handle
        .createWritable(
          web.FileSystemCreateWritableOptions(keepExistingData: false),
        )
        .toDart;
    try {
      await writable.write(musicXml.toJS).toDart;
    } finally {
      await writable.close().toDart;
    }
  }

  @override
  Future<void> remove(String scoreId) async {
    if (await _handle(scoreId) == null) {
      return;
    }
    await directory.removeEntry(scoreDocumentName(scoreId)).toDart;
  }

  @override
  Future<List<String>> ids() async {
    final ids = <String>[];
    final names = directory._keys();
    while (true) {
      final next = await names.next().toDart;
      if (next.done) break;
      final id = scoreIdOfDocument(next.value!.toDart);
      if (id != null) ids.add(id);
    }
    return ids;
  }
}

/// What `package:web` leaves out of a directory: walking through what is in
/// it, which the browser hands over as an async iterator.
extension on web.FileSystemDirectoryHandle {
  @JS('keys')
  external _NameIterator _keys();
}

extension type _NameIterator(JSObject _) implements JSObject {
  external JSPromise<_NextName> next();
}

extension type _NextName(JSObject _) implements JSObject {
  external bool get done;
  external JSString? get value;
}
