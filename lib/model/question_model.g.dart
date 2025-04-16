// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) =>
    QuestionModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      imageUrl: json['imageUrl'] as String?,
      type: $enumDecodeNullable(_$QuestionTypeEnumMap, json['type']),
      answers: (json['answers'] as List<dynamic>?)
          ?.map((e) => AnswerResList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuestionModelToJson(QuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'imageUrl': instance.imageUrl,
      'type': _$QuestionTypeEnumMap[instance.type],
      'answers': instance.answers,
    };

const _$QuestionTypeEnumMap = {
  QuestionType.number: 'NUMBER',
  QuestionType.operator: 'OPERATOR',
  QuestionType.math: 'MATH',
};

AnswerResList _$AnswerResListFromJson(Map<String, dynamic> json) =>
    AnswerResList(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String?,
      isCorrect: json['isCorrect'] as bool?,
      questionId: (json['questionId'] as num).toInt(),
    );

Map<String, dynamic> _$AnswerResListToJson(AnswerResList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'isCorrect': instance.isCorrect,
      'questionId': instance.questionId,
    };
