// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/get_scores_response.dart' as _i2;
import 'package:score_api/src/model/problem_details.dart' as _i4;

sealed class ListScoresResponse {
  const ListScoresResponse();
}

@_i1.immutable
class ListScoresResponse200 extends ListScoresResponse {
  const ListScoresResponse200({required this.body});

  final _i2.GetScoresResponse body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListScoresResponse200 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListScoresResponse400 extends ListScoresResponse {
  const ListScoresResponse400({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListScoresResponse400 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListScoresResponse401 extends ListScoresResponse {
  const ListScoresResponse401({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListScoresResponse401 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListScoresResponse403 extends ListScoresResponse {
  const ListScoresResponse403({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListScoresResponse403 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class ListScoresResponseDefault extends ListScoresResponse {
  const ListScoresResponseDefault({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ListScoresResponseDefault && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}
