// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:http/http.dart' as _i5;
import 'package:score_api/src/model/problem_details.dart' as _i6;
import 'package:score_api/src/operation/http_operation.dart' as _i1;
import 'package:score_api/src/response_wrapper/healthz_response.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i4;

final class Healthz extends _i1.HttpOperation<_i2.HealthzResponse> {
  Healthz(super.baseUrl, super.clientAccessor);

  _i3.Future<_i4.TonikResult<_i2.HealthzResponse, _i5.Response>> call({
    _i3.String? correlationId,
    _i4.TonikCancellation? cancellation,
  }) {
    return this.execute(
      cancellation: cancellation,
      prepare: () => _i1.HttpOperationRequest(
        method: 'GET',
        path: _path(),
        query: null,
        data: _data(),
        options: _options(correlationId: correlationId),
      ),
      decode: _parseResponse,
    );
  }

  _i3.List<_i3.String> _path() {
    return [r'healthz'];
  }

  _i3.Object? _data() {
    return null;
  }

  _i3.Map<_i3.String, _i3.String> _options({_i3.String? correlationId}) {
    final _$headers = <_i3.String, _i3.String>{};
    _$headers['Accept'] = r'text/plain,application/json';
    if (correlationId != null) {
      _$headers[r'X-Correlation-ID'] = correlationId.toSimple(
        explode: false,
        allowEmpty: false,
        literal: true,
      );
    }
    return _$headers;
  }

  _i2.HealthzResponse _parseResponse(_i5.Response response) {
    final _$mediaType = _i4.extractMediaType(response.headers['content-type']);
    switch ((response.statusCode, _$mediaType)) {
      case (200, r'text/plain'):
        final _$body = _i4.decodeResponseText(
          response.bodyBytes,
          contentType: response.headers['content-type'],
        );
        return _i2.HealthzResponse200(body: _$body);
      case (var status, r'application/json')
          when status >= 400 && status <= 499:
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i6.ProblemDetails.fromJson(_$json);
        return _i2.HealthzResponse4XX(body: _$body);
      case (_, r'application/problem+json'):
        final _$json = _i4.decodeResponseJson<_i3.Object?>(response.bodyBytes);
        final _$body = _i6.ProblemDetails.fromJson(_$json);
        return _i2.HealthzResponseDefault(body: _$body);
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
