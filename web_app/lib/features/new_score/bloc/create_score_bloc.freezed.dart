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
  DraftScore get score => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DraftScore score) save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(DraftScore score)? save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DraftScore score)? save,
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
  $Res call({DraftScore score});
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
              as DraftScore,
    ));
  }
}

/// @nodoc
abstract class _$CreateScoreEventCopyWith<$Res>
    implements $CreateScoreEventCopyWith<$Res> {
  factory _$CreateScoreEventCopyWith(
          _CreateScoreEvent value, $Res Function(_CreateScoreEvent) then) =
      __$CreateScoreEventCopyWithImpl<$Res>;
  @override
  $Res call({DraftScore score});
}

/// @nodoc
class __$CreateScoreEventCopyWithImpl<$Res>
    extends _$CreateScoreEventCopyWithImpl<$Res>
    implements _$CreateScoreEventCopyWith<$Res> {
  __$CreateScoreEventCopyWithImpl(
      _CreateScoreEvent _value, $Res Function(_CreateScoreEvent) _then)
      : super(_value, (v) => _then(v as _CreateScoreEvent));

  @override
  _CreateScoreEvent get _value => super._value as _CreateScoreEvent;

  @override
  $Res call({
    Object? score = freezed,
  }) {
    return _then(_CreateScoreEvent(
      score == freezed
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as DraftScore,
    ));
  }
}

/// @nodoc

class _$_CreateScoreEvent implements _CreateScoreEvent {
  const _$_CreateScoreEvent(this.score);

  @override
  final DraftScore score;

  @override
  String toString() {
    return 'CreateScoreEvent.save(score: $score)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CreateScoreEvent &&
            const DeepCollectionEquality().equals(other.score, score));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(score));

  @JsonKey(ignore: true)
  @override
  _$CreateScoreEventCopyWith<_CreateScoreEvent> get copyWith =>
      __$CreateScoreEventCopyWithImpl<_CreateScoreEvent>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DraftScore score) save,
  }) {
    return save(score);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(DraftScore score)? save,
  }) {
    return save?.call(score);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DraftScore score)? save,
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
  const factory _CreateScoreEvent(final DraftScore score) = _$_CreateScoreEvent;

  @override
  DraftScore get score => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$CreateScoreEventCopyWith<_CreateScoreEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CreateScoreState {
  Object? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CreateScoreStateCopyWith<CreateScoreState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateScoreStateCopyWith<$Res> {
  factory $CreateScoreStateCopyWith(
          CreateScoreState value, $Res Function(CreateScoreState) then) =
      _$CreateScoreStateCopyWithImpl<$Res>;
  $Res call({Object? error});
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
  }) {
    return _then(_value.copyWith(
      error: error == freezed ? _value.error : error,
    ));
  }
}

/// @nodoc
abstract class _$CreateScoreStateCopyWith<$Res>
    implements $CreateScoreStateCopyWith<$Res> {
  factory _$CreateScoreStateCopyWith(
          _CreateScoreState value, $Res Function(_CreateScoreState) then) =
      __$CreateScoreStateCopyWithImpl<$Res>;
  @override
  $Res call({Object? error});
}

/// @nodoc
class __$CreateScoreStateCopyWithImpl<$Res>
    extends _$CreateScoreStateCopyWithImpl<$Res>
    implements _$CreateScoreStateCopyWith<$Res> {
  __$CreateScoreStateCopyWithImpl(
      _CreateScoreState _value, $Res Function(_CreateScoreState) _then)
      : super(_value, (v) => _then(v as _CreateScoreState));

  @override
  _CreateScoreState get _value => super._value as _CreateScoreState;

  @override
  $Res call({
    Object? error = freezed,
  }) {
    return _then(_CreateScoreState(
      error: error == freezed ? _value.error : error,
    ));
  }
}

/// @nodoc

class _$_CreateScoreState implements _CreateScoreState {
  const _$_CreateScoreState({this.error});

  @override
  final Object? error;

  @override
  String toString() {
    return 'CreateScoreState(error: $error)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CreateScoreState &&
            const DeepCollectionEquality().equals(other.error, error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(error));

  @JsonKey(ignore: true)
  @override
  _$CreateScoreStateCopyWith<_CreateScoreState> get copyWith =>
      __$CreateScoreStateCopyWithImpl<_CreateScoreState>(this, _$identity);
}

abstract class _CreateScoreState implements CreateScoreState {
  const factory _CreateScoreState({final Object? error}) = _$_CreateScoreState;

  @override
  Object? get error => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$CreateScoreStateCopyWith<_CreateScoreState> get copyWith =>
      throw _privateConstructorUsedError;
}