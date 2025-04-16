import 'package:fun_edu/core/base/base_response.dart';
import 'package:fun_edu/core/services/question_service.dart';
import 'package:fun_edu/model/question_model.dart';


abstract class QuestionRepository {
  Future<BaseResponse<QuestionModel>> getQuestion(
    String? type,
    int? age, {
    int page = 0,
    int size = 10,
  });
}

class QuestionRepositoryImpl implements QuestionRepository {
  final QuestionService questionService;

  QuestionRepositoryImpl({
    required this.questionService,
  });

  @override
  Future<BaseResponse<QuestionModel>> getQuestion(
    String? type,
    int? age, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      final result = await questionService.getQuestion(
        page,
        size,
        type,
        age,
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }
}
