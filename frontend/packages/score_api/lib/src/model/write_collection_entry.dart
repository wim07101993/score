// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i4;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// One piece of a collection as the owner of the collection states it.
///
/// It says what the group does with the piece and nothing about how anyone looks
/// at it: a view belongs to a player rather than to a collection, and is written
/// by the player it belongs to at
/// `/collections/{collectionId}/entries/{entryId}/view`. Writing an entry
/// therefore leaves every player's view of it alone, the owner's own included.
///
/// Which entry it is, is in the path rather than here. Where it comes in the
/// collection is nowhere at all: a collection has no order to put a piece in.
///
@_i2.immutable
class WriteCollectionEntry extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const WriteCollectionEntry({
    required this.scoreId,
    required this.description,
    required this.transposition,
  });

  factory WriteCollectionEntry.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'score_id', r'description', r'transposition'},
      listKeys: {},
      context: r'WriteCollectionEntry',
    );
    return WriteCollectionEntry(
      scoreId: _$values[r'score_id'].decodeSimpleString(
        context: r'WriteCollectionEntry.score_id',
      ),
      description: _$values[r'description'].decodeSimpleString(
        context: r'WriteCollectionEntry.description',
      ),
      transposition: _$values[r'transposition'].decodeSimpleInt(
        context: r'WriteCollectionEntry.transposition',
      ),
    );
  }

  factory WriteCollectionEntry.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'WriteCollectionEntry');
    return WriteCollectionEntry(
      scoreId: _$map[r'score_id'].decodeJsonString(
        context: r'WriteCollectionEntry.score_id',
      ),
      description: _$map[r'description'].decodeJsonString(
        context: r'WriteCollectionEntry.description',
      ),
      transposition: _$map[r'transposition'].decodeJsonInt(
        context: r'WriteCollectionEntry.transposition',
      ),
    );
  }

  factory WriteCollectionEntry.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'score_id', r'description', r'transposition'},
      listKeys: {},
      context: r'WriteCollectionEntry',
    );
    return WriteCollectionEntry(
      scoreId: _$values[r'score_id'].decodeFormString(
        context: r'WriteCollectionEntry.score_id',
      ),
      description: _$values[r'description'].decodeFormString(
        context: r'WriteCollectionEntry.description',
      ),
      transposition: _$values[r'transposition'].decodeFormInt(
        context: r'WriteCollectionEntry.transposition',
      ),
    );
  }

  /// The piece.
  ///
  /// A score that is already in this collection under another entry is refused;
  /// a collection holds a piece once. Writing the entry the score is already in
  /// is not that: it is saying what the group does with a piece the collection
  /// already has, which is what an entry is for.
  ///
  final _i3.String scoreId;

  /// Whatever is worth remembering about this one.
  ///
  ///
  /// **Example**:
  /// ```
  /// page 214
  /// ```
  ///
  /// **Example**:
  /// ```
  /// in the red folder
  /// ```
  ///
  /// **Example**:
  /// ```
  /// the arrangement we do
  /// ```
  final _i3.String description;

  /// How far the group plays this one from where it is written, in semitones,
  /// negative for down.
  ///
  ///
  /// **Example**:
  /// ```json
  /// -2
  /// ```
  final _i3.int transposition;

  @_i3.override
  _i3.Object? toJson() => {
    r'score_id': scoreId,
    r'description': description,
    r'transposition': transposition,
  };

  $$WriteCollectionEntryCopyWith<WriteCollectionEntry> get copyWith =>
      _WriteCollectionEntryCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is WriteCollectionEntry &&
        other.scoreId == this.scoreId &&
        other.description == this.description &&
        other.transposition == this.transposition;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([scoreId, description, transposition]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    _$result[r'score_id'] = _i1.PropertyValue.scalar(scoreId);
    _$result[r'description'] = _i1.PropertyValue.scalar(description);
    _$result[r'transposition'] = _i1.PropertyValue.scalar(
      transposition.toString(),
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
      r'Cannot uriEncode WriteCollectionEntry: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$WriteCollectionEntryCopyWith<$Res> {
  factory $$WriteCollectionEntryCopyWith(WriteCollectionEntry value) =
      _WriteCollectionEntryCopyWith<$Res>;

  $Res call({
    _i3.String? scoreId,
    _i3.String? description,
    _i3.int? transposition,
  });
  _i3.String get scoreId;
  _i3.String get description;
  _i3.int get transposition;
}

class _WriteCollectionEntryCopyWith<$Res>
    implements $$WriteCollectionEntryCopyWith<$Res> {
  _WriteCollectionEntryCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final WriteCollectionEntry _value;

  @_i3.override
  _i3.String get scoreId => _value.scoreId;

  @_i3.override
  _i3.String get description => _value.description;

  @_i3.override
  _i3.int get transposition => _value.transposition;

  @_i3.override
  $Res call({
    _i3.Object? scoreId = _sentinel,
    _i3.Object? description = _sentinel,
    _i3.Object? transposition = _sentinel,
  }) {
    return (WriteCollectionEntry(
      scoreId: _i3.identical(scoreId, _sentinel)
          ? this.scoreId
          : (scoreId as _i3.String),
      description: _i3.identical(description, _sentinel)
          ? this.description
          : (description as _i3.String),
      transposition: _i3.identical(transposition, _sentinel)
          ? this.transposition
          : (transposition as _i3.int),
    ) as $Res);
  }
}
