// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i4;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// One score as it is played at one point in a gig, as the owner of the set
/// states it.
///
/// It says what the band does and nothing about how anyone looks at it: a view
/// belongs to a player rather than to a set, and is written by the player it
/// belongs to at `/sets/{setId}/entries/{entryId}/view`. Writing an entry
/// therefore leaves every player's view of it alone, the owner's own included.
///
/// Which entry it is, is in the path rather than here.
///
@_i2.immutable
class WriteSetEntry extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const WriteSetEntry({
    required this.scoreId,
    required this.description,
    required this.transposition,
    required this.position,
  });

  factory WriteSetEntry.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {
        r'score_id',
        r'description',
        r'transposition',
        r'position',
      },
      listKeys: {},
      context: r'WriteSetEntry',
    );
    return WriteSetEntry(
      scoreId: _$values[r'score_id'].decodeSimpleNullableString(
        context: r'WriteSetEntry.score_id',
      ),
      description: _$values[r'description'].decodeSimpleString(
        context: r'WriteSetEntry.description',
      ),
      transposition: _$values[r'transposition'].decodeSimpleInt(
        context: r'WriteSetEntry.transposition',
      ),
      position: _$values[r'position'].decodeSimpleInt(
        context: r'WriteSetEntry.position',
      ),
    );
  }

  factory WriteSetEntry.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'WriteSetEntry');
    return WriteSetEntry(
      scoreId: _$map[r'score_id'].decodeJsonNullableString(
        context: r'WriteSetEntry.score_id',
      ),
      description: _$map[r'description'].decodeJsonString(
        context: r'WriteSetEntry.description',
      ),
      transposition: _$map[r'transposition'].decodeJsonInt(
        context: r'WriteSetEntry.transposition',
      ),
      position: _$map[r'position'].decodeJsonInt(
        context: r'WriteSetEntry.position',
      ),
    );
  }

  factory WriteSetEntry.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {
        r'score_id',
        r'description',
        r'transposition',
        r'position',
      },
      listKeys: {},
      context: r'WriteSetEntry',
    );
    return WriteSetEntry(
      scoreId: _$values[r'score_id'].decodeFormNullableString(
        context: r'WriteSetEntry.score_id',
      ),
      description: _$values[r'description'].decodeFormString(
        context: r'WriteSetEntry.description',
      ),
      transposition: _$values[r'transposition'].decodeFormInt(
        context: r'WriteSetEntry.transposition',
      ),
      position: _$values[r'position'].decodeFormInt(
        context: r'WriteSetEntry.position',
      ),
    );
  }

  /// The score that is played, or `null` for a song that has none — one that
  /// is on paper rather than in here. Such an entry is called by its
  /// `description`.
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
  /// negative for down.
  ///
  ///
  /// **Example**:
  /// ```json
  /// -2
  /// ```
  final _i3.int transposition;

  /// Where in the running order it is played, counting from zero.
  ///
  /// The set is closed up around it: an entry written at a place the set
  /// already has an entry in puts that one and everything after it back by
  /// one, and an entry that is already in the set and is written at another
  /// place moves there, with everything between shifting to make room. What
  /// the rest are numbered afterwards is the server's, and it is always
  /// nought upwards with no gaps.
  ///
  /// A place beyond the end of the set is the end of the set rather than a
  /// refusal. A client whose idea of the set is a little out of date — one
  /// catching up after a gig it spent offline — is saying where this song
  /// goes, and the nearest place it can go is a better answer to that than a
  /// rejected write.
  ///
  ///
  /// **Example**:
  /// ```json
  /// 3
  /// ```
  final _i3.int position;

  @_i3.override
  _i3.Object? toJson() => {
    r'score_id': scoreId,
    r'description': description,
    r'transposition': transposition,
    r'position': position,
  };

  $$WriteSetEntryCopyWith<WriteSetEntry> get copyWith =>
      _WriteSetEntryCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is WriteSetEntry &&
        other.scoreId == this.scoreId &&
        other.description == this.description &&
        other.transposition == this.transposition &&
        other.position == this.position;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([scoreId, description, transposition, position]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    if (scoreId != null) {
      _$result[r'score_id'] = _i1.PropertyValue.scalar(scoreId!);
    }
    _$result[r'description'] = _i1.PropertyValue.scalar(description);
    _$result[r'transposition'] = _i1.PropertyValue.scalar(
      transposition.toString(),
    );
    _$result[r'position'] = _i1.PropertyValue.scalar(position.toString());
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
      r'Cannot uriEncode WriteSetEntry: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$WriteSetEntryCopyWith<$Res> {
  factory $$WriteSetEntryCopyWith(WriteSetEntry value) =
      _WriteSetEntryCopyWith<$Res>;

  $Res call({
    _i3.String? scoreId,
    _i3.String? description,
    _i3.int? transposition,
    _i3.int? position,
  });
  _i3.String? get scoreId;
  _i3.String get description;
  _i3.int get transposition;
  _i3.int get position;
}

class _WriteSetEntryCopyWith<$Res> implements $$WriteSetEntryCopyWith<$Res> {
  _WriteSetEntryCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final WriteSetEntry _value;

  @_i3.override
  _i3.String? get scoreId => _value.scoreId;

  @_i3.override
  _i3.String get description => _value.description;

  @_i3.override
  _i3.int get transposition => _value.transposition;

  @_i3.override
  _i3.int get position => _value.position;

  @_i3.override
  $Res call({
    _i3.Object? scoreId = _sentinel,
    _i3.Object? description = _sentinel,
    _i3.Object? transposition = _sentinel,
    _i3.Object? position = _sentinel,
  }) {
    return (WriteSetEntry(
      scoreId: _i3.identical(scoreId, _sentinel)
          ? this.scoreId
          : (scoreId as _i3.String?),
      description: _i3.identical(description, _sentinel)
          ? this.description
          : (description as _i3.String),
      transposition: _i3.identical(transposition, _sentinel)
          ? this.transposition
          : (transposition as _i3.int),
      position: _i3.identical(position, _sentinel)
          ? this.position
          : (position as _i3.int),
    ) as $Res);
  }
}
