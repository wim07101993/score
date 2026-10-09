// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i6;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i5;
import 'package:meta/meta.dart' as _i2;
import 'package:score_api/src/model/problem_details_error_code_model.dart'
    as _i4;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// What went wrong, in the shape
/// [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) gives a failure.
///
@_i2.immutable
class ProblemDetails extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const ProblemDetails({
    required this.$type,
    required this.title,
    required this.status,
    required this.detail,
    required this.instance,
    required this.errorCode,
    this.entryId,
    this.additionalProperties = const {},
  });

  factory ProblemDetails.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {
        r'type',
        r'title',
        r'status',
        r'detail',
        r'instance',
        r'errorCode',
        r'entryId',
      },
      listKeys: {},
      context: r'ProblemDetails',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {
      r'type',
      r'title',
      r'status',
      r'detail',
      r'instance',
      r'errorCode',
      r'entryId',
    };
    final _$additional = <_i3.String, _i3.Object?>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value;
      }
    }
    return ProblemDetails(
      $type: _$values[r'type'].decodeSimpleString(
        context: r'ProblemDetails.type',
      ),
      title: _$values[r'title'].decodeSimpleString(
        context: r'ProblemDetails.title',
      ),
      status: _$values[r'status'].decodeSimpleInt(
        context: r'ProblemDetails.status',
      ),
      detail: _$values[r'detail'].decodeSimpleString(
        context: r'ProblemDetails.detail',
      ),
      instance: _$values[r'instance'].decodeSimpleString(
        context: r'ProblemDetails.instance',
      ),
      errorCode: _i4.ProblemDetailsErrorCodeModel.fromSimple(
        _$values[r'errorCode'],
        explode: explode,
      ),
      entryId: _$values[r'entryId'].decodeSimpleNullableString(
        context: r'ProblemDetails.entryId',
      ),
      additionalProperties: _$additional,
    );
  }

  factory ProblemDetails.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'ProblemDetails');
    const _$knownKeys = {
      r'type',
      r'title',
      r'status',
      r'detail',
      r'instance',
      r'errorCode',
      r'entryId',
    };
    final _$additional = <_i3.String, _i3.Object?>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value;
      }
    }
    return ProblemDetails(
      $type: _$map[r'type'].decodeJsonString(context: r'ProblemDetails.type'),
      title: _$map[r'title'].decodeJsonString(context: r'ProblemDetails.title'),
      status: _$map[r'status'].decodeJsonInt(context: r'ProblemDetails.status'),
      detail: _$map[r'detail'].decodeJsonString(
        context: r'ProblemDetails.detail',
      ),
      instance: _$map[r'instance'].decodeJsonString(
        context: r'ProblemDetails.instance',
      ),
      errorCode: _i4.ProblemDetailsErrorCodeModel.fromJson(_$map[r'errorCode']),
      entryId: _$map[r'entryId'].decodeJsonNullableString(
        context: r'ProblemDetails.entryId',
      ),
      additionalProperties: _$additional,
    );
  }

  factory ProblemDetails.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {
        r'type',
        r'title',
        r'status',
        r'detail',
        r'instance',
        r'errorCode',
        r'entryId',
      },
      listKeys: {},
      context: r'ProblemDetails',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {
      r'type',
      r'title',
      r'status',
      r'detail',
      r'instance',
      r'errorCode',
      r'entryId',
    };
    final _$additional = <_i3.String, _i3.Object?>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeFormString(
          context: r'ProblemDetails.additionalProperties',
        );
      }
    }
    return ProblemDetails(
      $type: _$values[r'type'].decodeFormString(
        context: r'ProblemDetails.type',
      ),
      title: _$values[r'title'].decodeFormString(
        context: r'ProblemDetails.title',
      ),
      status: _$values[r'status'].decodeFormInt(
        context: r'ProblemDetails.status',
      ),
      detail: _$values[r'detail'].decodeFormString(
        context: r'ProblemDetails.detail',
      ),
      instance: _$values[r'instance'].decodeFormString(
        context: r'ProblemDetails.instance',
      ),
      errorCode: _i4.ProblemDetailsErrorCodeModel.fromForm(
        _$values[r'errorCode'],
        explode: explode,
      ),
      entryId: _$values[r'entryId'].decodeFormNullableString(
        context: r'ProblemDetails.entryId',
      ),
      additionalProperties: _$additional,
    );
  }

  /// What kind of failure this is, as a URI reference. `about:blank` when the
  /// failure is no more than its status code, which is all this server tells
  /// apart so far.
  ///
  ///
  /// **Example**:
  /// ```
  /// about:blank
  /// ```
  final _i3.String $type;

  /// What the kind of failure is called. The same for every failure of a kind,
  /// so that it can be shown to a human without reading the detail. With a
  /// `type` of `about:blank`, RFC 9457 asks for the status code's own name.
  ///
  ///
  /// **Example**:
  /// ```
  /// Not Found
  /// ```
  final _i3.String title;

  /// The http status code of the answer, repeated here so that the body stands
  /// on its own once it has been passed on by something that dropped the rest
  /// of the response.
  ///
  ///
  /// **Example**:
  /// ```json
  /// 404
  /// ```
  final _i3.int status;

  /// What went wrong with this request in particular, meant for a human. It
  /// says nothing the caller is not allowed to know: what went wrong inside the
  /// server belongs in its log, not in the answer.
  ///
  ///
  /// **Example**:
  /// ```
  /// no score found with the given id
  /// ```
  final _i3.String detail;

  /// Which occurrence of the problem this was, as a URI reference: the
  /// correlation id of the request that failed, written as a URN. It is what
  /// the server logged the failure under, so quoting it back is enough to find
  /// out what happened inside.
  ///
  ///
  /// **Example**:
  /// ```
  /// urn:uuid:5f6a2f1e-9b3c-4a7d-8e21-0c1d2e3f4a5b
  /// ```
  final _i3.String instance;

  /// A code on which an application can act. This is a machine readable code,
  /// not meant to display to an end-user, but can be used to show a translated
  /// error message.
  ///
  /// It is what a caller should branch on. `status` says how the request
  /// failed in the terms http has, and `detail` says it in the terms a
  /// developer reading a log has; neither is stable enough to switch on. This
  /// is: the set below only ever grows, and a code is never given a new
  /// meaning.
  ///
  ///
  /// **Example**:
  /// ```
  /// score_not_found
  /// ```
  final _i4.ProblemDetailsErrorCodeModel errorCode;

  /// An extension member, only on `score_already_in_collection`: the entry the
  /// collection already holds the score in, so that a client can point at that
  /// one rather than put the score in again.
  ///
  ///
  /// **Example**:
  /// ```
  /// 0b5c3a8e-2f4d-4e6a-9c1b-7d8e9f0a1b2c
  /// ```
  final _i3.String? entryId;

  final _i3.Map<_i3.String, _i3.Object?> additionalProperties;

  @_i3.override
  _i3.Object? toJson() {
    final _$map = <_i3.String, _i3.Object?>{
      r'type': $type,
      r'title': title,
      r'status': status,
      r'detail': detail,
      r'instance': instance,
      r'errorCode': errorCode.toJson(),
      if (entryId != null) r'entryId': entryId,
    };
    const _$knownKeys = {
      r'type',
      r'title',
      r'status',
      r'detail',
      r'instance',
      r'errorCode',
      r'entryId',
    };
    for (final _$k in additionalProperties.keys) {
      if (_$knownKeys.contains(_$k)) {
        throw _i1.EncodingException(
          r'Additional property keys must not collide with declared wire keys of ProblemDetails',
        );
      }
    }
    _$map.addAll(
      additionalProperties.map(
        (k, v) => _i3.MapEntry(
          k,
          _i1.encodeUnknownJson(
            v,
            context: r'ProblemDetails.additionalProperties',
          ),
        ),
      ),
    );
    return _$map;
  }

  $$ProblemDetailsCopyWith<ProblemDetails> get copyWith =>
      _ProblemDetailsCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i5.DeepCollectionEquality();
    return other is ProblemDetails &&
        other.$type == this.$type &&
        other.title == this.title &&
        other.status == this.status &&
        other.detail == this.detail &&
        other.instance == this.instance &&
        other.errorCode == this.errorCode &&
        other.entryId == this.entryId &&
        _$deepEquals.equals(
          other.additionalProperties,
          this.additionalProperties,
        );
  }

  @_i3.override
  _i3.int get hashCode {
    const deepEquals = _i5.DeepCollectionEquality();
    return _i3.Object.hashAll([
      $type,
      title,
      status,
      detail,
      instance,
      errorCode,
      entryId,
      deepEquals.hash(additionalProperties),
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    _$result[r'type'] = _i1.PropertyValue.scalar($type);
    _$result[r'title'] = _i1.PropertyValue.scalar(title);
    _$result[r'status'] = _i1.PropertyValue.scalar(status.toString());
    _$result[r'detail'] = _i1.PropertyValue.scalar(detail);
    _$result[r'instance'] = _i1.PropertyValue.scalar(instance);
    _$result[r'errorCode'] = _i1.PropertyValue.scalar(errorCode.toJson());
    if (entryId != null) {
      _$result[r'entryId'] = _i1.PropertyValue.scalar(entryId!);
    }
    const _$knownKeys = {
      r'type',
      r'title',
      r'status',
      r'detail',
      r'instance',
      r'errorCode',
      r'entryId',
    };
    for (final _$e in additionalProperties.entries) {
      if (_$knownKeys.contains(_$e.key)) {
        throw _i1.EncodingException(
          r'Additional property keys must not collide with declared wire keys of ProblemDetails',
        );
      }
      final _$v = _$e.value;
      if (_$v == null) continue;
      _$result[_$e.key] = _i1.PropertyValue.scalar(
        _i1.encodeUnknownFlatScalar(
          _$v,
          context: r'ProblemDetails.additionalProperties',
        ),
      );
    }
    return _$result;
  }

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i6.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode ProblemDetails: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$ProblemDetailsCopyWith<$Res> {
  factory $$ProblemDetailsCopyWith(ProblemDetails value) =
      _ProblemDetailsCopyWith<$Res>;

  $Res call({
    _i3.String? $type,
    _i3.String? title,
    _i3.int? status,
    _i3.String? detail,
    _i3.String? instance,
    _i4.ProblemDetailsErrorCodeModel? errorCode,
    _i3.String? entryId,
    _i3.Map<_i3.String, _i3.Object?>? additionalProperties,
  });
  _i3.String get $type;
  _i3.String get title;
  _i3.int get status;
  _i3.String get detail;
  _i3.String get instance;
  _i4.ProblemDetailsErrorCodeModel get errorCode;
  _i3.String? get entryId;
  _i3.Map<_i3.String, _i3.Object?> get additionalProperties;
}

class _ProblemDetailsCopyWith<$Res> implements $$ProblemDetailsCopyWith<$Res> {
  _ProblemDetailsCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final ProblemDetails _value;

  @_i3.override
  _i3.String get $type => _value.$type;

  @_i3.override
  _i3.String get title => _value.title;

  @_i3.override
  _i3.int get status => _value.status;

  @_i3.override
  _i3.String get detail => _value.detail;

  @_i3.override
  _i3.String get instance => _value.instance;

  @_i3.override
  _i4.ProblemDetailsErrorCodeModel get errorCode => _value.errorCode;

  @_i3.override
  _i3.String? get entryId => _value.entryId;

  @_i3.override
  _i3.Map<_i3.String, _i3.Object?> get additionalProperties =>
      _value.additionalProperties;

  @_i3.override
  $Res call({
    _i3.Object? $type = _sentinel,
    _i3.Object? title = _sentinel,
    _i3.Object? status = _sentinel,
    _i3.Object? detail = _sentinel,
    _i3.Object? instance = _sentinel,
    _i3.Object? errorCode = _sentinel,
    _i3.Object? entryId = _sentinel,
    _i3.Object? additionalProperties = _sentinel,
  }) {
    return (ProblemDetails(
      $type: _i3.identical($type, _sentinel)
          ? this.$type
          : ($type as _i3.String),
      title: _i3.identical(title, _sentinel)
          ? this.title
          : (title as _i3.String),
      status: _i3.identical(status, _sentinel)
          ? this.status
          : (status as _i3.int),
      detail: _i3.identical(detail, _sentinel)
          ? this.detail
          : (detail as _i3.String),
      instance: _i3.identical(instance, _sentinel)
          ? this.instance
          : (instance as _i3.String),
      errorCode: _i3.identical(errorCode, _sentinel)
          ? this.errorCode
          : (errorCode as _i4.ProblemDetailsErrorCodeModel),
      entryId: _i3.identical(entryId, _sentinel)
          ? this.entryId
          : (entryId as _i3.String?),
      additionalProperties: _i3.identical(additionalProperties, _sentinel)
          ? this.additionalProperties
          : (additionalProperties as _i3.Map<_i3.String, _i3.Object?>),
    ) as $Res);
  }
}
