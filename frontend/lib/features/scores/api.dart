import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:score/api.dart';
import 'package:score/config.dart';

/// The scores endpoints of the API.
///
/// A listing only ever answers with what changed inside a window, which is what
/// keeps a sync small. The consequence is that a score older than the window a
/// client has left to ask about is in no answer a listing will ever give: it
/// has to be asked for by its id, which is what [getScore] is for.
class ScoresApi {
  ScoresApi(
    this._config, {
    http.Client? client,
  })
      : _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  /// The scores that changed within the window.
  Future<List<Map<String, dynamic>>> listScores(
    DateTime? changesSince,
    DateTime? changesUntil,
    String authToken,
  ) async {
    const what = 'list the scores';
    final response = await callTheApi(
      () => _client.get(
        _config.path('scores', {
          'Changes-Since': apiDate(changesSince ?? DateTime.utc(1970)),
          'Changes-Until': apiDate(changesUntil ?? DateTime.now()),
        }),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
      what,
      ScoresApiException.new,
    );
    throwUnlessOk(response, what, ScoresApiException.new);
    return objectsIn(response, what, ScoresApiException.new);
  }

  /// The metadata of one score, asked for by id. `null` when there is nothing
  /// stored under it.
  Future<Map<String, dynamic>?> getScore(String scoreId, String authToken) async {
    const what = 'fetch the score';
    final response = await callTheApi(
      () => _client.get(
        _config.path('scores/$scoreId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ),
      what,
      ScoresApiException.new,
    );
    if (isNotThere(
      response,
      const {'score_not_found'},
      what,
      ScoresApiException.new,
    )) {
      return null;
    }
    throwUnlessOk(response, what, ScoresApiException.new);
    return objectIn(response, what, ScoresApiException.new);
  }

  /// The document itself.
  Future<String> getScoreMusicXml(String scoreId, String authToken) async {
    const what = 'fetch the score';
    final response = await callTheApi(
      () => _client.get(
        _config.path('scores/$scoreId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/vnd.recordare.musicxml',
        },
      ),
      what,
      ScoresApiException.new,
    );
    throwUnlessOk(response, what, ScoresApiException.new);
    // Read as utf-8 rather than as whatever the header happens to say: a
    // MusicXML document says its own encoding, and a score with an umlaut in
    // its title comes back mangled if the body is read as latin-1.
    return utf8.decode(response.bodyBytes);
  }

  Future<void> putScore(
      String scoreId, String authToken, String musicXml) async {
    const what = 'save the score';
    final response = await callTheApi(
      () => _client.put(
        _config.path('scores/$scoreId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/vnd.recordare.musicxml',
        },
        body: utf8.encode(musicXml),
      ),
      what,
      ScoresApiException.new,
    );
    throwUnlessOk(response, what, ScoresApiException.new);
  }

  Future<bool> canBeReached() => apiCanBeReached(_client, _config);
}

/// A call to the scores endpoints that did not come back with what was asked
/// for; see [ApiException].
class ScoresApiException extends ApiException {
  ScoresApiException(
    super.message,
    super.status, [
    super.problem,
  ]);
}
