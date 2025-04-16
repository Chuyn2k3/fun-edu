import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_response.g.dart';

@JsonSerializable(
  genericArgumentFactories: true,
)
class BaseResponse<T> {
  final DataResponse<T>? data;
  final int? code;
  final String? message;

  BaseResponse(
    this.data,
    this.code,
    this.message,
  );

  factory BaseResponse.fromJson(Map<String, dynamic> json,  T Function(Object? json) fromJsonT,) =>
      _$BaseResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => _$BaseResponseToJson(this, toJsonT);
}

@JsonSerializable(
  genericArgumentFactories: true,
)
class DataResponse<T> {
  final List<T>? content;

  DataResponse(this.content);

  factory DataResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$DataResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$DataResponseToJson(this, toJsonT);
}
