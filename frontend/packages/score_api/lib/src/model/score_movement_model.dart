// Generated code - do not modify by hand

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:convert' as _i4;
import 'dart:core' as _i3;

import 'package:meta/meta.dart' as _i2;
import 'package:tonik_util/tonik_util.dart' as _i1;

/// The movement within the work. Empty strings when the document names none.
@_i2.immutable
class ScoreMovementModel extends _i1.ObjectParameterEncodable
    implements _i1.UriEncodable {
  const ScoreMovementModel({required this.title, required this.number});

  factory ScoreMovementModel.fromSimple(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'title', r'number'},
      listKeys: {},
      context: r'ScoreMovementModel',
    );
    return ScoreMovementModel(
      title: _$values[r'title'].decodeSimpleString(
        context: r'ScoreMovementModel.title',
      ),
      number: _$values[r'number'].decodeSimpleString(
        context: r'ScoreMovementModel.number',
      ),
    );
  }

  factory ScoreMovementModel.fromJson(_i3.Object? json) {
    final _$map = json.decodeMap(context: r'ScoreMovementModel');
    return ScoreMovementModel(
      title: _$map[r'title'].decodeJsonString(
        context: r'ScoreMovementModel.title',
      ),
      number: _$map[r'number'].decodeJsonString(
        context: r'ScoreMovementModel.number',
      ),
    );
  }

  factory ScoreMovementModel.fromForm(
    _i3.String? value, {
    required _i3.bool explode,
  }) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'title', r'number'},
      listKeys: {},
      context: r'ScoreMovementModel',
    );
    return ScoreMovementModel(
      title: _$values[r'title'].decodeFormString(
        context: r'ScoreMovementModel.title',
      ),
      number: _$values[r'number'].decodeFormString(
        context: r'ScoreMovementModel.number',
      ),
    );
  }

  final _i3.String title;

  final _i3.String number;

  @_i3.override
  _i3.Object? toJson() => {r'title': title, r'number': number};

  $$ScoreMovementModelCopyWith<ScoreMovementModel> get copyWith =>
      _ScoreMovementModelCopyWith(this);

  @_i3.override
  _i3.bool operator ==(_i3.Object other) {
    if (_i3.identical(this, other)) return true;
    return other is ScoreMovementModel &&
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
      r'Cannot uriEncode ScoreMovementModel: complex types cannot be URI-encoded',
    );
  }
}

abstract class $$ScoreMovementModelCopyWith<$Res> {
  factory $$ScoreMovementModelCopyWith(ScoreMovementModel value) =
      _ScoreMovementModelCopyWith<$Res>;

  $Res call({_i3.String? title, _i3.String? number});
  _i3.String get title;
  _i3.String get number;
}

class _ScoreMovementModelCopyWith<$Res>
    implements $$ScoreMovementModelCopyWith<$Res> {
  _ScoreMovementModelCopyWith(this._value);

  static const _sentinel = _i3.Object();

  final ScoreMovementModel _value;

  @_i3.override
  _i3.String get title => _value.title;

  @_i3.override
  _i3.String get number => _value.number;

  @_i3.override
  $Res call({_i3.Object? title = _sentinel, _i3.Object? number = _sentinel}) {
    return (ScoreMovementModel(
      title: _i3.identical(title, _sentinel)
          ? this.title
          : (title as _i3.String),
      number: _i3.identical(number, _sentinel)
          ? this.number
          : (number as _i3.String),
    ) as $Res);
  }
}
