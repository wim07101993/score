// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i2;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/problem_details.dart' as _i3;

sealed class PutScoreResponse {
  const PutScoreResponse();
}

@_i1.immutable
class PutScoreResponse200 extends PutScoreResponse {
  const PutScoreResponse200();

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is PutScoreResponse200;
  }

  @_i2.override
  _i2.int get hashCode => runtimeType.hashCode;
}

@_i1.immutable
class PutScoreResponse400 extends PutScoreResponse {
  const PutScoreResponse400({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is PutScoreResponse400 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutScoreResponse401 extends PutScoreResponse {
  const PutScoreResponse401({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is PutScoreResponse401 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutScoreResponse403 extends PutScoreResponse {
  const PutScoreResponse403({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is PutScoreResponse403 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutScoreResponse413 extends PutScoreResponse {
  const PutScoreResponse413({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is PutScoreResponse413 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutScoreResponse415 extends PutScoreResponse {
  const PutScoreResponse415({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is PutScoreResponse415 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutScoreResponseDefault extends PutScoreResponse {
  const PutScoreResponseDefault({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is PutScoreResponseDefault && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}
