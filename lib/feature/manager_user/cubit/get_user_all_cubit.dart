import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/core/repositories/user_repository.dart';
import 'package:fun_edu/model/user_info_by_device_id_model.dart';

import 'package:get_it/get_it.dart';

part 'get_user_all_state.dart';

GetIt _sl = GetIt.instance;

class GetAllUserCubit extends Cubit<GetAllUserState> {
  GetAllUserCubit() : super(GetAllUserInitialState());
  final UserRepository _userRepository = _sl();

  Future<void> getGetAllUser() async {
    try {
      emit(GetAllUserLoadingState());
      final result = await _userRepository.getAllUser();
      if (result.data != null) {
        emit(GetAllUserLoadedState(getAllUser: result.data ?? []));
      } else {
        emit(EmptyDataCollectState());
      }
    } catch (e) {
      emit(GetAllUserErrorState(error: e.toString()));
    }
  }
}
