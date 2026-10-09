// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i6;
import 'dart:core' as _i3;

import 'package:http/http.dart' as _i5;
import 'package:score_api/src/model/collection.dart' as _i7;
import 'package:score_api/src/model/problem_details.dart' as _i8;
import 'package:score_api/src/operation/http_operation.dart' as _i1;
import 'package:score_api/src/response_wrapper/list_collections_response.dart'
    as _i2;
import 'package:tonik_util/tonik_util.dart' as _i4;

final class ListCollections
    extends _i1.HttpOperation<_i2.ListCollectionsResponse> {
  ListCollections(super.baseUrl, super.clientAccessor);

  _i3.Future<_i4.TonikResult<_i2.ListCollectionsResponse, _i5.Response>> call({
    required _i3.DateTime changesSince,
    required _i3.DateTime changesUntil,
    _i3.String? correlationId,
    _i4.TonikCancellation? cancellation,
  }) {
    return this.execute(
      cancellation: cancellation,
      prepare: () => _i1.HttpOperationRequest(
        method: 'GET',
        path: _path(),
        query: _queryParameters(
          changesSince: changesSince,
          changesUntil: changesUntil,
        ),
        data: _data(),
        options: _options(correlationId: correlationId),
      ),
      decode: _parseResponse,
    );
  }

  _i3.List<_i3.String> _path() {
    return [r'collections'];
  }

  _i3.Object? _data() {
    return null;
  }

  _i3.String? _queryParameters({
    required _i3.DateTime changesSince,
    required _i3.DateTime changesUntil,
  }) {
    final _$entries = <_i4.ParameterEntry>[];
    _$entries.addAll(
      changesSince.toForm(
        r'Changes-Since',
        explode: true,
        allowEmpty: false,
        textEncoding: _i6.utf8,
      ),
    );
    _$entries.addAll(
      changesUntil.toForm(
        r'Changes-Until',
        explode: true,
        allowEmpty: false,
        textEncoding: _i6.utf8,
      ),
    );
    if (_$entries.isEmpty) {
      return null;
    }
    return _$entries
        .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
        .join('&');
  }

  _i3.Map<_i3.String, _i3.String> _options({_i3.String? correlationId}) {
    final _$headers = <_i3.String, _i3.String>{};
    _$headers['Accept'] = r'application/json';
    if (correlationId != null) {
      _$headers[r'X-Correlation-ID'] = correlationId.toSimple(
        explode: false,
        allowEmpty: false,
        literal: true,
      );
    }
    return _$headers;
  }

  _i2.ListCollectionsResponse _parseResponse(_i5.Response response) {
    final _$mediaType = _i4.extractMediaType(response.headers['content-type']);
    switch ((response.statusCode, _$mediaType)) {
      case (200, r'application/json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _$json
            .decodeJsonList<_i3.Object?>()
            .map(_i7.Collection.fromJson)
            .toList();
        return _i2.ListCollectionsResponse200(body: _$body);
      case (400, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.ListCollectionsResponse400(body: _$body);
      case (401, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.ListCollectionsResponse401(body: _$body);
      case (403, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.ListCollectionsResponse403(body: _$body);
      case (_, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.ProblemDetails.fromJson(_$json);
        return _i2.ListCollectionsResponseDefault(body: _$body);
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
