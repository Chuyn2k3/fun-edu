part of 'question_daily_cubit.dart';

abstract class QuestionDailyState extends Equatable {
  const QuestionDailyState();
}

class QuestionDailyInitState extends QuestionDailyState {
  @override
  List<Object> get props => [];
}

class QuestionDailyLoadingState extends QuestionDailyState {
  @override
  List<Object> get props => [];
}

class QuestionDailyLoadedState extends QuestionDailyState {
  final List<QuestionModel> questions;

  const QuestionDailyLoadedState({required this.questions});
  @override
  List<Object> get props => [questions];
}

class EmptyQuestionDailyState extends QuestionDailyState {
  @override
  List<Object> get props => [];
}

class QuestionDailyErrorState extends QuestionDailyState {
  final String error;
  const QuestionDailyErrorState({required this.error});

  @override
  List<Object> get props => [error];
}
