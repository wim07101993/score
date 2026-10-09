// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i8;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i7;
import 'package:meta/meta.dart' as _i2;
import 'package:score_api/src/model/score_creators_model.dart' as _i6;
import 'package:score_api/src/model/score_movement_model.dart' as _i5;
import 'package:score_api/src/model/score_work_model.dart' as _i4;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// The metadata of a score, extracted from its MusicXML document.
@_i2.immutable
class Score extends _i1.ObjectParameterEncodable implements _i1.UriEncodable {
  const Score({
    required this.id,
    required this.work,
    required this.movement,
    required this.creators,
    required this.languages,
    required this.instruments,
    required this.lastChangedAt,
    required this.tags,
  });

  factory Score.fromSimple(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.SimpleDecodingException(
      r'Simple encoding not supported for Score: contains complex types',
    );
  }

  factory Score.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'Score');
    return Score(
      id: _$map[r'id'].decodeJsonString(context: r'Score.id'),
      work: _i4.ScoreWorkModel.fromJson(_$map[r'work']),
      movement: _i5.ScoreMovementModel.fromJson(_$map[r'movement']),
      creators: _i6.ScoreCreatorsModel.fromJson(_$map[r'creators']),
      languages: _$map[r'languages'].decodeJsonList<_i3.String>(
        context: r'Score.languages',
      ),
      instruments: _$map[r'instruments'].decodeJsonList<_i3.String>(
        context: r'Score.instruments',
      ),
      lastChangedAt: _$map[r'last_changed_at'].decodeJsonDateTime(
        context: r'Score.last_changed_at',
      ),
      tags: _$map[r'tags'].decodeJsonList<_i3.String>(context: r'Score.tags'),
    );
  }

  factory Score.fromForm(_i3.String? value, {required _i3.bool explode}) {
    throw _i1.FormDecodingException(
      r'Form encoding not supported for Score: contains complex types',
    );
  }

  /// The id the score was stored under.
  final _i3.String id;

  /// The work the score is part of. Empty strings when the document names none.
  final _i4.ScoreWorkModel work;

  /// The movement within the work. Empty strings when the document names none.
  final _i5.ScoreMovementModel movement;

  /// Who wrote the score.
  final _i6.ScoreCreatorsModel creators;

  /// The languages of the lyrics.
  ///
  /// **Example**:
  /// ```json
  /// [
  ///   "nl"
  /// ]
  /// ```
  final _i3.List<_i3.String> languages;

  /// The instruments the score is written for.
  ///
  /// **Example**:
  /// ```json
  /// [
  ///   "voice.vocals",
  ///   "keyboard.piano"
  /// ]
  /// ```
  final _i3.List<_i3.String> instruments;

  /// When the score was last uploaded.
  final _i3.DateTime lastChangedAt;

  /// The tags the score is filed under.
  final _i3.List<_i3.String> tags;

  @_i3.override
  _i3.Object? toJson() => {
    r'id': id,
    r'work': work.toJson(),
    r'movement': movement.toJson(),
    r'creators': creators.toJson(),
    r'languages': languages,
    r'instruments': instruments,
    r'last_changed_at': lastChangedAt.toTimeZonedIso8601String(),
    r'tags': tags,
  };

  $$ScoreCopyWith<Score> get copyWith => _ScoreCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i7.DeepCollectionEquality();
    return other is Score &&
        other.id == this.id &&
        other.work == this.work &&
        other.movement == this.movement &&
        other.creators == this.creators &&
        _$deepEquals.equals(other.languages, this.languages) &&
        _$deepEquals.equals(other.instruments, this.instruments) &&
        other.lastChangedAt == this.lastChangedAt &&
        _$deepEquals.equals(other.tags, this.tags);
  }

  @_i3.override
  _i3.int get hashCode {
    const deepEquals = _i7.DeepCollectionEquality();
    return _i3.Object.hashAll([
      id,
      work,
      movement,
      creators,
      deepEquals.hash(languages),
      deepEquals.hash(instruments),
      lastChangedAt,
      deepEquals.hash(tags),
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) => throw _i1.EncodingException(
    r'parameterProperties not supported for Score: contains complex types',
  );

  @_i3.override
  _i3.String uriEncode({
    required _i3.bool allowEmpty,
    required _i8.Encoding textEncoding,
    _i3.bool useQueryComponent = false,
    _i3.bool allowReserved = false,
  }) {
    throw _i1.EncodingException(
      r'Cannot uriEncode Score: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$ScoreCopyWith<$Res> {
  factory $$ScoreCopyWith(Score value) = _ScoreCopyWith<$Res>;

  $Res call({
    _i3.String? id,
    _i4.ScoreWorkModel? work,
    _i5.ScoreMovementModel? movement,
    _i6.ScoreCreatorsModel? creators,
    _i3.List<_i3.String>? languages,
    _i3.List<_i3.String>? instruments,
    _i3.DateTime? lastChangedAt,
    _i3.List<_i3.String>? tags,
  });
  _i3.String get id;
  _i4.ScoreWorkModel get work;
  _i5.ScoreMovementModel get movement;
  _i6.ScoreCreatorsModel get creators;
  _i3.List<_i3.String> get languages;
  _i3.List<_i3.String> get instruments;
  _i3.DateTime get lastChangedAt;
  _i3.List<_i3.String> get tags;
}

class _ScoreCopyWith<$Res> implements $$ScoreCopyWith<$Res> {
  _ScoreCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final Score _value;

  @_i3.override
  _i3.String get id => _value.id;

  @_i3.override
  _i4.ScoreWorkModel get work => _value.work;

  @_i3.override
  _i5.ScoreMovementModel get movement => _value.movement;

  @_i3.override
  _i6.ScoreCreatorsModel get creators => _value.creators;

  @_i3.override
  _i3.List<_i3.String> get languages => _value.languages;

  @_i3.override
  _i3.List<_i3.String> get instruments => _value.instruments;

  @_i3.override
  _i3.DateTime get lastChangedAt => _value.lastChangedAt;

  @_i3.override
  _i3.List<_i3.String> get tags => _value.tags;

  @_i3.override
  $Res call({
    _i3.Object? id = _sentinel,
    _i3.Object? work = _sentinel,
    _i3.Object? movement = _sentinel,
    _i3.Object? creators = _sentinel,
    _i3.Object? languages = _sentinel,
    _i3.Object? instruments = _sentinel,
    _i3.Object? lastChangedAt = _sentinel,
    _i3.Object? tags = _sentinel,
  }) {
    return (Score(
      id: _i3.identical(id, _sentinel) ? this.id : (id as _i3.String),
      work: _i3.identical(work, _sentinel)
          ? this.work
          : (work as _i4.ScoreWorkModel),
      movement: _i3.identical(movement, _sentinel)
          ? this.movement
          : (movement as _i5.ScoreMovementModel),
      creators: _i3.identical(creators, _sentinel)
          ? this.creators
          : (creators as _i6.ScoreCreatorsModel),
      languages: _i3.identical(languages, _sentinel)
          ? this.languages
          : (languages as _i3.List<_i3.String>),
      instruments: _i3.identical(instruments, _sentinel)
          ? this.instruments
          : (instruments as _i3.List<_i3.String>),
      lastChangedAt: _i3.identical(lastChangedAt, _sentinel)
          ? this.lastChangedAt
          : (lastChangedAt as _i3.DateTime),
      tags: _i3.identical(tags, _sentinel)
          ? this.tags
          : (tags as _i3.List<_i3.String>),
    ) as $Res);
  }
}
