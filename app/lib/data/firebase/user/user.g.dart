// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_User _$_$_UserFromJson(Map<String, dynamic> json) {
  return _$_User(
    displayName: json['displayName'] as String,
    accessLevels:
        AccessLevels.fromJson(json['accessLevels'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$_$_UserToJson(_$_User instance) => <String, dynamic>{
      'displayName': instance.displayName,
      'accessLevels': instance.accessLevels,
    };
