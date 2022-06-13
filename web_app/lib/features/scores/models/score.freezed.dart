// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$Score {
  String get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  String? get dedication => throw _privateConstructorUsedError;
  List<String> get composers => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScoreCopyWith<Score> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScoreCopyWith<$Res> {
  factory $ScoreCopyWith(Score value, $Res Function(Score) then) =
      _$ScoreCopyWithImpl<$Res>;
  $Res call(
      {String title,
      String? subtitle,
      String? dedication,
      List<String> composers});
}

/// @nodoc
class _$ScoreCopyWithImpl<$Res> implements $ScoreCopyWith<$Res> {
  _$ScoreCopyWithImpl(this._value, this._then);

  final Score _value;
  // ignore: unused_field
  final $Res Function(Score) _then;

  @override
  $Res call({
    Object? title = freezed,
    Object? subtitle = freezed,
    Object? dedication = freezed,
    Object? composers = freezed,
  }) {
    return _then(_value.copyWith(
      title: title == freezed
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: subtitle == freezed
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String?,
      dedication: dedication == freezed
          ? _value.dedication
          : dedication // ignore: cast_nullable_to_non_nullable
              as String?,
      composers: composers == freezed
          ? _value.composers
          : composers // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
abstract class _$ScoreCopyWith<$Res> implements $ScoreCopyWith<$Res> {
  factory _$ScoreCopyWith(_Score value, $Res Function(_Score) then) =
      __$ScoreCopyWithImpl<$Res>;
  @override
  $Res call(
      {String title,
      String? subtitle,
      String? dedication,
      List<String> composers});
}

/// @nodoc
class __$ScoreCopyWithImpl<$Res> extends _$ScoreCopyWithImpl<$Res>
    implements _$ScoreCopyWith<$Res> {
  __$ScoreCopyWithImpl(_Score _value, $Res Function(_Score) _then)
      : super(_value, (v) => _then(v as _Score));

  @override
  _Score get _value => super._value as _Score;

  @override
  $Res call({
    Object? title = freezed,
    Object? subtitle = freezed,
    Object? dedication = freezed,
    Object? composers = freezed,
  }) {
    return _then(_Score(
      title: title == freezed
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: subtitle == freezed
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String?,
      dedication: dedication == freezed
          ? _value.dedication
          : dedication // ignore: cast_nullable_to_non_nullable
              as String?,
      composers: composers == freezed
          ? _value.composers
          : composers // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$_Score extends _Score {
  const _$_Score(
      {required this.title,
      required this.subtitle,
      required this.dedication,
      required final List<String> composers})
      : _composers = composers,
        super._();

  @override
  final String title;
  @override
  final String? subtitle;
  @override
  final String? dedication;
  final List<String> _composers;
  @override
  List<String> get composers {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_composers);
  }

  @override
  String toString() {
    return 'Score(title: $title, subtitle: $subtitle, dedication: $dedication, composers: $composers)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Score &&
            const DeepCollectionEquality().equals(other.title, title) &&
            const DeepCollectionEquality().equals(other.subtitle, subtitle) &&
            const DeepCollectionEquality()
                .equals(other.dedication, dedication) &&
            const DeepCollectionEquality().equals(other.composers, composers));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(title),
      const DeepCollectionEquality().hash(subtitle),
      const DeepCollectionEquality().hash(dedication),
      const DeepCollectionEquality().hash(composers));

  @JsonKey(ignore: true)
  @override
  _$ScoreCopyWith<_Score> get copyWith =>
      __$ScoreCopyWithImpl<_Score>(this, _$identity);
}

abstract class _Score extends Score {
  const factory _Score(
      {required final String title,
      required final String? subtitle,
      required final String? dedication,
      required final List<String> composers}) = _$_Score;
  const _Score._() : super._();

  @override
  String get title => throw _privateConstructorUsedError;
  @override
  String? get subtitle => throw _privateConstructorUsedError;
  @override
  String? get dedication => throw _privateConstructorUsedError;
  @override
  List<String> get composers => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$ScoreCopyWith<_Score> get copyWith => throw _privateConstructorUsedError;
}
