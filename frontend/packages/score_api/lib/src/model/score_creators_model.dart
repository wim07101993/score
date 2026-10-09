// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i5;
import 'dart:core' as _i3;

import 'package:collection/collection.dart' as _i4;
import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// Who wrote the score.
@_i2.immutable
class ScoreCreatorsModel extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const ScoreCreatorsModel({required this.composers, required this.lyricists});

  factory ScoreCreatorsModel.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'composers', r'lyricists'},
      listKeys: {r'composers', r'lyricists'},
      context: r'ScoreCreatorsModel',
    );
    return ScoreCreatorsModel(
      composers: _$values[r'composers'].decodeSimpleStringList(
        context: r'ScoreCreatorsModel.composers',
      ),
      lyricists: _$values[r'lyricists'].decodeSimpleStringList(
        context: r'ScoreCreatorsModel.lyricists',
      ),
    );
  }

  factory ScoreCreatorsModel.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'ScoreCreatorsModel');
    return ScoreCreatorsModel(
      composers: _$map[r'composers'].decodeJsonList<_i3.String>(
        context: r'ScoreCreatorsModel.composers',
      ),
      lyricists: _$map[r'lyricists'].decodeJsonList<_i3.String>(
        context: r'ScoreCreatorsModel.lyricists',
      ),
    );
  }

  factory ScoreCreatorsModel.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'composers', r'lyricists'},
      listKeys: {r'composers', r'lyricists'},
      context: r'ScoreCreatorsModel',
    );
    return ScoreCreatorsModel(
      composers: _$values[r'composers'].decodeFormStringList(
        context: r'ScoreCreatorsModel.composers',
      ),
      lyricists: _$values[r'lyricists'].decodeFormStringList(
        context: r'ScoreCreatorsModel.lyricists',
      ),
    );
  }

  /// **Example**:
  /// ```json
  /// [
  ///   "Ludwig van Beethoven"
  /// ]
  /// ```
  final _i3.List<_i3.String> composers;

  /// **Example**:
  /// ```json
  /// [
  ///   "Aloys Jeitteles"
  /// ]
  /// ```
  final _i3.List<_i3.String> lyricists;

  @_i3.override
  _i3.Object? toJson() => {r'composers': composers, r'lyricists': lyricists};

  $$ScoreCreatorsModelCopyWith<ScoreCreatorsModel> get copyWith =>
      _ScoreCreatorsModelCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    const _$deepEquals = _i4.DeepCollectionEquality();
    return other is ScoreCreatorsModel &&
        _$deepEquals.equals(other.composers, this.composers) &&
        _$deepEquals.equals(other.lyricists, this.lyricists);
  }

  @_i3.override
  _i3.int get hashCode {
    const deepEquals = _i4.DeepCollectionEquality();
    return _i3.Object.hashAll([
      deepEquals.hash(composers),
      deepEquals.hash(lyricists),
    ]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    _$result[r'composers'] = _i1.PropertyValue.array(composers);
    _$result[r'lyricists'] = _i1.PropertyValue.array(lyricists);
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
      r'Cannot uriEncode ScoreCreatorsModel: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$ScoreCreatorsModelCopyWith<$Res> {
  factory $$ScoreCreatorsModelCopyWith(ScoreCreatorsModel value) =
      _ScoreCreatorsModelCopyWith<$Res>;

  $Res call({_i3.List<_i3.String>? composers, _i3.List<_i3.String>? lyricists});
  _i3.List<_i3.String> get composers;
  _i3.List<_i3.String> get lyricists;
}

class _ScoreCreatorsModelCopyWith<$Res>
    implements $$ScoreCreatorsModelCopyWith<$Res> {
  _ScoreCreatorsModelCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final ScoreCreatorsModel _value;

  @_i3.override
  _i3.List<_i3.String> get composers => _value.composers;

  @_i3.override
  _i3.List<_i3.String> get lyricists => _value.lyricists;

  @_i3.override
  $Res call({
    _i3.Object? composers = _sentinel,
    _i3.Object? lyricists = _sentinel,
  }) {
    return (ScoreCreatorsModel(
      composers: _i3.identical(composers, _sentinel)
          ? this.composers
          : (composers as _i3.List<_i3.String>),
      lyricists: _i3.identical(lyricists, _sentinel)
          ? this.lyricists
          : (lyricists as _i3.List<_i3.String>),
    ) as $Res);
  }
}
