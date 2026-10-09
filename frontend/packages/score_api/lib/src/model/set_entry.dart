// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i5;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:score_api/src/model/entry_view.dart' as _i4;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// One score as it is played at one point in a gig.
///
/// Everything here but `view` is the same for everyone the set is shared with:
/// it is what the band does, and it is the owner's to say. `view` is the
/// caller's own and nobody else's.
///
@_i2.immutable
class SetEntry extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const SetEntry({
    required this.id,
    required this.position,
    required this.scoreId,
    required this.description,
    required this.transposition,
    required this.view,
  });

  factory SetEntry.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for SetEntry: contains complex types',
    );
  }

  factory SetEntry.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'SetEntry');
    return SetEntry(
      id: _$map[r'id'].decodeJsonString(context: r'SetEntry.id'),
      position: _$map[r'position'].decodeJsonInt(context: r'SetEntry.position'),
      scoreId: _$map[r'score_id'].decodeJsonNullableString(
        context: r'SetEntry.score_id',
      ),
      description: _$map[r'description'].decodeJsonString(
        context: r'SetEntry.description',
      ),
      transposition: _$map[r'transposition'].decodeJsonInt(
        context: r'SetEntry.transposition',
      ),
      view: _i4.EntryView.fromJson(_$map[r'view']),
    );
  }

  factory SetEntry.fromForm(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for SetEntry: contains complex types',
    );
  }

  /// The id of this entry.
  ///
  /// It belongs to the entry rather than to the score, because the same score
  /// may be played more than once in a gig, each time with its own key and its
  /// own note next to it.
  ///
  /// It is the client's to name — an entry is written at
  /// `/sets/{setId}/entries/{entryId}` — and it stays the entry's for as long
  /// as the entry is in the set, so that what a player has said about how they
  /// look at it keeps pointing at the same thing. An id that is already an
  /// entry of another set is refused rather than taken over.
  ///
  final _i3.String id;

  /// Where in the running order this one is played, counting from zero.
  ///
  /// The entries of a set come back in playing order, so this says nothing the
  /// order does not; it is here for a client holding one entry on its own,
  /// which the order of a list it is not looking at cannot tell.
  ///
  ///
  /// **Example**:
  /// ```json
  /// 3
  /// ```
  final _i3.int position;

  /// The score that is played, or `null` for a song that has none.
  ///
  /// Half of what a band plays is on paper, in a folder, on a stand. An entry
  /// without a score is that: what is played and where in the gig it comes,
  /// with nothing to open. It is called by its `description`, which is the
  /// only thing there is to go by when there is no score to take a title from.
  ///
  final _i3.String? scoreId;

  /// Whatever the player needs to remember about this one.
  ///
  ///
  /// **Example**:
  /// ```
  /// capo 2
  /// ```
  ///
  /// **Example**:
  /// ```
  /// second verse only
  /// ```
  ///
  /// **Example**:
  /// ```
  /// straight into the next
  /// ```
  final _i3.String description;

  /// How far the band plays this one from where it is written, in semitones,
  /// negative for down. It is the arrangement rather than anyone's own reading
  /// of it: everybody the set is shared with plays it in this key, and what
  /// one player reads it as on top of that is in their `view`.
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
    r'position': position,
    r'score_id': scoreId,
    r'description': description,
    r'transposition': transposition,
    r'view': view.toJson(),
  };

  $$SetEntryCopyWith<SetEntry> get copyWith => _SetEntryCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is SetEntry &&
        other.id == this.id &&
        other.position == this.position &&
        other.scoreId == this.scoreId &&
        other.description == this.description &&
        other.transposition == this.transposition &&
        other.view == this.view;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([
      id,
      position,
      scoreId,
      description,
      transposition,
      view,
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for SetEntry: contains complex types',
  );

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i5.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode SetEntry: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$SetEntryCopyWith<$Res> {
  factory $$SetEntryCopyWith(SetEntry value) = _SetEntryCopyWith<$Res>;

  $Res call({
    _i3.String? id,
    _i3.int? position,
    _i3.String? scoreId,
    _i3.String? description,
    _i3.int? transposition,
    _i4.EntryView? view,
  });
  _i3.String get id;
  _i3.int get position;
  _i3.String? get scoreId;
  _i3.String get description;
  _i3.int get transposition;
  _i4.EntryView get view;
}

class _SetEntryCopyWith<$Res> implements $$SetEntryCopyWith<$Res> {
  _SetEntryCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final SetEntry _value;

  @_i3.override
  _i3.String get id => _value.id;

  @_i3.override
  _i3.int get position => _value.position;

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
    _i3.Object? position = _sentinel,
    _i3.Object? scoreId = _sentinel,
    _i3.Object? description = _sentinel,
    _i3.Object? transposition = _sentinel,
    _i3.Object? view = _sentinel,
  }) {
    return (SetEntry(
      id: _i3.identical(id, _sentinel) ? this.id : (id as _i3.String),
      position: _i3.identical(position, _sentinel)
          ? this.position
          : (position as _i3.int),
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
