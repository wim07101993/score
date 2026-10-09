// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i2;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/problem_details.dart' as _i3;

sealed class DeleteCollectionResponse {
  const DeleteCollectionResponse();
}

@_i1.immutable
class DeleteCollectionResponse204 extends DeleteCollectionResponse {
  const DeleteCollectionResponse204();

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionResponse204;
  }

  @_i2.override
  _i2.int get hashCode => runtimeType.hashCode;
}

@_i1.immutable
class DeleteCollectionResponse400 extends DeleteCollectionResponse {
  const DeleteCollectionResponse400({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionResponse400 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionResponse401 extends DeleteCollectionResponse {
  const DeleteCollectionResponse401({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionResponse401 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionResponse403 extends DeleteCollectionResponse {
  const DeleteCollectionResponse403({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionResponse403 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionResponse404 extends DeleteCollectionResponse {
  const DeleteCollectionResponse404({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionResponse404 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionResponseDefault extends DeleteCollectionResponse {
  const DeleteCollectionResponseDefault({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionResponseDefault && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}
