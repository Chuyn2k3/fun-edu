import 'package:freezed_annotation/freezed_annotation.dart';
part 'user_info_by_device_id_model.g.dart';

@JsonSerializable()
class UserInfoByDeviceIdModel {
  final String? deviceId;
  @JsonKey(name: "username")
  final String? userName;
  final int? age;
  final int? coin;
  final String? gameName;
  UserInfoByDeviceIdModel({
     this.deviceId,
     this.userName,
     this.age,
     this.coin,
     this.gameName,
  });
  factory UserInfoByDeviceIdModel.fromJson(Map<String, dynamic> json) =>
      _$UserInfoByDeviceIdModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoByDeviceIdModelToJson(this);
}
