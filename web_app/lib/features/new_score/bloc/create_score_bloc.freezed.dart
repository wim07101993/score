// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'create_score_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$CreateScoreEvent {
  Score get score => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Score score) save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(Score score)? save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Score score)? save,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CreateScoreEvent value) save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_CreateScoreEvent value)? save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CreateScoreEvent value)? save,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CreateScoreEventCopyWith<CreateScoreEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateScoreEventCopyWith<$Res> {
  factory $CreateScoreEventCopyWith(
          CreateScoreEvent value, $Res Function(CreateScoreEvent) then) =
      _$CreateScoreEventCopyWithImpl<$Res>;
  $Res call({Score score});
}

/// @nodoc
class _$CreateScoreEventCopyWithImpl<$Res>
    implements $CreateScoreEventCopyWith<$Res> {
  _$CreateScoreEventCopyWithImpl(this._value, this._then);

  final CreateScoreEvent _value;
  // ignore: unused_field
  final $Res Function(CreateScoreEvent) _then;

  @override
  $Res call({
    Object? score = freezed,
  }) {
    return _then(_value.copyWith(
      score: score == freezed
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as Score,
    ));
  }
}

/// @nodoc
abstract class _$$_CreateScoreEventCopyWith<$Res>
    implements $CreateScoreEventCopyWith<$Res> {
  factory _$$_CreateScoreEventCopyWith(
          _$_CreateScoreEvent value, $Res Function(_$_CreateScoreEvent) then) =
      __$$_CreateScoreEventCopyWithImpl<$Res>;
  @override
  $Res call({Score score});
}

/// @nodoc
class __$$_CreateScoreEventCopyWithImpl<$Res>
    extends _$CreateScoreEventCopyWithImpl<$Res>
    implements _$$_CreateScoreEventCopyWith<$Res> {
  __$$_CreateScoreEventCopyWithImpl(
      _$_CreateScoreEvent _value, $Res Function(_$_CreateScoreEvent) _then)
      : super(_value, (v) => _then(v as _$_CreateScoreEvent));

  @override
  _$_CreateScoreEvent get _value => super._value as _$_CreateScoreEvent;

  @override
  $Res call({
    Object? score = freezed,
  }) {
    return _then(_$_CreateScoreEvent(
      score == freezed
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as Score,
    ));
  }
}

/// @nodoc

class _$_CreateScoreEvent implements _CreateScoreEvent {
  const _$_CreateScoreEvent(this.score);

  @override
  final Score score;

  @override
  String toString() {
    return 'CreateScoreEvent.save(score: $score)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CreateScoreEvent &&
            const DeepCollectionEquality().equals(other.score, score));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(score));

  @JsonKey(ignore: true)
  @override
  _$$_CreateScoreEventCopyWith<_$_CreateScoreEvent> get copyWith =>
      __$$_CreateScoreEventCopyWithImpl<_$_CreateScoreEvent>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Score score) save,
  }) {
    return save(score);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(Score score)? save,
  }) {
    return save?.call(score);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Score score)? save,
    required TResult orElse(),
  }) {
    if (save != null) {
      return save(score);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CreateScoreEvent value) save,
  }) {
    return save(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_CreateScoreEvent value)? save,
  }) {
    return save?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CreateScoreEvent value)? save,
    required TResult orElse(),
  }) {
    if (save != null) {
      return save(this);
    }
    return orElse();
  }
}

abstract class _CreateScoreEvent implements CreateScoreEvent {
  const factory _CreateScoreEvent(final Score score) = _$_CreateScoreEvent;

  @override
  Score get score;
  @override
  @JsonKey(ignore: true)
  _$$_CreateScoreEventCopyWith<_$_CreateScoreEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CreateScoreState {
  Object? get error => throw _privateConstructorUsedError;
  bool get created => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CreateScoreStateCopyWith<CreateScoreState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateScoreStateCopyWith<$Res> {
  factory $CreateScoreStateCopyWith(
          CreateScoreState value, $Res Function(CreateScoreState) then) =
      _$CreateScoreStateCopyWithImpl<$Res>;
  $Res call({Object? error, bool created});
}

/// @nodoc
class _$CreateScoreStateCopyWithImpl<$Res>
    implements $CreateScoreStateCopyWith<$Res> {
  _$CreateScoreStateCopyWithImpl(this._value, this._then);

  final CreateScoreState _value;
  // ignore: unused_field
  final $Res Function(CreateScoreState) _then;

  @override
  $Res call({
    Object? error = freezed,
    Object? created = freezed,
  }) {
    return _then(_value.copyWith(
      error: error == freezed ? _value.error : error,
      created: created == freezed
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$$_CreateScoreStateCopyWith<$Res>
    implements $CreateScoreStateCopyWith<$Res> {
  factory _$$_CreateScoreStateCopyWith(
          _$_CreateScoreState value, $Res Function(_$_CreateScoreState) then) =
      __$$_CreateScoreStateCopyWithImpl<$Res>;
  @override
  $Res call({Object? error, bool created});
}

/// @nodoc
class __$$_CreateScoreStateCopyWithImpl<$Res>
    extends _$CreateScoreStateCopyWithImpl<$Res>
    implements _$$_CreateScoreStateCopyWith<$Res> {
  __$$_CreateScoreStateCopyWithImpl(
      _$_CreateScoreState _value, $Res Function(_$_CreateScoreState) _then)
      : super(_value, (v) => _then(v as _$_CreateScoreState));

  @override
  _$_CreateScoreState get _value => super._value as _$_CreateScoreState;

  @override
  $Res call({
    Object? error = freezed,
    Object? created = freezed,
  }) {
    return _then(_$_CreateScoreState(
      error: error == freezed ? _value.error : error,
      created: created == freezed
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_CreateScoreState implements _CreateScoreState {
  const _$_CreateScoreState({this.error, this.created = false});

  @override
  final Object? error;
  @override
  @JsonKey()
  final bool created;

  @override
  String toString() {
    return 'CreateScoreState(error: $error, created: $created)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CreateScoreState &&
            const DeepCollectionEquality().equals(other.error, error) &&
            const DeepCollectionEquality().equals(other.created, created));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(error),
      const DeepCollectionEquality().hash(created));

  @JsonKey(ignore: true)
  @override
  _$$_CreateScoreStateCopyWith<_$_CreateScoreState> get copyWith =>
      __$$_CreateScoreStateCopyWithImpl<_$_CreateScoreState>(this, _$identity);
}

abstract class _CreateScoreState implements CreateScoreState {
  const factory _CreateScoreState({final Object? error, final bool created}) =
      _$_CreateScoreState;

  @override
  Object? get error;
  @override
  bool get created;
  @override
  @JsonKey(ignore: true)
  _$$_CreateScoreStateCopyWith<_$_CreateScoreState> get copyWith =>
      throw _privateConstructorUsedError;
}
