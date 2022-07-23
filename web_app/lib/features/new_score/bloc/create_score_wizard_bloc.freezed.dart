// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'create_score_wizard_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$CreateScoreWizardEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? save,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? save,
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
}

/// @nodoc
abstract class $CreateScoreWizardEventCopyWith<$Res> {
  factory $CreateScoreWizardEventCopyWith(CreateScoreWizardEvent value,
          $Res Function(CreateScoreWizardEvent) then) =
      _$CreateScoreWizardEventCopyWithImpl<$Res>;
}

/// @nodoc
class _$CreateScoreWizardEventCopyWithImpl<$Res>
    implements $CreateScoreWizardEventCopyWith<$Res> {
  _$CreateScoreWizardEventCopyWithImpl(this._value, this._then);

  final CreateScoreWizardEvent _value;
  // ignore: unused_field
  final $Res Function(CreateScoreWizardEvent) _then;
}

/// @nodoc
abstract class _$$_CreateScoreEventCopyWith<$Res> {
  factory _$$_CreateScoreEventCopyWith(
          _$_CreateScoreEvent value, $Res Function(_$_CreateScoreEvent) then) =
      __$$_CreateScoreEventCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_CreateScoreEventCopyWithImpl<$Res>
    extends _$CreateScoreWizardEventCopyWithImpl<$Res>
    implements _$$_CreateScoreEventCopyWith<$Res> {
  __$$_CreateScoreEventCopyWithImpl(
      _$_CreateScoreEvent _value, $Res Function(_$_CreateScoreEvent) _then)
      : super(_value, (v) => _then(v as _$_CreateScoreEvent));

  @override
  _$_CreateScoreEvent get _value => super._value as _$_CreateScoreEvent;
}

/// @nodoc

class _$_CreateScoreEvent implements _CreateScoreEvent {
  const _$_CreateScoreEvent();

  @override
  String toString() {
    return 'CreateScoreWizardEvent.save()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_CreateScoreEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() save,
  }) {
    return save();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? save,
  }) {
    return save?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? save,
    required TResult orElse(),
  }) {
    if (save != null) {
      return save();
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

abstract class _CreateScoreEvent implements CreateScoreWizardEvent {
  const factory _CreateScoreEvent() = _$_CreateScoreEvent;
}

/// @nodoc
mixin _$CreateScoreWizardState {
  Object? get error => throw _privateConstructorUsedError;
  EditableScore get score => throw _privateConstructorUsedError;
  bool get created => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CreateScoreWizardStateCopyWith<CreateScoreWizardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateScoreWizardStateCopyWith<$Res> {
  factory $CreateScoreWizardStateCopyWith(CreateScoreWizardState value,
          $Res Function(CreateScoreWizardState) then) =
      _$CreateScoreWizardStateCopyWithImpl<$Res>;
  $Res call({Object? error, EditableScore score, bool created});
}

/// @nodoc
class _$CreateScoreWizardStateCopyWithImpl<$Res>
    implements $CreateScoreWizardStateCopyWith<$Res> {
  _$CreateScoreWizardStateCopyWithImpl(this._value, this._then);

  final CreateScoreWizardState _value;
  // ignore: unused_field
  final $Res Function(CreateScoreWizardState) _then;

  @override
  $Res call({
    Object? error = freezed,
    Object? score = freezed,
    Object? created = freezed,
  }) {
    return _then(_value.copyWith(
      error: error == freezed ? _value.error : error,
      score: score == freezed
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as EditableScore,
      created: created == freezed
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$$_CreateScoreStateCopyWith<$Res>
    implements $CreateScoreWizardStateCopyWith<$Res> {
  factory _$$_CreateScoreStateCopyWith(
          _$_CreateScoreState value, $Res Function(_$_CreateScoreState) then) =
      __$$_CreateScoreStateCopyWithImpl<$Res>;
  @override
  $Res call({Object? error, EditableScore score, bool created});
}

/// @nodoc
class __$$_CreateScoreStateCopyWithImpl<$Res>
    extends _$CreateScoreWizardStateCopyWithImpl<$Res>
    implements _$$_CreateScoreStateCopyWith<$Res> {
  __$$_CreateScoreStateCopyWithImpl(
      _$_CreateScoreState _value, $Res Function(_$_CreateScoreState) _then)
      : super(_value, (v) => _then(v as _$_CreateScoreState));

  @override
  _$_CreateScoreState get _value => super._value as _$_CreateScoreState;

  @override
  $Res call({
    Object? error = freezed,
    Object? score = freezed,
    Object? created = freezed,
  }) {
    return _then(_$_CreateScoreState(
      error: error == freezed ? _value.error : error,
      score: score == freezed
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as EditableScore,
      created: created == freezed
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_CreateScoreState implements _CreateScoreState {
  const _$_CreateScoreState(
      {this.error, required this.score, this.created = false});

  @override
  final Object? error;
  @override
  final EditableScore score;
  @override
  @JsonKey()
  final bool created;

  @override
  String toString() {
    return 'CreateScoreWizardState(error: $error, score: $score, created: $created)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CreateScoreState &&
            const DeepCollectionEquality().equals(other.error, error) &&
            const DeepCollectionEquality().equals(other.score, score) &&
            const DeepCollectionEquality().equals(other.created, created));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(error),
      const DeepCollectionEquality().hash(score),
      const DeepCollectionEquality().hash(created));

  @JsonKey(ignore: true)
  @override
  _$$_CreateScoreStateCopyWith<_$_CreateScoreState> get copyWith =>
      __$$_CreateScoreStateCopyWithImpl<_$_CreateScoreState>(this, _$identity);
}

abstract class _CreateScoreState implements CreateScoreWizardState {
  const factory _CreateScoreState(
      {final Object? error,
      required final EditableScore score,
      final bool created}) = _$_CreateScoreState;

  @override
  Object? get error;
  @override
  EditableScore get score;
  @override
  bool get created;
  @override
  @JsonKey(ignore: true)
  _$$_CreateScoreStateCopyWith<_$_CreateScoreState> get copyWith =>
      throw _privateConstructorUsedError;
}