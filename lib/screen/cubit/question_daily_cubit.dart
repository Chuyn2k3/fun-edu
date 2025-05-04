import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fun_edu/core/repositories/question_repository.dart';
import 'package:fun_edu/model/question_model.dart';
import 'package:get_it/get_it.dart';

part 'question_daily_state.dart';

GetIt _sl = GetIt.instance;

class QuestionDailyCubit extends Cubit<QuestionDailyState> {
  QuestionDailyCubit() : super(QuestionDailyInitState());
  final QuestionRepository _questionRepository = _sl();
  void getQuestionDaily() async {
    try {
      emit(QuestionDailyLoadingState());
      final result = await _questionRepository.getQuestionDaily();
      final questions = result.data?.content;
      if (questions != null) {
        emit(QuestionDailyLoadedState(questions: questions));
      } else {
        emit(EmptyQuestionDailyState());
      }
    } on DioError catch (e) {
      emit(QuestionDailyErrorState(error: e.message));
    }
  }
}
