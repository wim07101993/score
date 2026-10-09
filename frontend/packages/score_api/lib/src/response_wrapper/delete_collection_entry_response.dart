// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i2;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/problem_details.dart' as _i3;

sealed class DeleteCollectionEntryResponse {
  const DeleteCollectionEntryResponse();
}

@_i1.immutable
class DeleteCollectionEntryResponse204 extends DeleteCollectionEntryResponse {
  const DeleteCollectionEntryResponse204();

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionEntryResponse204;
  }

  @_i2.override
  _i2.int get hashCode => runtimeType.hashCode;
}

@_i1.immutable
class DeleteCollectionEntryResponse400 extends DeleteCollectionEntryResponse {
  const DeleteCollectionEntryResponse400({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionEntryResponse400 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionEntryResponse401 extends DeleteCollectionEntryResponse {
  const DeleteCollectionEntryResponse401({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionEntryResponse401 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionEntryResponse403 extends DeleteCollectionEntryResponse {
  const DeleteCollectionEntryResponse403({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionEntryResponse403 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionEntryResponse404 extends DeleteCollectionEntryResponse {
  const DeleteCollectionEntryResponse404({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionEntryResponse404 && other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}

@_i1.immutable
class DeleteCollectionEntryResponseDefault
    extends DeleteCollectionEntryResponse {
  const DeleteCollectionEntryResponseDefault({required this.body});

  final _i3.ProblemDetails body;

  @_i2.override
  _i2.bool operator ==(_i2.Object other) {
    if (_i2.identical(this, other)) return true;
    return other is DeleteCollectionEntryResponseDefault &&
        other.body == this.body;
  }

  @_i2.override
  _i2.int get hashCode => body.hashCode;
}
