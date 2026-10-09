import 'package:score/features/scores/storage/score_documents_io.dart'
    if (dart.library.js_interop) 'package:score/features/scores/storage/score_documents_web.dart';

abstract interface class ScoreDocuments {
  static Future<ScoreDocuments> open() => openScoreDocuments();

  Future<String?> read(String scoreId);

  Future<void> write(String scoreId, String musicXml);

  Future<void> remove(String scoreId);

  /// The scores whose documents are on this device.
  Future<List<String>> ids();
}

const _documentExtension = '.musicxml';

String scoreDocumentName(String scoreId) =>
    '${Uri.encodeComponent(scoreId)}$_documentExtension';

/// The score a document of [name] is of, or null for anything that is not a
/// score's document — one half-written when the app was stopped, say.
String? scoreIdOfDocument(String name) => name.endsWith(_documentExtension)
    ? Uri.decodeComponent(
        name.substring(0, name.length - _documentExtension.length),
      )
    : null;

class InMemoryScoreDocuments() implements ScoreDocuments {
  final Map<String, String> _documents = {};

  @override
  Future<String?> read(String scoreId) async => _documents[scoreId];

  @override
  Future<void> write(String scoreId, String musicXml) async =>
      _documents[scoreId] = musicXml;

  @override
  Future<void> remove(String scoreId) async => _documents.remove(scoreId);

  @override
  Future<List<String>> ids() async => _documents.keys.toList(growable: false);
}
