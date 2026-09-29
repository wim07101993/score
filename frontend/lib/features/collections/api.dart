import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:score/config.dart';

/// The collections endpoints of the API.
///
/// Everything about talking to the server is the same as it is for a set, for
/// the same reason: a write is made from an edit that was already accepted and
/// stored on this device, so a failure has to say more than that it failed.
/// Whether the write is worth trying again decides between keeping the edit
/// queued and giving it up, and that is what [CollectionsApiException] carries.

/// A call that did not come back with what was asked for.
///
/// The status is the one http gave, and [errorCode] the one this API gives —
/// which is the one to branch on, the way the API says. Both are absent when
/// the call never reached a server at all.
class CollectionsApiException implements Exception {
  CollectionsApiException(
    this.message,
    this.status, [
    this.problem,
  ]);

  final String message;
  final int? status;

  /// The RFC 9457 body, when there was one.
  final Map<String, dynamic>? problem;

  String? get errorCode => problem?['errorCode'] as String?;

  String get detail => (problem?['detail'] as String?) ?? message;

  /// Whether the same call is worth making again later.
  ///
  /// A request the server refused to read is refused just as firmly the next
  /// time: a collection naming a score that does not exist, or an address that
  /// is not an address, is not going to start being accepted because time
  /// passed. What is worth trying again is everything that says nothing about
  /// the request — the network being down, the server being unwell, a token
  /// that has run out.
  bool get isWorthRetrying {
    if (status == null) {
      // Nothing answered, so nothing has been said about the request.
      return true;
    }
    if (errorCode == 'not_collection_owner') {
      // The collection belongs to someone else, and waiting does not change
      // whose it is.
      return false;
    }
    if (status == 401 || status == 403) {
      // A token that expired mid-sync, or a role that has yet to be granted:
      // both are about the caller rather than about what was written.
      return true;
    }
    return status! < 400 || status! >= 500;
  }

  /// Whether this is the collection saying it already holds the piece.
  ///
  /// It is the one refusal a set has no equivalent of, and the only one that
  /// is worth acting on rather than reporting: the piece the client was trying
  /// to add is in the collection, which is what it wanted. What it is in is
  /// [alreadyInEntryId].
  bool get isAlreadyInTheCollection =>
      errorCode == 'score_already_in_collection';

  /// The entry the piece is already in, when that is what went wrong.
  String? get alreadyInEntryId =>
      isAlreadyInTheCollection ? (problem?['entryId'] as String?) : null;

  @override
  String toString() => message;
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
    final response = await _call(
      () => _client.get(
        _config.path('collections', {
          'Changes-Since': _formatDate(changesSince ?? DateTime.utc(1970)),
          'Changes-Until': _formatDate(changesUntil ?? DateTime.now()),
        }),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      'list the collections',
    );
    _throwUnlessOk(response, 'list the collections');
    return [
      for (final collection in jsonDecode(response.body) as List)
        (collection as Map).cast<String, dynamic>(),
    ];
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
    final response = await _call(
      () => _client.get(
        _config.path('collections/$collectionId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      'fetch the collection',
    );
    if (response.statusCode == 404) {
      return null;
    }
    _throwUnlessOk(response, 'fetch the collection');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
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
  ) async {
    final response = await _call(
      () => _client.put(
        _config.path('collections/$collectionId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(writeCollection),
      ),
      'save the collection',
    );
    _throwUnlessOk(response, 'save the collection');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

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
  ) async {
    final response = await _call(
      () => _client.put(
        _config.path('collections/$collectionId/entries/$entryId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(writeEntry),
      ),
      'save the entry',
    );
    _throwUnlessOk(response, 'save the entry');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  /// Takes one piece out of a collection. An entry that is already gone is not
  /// an error: what was asked for is the state it is now in.
  Future<void> deleteEntry(
    String collectionId,
    String entryId,
    String authToken,
  ) async {
    final response = await _call(
      () => _client.delete(
        _config.path('collections/$collectionId/entries/$entryId'),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
      'delete the entry',
    );
    if (response.statusCode == 404) {
      return;
    }
    _throwUnlessOk(response, 'delete the entry');
  }

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
  ) async {
    final response = await _call(
      () => _client.put(
        _config.path('collections/$collectionId/entries/$entryId/view'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(writeView),
      ),
      'save the view',
    );
    _throwUnlessOk(response, 'save the view');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  /// Marks the collection as deleted. One that was already gone is not an
  /// error: what was asked for is the state it is now in.
  Future<void> deleteCollection(String collectionId, String authToken) async {
    final response = await _call(
      () => _client.delete(
        _config.path('collections/$collectionId'),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
      'delete the collection',
    );
    if (response.statusCode == 404) {
      return;
    }
    _throwUnlessOk(response, 'delete the collection');
  }

  Future<bool> canBeReached() async {
    try {
      final response = await _client
          .get(_config.path('healthz'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 400;
    } catch (error) {
      return false;
    }
  }

  /// Makes the call, turning a network that is not there into the same kind of
  /// failure as a server that said no — one with no status, since nothing
  /// answered.
  Future<http.Response> _call(
      Future<http.Response> Function() send, String what) async {
    try {
      return await send();
    } catch (error) {
      throw CollectionsApiException('failed to $what: $error', null);
    }
  }
}

void _throwUnlessOk(http.Response response, String what) {
  if (response.statusCode < 400) {
    return;
  }

  Map<String, dynamic>? problem;
  try {
    final parsed = jsonDecode(response.body);
    // Every failure this API answers with is an RFC 9457 object; anything else
    // came from something in between that does not know about it.
    problem = parsed is Map ? parsed.cast<String, dynamic>() : null;
  } catch (error) {
    problem = null;
  }

  throw CollectionsApiException(
    'failed to $what: ${response.statusCode} ${response.body}',
    response.statusCode,
    problem,
  );
}

/// Writes a moment the way the API reads it: RFC 3339, in UTC, so that a window
/// ends exactly where it was asked to.
String _formatDate(DateTime date) => date.toUtc().toIso8601String();
