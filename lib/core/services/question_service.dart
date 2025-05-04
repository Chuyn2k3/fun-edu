import 'package:dio/dio.dart';
import 'package:fun_edu/core/base/base_response.dart';
import 'package:fun_edu/model/question_model.dart';
import 'package:retrofit/retrofit.dart';

part 'question_service.g.dart';

@RestApi()
abstract class QuestionService {
  factory QuestionService(Dio dio, {String baseUrl}) = _QuestionService;
  @GET("40/api/v1/question")
  Future<BaseListResponse<QuestionModel>> getQuestion(
    @Query("page") int page,
    @Query("size") int size,
    @Query("type") String? type,
    @Query("age") int? age,
  );

  @GET("40/api/v1/question")
  Future<BaseListResponse<QuestionModel>> getQuestionDaily();
}
