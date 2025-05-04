import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/core/repositories/user_repository.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';
import 'package:get_it/get_it.dart';

part 'update_user_coin_state.dart';

GetIt _sl = GetIt.instance;

class UpdateUserCoinCubit extends Cubit<UpdateUserCoinState> {
  UpdateUserCoinCubit() : super(UpdateUserCoinInitialState());
  final UserRepository _userRepository = _sl();
  void updateUserCoin({
    required UserInfoByDeviceIdModel request,
  }) async {
    emit(UpdateUserCoinLoadingState());
    try {
      final _ = await _userRepository.updateUserCoin(request);
      emit(UpdateUserCoinLoadedState());
    } on DioError catch (e) {
      emit(UpdateUserCoinErrorState(error: e.message));
    }
  }
}
