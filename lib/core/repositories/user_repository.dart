import 'package:fun_edu/core/base/base_response.dart';
import 'package:fun_edu/core/services/user_service.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';

abstract class UserRepository {
  Future<void> saveUserByDeviceId(UserInfoByDeviceIdModel request);
  Future<BaseResponse<UserInfoByDeviceIdModel>> getUserInfo(
      {required String deviceId});
  Future<void> updateUserCoin(UserInfoByDeviceIdModel request);
  Future<BaseResponseList<UserInfoByDeviceIdModel>> getAllUser();
}

class UserRepositoryImpl implements UserRepository {
  final UserServices userServices;
  const UserRepositoryImpl({required this.userServices});

  @override
  Future<void> saveUserByDeviceId(UserInfoByDeviceIdModel request) async {
    try {
      final _ = await userServices.saveUserByDeviceId(request);
      return;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponse<UserInfoByDeviceIdModel>> getUserInfo(
      {required String deviceId}) async {
    try {
      final result = await userServices.getUserInfo(deviceId);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUserCoin(UserInfoByDeviceIdModel request) async {
    try {
      final _ = await userServices.updateUserCoin(request);
      return;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BaseResponseList<UserInfoByDeviceIdModel>> getAllUser() async {
    try {
      final result = await userServices.getAllUser();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
