// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i2;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/problem_details.dart' as _i3;

sealed class HealthzResponse {
  const HealthzResponse();
}

@_i1.immutable
class HealthzResponse200 extends HealthzResponse {
  const HealthzResponse200({required this.body});

  final _i2.String body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is HealthzResponse200 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class HealthzResponse4XX extends HealthzResponse {
  const HealthzResponse4XX({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is HealthzResponse4XX && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class HealthzResponseDefault extends HealthzResponse {
  const HealthzResponseDefault({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is HealthzResponseDefault && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}
