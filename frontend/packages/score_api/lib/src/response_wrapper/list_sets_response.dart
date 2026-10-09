// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/get_sets_response.dart' as _i2;
import 'package:score_api/src/model/problem_details.dart' as _i4;

sealed class ListSetsResponse {
  const ListSetsResponse();
}

@_i1.immutable
class ListSetsResponse200 extends ListSetsResponse {
  const ListSetsResponse200({required this.body});

  final _i2.GetSetsResponse body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListSetsResponse200 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListSetsResponse400 extends ListSetsResponse {
  const ListSetsResponse400({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListSetsResponse400 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListSetsResponse401 extends ListSetsResponse {
  const ListSetsResponse401({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListSetsResponse401 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListSetsResponse403 extends ListSetsResponse {
  const ListSetsResponse403({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListSetsResponse403 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListSetsResponseDefault extends ListSetsResponse {
  const ListSetsResponseDefault({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListSetsResponseDefault && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}
