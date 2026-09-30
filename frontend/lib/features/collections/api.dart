import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:score/api.dart';
import 'package:score/config.dart';

/// The collections endpoints of the API.
///
/// Everything about talking to the server is the same as it is for a set, for
/// the same reason: a write is made from an edit that was already accepted and
/// stored on this device, so a failure has to say more than that it failed.
/// Whether the write is worth trying again decides between keeping the edit
/// queued and giving it up, and that is what [CollectionsApiException] carries.

/// A call to the collections endpoints that did not come back with what was
/// asked for; see [ApiException].
class CollectionsApiException extends ApiException {
  CollectionsApiException(
    super.message,
    super.status, [
    super.problem,
  ]);

  /// The collection belongs to someone else, and waiting does not change whose
  /// it is.
  @override
  String get notTheOwnersCode => 'not_collection_owner';

  /// Whether this is the collection saying it already holds the piece.
  ///
  /// It is the one refusal a set has no equivalent of, and the only one that
  /// is worth acting on rather than reporting: the piece the client was trying
  /// to add is in the collection, which is what it wanted.
  bool get isAlreadyInTheCollection =>
      errorCode == 'score_already_in_collection';
}

class CollectionsApi {
  CollectionsApi(
    this._config, {
    http.Client? client,
  }) : _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  /// The collections that changed within the window, the caller's own and the
  /// ones shared with them. Collections that were deleted within it come back
  /// too, with `deleted_at` filled in.
  Future<List<Map<String, dynamic>>> listCollections(
    DateTime? changesSince,
    DateTime? changesUntil,
    String authToken,
  ) async {
    const what = 'list the collections';
    final response = await callTheApi(
      () => _client.get(
        _config.path('collections', {
          'Changes-Since': apiDate(changesSince ?? DateTime.utc(1970)),
          'Changes-Until': apiDate(changesUntil ?? DateTime.now()),
        }),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      what,
      CollectionsApiException.new,
    );
    throwUnlessOk(response, what, CollectionsApiException.new);
    return objectsIn(response, what, CollectionsApiException.new);
  }

  /// One collection, asked for by id. `null` when there is no such collection,
  /// or when it is neither the caller's nor shared with them.
  ///
  /// A listing only ever answers with what changed inside a window, so this is
  /// the only way to get hold of a collection that is older than the window a
  /// client has left to ask about.
  Future<Map<String, dynamic>?> getCollection(
    String collectionId,
    String authToken,
  ) async {
    const what = 'fetch the collection';
    final response = await callTheApi(
      () => _client.get(
        _config.path('collections/$collectionId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      what,
      CollectionsApiException.new,
    );
    if (isNotThere(
      response,
      const {'collection_not_found'},
      what,
      CollectionsApiException.new,
    )) {
      return null;
    }
    throwUnlessOk(response, what, CollectionsApiException.new);
    return objectIn(response, what, CollectionsApiException.new);
  }

  /// Stores what the collection is — the group of pieces, and who may read it
  /// — under the given id, and hands back the collection as it now reads.
  ///
  /// What is in it is not written here and is not touched by writing here: an
  /// entry is a resource of its own, put into the collection and taken out
  /// again one at a time.
  Future<Map<String, dynamic>> putCollection(
    String collectionId,
    String authToken,
    Map<String, Object?> writeCollection,
  ) =>
      _write('collections/$collectionId', authToken, writeCollection,
          'save the collection');

  /// Puts one piece into a collection, or changes what the group does with it,
  /// and hands the entry back as it now reads.
  ///
  /// A collection holds a piece once: an entry naming a score that is already
  /// in it under another entry comes back as a
  /// [CollectionsApiException.isAlreadyInTheCollection] refusal, carrying the
  /// entry it is already in.
  Future<Map<String, dynamic>> putEntry(
    String collectionId,
    String entryId,
    String authToken,
    Map<String, Object?> writeEntry,
  ) =>
      _write('collections/$collectionId/entries/$entryId', authToken,
          writeEntry, 'save the entry');

  /// Takes one piece out of a collection. An entry that is already gone is not
  /// an error: what was asked for is the state it is now in.
  Future<void> deleteEntry(
    String collectionId,
    String entryId,
    String authToken,
  ) =>
      _delete('collections/$collectionId/entries/$entryId', authToken,
          'delete the entry');

  /// Stores how the caller looks at one entry of a collection, and hands it
  /// back as it now reads.
  ///
  /// Anyone who can read the collection can write their own view of its
  /// entries: it says nothing about the collection and changes nothing anybody
  /// else sees, so a player who cannot add a piece to the book can still say
  /// how they read one that is in it.
  Future<Map<String, dynamic>> putEntryView(
    String collectionId,
    String entryId,
    String authToken,
    Map<String, Object?> writeView,
  ) =>
      _write('collections/$collectionId/entries/$entryId/view', authToken,
          writeView, 'save the view');

  /// Marks the collection as deleted. One that was already gone is not an
  /// error: what was asked for is the state it is now in.
  Future<void> deleteCollection(String collectionId, String authToken) =>
      _delete('collections/$collectionId', authToken, 'delete the collection');

  Future<bool> canBeReached() => apiCanBeReached(_client, _config);

  Future<Map<String, dynamic>> _write(
    String path,
    String authToken,
    Map<String, Object?> body,
    String what,
  ) async {
    final response = await callTheApi(
      () => _client.put(
        _config.path(path),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ),
      what,
      CollectionsApiException.new,
    );
    throwUnlessOk(response, what, CollectionsApiException.new);
    return objectIn(response, what, CollectionsApiException.new);
  }

  Future<void> _delete(String path, String authToken, String what) async {
    final response = await callTheApi(
      () => _client.delete(
        _config.path(path),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
      what,
      CollectionsApiException.new,
    );
    if (isNotThere(
      response,
      const {'collection_not_found', 'collection_entry_not_found'},
      what,
      CollectionsApiException.new,
    )) {
      return;
    }
    throwUnlessOk(response, what, CollectionsApiException.new);
  }
}
