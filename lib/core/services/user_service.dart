import 'package:dio/dio.dart';
import 'package:fun_edu/core/base/base_response.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';
import 'package:retrofit/retrofit.dart';

part 'user_service.g.dart';

@RestApi()
abstract class UserServices {
  factory UserServices(Dio dio, {String baseUrl}) = _UserServices;
  @POST("/api/v1/user")
  Future<void> saveUserByDeviceId(@Body() UserInfoByDeviceIdModel request);

  @GET("/api/v1/user/{deviceId}")
  Future<BaseResponse<UserInfoByDeviceIdModel>> getUserInfo(
      @Path("deviceId") String deviceId);

  @PUT("/api/v1/user/update-coin")
  Future<void> updateUserCoin(@Body() UserInfoByDeviceIdModel request);

  @GET("/api/v1/user/get-all")
  Future<BaseResponseList<UserInfoByDeviceIdModel>> getAllUser();
}
