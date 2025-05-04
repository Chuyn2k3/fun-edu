import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fun_edu/utils/enum/question_type.dart';
part 'question_model.g.dart';

@JsonSerializable()
class QuestionModel {
  int id;
  String? title;
  String? content;
  String? imageUrl;
  QuestionType? type;
  String? createTime;
  String? updateTime;
  List<AnswerResList>? answers;

  QuestionModel({
    required this.id,
    this.title,
    this.content,
    this.imageUrl,
    this.type,
    this.createTime,
    this.updateTime,
    this.answers,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionModelToJson(this);
}

@JsonSerializable()
class AnswerResList {
  int id;
  String? content;
  bool? isCorrect;
  int questionId;

  AnswerResList({
    required this.id,
    this.content,
    this.isCorrect,
    required this.questionId,
  });
  factory AnswerResList.fromJson(Map<String, dynamic> json) =>
      _$AnswerResListFromJson(json);
  Map<String, dynamic> toJson() => _$AnswerResListToJson(this);
}
