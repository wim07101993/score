// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i5;

import 'package:http/http.dart' as _i8;
import 'package:score_api/src/operation/get_score.dart' as _i3;
import 'package:score_api/src/operation/list_scores.dart' as _i2;
import 'package:score_api/src/operation/put_score.dart' as _i4;
import 'package:score_api/src/request_body/scores_score_id_put_body_request_body.dart'
    as _i11;
import 'package:score_api/src/response_wrapper/get_score_response.dart' as _i9;
import 'package:score_api/src/response_wrapper/list_scores_response.dart'
    as _i7;
import 'package:score_api/src/response_wrapper/put_score_response.dart' as _i10;
import 'package:score_api/src/server/server.dart' as _i1;
import 'package:tonik_util/tonik_util.dart' as _i6;

/// Sheet music and the metadata extracted from it.
class ScoresApi {
  ScoresApi(_i1.Server server)
    : _listScores = _i2.ListScores(server.baseUrl, () => server.client),
      _getScore = _i3.GetScore(server.baseUrl, () => server.client),
      _putScore = _i4.PutScore(server.baseUrl, () => server.client);

  final _i2.ListScores _listScores;

  final _i3.GetScore _getScore;

  final _i4.PutScore _putScore;

  /// List the scores that changed within a window.
  /// Returns the metadata of every score whose last change falls within the
  /// given window, most recently changed first. Both ends of the window are
  /// inclusive and both are required: a client synchronises by asking for
  /// everything since the moment it last asked.
  ///
  /// Requires the `score_viewer` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [changesSince] The start of the change window, inclusive.
  /// [changesUntil] The end of the change window, inclusive.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  ///
  /// Parameter examples:
  /// [changesSince]:
  /// **Example**:
  /// ```
  /// 2024-01-01T00:00:00Z
  /// ```
  ///
  /// [changesUntil]:
  /// **Example**:
  /// ```
  /// 2024-01-01T00:00:00Z
  /// ```
  _i5.Future<_i6.TonikResult<_i7.ListScoresResponse, _i8.Response>> listScores({
    required _i5.DateTime changesSince,
    required _i5.DateTime changesUntil,
    _i5.String? correlationId,
    _i6.TonikCancellation? cancellation,
  }) async => _listScores(
    changesSince: changesSince,
    changesUntil: changesUntil,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Fetch a single score.
  /// Returns either the metadata of the score or the MusicXML document it was
  /// extracted from, whichever the `Accept` header asks for. Anything that is
  /// not one of the MusicXML media types is answered with the JSON metadata.
  ///
  /// Requires the `score_viewer` role for both representations: the document
  /// is not a way around the role check that protects the metadata.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [scoreId] The id the score is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i5.Future<_i6.TonikResult<_i9.GetScoreResponse, _i8.Response>> getScore({
    required _i5.String scoreId,
    _i5.String? correlationId,
    _i6.TonikCancellation? cancellation,
  }) async => _getScore(
    scoreId: scoreId,
    correlationId: correlationId,
    cancellation: cancellation,
  );

  /// Add or replace a score.
  /// Stores the MusicXML document under the given id, replacing whatever was
  /// stored under it before, and extracts the metadata the scores are listed
  /// by. A document that is not MusicXML, or that carries something the
  /// server cannot store such as an unknown instrument, is rejected whole:
  /// nothing of it is left behind.
  ///
  /// Requires the `score_editor` role.
  ///
  ///
  /// Security:
  /// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
  /// `Authorization: Bearer {token}`.
  ///
  ///   Required scopes: score_viewer, score_editor
  /// [scoreId] The id the score is stored under.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  _i5.Future<_i6.TonikResult<_i10.PutScoreResponse, _i8.Response>> putScore({
    required _i11.ScoresScoreIdPutBodyRequestBody body,
    required _i5.String scoreId,
    _i5.String? correlationId,
    _i6.TonikCancellation? cancellation,
  }) async => _putScore(
    body: body,
    scoreId: scoreId,
    correlationId: correlationId,
    cancellation: cancellation,
  );
}
