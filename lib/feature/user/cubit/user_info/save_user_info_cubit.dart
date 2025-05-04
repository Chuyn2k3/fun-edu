import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/core/repositories/user_repository.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';
import 'package:get_it/get_it.dart';

part 'save_user_info_state.dart';

GetIt _sl = GetIt.instance;

class SaveUserInfoCubit extends Cubit<SaveUserInfoState> {
  SaveUserInfoCubit() : super(SaveUserInfoInitialState());
  final UserRepository _userRepository = _sl();
  void saveDeviceInfo({
    required UserInfoByDeviceIdModel request,
  }) async {
    emit(SaveUserInfoLoadingState());
    try {
      final _ = await _userRepository.saveUserByDeviceId(request);
      emit(SaveUserInfoLoadedState());
    } on DioError catch (e) {
      emit(SaveUserInfoErrorState(error: e.message));
    }
  }
}
