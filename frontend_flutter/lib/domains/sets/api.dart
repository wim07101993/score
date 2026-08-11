import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';

/// The sets endpoints of the API.
///
/// Unlike the scores endpoints, these are written to as well as read from, and
/// a write is made from an edit that was already accepted and stored on this
/// device. So a failure has to say more than that it failed: whether the write
/// is worth trying again decides between keeping the edit queued and giving it
/// up, and that is what [SetsApiException] carries.

/// A call that did not come back with what was asked for.
///
/// The status is the one http gave, and [errorCode] the one this API gives —
/// which is the one to branch on, the way the API says. Both are absent when
/// the call never reached a server at all.
class SetsApiException implements Exception {
  SetsApiException(this.message, this.status, [this.problem]);

  final String message;
  final int? status;

  /// The RFC 9457 body, when there was one.
  final Map<String, dynamic>? problem;

  String? get errorCode => problem?['errorCode'] as String?;

  String get detail => (problem?['detail'] as String?) ?? message;

  /// Whether the same call is worth making again later.
  ///
  /// A request the server refused to read is refused just as firmly the next
  /// time: a set naming a score that does not exist, or an address that is not
  /// an address, is not going to start being accepted because time passed. What
  /// is worth trying again is everything that says nothing about the request —
  /// the network being down, the server being unwell, a token that has run out.
  bool get isWorthRetrying {
    if (status == null) {
      // Nothing answered, so nothing has been said about the request.
      return true;
    }
    if (errorCode == 'not_set_owner') {
      // The set belongs to someone else, and waiting does not change whose it
      // is.
      return false;
    }
    if (status == 401 || status == 403) {
      // A token that expired mid-sync, or a role that has yet to be granted:
      // both are about the caller rather than about what was written.
      return true;
    }
    return status! < 400 || status! >= 500;
  }

  @override
  String toString() => message;
}

class SetsApi {
  SetsApi(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  /// The sets that changed within the window, the caller's own and the ones
  /// shared with them. Sets that were deleted within it come back too, with
  /// `deleted_at` filled in.
  Future<List<Map<String, dynamic>>> listSets(
    DateTime? changesSince,
    DateTime? changesUntil,
    String authToken,
  ) async {
    final response = await _call(
      () => _client.get(
        _config.path('sets', {
          'Changes-Since': _formatDate(changesSince ?? DateTime.utc(1970)),
          'Changes-Until': _formatDate(changesUntil ?? DateTime.now()),
        }),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      'list the sets',
    );
    _throwUnlessOk(response, 'list the sets');
    return [
      for (final set in jsonDecode(response.body) as List)
        (set as Map).cast<String, dynamic>(),
    ];
  }

  /// One set, asked for by id. `null` when there is no such set, or when it is
  /// neither the caller's nor shared with them.
  Future<Map<String, dynamic>?> getSet(String setId, String authToken) async {
    final response = await _call(
      () => _client.get(
        _config.path('sets/$setId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      'fetch the set',
    );
    if (response.statusCode == 404) {
      return null;
    }
    _throwUnlessOk(response, 'fetch the set');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  /// Stores what the set is — the gig, and who may read it — and hands back the
  /// set as it now reads.
  ///
  /// What is played in it is not written here and is not touched by writing
  /// here: an entry is a resource of its own, put into the set and taken out
  /// again one at a time. So a set is created empty and filled afterwards, and
  /// correcting a title never restates the running order.
  Future<Map<String, dynamic>> putSet(
    String setId,
    String authToken,
    Map<String, Object?> writeSet,
  ) async {
    final response = await _call(
      () => _client.put(
        _config.path('sets/$setId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(writeSet),
      ),
      'save the set',
    );
    _throwUnlessOk(response, 'save the set');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  /// Puts one score into a set, or changes how it is played, and hands the
  /// entry back as it now reads — including where in the running order it
  /// ended up.
  Future<Map<String, dynamic>> putEntry(
    String setId,
    String entryId,
    String authToken,
    Map<String, Object?> writeEntry,
  ) async {
    final response = await _call(
      () => _client.put(
        _config.path('sets/$setId/entries/$entryId'),
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

  /// Takes one score out of a set. An entry that is already gone is not an
  /// error: what was asked for is the state it is now in.
  Future<void> deleteEntry(
      String setId, String entryId, String authToken) async {
    final response = await _call(
      () => _client.delete(
        _config.path('sets/$setId/entries/$entryId'),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
      'delete the entry',
    );
    if (response.statusCode == 404) {
      return;
    }
    _throwUnlessOk(response, 'delete the entry');
  }

  /// Stores how the caller looks at one entry of a set.
  ///
  /// Anyone who can read the set can write their own view of its entries: it
  /// says nothing about the set and changes nothing anybody else sees, so a
  /// player who cannot change a note of the running order can still say how
  /// they read it.
  Future<Map<String, dynamic>> putEntryView(
    String setId,
    String entryId,
    String authToken,
    Map<String, Object?> writeView,
  ) async {
    final response = await _call(
      () => _client.put(
        _config.path('sets/$setId/entries/$entryId/view'),
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

  /// Marks the set as deleted. A set that was already gone is not an error.
  Future<void> deleteSet(String setId, String authToken) async {
    final response = await _call(
      () => _client.delete(
        _config.path('sets/$setId'),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
      'delete the set',
    );
    if (response.statusCode == 404) {
      return;
    }
    _throwUnlessOk(response, 'delete the set');
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
      throw SetsApiException('failed to $what: $error', null);
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

  throw SetsApiException(
    'failed to $what: ${response.statusCode} ${response.body}',
    response.statusCode,
    problem,
  );
}

String _formatDate(DateTime date) => date.toUtc().toIso8601String();
