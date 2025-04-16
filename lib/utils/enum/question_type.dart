import 'package:freezed_annotation/freezed_annotation.dart';

enum QuestionType {
  @JsonValue('NUMBER')
  number,

  @JsonValue('OPERATOR')
  operator,

  @JsonValue('MATH')
  math,
}
