part of 'save_user_info_cubit.dart';

abstract class SaveUserInfoState extends Equatable {
  const SaveUserInfoState();
}

class SaveUserInfoInitialState extends SaveUserInfoState {
  @override
  List<Object> get props => [];
}

class SaveUserInfoLoadingState extends SaveUserInfoState {
  @override
  List<Object> get props => [];
}

class SaveUserInfoLoadedState extends SaveUserInfoState {
  @override
  List<Object> get props => [];
}

class EmptySaveUserInfoState extends SaveUserInfoState {
  @override
  List<Object> get props => [];
}

class SaveUserInfoErrorState extends SaveUserInfoState {
  final String error;
  const SaveUserInfoErrorState({required this.error});

  @override
  List<Object> get props => [error];
}
