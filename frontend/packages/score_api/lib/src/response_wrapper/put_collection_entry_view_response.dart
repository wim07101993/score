// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/entry_view.dart' as _i2;
import 'package:score_api/src/model/problem_details.dart' as _i4;

sealed class PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse();
}

@_i1.immutable
class PutCollectionEntryViewResponse200 extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse200({required this.body});

  final _i2.EntryView body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponse200 &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryViewResponse400 extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse400({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponse400 &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryViewResponse401 extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse401({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponse401 &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryViewResponse403 extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse403({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponse403 &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryViewResponse404 extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse404({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponse404 &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryViewResponse413 extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse413({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponse413 &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryViewResponse415 extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponse415({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponse415 &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryViewResponseDefault
    extends PutCollectionEntryViewResponse {
  const PutCollectionEntryViewResponseDefault({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryViewResponseDefault &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}
