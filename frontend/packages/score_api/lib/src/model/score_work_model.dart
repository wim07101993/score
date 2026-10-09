// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i4;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// The work the score is part of. Empty strings when the document names none.
@_i2.immutable
class ScoreWorkModel extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const ScoreWorkModel({required this.title, required this.number});

  factory ScoreWorkModel.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'title', r'number'},
      listKeys: {},
      context: r'ScoreWorkModel',
    );
    return ScoreWorkModel(
      title: _$values[r'title'].decodeSimpleString(
        context: r'ScoreWorkModel.title',
      ),
      number: _$values[r'number'].decodeSimpleString(
        context: r'ScoreWorkModel.number',
      ),
    );
  }

  factory ScoreWorkModel.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'ScoreWorkModel');
    return ScoreWorkModel(
      title: _$map[r'title'].decodeJsonString(context: r'ScoreWorkModel.title'),
      number: _$map[r'number'].decodeJsonString(
        context: r'ScoreWorkModel.number',
      ),
    );
  }

  factory ScoreWorkModel.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'title', r'number'},
      listKeys: {},
      context: r'ScoreWorkModel',
    );
    return ScoreWorkModel(
      title: _$values[r'title'].decodeFormString(
        context: r'ScoreWorkModel.title',
      ),
      number: _$values[r'number'].decodeFormString(
        context: r'ScoreWorkModel.number',
      ),
    );
  }

  /// **Example**:
  /// ```
  /// An die ferne Geliebte
  /// ```
  final _i3.String title;

  /// **Example**:
  /// ```
  /// Op. 98
  /// ```
  final _i3.String number;

  @_i3.override
  _i3.Object? toJson() => {r'title': title, r'number': number};

  $$ScoreWorkModelCopyWith<ScoreWorkModel> get copyWith =>
      _ScoreWorkModelCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ScoreWorkModel &&
        other.title == this.title &&
        other.number == this.number;
  }

  @_i3.override
  _i3.int get hashCode {
    return _i3.Object.hashAll([title, number]);
  }

  _i1.EncodingShape get currentEncodingShape => _i1.EncodingShape.complex;

  @_i3.override
  _i3.Map<_i3.String, _i1.PropertyValue> parameterProperties({
    _i3.bool allowEmpty = true,
  }) {
    final _$result = <_i3.String, _i1.PropertyValue>{};
    _$result[r'title'] = _i1.PropertyValue.scalar(title);
    _$result[r'number'] = _i1.PropertyValue.scalar(number);
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
      r'Cannot uriEncode ScoreWorkModel: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$ScoreWorkModelCopyWith<$Res> {
  factory $$ScoreWorkModelCopyWith(ScoreWorkModel value) =
      _ScoreWorkModelCopyWith<$Res>;

  $Res call({_i3.String? title, _i3.String? number});
  _i3.String get title;
  _i3.String get number;
}

class _ScoreWorkModelCopyWith<$Res> implements $$ScoreWorkModelCopyWith<$Res> {
  _ScoreWorkModelCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final ScoreWorkModel _value;

  @_i3.override
  _i3.String get title => _value.title;

  @_i3.override
  _i3.String get number => _value.number;

  @_i3.override
  $Res call({_i3.Object? title = _sentinel, _i3.Object? number = _sentinel}) {
    return (ScoreWorkModel(
      title: _i3.identical(title, _sentinel)
          ? this.title
          : (title as _i3.String),
      number: _i3.identical(number, _sentinel)
          ? this.number
          : (number as _i3.String),
    ) as $Res);
  }
}
