// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i5;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// A collection as the client states it: what the group of pieces is, and who may
/// read it.
///
/// What is in it is not here. An entry is a resource of its own, written and
/// taken out one at a time at
/// `/collections/{collectionId}/entries/{entryId}`, so a collection is created
/// empty and filled afterwards. That is what keeps the whole of a book from being
/// restated every time a title is corrected, and what lets a client that added
/// one piece send one piece.
///
@_i2.immutable
class WriteCollection extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const WriteCollection({
    required this.title,
    required this.description,
    required this.sharedWith,
  });

  factory WriteCollection.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'title', r'description', r'shared_with'},
      listKeys: {r'shared_with'},
      context: r'WriteCollection',
    );
    return WriteCollection(
      title: _$values[r'title'].decodeSimpleString(
        context: r'WriteCollection.title',
      ),
      description: _$values[r'description'].decodeSimpleString(
        context: r'WriteCollection.description',
      ),
      sharedWith: _$values[r'shared_with'].decodeSimpleStringList(
        context: r'WriteCollection.shared_with',
      ),
    );
  }

  factory WriteCollection.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'WriteCollection');
    return WriteCollection(
      title: _$map[r'title'].decodeJsonString(
        context: r'WriteCollection.title',
      ),
      description: _$map[r'description'].decodeJsonString(
        context: r'WriteCollection.description',
      ),
      sharedWith: _$map[r'shared_with'].decodeJsonList<_i3.String>(
        context: r'WriteCollection.shared_with',
      ),
    );
  }

  factory WriteCollection.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'title', r'description', r'shared_with'},
      listKeys: {r'shared_with'},
      context: r'WriteCollection',
    );
    return WriteCollection(
      title: _$values[r'title'].decodeFormString(
        context: r'WriteCollection.title',
      ),
      description: _$values[r'description'].decodeFormString(
        context: r'WriteCollection.description',
      ),
      sharedWith: _$values[r'shared_with'].decodeFormStringList(
        context: r'WriteCollection.shared_with',
      ),
    );
  }

  /// **Example**:
  /// ```
  /// The Real Book
  /// ```
  ///
  /// **Example**:
  /// ```
  /// vol. 1
  /// ```
  final _i3.String title;

  final _i3.String description;

  /// The addresses the collection should be readable by.
  ///
  /// They are compared in lower case, since an address says nothing about who
  /// it belongs to by the case it was typed in. Anything that is not an address
  /// is refused rather than tidied up, so a share that was going to go nowhere
  /// is said so at the time it is written. The owner's own address is ignored:
  /// they already have the collection.
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

  $$WriteCollectionCopyWith<WriteCollection> get copyWith =>
      _WriteCollectionCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i4.DeepCollectionEquality();
    return other is WriteCollection &&
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
      r'Cannot uriEncode WriteCollection: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$WriteCollectionCopyWith<$Res> {
  factory $$WriteCollectionCopyWith(WriteCollection value) =
      _WriteCollectionCopyWith<$Res>;

  $Res call({
    _i3.String? title,
    _i3.String? description,
    _i3.List<_i3.String>? sharedWith,
  });
  _i3.String get title;
  _i3.String get description;
  _i3.List<_i3.String> get sharedWith;
}

class _WriteCollectionCopyWith<$Res>
    implements $$WriteCollectionCopyWith<$Res> {
  _WriteCollectionCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final WriteCollection _value;

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
    return (WriteCollection(
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
