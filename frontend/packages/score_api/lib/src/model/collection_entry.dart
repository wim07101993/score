// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i5;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:score_api/src/model/entry_view.dart' as _i4;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// One piece as it stands in a collection.
///
/// Everything here but `view` is the same for everyone the collection is shared
/// with: it is what the group does with the piece, and it is the owner's to say.
/// `view` is the caller's own and nobody else's.
///
/// There is no position. Where a piece comes in a collection is not a thing a
/// collection has an answer to, and a number nobody means anything by is a number
/// somebody will end up sorting on.
///
@_i2.immutable
class CollectionEntry extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const CollectionEntry({
    required this.id,
    required this.scoreId,
    required this.description,
    required this.transposition,
    required this.view,
  });

  factory CollectionEntry.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for CollectionEntry: contains complex types',
    );
  }

  factory CollectionEntry.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'CollectionEntry');
    return CollectionEntry(
      id: _$map[r'id'].decodeJsonString(context: r'CollectionEntry.id'),
      scoreId: _$map[r'score_id'].decodeJsonNullableString(
        context: r'CollectionEntry.score_id',
      ),
      description: _$map[r'description'].decodeJsonString(
        context: r'CollectionEntry.description',
      ),
      transposition: _$map[r'transposition'].decodeJsonInt(
        context: r'CollectionEntry.transposition',
      ),
      view: _i4.EntryView.fromJson(_$map[r'view']),
    );
  }

  factory CollectionEntry.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for CollectionEntry: contains complex types',
    );
  }

  /// The id of this entry.
  ///
  /// It belongs to the entry rather than to the score, so that a piece keeps
  /// what has been said about it when the collection is rewritten around it,
  /// and so that the same score can be in a set and in a collection without the
  /// two sharing a key or a reading.
  ///
  /// It is the client's to name — an entry is written at
  /// `/collections/{collectionId}/entries/{entryId}` — and it stays the
  /// entry's for as long as the entry is in the collection, so that what a
  /// player has said about how they look at it keeps pointing at the same
  /// thing. An id that is already an entry of another collection is refused
  /// rather than taken over.
  ///
  final _i3.String id;

  /// The piece, or `null` for one that is in the collection but not in here.
  ///
  /// A score is in a collection at most once: that is the whole of what makes a
  /// collection a collection rather than a set. The pieces that have no score
  /// are outside that rule — half of what is in a book is on paper until
  /// somebody gets round to scanning it, they are told apart by what is written
  /// next to them, and two lines of a book nobody has scanned are two pieces.
  ///
  final _i3.String? scoreId;

  /// Whatever is worth remembering about this one, and the only name it has
  /// when there is no score to take a title from. For a piece with no score it
  /// is therefore never blank: being told apart by it is what puts those pieces
  /// outside the rule above.
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
  /// negative for down. It is the arrangement rather than anyone's own reading
  /// of it: everybody the collection is shared with plays it in this key, and
  /// what one player reads it as on top of that is in their `view`.
  ///
  ///
  /// **Example**:
  /// ```json
  /// -2
  /// ```
  final _i3.int transposition;

  /// How the caller looks at this entry, which is theirs alone.
  final _i4.EntryView view;

  @_i3.override
  _i3.Object? toJson() => {
    r'id': id,
    r'score_id': scoreId,
    r'description': description,
    r'transposition': transposition,
    r'view': view.toJson(),
  };

  $$CollectionEntryCopyWith<CollectionEntry> get copyWith =>
      _CollectionEntryCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is CollectionEntry &&
        other.id == this.id &&
        other.scoreId == this.scoreId &&
        other.description == this.description &&
        other.transposition == this.transposition &&
        other.view == this.view;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([id, scoreId, description, transposition, view]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for CollectionEntry: contains complex types',
  );

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i5.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode CollectionEntry: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$CollectionEntryCopyWith<$Res> {
  factory $$CollectionEntryCopyWith(CollectionEntry value) =
      _CollectionEntryCopyWith<$Res>;

  $Res call({
    _i3.String? id,
    _i3.String? scoreId,
    _i3.String? description,
    _i3.int? transposition,
    _i4.EntryView? view,
  });
  _i3.String get id;
  _i3.String? get scoreId;
  _i3.String get description;
  _i3.int get transposition;
  _i4.EntryView get view;
}

class _CollectionEntryCopyWith<$Res>
    implements $$CollectionEntryCopyWith<$Res> {
  _CollectionEntryCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final CollectionEntry _value;

  @_i3.override
  _i3.String get id => _value.id;

  @_i3.override
  _i3.String? get scoreId => _value.scoreId;

  @_i3.override
  _i3.String get description => _value.description;

  @_i3.override
  _i3.int get transposition => _value.transposition;

  @_i3.override
  _i4.EntryView get view => _value.view;

  @_i3.override
  $Res call({
    _i3.Object? id = _sentinel,
    _i3.Object? scoreId = _sentinel,
    _i3.Object? description = _sentinel,
    _i3.Object? transposition = _sentinel,
    _i3.Object? view = _sentinel,
  }) {
    return (CollectionEntry(
      id: _i3.identical(id, _sentinel) ? this.id : (id as _i3.String),
      scoreId: _i3.identical(scoreId, _sentinel)
          ? this.scoreId
          : (scoreId as _i3.String?),
      description: _i3.identical(description, _sentinel)
          ? this.description
          : (description as _i3.String),
      transposition: _i3.identical(transposition, _sentinel)
          ? this.transposition
          : (transposition as _i3.int),
      view: _i3.identical(view, _sentinel)
          ? this.view
          : (view as _i4.EntryView),
    ) as $Res);
  }
}
