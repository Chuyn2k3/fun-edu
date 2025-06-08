part of 'get_user_all_cubit.dart';

abstract class GetAllUserState extends Equatable {
  const GetAllUserState();
}

class GetAllUserInitialState extends GetAllUserState {
  @override
  List<Object> get props => [];
}

class GetAllUserLoadingState extends GetAllUserState {
  @override
  List<Object> get props => [];
}

class GetAllUserLoadedState extends GetAllUserState {
  final List<UserInfoByDeviceIdModel> getAllUser;
  const GetAllUserLoadedState({
    required this.getAllUser,
  });

  @override
  List<Object> get props => [getAllUser];
}

class EmptyDataCollectState extends GetAllUserState {
  @override
  List<Object> get props => [];
}

class GetAllUserErrorState extends GetAllUserState {
  final String error;
  const GetAllUserErrorState({required this.error});

  @override
  List<Object> get props => [error];
}
