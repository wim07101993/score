// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i4;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// A set or collection that was deleted, as a listing answers it.
///
/// Everything about it is gone but its id and when it went, which is all a
/// client holding a copy needs to drop it.
///
@_i2.immutable
class DeletedResource extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const DeletedResource({required this.id, required this.deletedAt});

  factory DeletedResource.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'id', r'deleted_at'},
      listKeys: {},
      context: r'DeletedResource',
    );
    return DeletedResource(
      id: _$values[r'id'].decodeSimpleString(context: r'DeletedResource.id'),
      deletedAt: _$values[r'deleted_at'].decodeSimpleDateTime(
        context: r'DeletedResource.deleted_at',
      ),
    );
  }

  factory DeletedResource.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'DeletedResource');
    return DeletedResource(
      id: _$map[r'id'].decodeJsonString(context: r'DeletedResource.id'),
      deletedAt: _$map[r'deleted_at'].decodeJsonDateTime(
        context: r'DeletedResource.deleted_at',
      ),
    );
  }

  factory DeletedResource.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'id', r'deleted_at'},
      listKeys: {},
      context: r'DeletedResource',
    );
    return DeletedResource(
      id: _$values[r'id'].decodeFormString(context: r'DeletedResource.id'),
      deletedAt: _$values[r'deleted_at'].decodeFormDateTime(
        context: r'DeletedResource.deleted_at',
      ),
    );
  }

  /// The id the resource was stored under.
  final _i3.String id;

  /// When the resource was deleted.
  final _i3.DateTime deletedAt;

  @_i3.override
  _i3.Object? toJson() => {
    r'id': id,
    r'deleted_at': deletedAt.toTimeZonedIso8601String(),
  };

  $$DeletedResourceCopyWith<DeletedResource> get copyWith =>
      _DeletedResourceCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is DeletedResource &&
        other.id == this.id &&
        other.deletedAt == this.deletedAt;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([id, deletedAt]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    _$result[r'id'] = _i1.PropertyValue.scalar(id);
    _$result[r'deleted_at'] = _i1.PropertyValue.scalar(
      deletedAt.toTimeZonedIso8601String(),
    );
    return _$result;
  }

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i4.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode DeletedResource: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$DeletedResourceCopyWith<$Res> {
  factory $$DeletedResourceCopyWith(DeletedResource value) =
      _DeletedResourceCopyWith<$Res>;

  $Res call({_i3.String? id, _i3.DateTime? deletedAt});
  _i3.String get id;
  _i3.DateTime get deletedAt;
}

class _DeletedResourceCopyWith<$Res>
    implements $$DeletedResourceCopyWith<$Res> {
  _DeletedResourceCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final DeletedResource _value;

  @_i3.override
  _i3.String get id => _value.id;

  @_i3.override
  _i3.DateTime get deletedAt => _value.deletedAt;

  @_i3.override
  $Res call({_i3.Object? id = _sentinel, _i3.Object? deletedAt = _sentinel}) {
    return (DeletedResource(
      id: _i3.identical(id, _sentinel) ? this.id : (id as _i3.String),
      deletedAt: _i3.identical(deletedAt, _sentinel)
          ? this.deletedAt
          : (deletedAt as _i3.DateTime),
    ) as $Res);
  }
}
