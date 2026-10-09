// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i7;
import 'dart:core' as _i3;

import 'package:http/http.dart' as _i5;
import 'package:score_api/src/model/entry_view.dart' as _i8;
import 'package:score_api/src/model/problem_details.dart' as _i9;
import 'package:score_api/src/model/write_entry_view.dart' as _i6;
import 'package:score_api/src/operation/http_operation.dart' as _i1;
import 'package:score_api/src/response_wrapper/put_set_entry_view_response.dart'
    as _i2;
import 'package:tonik_util/tonik_util.dart' as _i4;

final class PutSetEntryView
    extends _i1.HttpOperation<_i2.PutSetEntryViewResponse> {
  PutSetEntryView(super.baseUrl, super.clientAccessor);

  _i3.Future<_i4.TonikResult<_i2.PutSetEntryViewResponse, _i5.Response>> call({
    required _i6.WriteEntryView body,
    required _i3.String setId,
    required _i3.String entryId,
    _i3.String? correlationId,
    _i4.TonikCancellation? cancellation,
  }) {
    return this.execute(
      cancellation: cancellation,
      prepare: () => _i1.HttpOperationRequest(
        method: 'PUT',
        path: _path(setId: setId, entryId: entryId),
        query: null,
        data: _data(body: body),
        options: _options(correlationId: correlationId),
      ),
      decode: _parseResponse,
    );
  }

  _i3.List<_i3.String> _path({
    required _i3.String setId,
    required _i3.String entryId,
  }) {
    return [
      r'sets',
      setId.toSimple(explode: false, allowEmpty: false),
      r'entries',
      entryId.toSimple(explode: false, allowEmpty: false),
      r'view',
    ];
  }

  _i3.Object? _data({required _i6.WriteEntryView body}) {
    return _i7.utf8.encode(_i7.jsonEncode(body.toJson()));
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
    _$headers[r'Content-Type'] = r'application/json';
    return _$headers;
  }

  _i2.PutSetEntryViewResponse _parseResponse(_i5.Response response) {
    final _$mediaType = _i4.extractMediaType(response.headers['content-type']);
    switch ((response.statusCode, _$mediaType)) {
      case (200, r'application/json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i8.EntryView.fromJson(_$json);
        return _i2.PutSetEntryViewResponse200(body: _$body);
      case (400, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i9.ProblemDetails.fromJson(_$json);
        return _i2.PutSetEntryViewResponse400(body: _$body);
      case (401, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i9.ProblemDetails.fromJson(_$json);
        return _i2.PutSetEntryViewResponse401(body: _$body);
      case (403, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i9.ProblemDetails.fromJson(_$json);
        return _i2.PutSetEntryViewResponse403(body: _$body);
      case (404, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i9.ProblemDetails.fromJson(_$json);
        return _i2.PutSetEntryViewResponse404(body: _$body);
      case (413, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i9.ProblemDetails.fromJson(_$json);
        return _i2.PutSetEntryViewResponse413(body: _$body);
      case (415, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i9.ProblemDetails.fromJson(_$json);
        return _i2.PutSetEntryViewResponse415(body: _$body);
      case (_, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i9.ProblemDetails.fromJson(_$json);
        return _i2.PutSetEntryViewResponseDefault(body: _$body);
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
