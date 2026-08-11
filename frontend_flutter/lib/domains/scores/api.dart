import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';

/// The scores endpoints of the API.
///
/// A listing only ever answers with what changed inside a window, which is what
/// keeps a sync small. The consequence is that a score older than the window a
/// client has left to ask about is in no answer a listing will ever give: it
/// has to be asked for by its id, which is what [getScore] is for.
class ScoresApi {
  ScoresApi(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  /// The scores that changed within the window.
  Future<List<Map<String, dynamic>>> listScores(
    DateTime? changesSince,
    DateTime? changesUntil,
    String authToken,
  ) async {
    final response = await _client.get(
      _config.path('scores', {
        'Changes-Since': _formatDate(changesSince ?? DateTime.utc(1970)),
        'Changes-Until': _formatDate(changesUntil ?? DateTime.now()),
      }),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    _throwUnlessOk(response, 'list the scores');
    return [
      for (final score in jsonDecode(response.body) as List)
        (score as Map).cast<String, dynamic>(),
    ];
  }

  /// The metadata of one score, asked for by id. `null` when there is nothing
  /// stored under it.
  Future<Map<String, dynamic>?> getScore(String scoreId, String authToken) async {
    final response = await _client.get(
      _config.path('scores/$scoreId'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 404) {
      return null;
    }
    _throwUnlessOk(response, 'fetch the score');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  /// The document itself.
  Future<String> getScoreMusicXml(String scoreId, String authToken) async {
    final response = await _client.get(
      _config.path('scores/$scoreId'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/vnd.recordare.musicxml',
      },
    );
    _throwUnlessOk(response, 'fetch the score');
    // Read as utf-8 rather than as whatever the header happens to say: a
    // MusicXML document says its own encoding, and a score with an umlaut in
    // its title comes back mangled if the body is read as latin-1.
    return utf8.decode(response.bodyBytes);
  }

  Future<void> putScore(
      String scoreId, String authToken, String musicXml) async {
    final response = await _client.put(
      _config.path('scores/$scoreId'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/vnd.recordare.musicxml',
      },
      body: utf8.encode(musicXml),
    );
    _throwUnlessOk(response, 'save the score');
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
}

class ScoresApiException implements Exception {
  ScoresApiException(this.message, this.status);

  final String message;
  final int? status;

  @override
  String toString() => message;
}

void _throwUnlessOk(http.Response response, String what) {
  if (response.statusCode < 400) {
    return;
  }
  throw ScoresApiException(
    'failed to $what: ${response.statusCode} ${response.body}',
    response.statusCode,
  );
}

/// Writes a moment the way the API reads it: RFC 3339, in UTC, keeping the
/// milliseconds, so that a window ends exactly where it was asked to and
/// nothing that changed inside the second it was asked about falls outside it.
String _formatDate(DateTime date) => date.toUtc().toIso8601String();
