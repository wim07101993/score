// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i5;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// A set as the client states it: what the gig is, and who may read it.
///
/// What is played is not here. An entry is a resource of its own, written and
/// taken out one at a time at `/sets/{setId}/entries/{entryId}`, so a set is
/// created empty and filled afterwards. That is what keeps the running order from
/// being restated every time a title is corrected, and what lets a client that
/// added one song send one song.
///
@_i2.immutable
class WriteSet extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const WriteSet({
    required this.title,
    required this.description,
    required this.sharedWith,
  });

  factory WriteSet.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'title', r'description', r'shared_with'},
      listKeys: {r'shared_with'},
      context: r'WriteSet',
    );
    return WriteSet(
      title: _$values[r'title'].decodeSimpleString(context: r'WriteSet.title'),
      description: _$values[r'description'].decodeSimpleString(
        context: r'WriteSet.description',
      ),
      sharedWith: _$values[r'shared_with'].decodeSimpleStringList(
        context: r'WriteSet.shared_with',
      ),
    );
  }

  factory WriteSet.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'WriteSet');
    return WriteSet(
      title: _$map[r'title'].decodeJsonString(context: r'WriteSet.title'),
      description: _$map[r'description'].decodeJsonString(
        context: r'WriteSet.description',
      ),
      sharedWith: _$map[r'shared_with'].decodeJsonList<_i3.String>(
        context: r'WriteSet.shared_with',
      ),
    );
  }

  factory WriteSet.fromForm(_i3.String? value, {required _i3.bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'title', r'description', r'shared_with'},
      listKeys: {r'shared_with'},
      context: r'WriteSet',
    );
    return WriteSet(
      title: _$values[r'title'].decodeFormString(context: r'WriteSet.title'),
      description: _$values[r'description'].decodeFormString(
        context: r'WriteSet.description',
      ),
      sharedWith: _$values[r'shared_with'].decodeFormStringList(
        context: r'WriteSet.shared_with',
      ),
    );
  }

  /// **Example**:
  /// ```
  /// Zomerbar 12 juli
  /// ```
  final _i3.String title;

  final _i3.String description;

  /// The addresses the set should be readable by.
  ///
  /// They are compared in lower case, since an address says nothing about who
  /// it belongs to by the case it was typed in. Anything that is not an
  /// address is refused rather than tidied up, so a share that was going to go
  /// nowhere is said so at the time it is written. The owner's own address is
  /// ignored: they already have the set.
  ///
  ///
  /// **Example**:
  /// ```json
  /// [
  ///   "bas@example.com"
  /// ]
  /// ```
  final _i3.List<_i3.String> sharedWith;

  @_i3.override
  _i3.Object? toJson() => {
    r'title': title,
    r'description': description,
    r'shared_with': sharedWith,
  };

  $$WriteSetCopyWith<WriteSet> get copyWith => _WriteSetCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i4.DeepCollectionEquality();
    return other is WriteSet &&
        other.title == this.title &&
        other.description == this.description &&
        _$deepEquals.equals(other.sharedWith, this.sharedWith);
  }

  @_i3.override
  _i3.int get hashCode {
    const deepEquals = _i4.DeepCollectionEquality();
    return _i3.Object.hashAll([
      title,
      description,
      deepEquals.hash(sharedWith),
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    _$result[r'title'] = _i1.PropertyValue.scalar(title);
    _$result[r'description'] = _i1.PropertyValue.scalar(description);
    _$result[r'shared_with'] = _i1.PropertyValue.array(sharedWith);
    return _$result;
  }

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i5.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode WriteSet: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$WriteSetCopyWith<$Res> {
  factory $$WriteSetCopyWith(WriteSet value) = _WriteSetCopyWith<$Res>;

  $Res call({
    _i3.String? title,
    _i3.String? description,
    _i3.List<_i3.String>? sharedWith,
  });
  _i3.String get title;
  _i3.String get description;
  _i3.List<_i3.String> get sharedWith;
}

class _WriteSetCopyWith<$Res> implements $$WriteSetCopyWith<$Res> {
  _WriteSetCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final WriteSet _value;

  @_i3.override
  _i3.String get title => _value.title;

  @_i3.override
  _i3.String get description => _value.description;

  @_i3.override
  _i3.List<_i3.String> get sharedWith => _value.sharedWith;

  @_i3.override
  $Res call({
    _i3.Object? title = _sentinel,
    _i3.Object? description = _sentinel,
    _i3.Object? sharedWith = _sentinel,
  }) {
    return (WriteSet(
      title: _i3.identical(title, _sentinel)
          ? this.title
          : (title as _i3.String),
      description: _i3.identical(description, _sentinel)
          ? this.description
          : (description as _i3.String),
      sharedWith: _i3.identical(sharedWith, _sentinel)
          ? this.sharedWith
          : (sharedWith as _i3.List<_i3.String>),
    ) as $Res);
  }
}
