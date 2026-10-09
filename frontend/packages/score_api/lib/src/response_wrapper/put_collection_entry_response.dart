// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i1;
import 'package:score_api/src/model/collection_entry.dart' as _i2;
import 'package:score_api/src/model/problem_details.dart' as _i4;

sealed class PutCollectionEntryResponse {
  const PutCollectionEntryResponse();
}

@_i1.immutable
class PutCollectionEntryResponse200 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse200({required this.body});

  final _i2.CollectionEntry body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse200 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponse400 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse400({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse400 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponse401 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse401({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse401 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponse403 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse403({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse403 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponse404 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse404({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse404 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponse409 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse409({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse409 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponse413 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse413({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse413 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponse415 extends PutCollectionEntryResponse {
  const PutCollectionEntryResponse415({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponse415 && other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}

@_i1.immutable
class PutCollectionEntryResponseDefault extends PutCollectionEntryResponse {
  const PutCollectionEntryResponseDefault({required this.body});

  final _i4.ProblemDetails body;

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is PutCollectionEntryResponseDefault &&
        other.body == this.body;
  }

  @_i3.override
  _i3.int get hashCode => body.hashCode;
}
