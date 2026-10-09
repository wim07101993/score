import 'dart:io';

import 'package:http/http.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/storage/api_exception.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/error_extensions.dart';
import 'package:score_api/score_api.dart' as api;
import 'package:tonik_util/tonik_util.dart';

class const ScoresApi({
  required final ApiClientFactory clientFactory,
}) {
  api.ScoresApi get _api => clientFactory.build(api.ScoresApi.new);

  Future<List<Score>> listScores({
    required DateTime since,
    DateTime? until,
  }) async {
    final result = await _api.listScores(
      changesSince: since,
      changesUntil: until ?? endOfTime,
    );
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.ListScoresResponse200(:final body) =>
          body.map((el) => el.toScore()).toList(growable: false),
        api.ListScoresResponse400(:final body) => throw body.toApiException(),
        api.ListScoresResponse401(:final body) => throw body.toApiException(),
        api.ListScoresResponse403(:final body) => throw body.toApiException(),
        api.ListScoresResponseDefault(:final body) =>
          throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  Future<Score?> getScore(
    String scoreId,
  ) async {
    final result = await _api.getScore(scoreId: scoreId);
    return switch (result) {
      TonikSuccess(:final value) => switch (value) {
        api.GetScoreResponse200(
          body: api.ScoresScoreIdGet200ResponseJson(:final body),
        ) =>
          body.toScore(),
        // Its document rather than its details: asked for with the details'
        // `Accept`, that is not the API answering.
        api.GetScoreResponse200() => throw ApiException.fromUnexpectedResponse(
          response: result.response,
        ),
        api.GetScoreResponse404(:final body)
            when body.errorCode == ErrorCode.scoreNotFound =>
          null,
        api.GetScoreResponse400(:final body) => throw body.toApiException(),
        api.GetScoreResponse401(:final body) => throw body.toApiException(),
        api.GetScoreResponse403(:final body) => throw body.toApiException(),
        api.GetScoreResponse404(:final body) => throw body.toApiException(),
        api.GetScoreResponseDefault(:final body) => throw body.toApiException(),
      },
      TonikError() => throw result.toApiException(),
    };
  }

  /// The document itself. `null` when there is nothing stored under it.
  ///
  /// The one call that is not made through the generated client. The server
  /// answers the address of a score with its document only when that is the
  /// one thing asked for, and asking is an `Accept` header — which a generated
  /// client sets itself, to everything the address can answer with, since the
  /// OpenAPI document cannot describe a header of that name as a parameter.
  Future<String?> getScoreMusicXml(String scoreId) async {
    const musicxmlContentType = 'application/vnd.recordare.musicxml';
    final Response response;
    try {
      response = await clientFactory.get(
        clientFactory.config.path('scores/$scoreId'),
        headers: {HttpHeaders.acceptHeader: musicxmlContentType},
      );
    } catch (error) {
      if (!isNetworkFailure(error)) rethrow;
      throw ApiException.fromSendError(error: error);
    }

    if (response.statusCode == HttpStatus.notFound &&
        response.problem?.errorCode == ErrorCode.scoreNotFound) {
      return null;
    }

    final contentType = response.headers[HttpHeaders.contentTypeHeader];
    if (response.statusCode == HttpStatus.ok &&
        contentType == musicxmlContentType) {
      return response.body;
    }

    throw response.problem?.toApiException() ??
        ApiException.fromUnexpectedResponse(response: response);
  }

  Future<void> putScore(
    String scoreId,
    String musicXml,
  ) async {
    final result = await _api.putScore(
      scoreId: scoreId,
      body: api.ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxml(musicXml),
    );
    switch (result) {
      case TonikSuccess(:final value):
        switch (value) {
          case api.PutScoreResponse200():
            return;
          case api.PutScoreResponse400(:final body):
            throw body.toApiException();
          case api.PutScoreResponse401(:final body):
            throw body.toApiException();
          case api.PutScoreResponse403(:final body):
            throw body.toApiException();
          case api.PutScoreResponse413(:final body):
            throw body.toApiException();
          case api.PutScoreResponse415(:final body):
            throw body.toApiException();
          case api.PutScoreResponseDefault(:final body):
            throw body.toApiException();
        }
      case TonikError():
        throw result.toApiException();
    }
  }

  Future<bool> canBeReached() => clientFactory.canBeReached();
}

extension on api.Score {
  Score toScore() => Score(
    id: id,
    work: Work(title: work.title, number: work.number),
    movement: Movement(title: movement.title, number: movement.number),
    creators: Creators(
      composers: creators.composers,
      lyricists: creators.lyricists,
    ),
    languages: languages,
    instruments: instruments,
    lastChangedAt: lastChangedAt,
    tags: tags,
  );
}
