// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i2;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/problem_details.dart' as _i3;

sealed class DeleteSetResponse {
  const DeleteSetResponse();
}

@_i1.immutable
class DeleteSetResponse204 extends DeleteSetResponse {
  const DeleteSetResponse204();

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetResponse204;
  }

  @_i2.override
  _i2.int get hashCode => runtimeType.hashCode;
}

@_i1.immutable
class DeleteSetResponse400 extends DeleteSetResponse {
  const DeleteSetResponse400({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetResponse400 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetResponse401 extends DeleteSetResponse {
  const DeleteSetResponse401({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetResponse401 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetResponse403 extends DeleteSetResponse {
  const DeleteSetResponse403({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetResponse403 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetResponse404 extends DeleteSetResponse {
  const DeleteSetResponse404({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetResponse404 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetResponseDefault extends DeleteSetResponse {
  const DeleteSetResponseDefault({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetResponseDefault && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}
