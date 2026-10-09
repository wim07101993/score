// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/problem_details.dart' as _i4;
import 'package:score_api/src/model/set_entry.dart' as _i2;

sealed class PutSetEntryResponse {
  const PutSetEntryResponse();
}

@_i1.immutable
class PutSetEntryResponse200 extends PutSetEntryResponse {
  const PutSetEntryResponse200({required this.body});

  final _i2.SetEntry body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponse200 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutSetEntryResponse400 extends PutSetEntryResponse {
  const PutSetEntryResponse400({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponse400 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutSetEntryResponse401 extends PutSetEntryResponse {
  const PutSetEntryResponse401({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponse401 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutSetEntryResponse403 extends PutSetEntryResponse {
  const PutSetEntryResponse403({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponse403 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutSetEntryResponse404 extends PutSetEntryResponse {
  const PutSetEntryResponse404({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponse404 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutSetEntryResponse413 extends PutSetEntryResponse {
  const PutSetEntryResponse413({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponse413 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutSetEntryResponse415 extends PutSetEntryResponse {
  const PutSetEntryResponse415({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponse415 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutSetEntryResponseDefault extends PutSetEntryResponse {
  const PutSetEntryResponseDefault({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutSetEntryResponseDefault && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}
