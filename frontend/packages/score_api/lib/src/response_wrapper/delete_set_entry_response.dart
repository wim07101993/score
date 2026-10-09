// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i2;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/problem_details.dart' as _i3;

sealed class DeleteSetEntryResponse {
  const DeleteSetEntryResponse();
}

@_i1.immutable
class DeleteSetEntryResponse204 extends DeleteSetEntryResponse {
  const DeleteSetEntryResponse204();

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetEntryResponse204;
  }

  @_i2.override
  _i2.int get hashCode => runtimeType.hashCode;
}

@_i1.immutable
class DeleteSetEntryResponse400 extends DeleteSetEntryResponse {
  const DeleteSetEntryResponse400({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetEntryResponse400 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetEntryResponse401 extends DeleteSetEntryResponse {
  const DeleteSetEntryResponse401({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetEntryResponse401 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetEntryResponse403 extends DeleteSetEntryResponse {
  const DeleteSetEntryResponse403({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetEntryResponse403 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetEntryResponse404 extends DeleteSetEntryResponse {
  const DeleteSetEntryResponse404({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetEntryResponse404 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteSetEntryResponseDefault extends DeleteSetEntryResponse {
  const DeleteSetEntryResponseDefault({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteSetEntryResponseDefault && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}
