import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/core/repositories/user_repository.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';
import 'package:get_it/get_it.dart';

part 'get_user_info_state.dart';

GetIt _sl = GetIt.instance;

class GetUserInfoCubit extends Cubit<GetUserInfoState> {
  GetUserInfoCubit() : super(GetUserInfoInitialState());
  final UserRepository _userRepository = _sl();
  void getDeviceInfo({
    required String deviceId,
  }) async {
    emit(GetUserInfoLoadingState());
    try {
      final result = await _userRepository.getUserInfo(deviceId: deviceId);
      final response = result.data;
      print(result.data?.toJson());
      if (response != null) {
        emit(GetUserInfoLoadedState(user: response));
      } else {
        emit(EmptyGetUserInfoState());
      }
    } on DioError catch (e) {
      emit(GetUserInfoErrorState(error: e.message));
    }
  }
}
