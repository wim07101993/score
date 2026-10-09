// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i7;
import 'dart:core' as _i3;

import 'package:http/http.dart' as _i5;
import 'package:score_api/src/model/problem_details.dart' as _i8;
import 'package:score_api/src/operation/http_operation.dart' as _i1;
import 'package:score_api/src/request_body/scores_score_id_put_body_request_body.dart'
    as _i6;
import 'package:score_api/src/response_wrapper/put_score_response.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i4;

final class PutScore extends _i1.HttpOperation<_i2.PutScoreResponse> {
  PutScore(super.baseUrl, super.clientAccessor);

  _i3.Future<_i4.TonikResult<_i2.PutScoreResponse, _i5.Response>> call({
    required _i6.ScoresScoreIdPutBodyRequestBody body,
    required _i3.String scoreId,
    _i3.String? correlationId,
    _i4.TonikCancellation? cancellation,
  }) {
    return this.execute(
      cancellation: cancellation,
      prepare: () => _i1.HttpOperationRequest(
        method: 'PUT',
        path: _path(scoreId: scoreId),
        query: null,
        data: _data(body: body),
        options: _options(correlationId: correlationId, body: body),
      ),
      decode: _parseResponse,
    );
  }

  _i3.List<_i3.String> _path({required _i3.String scoreId}) {
    return [r'scores', scoreId.toSimple(explode: false, allowEmpty: false)];
  }

  _i3.Object? _data({required _i6.ScoresScoreIdPutBodyRequestBody body}) {
    return switch (body) {
      final _i6.ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxml value =>
        _i7.utf8.encode(value.value),
      final _i6.ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxmlXml value =>
        _i7.utf8.encode(value.value),
    };
  }

  _i3.Map<_i3.String, _i3.String> _options({
    required _i6.ScoresScoreIdPutBodyRequestBody body,
    _i3.String? correlationId,
  }) {
    final _$contentType = switch (body) {
      _i6.ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxml _ =>
        r'application/vnd.recordare.musicxml',

      _i6.ScoresScoreIdPutBodyRequestBodyVndRecordareMusicxmlXml _ =>
        r'application/vnd.recordare.musicxml+xml',
    };
    final _$headers = <_i3.String, _i3.String>{};
    _$headers['Accept'] = r'*/*';
    if (correlationId != null) {
      _$headers[r'X-Correlation-ID'] = correlationId.toSimple(
        explode: false,
        allowEmpty: false,
        literal: true,
      );
    }
    _$headers[r'Content-Type'] = _$contentType;
    return _$headers;
  }

  _i2.PutScoreResponse _parseResponse(_i5.Response response) {
    final _$mediaType = _i4.extractMediaType(response.headers['content-type']);
    switch ((response.statusCode, _$mediaType)) {
      case (200, _):
        return _i2.PutScoreResponse200();
      case (400, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.PutScoreResponse400(body: _$body);
      case (401, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.PutScoreResponse401(body: _$body);
      case (403, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.PutScoreResponse403(body: _$body);
      case (413, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.PutScoreResponse413(body: _$body);
      case (415, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.PutScoreResponse415(body: _$body);
      case (_, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.PutScoreResponseDefault(body: _$body);
      default:
        final _$content = response.headers['content-type'] ?? 'not specified';
        final _$matched = _$mediaType ?? 'none';
        final _$status = response.statusCode;
        throw _i4.ResponseDecodingException(
          'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
        );
    }
  }
}
