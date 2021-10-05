// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'access_levels.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

AccessLevels _$AccessLevelsFromJson(Map<String, dynamic> json) {
  return _AccessLevels.fromJson(json);
}

/// @nodoc
class _$AccessLevelsTearOff {
  const _$AccessLevelsTearOff();

  _AccessLevels call({bool application = false, bool admin = false}) {
    return _AccessLevels(
      application: application,
      admin: admin,
    );
  }

  AccessLevels fromJson(Map<String, Object> json) {
    return AccessLevels.fromJson(json);
  }
}

/// @nodoc
const $AccessLevels = _$AccessLevelsTearOff();

/// @nodoc
mixin _$AccessLevels {
  bool get application => throw _privateConstructorUsedError;
  bool get admin => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AccessLevelsCopyWith<AccessLevels> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccessLevelsCopyWith<$Res> {
  factory $AccessLevelsCopyWith(
          AccessLevels value, $Res Function(AccessLevels) then) =
      _$AccessLevelsCopyWithImpl<$Res>;
  $Res call({bool application, bool admin});
}

/// @nodoc
class _$AccessLevelsCopyWithImpl<$Res> implements $AccessLevelsCopyWith<$Res> {
  _$AccessLevelsCopyWithImpl(this._value, this._then);

  final AccessLevels _value;
  // ignore: unused_field
  final $Res Function(AccessLevels) _then;

  @override
  $Res call({
    Object? application = freezed,
    Object? admin = freezed,
  }) {
    return _then(_value.copyWith(
      application: application == freezed
          ? _value.application
          : application // ignore: cast_nullable_to_non_nullable
              as bool,
      admin: admin == freezed
          ? _value.admin
          : admin // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
abstract class _$AccessLevelsCopyWith<$Res>
    implements $AccessLevelsCopyWith<$Res> {
  factory _$AccessLevelsCopyWith(
          _AccessLevels value, $Res Function(_AccessLevels) then) =
      __$AccessLevelsCopyWithImpl<$Res>;
  @override
  $Res call({bool application, bool admin});
}

/// @nodoc
class __$AccessLevelsCopyWithImpl<$Res> extends _$AccessLevelsCopyWithImpl<$Res>
    implements _$AccessLevelsCopyWith<$Res> {
  __$AccessLevelsCopyWithImpl(
      _AccessLevels _value, $Res Function(_AccessLevels) _then)
      : super(_value, (v) => _then(v as _AccessLevels));

  @override
  _AccessLevels get _value => super._value as _AccessLevels;

  @override
  $Res call({
    Object? application = freezed,
    Object? admin = freezed,
  }) {
    return _then(_AccessLevels(
      application: application == freezed
          ? _value.application
          : application // ignore: cast_nullable_to_non_nullable
              as bool,
      admin: admin == freezed
          ? _value.admin
          : admin // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_AccessLevels implements _AccessLevels {
  const _$_AccessLevels({this.application = false, this.admin = false});

  factory _$_AccessLevels.fromJson(Map<String, dynamic> json) =>
      _$_$_AccessLevelsFromJson(json);

  @JsonKey(defaultValue: false)
  @override
  final bool application;
  @JsonKey(defaultValue: false)
  @override
  final bool admin;

  @override
  String toString() {
    return 'AccessLevels(application: $application, admin: $admin)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _AccessLevels &&
            (identical(other.application, application) ||
                const DeepCollectionEquality()
                    .equals(other.application, application)) &&
            (identical(other.admin, admin) ||
                const DeepCollectionEquality().equals(other.admin, admin)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(application) ^
      const DeepCollectionEquality().hash(admin);

  @JsonKey(ignore: true)
  @override
  _$AccessLevelsCopyWith<_AccessLevels> get copyWith =>
      __$AccessLevelsCopyWithImpl<_AccessLevels>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$_$_AccessLevelsToJson(this);
  }
}

abstract class _AccessLevels implements AccessLevels {
  const factory _AccessLevels({bool application, bool admin}) = _$_AccessLevels;

  factory _AccessLevels.fromJson(Map<String, dynamic> json) =
      _$_AccessLevels.fromJson;

  @override
  bool get application => throw _privateConstructorUsedError;
  @override
  bool get admin => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$AccessLevelsCopyWith<_AccessLevels> get copyWith =>
      throw _privateConstructorUsedError;
}
