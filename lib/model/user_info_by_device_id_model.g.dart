// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_by_device_id_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfoByDeviceIdModel _$UserInfoByDeviceIdModelFromJson(
        Map<String, dynamic> json) =>
    UserInfoByDeviceIdModel(
      deviceId: json['deviceId'] as String?,
      userName: json['username'] as String?,
      age: (json['age'] as num?)?.toInt(),
      coin: (json['coin'] as num?)?.toInt(),
      gameName: json['gameName'] as String?,
    );

Map<String, dynamic> _$UserInfoByDeviceIdModelToJson(
        UserInfoByDeviceIdModel instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'username': instance.userName,
      'age': instance.age,
      'coin': instance.coin,
      'gameName': instance.gameName,
    };
