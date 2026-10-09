// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/get_collections_response.dart' as _i2;
import 'package:score_api/src/model/problem_details.dart' as _i4;

sealed class ListCollectionsResponse {
  const ListCollectionsResponse();
}

@_i1.immutable
class ListCollectionsResponse200 extends ListCollectionsResponse {
  const ListCollectionsResponse200({required this.body});

  final _i2.GetCollectionsResponse body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListCollectionsResponse200 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListCollectionsResponse400 extends ListCollectionsResponse {
  const ListCollectionsResponse400({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListCollectionsResponse400 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListCollectionsResponse401 extends ListCollectionsResponse {
  const ListCollectionsResponse401({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListCollectionsResponse401 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListCollectionsResponse403 extends ListCollectionsResponse {
  const ListCollectionsResponse403({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListCollectionsResponse403 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListCollectionsResponseDefault extends ListCollectionsResponse {
  const ListCollectionsResponseDefault({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListCollectionsResponseDefault && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}
