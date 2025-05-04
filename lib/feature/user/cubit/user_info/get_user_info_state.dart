part of 'get_user_info_cubit.dart';

abstract class GetUserInfoState extends Equatable {
  const GetUserInfoState();
}

class GetUserInfoInitialState extends GetUserInfoState {
  @override
  List<Object> get props => [];
}

class GetUserInfoLoadingState extends GetUserInfoState {
  @override
  List<Object> get props => [];
}

class GetUserInfoLoadedState extends GetUserInfoState {
  final UserInfoByDeviceIdModel user;

  const GetUserInfoLoadedState({required this.user});
  @override
  List<Object> get props => [user];
}

class EmptyGetUserInfoState extends GetUserInfoState {
  @override
  List<Object> get props => [];
}

class GetUserInfoErrorState extends GetUserInfoState {
  final String error;
  const GetUserInfoErrorState({required this.error});

  @override
  List<Object> get props => [error];
}
