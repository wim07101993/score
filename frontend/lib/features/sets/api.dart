import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:score/api.dart';
import 'package:score/config.dart';

/// The sets endpoints of the API.
///
/// Unlike the scores endpoints, these are written to as well as read from, and
/// a write is made from an edit that was already accepted and stored on this
/// device. So a failure has to say more than that it failed: whether the write
/// is worth trying again decides between keeping the edit queued and giving it
/// up, and that is what [SetsApiException] carries.

/// A call to the sets endpoints that did not come back with what was asked
/// for; see [ApiException].
class SetsApiException extends ApiException {
  SetsApiException(
    super.message,
    super.status, [
    super.problem,
  ]);

  /// The set belongs to someone else, and waiting does not change whose it is.
  @override
  String get notTheOwnersCode => 'not_set_owner';
}

class SetsApi {
  SetsApi(
    this._config, {
    http.Client? client,
  })
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
    const what = 'list the sets';
    final response = await callTheApi(
      () => _client.get(
        _config.path('sets', {
          'Changes-Since': apiDate(changesSince ?? DateTime.utc(1970)),
          'Changes-Until': apiDate(changesUntil ?? DateTime.now()),
        }),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      what,
      SetsApiException.new,
    );
    throwUnlessOk(response, what, SetsApiException.new);
    return objectsIn(response, what, SetsApiException.new);
  }

  /// One set, asked for by id. `null` when there is no such set, or when it is
  /// neither the caller's nor shared with them.
  Future<Map<String, dynamic>?> getSet(String setId, String authToken) async {
    const what = 'fetch the set';
    final response = await callTheApi(
      () => _client.get(
        _config.path('sets/$setId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      what,
      SetsApiException.new,
    );
    if (isNotThere(
      response,
      const {'set_not_found'},
      what,
      SetsApiException.new,
    )) {
      return null;
    }
    throwUnlessOk(response, what, SetsApiException.new);
    return objectIn(response, what, SetsApiException.new);
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
  ) =>
      _write('sets/$setId', authToken, writeSet, 'save the set');

  /// Puts one score into a set, or changes how it is played, and hands the
  /// entry back as it now reads — including where in the running order it
  /// ended up.
  Future<Map<String, dynamic>> putEntry(
    String setId,
    String entryId,
    String authToken,
    Map<String, Object?> writeEntry,
  ) =>
      _write('sets/$setId/entries/$entryId', authToken, writeEntry,
          'save the entry');

  /// Takes one score out of a set. An entry that is already gone is not an
  /// error: what was asked for is the state it is now in.
  Future<void> deleteEntry(String setId, String entryId, String authToken) =>
      _delete('sets/$setId/entries/$entryId', authToken, 'delete the entry');

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
  ) =>
      _write('sets/$setId/entries/$entryId/view', authToken, writeView,
          'save the view');

  /// Marks the set as deleted. A set that was already gone is not an error.
  Future<void> deleteSet(String setId, String authToken) =>
      _delete('sets/$setId', authToken, 'delete the set');

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
      SetsApiException.new,
    );
    throwUnlessOk(response, what, SetsApiException.new);
    return objectIn(response, what, SetsApiException.new);
  }

  Future<void> _delete(String path, String authToken, String what) async {
    final response = await callTheApi(
      () => _client.delete(
        _config.path(path),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
      what,
      SetsApiException.new,
    );
    if (isNotThere(
      response,
      const {'set_not_found', 'set_entry_not_found'},
      what,
      SetsApiException.new,
    )) {
      return;
    }
    throwUnlessOk(response, what, SetsApiException.new);
  }
}
