part of 'update_user_coin_cubit.dart';

abstract class UpdateUserCoinState extends Equatable {
  const UpdateUserCoinState();
}

class UpdateUserCoinInitialState extends UpdateUserCoinState {
  @override
  List<Object> get props => [];
}

class UpdateUserCoinLoadingState extends UpdateUserCoinState {
  @override
  List<Object> get props => [];
}

class UpdateUserCoinLoadedState extends UpdateUserCoinState {
  @override
  List<Object> get props => [];
}

class EmptyUpdateUserCoinState extends UpdateUserCoinState {
  @override
  List<Object> get props => [];
}

class UpdateUserCoinErrorState extends UpdateUserCoinState {
  final String error;
  const UpdateUserCoinErrorState({required this.error});

  @override
  List<Object> get props => [error];
}
