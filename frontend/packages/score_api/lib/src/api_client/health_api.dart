// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:http/http.dart' as _i6;
import 'package:score_api/src/operation/healthz.dart' as _i2;
import 'package:score_api/src/response_wrapper/healthz_response.dart' as _i5;
import 'package:score_api/src/server/server.dart' as _i1;
import 'package:tonik_util/tonik_util.dart' as _i4;

/// Whether the server is up.
class HealthApi {
  HealthApi(_i1.Server server)
    : _healthz = _i2.Healthz(server.baseUrl, () => server.client);

  final _i2.Healthz _healthz;

  /// Whether the server is up.
  /// Answers `OK` as long as the server is serving. Public.
  /// [correlationId] An id a caller ties its own requests together with. The server logs the
  /// request under it and answers a failure with it as the `instance` of the
  /// problem, so that reporting a failure is enough to find it. A caller that
  /// sends nothing, or sends something that is not a uuid, is given one.
  ///
  ///
  /// Response 200 (text/plain):
  /// **Example** "ok" — Server is healthy:
  /// ```
  /// ok
  /// ```
  ///
  /// **Example** "fail" — Server is not healthy:
  /// ```
  /// fail
  /// ```
  _i3.Future<_i4.TonikResult<_i5.HealthzResponse, _i6.Response>> healthz({
    _i3.String? correlationId,
    _i4.TonikCancellation? cancellation,
  }) async =>
      _healthz(correlationId: correlationId, cancellation: cancellation);
}
